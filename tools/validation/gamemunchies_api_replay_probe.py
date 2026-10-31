"""New API scope one-shot test replay; never migrate an old SDK scope.

The shared validation/send implementation is reused. This CLI has no option to
select a different host, game, production environment, device or payload fields.
"""
import gamemunchies_replay_probe as legacy

ORIGIN = legacy.API_ORIGIN


def prepare(snapshot, *, platform, now=None):
    return legacy.prepare(snapshot, platform=platform, now=now, origin=ORIGIN)


if __name__ == '__main__':
    raise SystemExit(legacy.main(origin=ORIGIN,
                               private_subdirectory='gamemunchies-live-qa/runtime-private'))
