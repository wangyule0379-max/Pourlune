"""Validate public build destinations; validation is not ownership approval."""
import ipaddress
import re
from urllib.parse import unquote, urlsplit


class DestinationError(Exception):
    pass


def public_domain(host):
    if not host or len(host) > 253:
        return False
    host = host.lower()
    reserved = ('example.com', 'example.org', 'example.net', 'localhost')
    if any(host == item or host.endswith('.' + item) for item in reserved):
        return False
    if host.endswith(('.invalid', '.test', '.example', '.localhost', '.local')):
        return False
    try:
        ipaddress.ip_address(host)
        return False
    except ValueError:
        pass
    return bool('.' in host and all(re.fullmatch(
        r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?', label
    ) for label in host.split('.')) and not host.split('.')[-1].isdigit())


def validate_destinations(support_url='', privacy_url='', feedback_email=''):
    values = dict(support_url=support_url, privacy_url=privacy_url,
                  feedback_email=feedback_email)
    for name, value in values.items():
        if not value:
            continue
        if value != value.strip() or any(ord(c) <= 32 or ord(c) == 127 for c in unquote(value)):
            raise DestinationError('invalid_public_destination_' + name)
        if name.endswith('_url'):
            try:
                url = urlsplit(value)
                valid = (url.scheme == 'https' and public_domain(url.hostname)
                         and url.username is None and url.password is None
                         and url.port in {None, 443} and '\\' not in value)
            except ValueError:
                valid = False
        else:
            local, sep, host = value.rpartition('@')
            valid = (bool(sep) and len(value) <= 254 and len(local) <= 64
                     and not local.startswith('.') and not local.endswith('.')
                     and '..' not in local and public_domain(host)
                     and bool(re.fullmatch(r"[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+", local)))
        if not valid:
            raise DestinationError('invalid_public_destination_' + name)
    return {**values, 'ready': all(values.values())}


def add_destination_arguments(parser):
    parser.add_argument('--support-url', default='')
    parser.add_argument('--privacy-url', default='')
    parser.add_argument('--feedback-email', default='')
