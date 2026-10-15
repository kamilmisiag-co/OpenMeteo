#!/usr/bin/env python3
import json, os, subprocess, sys

APP_TARGET = "OpenMeteo.app"


def percent(fraction):
    return f"{fraction * 100:.1f}%"


def main():
    if len(sys.argv) != 2:
        sys.exit(f"Usage: {sys.argv[0]} <path/to/result.xcresult>")
    bundle = sys.argv[1]
    if not os.path.isdir(bundle):
        sys.exit(f"No result bundle at {bundle}; did the unit tests run?")

    try:
        report = json.loads(subprocess.check_output(
            ["xcrun", "xccov", "view", "--report", "--json", bundle]))
    except subprocess.CalledProcessError:
        sys.exit(f"No coverage data in {bundle}; did the unit tests run?")
    target = next((t for t in report["targets"] if t["name"] == APP_TARGET), None)
    if target is None:
        sys.exit(f"{APP_TARGET} has no coverage in {bundle}; is code coverage enabled?")

    print("### Unit test coverage\n")
    print(f"**{APP_TARGET}: {percent(target['lineCoverage'])}** "
          f"({target['coveredLines']} of {target['executableLines']} lines)\n")
    print("| File | Coverage | Lines covered |")
    print("| --- | ---: | ---: |")
    for file in sorted(target["files"], key=lambda f: (f["lineCoverage"], f["name"])):
        print(f"| {file['name']} | {percent(file['lineCoverage'])} "
              f"| {file['coveredLines']} / {file['executableLines']} |")


if __name__ == "__main__":
    main()
