"""One version source for native metadata and the Settings label."""
import re


class BuildError(Exception):
    pass


def read_version(source):
    versions = re.findall(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', source, re.M)
    if len(versions) != 1 or len(re.findall(r'^version:', source, re.M)) != 1:
        raise BuildError('invalid_version')
    name, number = versions[0]
    if not 1 <= int(number) <= 2100000000:
        raise BuildError('invalid_build_number')
    return name, int(number)


def display_definitions(source, command):
    name, number = read_version(source)
    values = {'--build-name': name, '--build-number': str(number)}
    seen = set()
    for i, arg in enumerate(command):
        key = arg.split('=', 1)[0]
        if key not in values:
            continue
        if key in seen:
            raise BuildError('duplicate_build_version')
        seen.add(key)
        value = (arg.split('=', 1)[1] if '=' in arg else
                 command[i + 1] if i + 1 < len(command) else '')
        values[key] = value
    name, number = read_version(f"version: {values['--build-name']}+{values['--build-number']}")
    return {'POURLUNE_VERSION_NAME': name, 'POURLUNE_VERSION_CODE': str(number)}
