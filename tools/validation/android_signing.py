"""Use explicitly authorized existing upload assets. Never create/reset a key."""
import datetime as dt
import hashlib
import os
from pathlib import Path
import re
import stat
import subprocess
import zipfile


class SigningError(Exception):
    pass


def _private_file(path, root):
    path = Path(path)
    try:
        info = path.stat()
        if (path.is_symlink() or path.resolve().is_relative_to(root.resolve())
                or not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid()
                or info.st_mode & 0o077 or path.parent.stat().st_mode & 0o077):
            raise SigningError('android_signing_file_must_be_private_outside_repository')
        return path.resolve()
    except OSError:
        raise SigningError('android_signing_file_missing_or_unreadable') from None


def _run(args, code):
    try:
        result = subprocess.run(args, capture_output=True, text=True, errors='replace',
                                stdin=subprocess.DEVNULL, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        raise SigningError(code) from None
    if result.returncode:
        # Never echo external output: errors can include secrets or personal DN.
        raise SigningError(code)
    return result.stdout


def inspect_signer(keystore, alias, password_file, expected_sha256, root,
                   key_password_file=None):
    if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}', alias or '') or alias.lower() == 'androiddebugkey':
        raise SigningError('invalid_android_upload_alias')
    expected = (expected_sha256 or '').replace(':', '').upper()
    if not re.fullmatch(r'[A-F0-9]{64}', expected):
        raise SigningError('android_upload_certificate_pin_required')
    key = _private_file(keystore, root)
    password = _private_file(password_file, root)
    files = [password]
    if key_password_file:
        files.append(_private_file(key_password_file, root))
    for p in files:
        if p.stat().st_size > 1026:
            raise SigningError('android_password_file_must_contain_one_nonempty_line')
        value = p.read_bytes().removesuffix(b'\n').removesuffix(b'\r')
        if not 6 <= len(value) <= 1024 or b'\n' in value or b'\r' in value:
            raise SigningError('android_password_file_must_contain_one_nonempty_line')
    listing = _run(['keytool', '-J-Duser.language=en', '-J-Duser.country=US',
                    '-J-Duser.timezone=UTC', '-list', '-v', '-keystore', str(key),
                    '-storepass:file', str(password), '-alias', alias],
                   'android_keystore_or_alias_rejected')
    fingerprint = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', listing)
    period = re.search(r'Valid from: (.*?) until: ([^\r\n]+)', listing)
    if ('Entry type: PrivateKeyEntry' not in listing
            or re.search(r'CN\s*=\s*Android Debug(?:,|\s|$)', listing, re.I)
            or not fingerprint or fingerprint[1].replace(':', '').upper() != expected
            or not period):
        raise SigningError('android_upload_certificate_mismatch_or_debug')
    try:
        start, end = [dt.datetime.strptime(v.strip(), '%a %b %d %H:%M:%S %Z %Y')
                      .replace(tzinfo=dt.timezone.utc) for v in period.groups()]
    except ValueError:
        raise SigningError('android_upload_certificate_dates_unreadable') from None
    if not start <= dt.datetime.now(dt.timezone.utc) < end:
        raise SigningError('android_upload_certificate_not_current')
    return {'alias': alias, 'certificate_sha256': expected,
            'certificate_expires_utc': end.isoformat(), 'debug_certificate': False}


def sign_aab(source, output, **credentials):
    source, output = Path(source), Path(output)
    if output.exists() or source.resolve() == output.resolve():
        raise SigningError('android_signed_output_must_be_new')
    metadata = inspect_signer(**credentials)
    args = ['-keystore', str(Path(credentials['keystore']).resolve()),
            '-storepass:file', str(Path(credentials['password_file']).resolve())]
    key_password = credentials.get('key_password_file') or credentials['password_file']
    try:
        _run(['jarsigner', '-J-Duser.language=en', '-J-Duser.country=US',
              *args, '-keypass:file', str(Path(key_password).resolve()),
              '-digestalg', 'SHA-256', '-signedjar', str(output), str(source),
              credentials['alias']], 'android_aab_signing_failed')
        result = _run(['jarsigner', '-J-Duser.language=en', '-J-Duser.country=US',
                       '-verify', '-strict', *args, str(output), credentials['alias']],
                      'android_aab_signature_verification_failed')
        if 'jar verified.' not in result.lower():
            raise SigningError('android_aab_signature_verification_failed')
        certificate = _run(['keytool', '-J-Duser.language=en', '-J-Duser.country=US',
                            '-printcert', '-v', '-jarfile', str(output)],
                           'android_signed_certificate_unreadable')
        fingerprint = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', certificate)
        if not fingerprint or fingerprint[1].replace(':', '').upper() != metadata['certificate_sha256']:
            raise SigningError('android_signed_certificate_pin_mismatch')
        with zipfile.ZipFile(source) as before, zipfile.ZipFile(output) as after:
            payload = lambda z: {n: hashlib.sha256(z.read(n)).hexdigest()
                                 for n in z.namelist() if not n.upper().startswith('META-INF/')}
            names = after.namelist()
            if (len(names) != len(set(names)) or payload(before) != payload(after)
                    or not any(n.upper().endswith('.SF') for n in names)
                    or not any(n.upper().endswith(('.RSA', '.DSA', '.EC')) for n in names)):
                raise SigningError('android_signed_payload_mismatch')
        return {**metadata, 'jarsigner_strict_verified': True,
                'payload_unchanged': True, 'uploaded': False}
    except (SigningError, OSError, zipfile.BadZipFile):
        output.unlink(missing_ok=True)
        raise SigningError('android_aab_sign_or_verify_failed') from None
