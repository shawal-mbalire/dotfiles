set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments := true

root := justfile_directory()

default:
    @just --list

[positional-arguments]
deploy env target *flags:
    #!/usr/bin/env python3
    import subprocess, sys

    env, target, *flags = sys.argv[1:]
    if env not in ("dev", "staging", "prod"):
        raise SystemExit(f"bad env: {env}")

    proc = subprocess.run(["just", target, "deploy", env, *flags],
                          text=True, capture_output=True)
    print(proc.stdout, end="")
    if proc.returncode != 0:
        print(proc.stderr, file=sys.stderr)
        raise SystemExit(proc.returncode)

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
    import subprocess, sys

    source, target = sys.argv[1:3]
    if source == target:
        raise SystemExit("source and target are the same")
    raise SystemExit(subprocess.run(["rsync", "-a", "--delete", source, target]).returncode)

[parallel]
build-all: build-a build-b build-c

build-a:
    @sleep 0.3 && echo "built a"
build-b:
    @sleep 0.3 && echo "built b"
build-c:
    @sleep 0.3 && echo "built c"

[positional-arguments]
schedule *steps:
    #!/usr/bin/env python3
    import subprocess, sys

    procs = [subprocess.Popen(step, shell=True) for step in sys.argv[1:]]
    codes = [p.wait() for p in procs]
    if any(codes):
        raise SystemExit("one or more steps failed")

[positional-arguments]
fanout *stacks:
    #!/usr/bin/env python3
    import subprocess, sys
    from concurrent.futures import ThreadPoolExecutor

    def build(stack: str) -> int:
        return subprocess.run(["just", stack, "build"]).returncode

    with ThreadPoolExecutor(max_workers=4) as pool:
        codes = list(pool.map(build, sys.argv[1:]))
    if any(codes):
        raise SystemExit("one or more builds failed")
