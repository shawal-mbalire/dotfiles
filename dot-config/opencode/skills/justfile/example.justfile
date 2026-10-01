set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments := true

root := justfile_directory()

default:
    @just --list

[positional-arguments]
deploy env target *flags:
    #!/usr/bin/env python3
    import sys
    env, target, *flags = sys.argv[1:]

    if env not in ("dev", "staging", "prod"):
        raise SystemExit(f"bad env: {env}")

    print(f"deploying {target} to {env}")
    for flag in flags:
        print(f"  flag: {flag}")

[positional-arguments]
check-tools:
    #!/usr/bin/env python3
    import shutil
    for tool in ("just", "python3", "git"):
        if shutil.which(tool) is None:
            raise SystemExit(f"missing tool: {tool}")
    print("all tools present")

[positional-arguments]
sync source target:
    #!/usr/bin/env python3
    import sys
    source, target = sys.argv[1:3]
    if source == target:
        raise SystemExit("source and target are the same")
    print(f"syncing {source} -> {target}")

[parallel]
build-all: build-a build-b build-c

build-a:
    @sleep 0.3 && echo "built a"
build-b:
    @sleep 0.3 && echo "built b"
build-c:
    @sleep 0.3 && echo "built c"

[positional-arguments]
fanout *items:
    #!/usr/bin/env python3
    import asyncio, sys

    async def work(name: str) -> None:
        await asyncio.sleep(0.2)
        print(f"done {name}", flush=True)

    async def main() -> None:
        await asyncio.gather(*(work(t) for t in sys.argv[1:]))

    asyncio.run(main())