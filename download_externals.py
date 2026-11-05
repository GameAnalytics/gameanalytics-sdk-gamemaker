#!/usr/bin/env python3
"""
Fetches the upstream GameAnalytics SDKs this extension is built on, at the
versions recorded in dependencies.json.

The GameMaker SDK is a wrapper: each platform target binds to a different
upstream SDK, and nothing in the tree recorded which version of each one the
shipped artifacts came from. dependencies.json is that record, and this script
brings the tree back in line with it. To upgrade a dependency, bump it there
and re-run this.

    ./download_externals.py                 # all dependencies
    ./download_externals.py GA-SDK-JAVASCRIPT   # just one

Two of the four are fetched; two are reported on, because there is nothing to
download:

  GA-SDK-CPP          desktop. Extracted to external/gameanalytics-sdk-cpp as a
                      source tree, not a prebuilt library: DesktopSource's
                      CMakeLists builds the SDK itself (add_subdirectory) so it
                      can force GA_HTTP_USE_CURL=OFF, and GameAnalyticsHttpGM.cpp
                      includes GAUtilities.h, which lives under source/ and is
                      not in the published static-no-deps release.
  GA-SDK-JAVASCRIPT   HTML5. dist/GameAnalytics.min.js replaces the extension's
                      GameAnalytics.js verbatim — this is a drop-in.
  GA-SDK-IOS          reported only. The shipped fat libGameAnalytics.a was
                      taken from the internal binaries repository; the public
                      releases carry no .a at all, and 5.x publishes an
                      .xcframework instead, which is a packaging change the
                      extension's .yy would have to follow. Upgrading is a
                      deliberate piece of work, not a download.
  GA-SDK-ANDROID      reported only. Gradle resolves it from Maven at build
                      time, so the version is a coordinate inside
                      GameAnalyticsExt.yy rather than a file in the tree. This
                      script checks that coordinate against dependencies.json
                      and leaves the .yy alone — it is IDE-managed.
"""

import json
import os
import re
import shutil
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
EXTENSION_DIR = os.path.join(ROOT_DIR, "sample", "extensions", "GameAnalyticsExt")


def fetch(url, dest_path):
    """Downloads url to dest_path, creating parent directories as needed."""
    print(f"Downloading {url}...")
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    try:
        with urllib.request.urlopen(url) as response, open(dest_path, "wb") as f:
            shutil.copyfileobj(response, f)
    except urllib.error.URLError as e:
        print(f"Error downloading file: {e}")
        sys.exit(1)


def resolve_tag(base_url, version):
    """
    Returns the tag that exists upstream for this version.

    Tag spelling is not consistent across the GameAnalytics repositories, and
    not even within one: GA-SDK-JAVASCRIPT tagged 4.4.6 bare and v4.4.7 with a
    prefix. Rather than encode that per repository, try both and use whichever
    the server has.
    """
    archive_base = base_url.rstrip("/") + "/archive/refs/tags"
    for tag in (f"v{version}", version):
        request = urllib.request.Request(f"{archive_base}/{tag}.tar.gz", method="HEAD")
        try:
            with urllib.request.urlopen(request):
                return tag
        except urllib.error.HTTPError:
            continue
        except urllib.error.URLError as e:
            print(f"Error reaching {base_url}: {e}")
            sys.exit(1)

    print(f"Neither tag 'v{version}' nor '{version}' exists at {base_url}")
    sys.exit(1)


def download_cpp_sdk(sdk_info):
    """
    Extracts the C++ SDK source tree to external/gameanalytics-sdk-cpp, which is
    what DesktopSource's build wants as -DGA_SDK_DIR.

    A 'ref' in dependencies.json wins over 'version': the desktop libraries are
    currently built from a commit past v5.4.1, because the tag builds the static
    library without -fPIC and the Linux .so then fails to link. Once that change
    is in a release, drop the ref and this takes the tag instead.
    """
    base_url = sdk_info["url"].rstrip("/")
    ref = sdk_info.get("ref")
    if ref:
        archive_url = f"{base_url}/archive/{ref}.tar.gz"
        print(f"Using ref {ref} (past v{sdk_info['version']}, for the -fPIC fix)")
    else:
        archive_url = f"{base_url}/archive/refs/tags/{resolve_tag(base_url, sdk_info['version'])}.tar.gz"

    dest_dir = os.path.join(ROOT_DIR, "external", "gameanalytics-sdk-cpp")

    with tempfile.TemporaryDirectory() as work_dir:
        archive_path = os.path.join(work_dir, "sdk.tar.gz")
        fetch(archive_url, archive_path)

        print(f"Extracting to {dest_dir}...")
        extract_dir = os.path.join(work_dir, "extracted")
        with tarfile.open(archive_path, "r:gz") as tar:
            tar.extractall(extract_dir)

        # A GitHub source archive holds exactly one top-level directory, named
        # after the repository and ref; its name is not worth predicting.
        entries = [e for e in os.listdir(extract_dir) if not e.startswith(".")]
        if len(entries) != 1:
            print(f"Expected one directory in the archive, found: {entries}")
            sys.exit(1)
        unpacked = os.path.join(extract_dir, entries[0])

        if not os.path.exists(os.path.join(unpacked, "CMakeLists.txt")):
            print(f"No CMakeLists.txt in {unpacked} — not a C++ SDK source tree")
            sys.exit(1)

        if os.path.exists(dest_dir):
            shutil.rmtree(dest_dir)
        os.makedirs(os.path.dirname(dest_dir), exist_ok=True)
        shutil.move(unpacked, dest_dir)

    print("Build the desktop library against it with:")
    print("  ./sample/extensions/GameAnalyticsExt/DesktopSource/build_macos.sh \\")
    print("      external/gameanalytics-sdk-cpp")
    print("Update complete.")


def download_js_sdk(sdk_info):
    """
    Replaces the extension's GameAnalytics.js with the JavaScript SDK's
    minified bundle.

    The minified build is the one to take: it wraps itself in (function(scope){
    and inlines CryptoJS, so GameMaker's HTML5 target can load it as a plain
    extension file with no bundler and no second script to order before it.
    """
    base_url = sdk_info["url"].rstrip("/")
    tag = resolve_tag(base_url, sdk_info["version"])
    raw_base_url = base_url.replace("github.com", "raw.githubusercontent.com")
    download_url = f"{raw_base_url}/{tag}/dist/GameAnalytics.min.js"

    dest_path = os.path.join(EXTENSION_DIR, "GameAnalytics.js")
    fetch(download_url, dest_path)
    print(f"Updated {dest_path}.")
    print("Update complete.")


def report_ios_sdk(sdk_info):
    """Reports the shipped iOS version; see the module docstring for why."""
    lib_path = os.path.join(
        EXTENSION_DIR, "iOSSource", "GameAnalyticsSDK", "libGameAnalytics.a"
    )
    print(f"Pinned at {sdk_info['version']}, shipped as {os.path.relpath(lib_path, ROOT_DIR)}.")
    if not os.path.exists(lib_path):
        print("  warning: that library is missing from the tree")
    print("  Not downloadable: the public releases carry no static library, and")
    print("  5.x ships an .xcframework, which GameAnalyticsExt.yy would have to")
    print("  be reworked for. Upgrade by hand, in the IDE.")


def report_android_sdk(sdk_info):
    """
    Checks the Maven coordinate in GameAnalyticsExt.yy against the manifest.

    Read-only on purpose. The coordinate sits inside the .yy's
    androidcodeinjection string, and that file is IDE-managed JSON with trailing
    commas — editing it from a script is how the two drift out of step.
    """
    yy_path = os.path.join(EXTENSION_DIR, "GameAnalyticsExt.yy")
    expected = sdk_info["version"]
    print(f"Pinned at {expected}, resolved from Maven by Gradle at build time.")

    try:
        with open(yy_path, "r", encoding="utf-8") as f:
            yy_source = f.read()
    except FileNotFoundError:
        print(f"  warning: {os.path.relpath(yy_path, ROOT_DIR)} not found")
        return

    match = re.search(
        r"com\.gameanalytics\.sdk:gameanalytics-android:([0-9][^\"\\\s]*)", yy_source
    )
    if not match:
        print("  warning: no gameanalytics-android coordinate in GameAnalyticsExt.yy")
    elif match.group(1) != expected:
        print(f"  MISMATCH: GameAnalyticsExt.yy declares {match.group(1)}")
        print("  Change it in the GameMaker IDE, under the extension's Android properties.")
    else:
        print("  GameAnalyticsExt.yy agrees.")


HANDLERS = {
    "GA-SDK-CPP": download_cpp_sdk,
    "GA-SDK-JAVASCRIPT": download_js_sdk,
    "GA-SDK-IOS": report_ios_sdk,
    "GA-SDK-ANDROID": report_android_sdk,
}


def process_dependencies(only=None):
    """
    Runs the handler for each dependency in dependencies.json, or for just the
    ones named in `only`.
    """
    dependencies_file = os.path.join(ROOT_DIR, "dependencies.json")
    try:
        with open(dependencies_file, "r", encoding="utf-8") as f:
            dependencies = json.load(f)
    except FileNotFoundError:
        print(f"dependencies.json not found in {ROOT_DIR}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing dependencies.json: {e}")
        sys.exit(1)

    known = {sdk_info.get("name", "") for sdk_info in dependencies}
    if only:
        unknown = [name for name in only if name not in known]
        if unknown:
            print(f"Not in dependencies.json: {', '.join(unknown)}")
            print(f"Known: {', '.join(sorted(known))}")
            sys.exit(1)

    for sdk_info in dependencies:
        sdk_name = sdk_info.get("name", "")
        if only and sdk_name not in only:
            continue
        print(f"\nProcessing dependency: {sdk_name}")
        handler = HANDLERS.get(sdk_name)
        if handler:
            handler(sdk_info)
        else:
            print(f"Dependency '{sdk_name}' is not implemented yet.")


if __name__ == "__main__":
    process_dependencies(only=sys.argv[1:] or None)
