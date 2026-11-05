#!/usr/bin/env python3
"""
Publishes a GameAnalytics GameMaker SDK release.

Replaces publish_gamemaker_release.py from the development repository. That
script was written when the SDK lived in two places and shipped from a third:
it maintained four version strings, pulled prebuilt libraries off
download.gameanalytics.com, packaged a GMS1 `.gmez`, and committed the result
into a separate public repository. None of that applies here — this repository
*is* the public SDK, the extension exists once under sample/, and the desktop
libraries are built by CI from source.

So the shape is different:

  publish_gamemaker_release.py            this script
  ------------------------------------    ------------------------------------
  4 version strings (.gmx, .yy, 2 .gml)   2 (GameAnalyticsExt.yy, GameAnalytics.gml)
  libs from download.gameanalytics.com    rebuilt on CI, collected by
                                            ./fetch_desktop_binaries.py
  JS/iOS from the private GA-SDK-BINARIES ./download_externals.py, from the
                                            public repos in dependencies.json
  7z a gameanalytics.gmez (GMS1)          a zip of the extension + scripts
  changelog prepended to README.md        prepended to CHANGELOG.md
  commits into ../GA-SDK-GAMEMAKER        commits and tags here
  no release                              a GitHub release carrying the zip

Downloading the old prebuilt libraries is deliberately *not* carried over:
those are the February 2022 builds, and they contain an out-of-bounds read in
the add*EventJson entry points. Taking them again would reintroduce a crash.
The libraries are rebuilt on CI instead.

Usage:

    ./publish_release.py -v 4.2.0 -c "first line::second line"
    ./publish_release.py -v 4.2.0 -c "..." --dry-run
    ./publish_release.py -v 4.2.0 -c "..." --skip-ci   # trust the committed libs

The Marketplace upload stays manual: it is an IDE and web flow with no API.
The script prints the remaining steps when it finishes.

Credentials
-----------
The GameAnalytics game key and secret are read from a file that is never
committed — internal/ is in .gitignore, and the script refuses to run if the
file has somehow become tracked:

    internal/release-credentials.env

        GA_GAME_KEY=...
        GA_GAME_SECRET=...

They are used for one thing: asking the GameAnalytics backend whether it
accepts the new `sdk_version` string before the release is tagged. That string
is what identifies this SDK in every event the game sends, and a version the
backend rejects is invisible until the data stops arriving. Run
`--init-credentials` to write a template. Values are never printed.
"""

import argparse
import base64
import hashlib
import hmac
import json
import os
import re
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
EXTENSION_DIR = os.path.join(ROOT_DIR, "sample", "extensions", "GameAnalyticsExt")
SCRIPTS_DIR = os.path.join(ROOT_DIR, "sample", "scripts", "GameAnalytics")
OBJECT_DIR = os.path.join(ROOT_DIR, "sample", "objects", "obj_gameanalytics")

YY_FILE = os.path.join(EXTENSION_DIR, "GameAnalyticsExt.yy")
GML_FILE = os.path.join(SCRIPTS_DIR, "GameAnalytics.gml")
CHANGELOG_FILE = os.path.join(ROOT_DIR, "CHANGELOG.md")
CREDENTIALS_FILE = os.path.join(ROOT_DIR, "internal", "release-credentials.env")

CHANGELOG_TOP_TAG = "<!--(CHANGELOG_TOP)-->"
WORKFLOW = "desktop-binaries.yml"

# The libraries CI produces, and the two dependency files
# ./download_externals.py maintains. A release missing any of them is broken in
# a way that only shows up when a game calls into the extension.
SHIPPED_BINARIES = [
    "libGameAnalytics.dylib",
    "libGameAnalytics.so",
    "GameAnalytics.dll",
]

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


# Progress goes to stdout and failures to stderr, so leaving stdout
# block-buffered would reorder the two whenever the output is piped into a log
# — the error would surface above the step it came from.
sys.stdout.reconfigure(line_buffering=True)


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def run(args, cwd=ROOT_DIR, capture=False, check=True):
    """Runs a subprocess, echoing it so the transcript shows what was done."""
    print("  $ " + " ".join(args))
    result = subprocess.run(
        args, cwd=cwd, check=False,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        text=True,
    )
    if check and result.returncode != 0:
        if capture and result.stderr:
            print(result.stderr.strip(), file=sys.stderr)
        fail(f"command failed ({result.returncode}): {' '.join(args)}")
    return result


def git(*args, capture=True, check=True):
    return run(["git", *args], capture=capture, check=check)


# --------------------------------------------------------------------------
# credentials
# --------------------------------------------------------------------------

def write_credentials_template():
    """Creates internal/release-credentials.env, owner-readable only."""
    if os.path.exists(CREDENTIALS_FILE):
        fail(f"{rel(CREDENTIALS_FILE)} already exists — not overwriting it")
    os.makedirs(os.path.dirname(CREDENTIALS_FILE), exist_ok=True)
    # Created 0600 from the start: writing it first and chmod-ing after would
    # leave the secret briefly readable by anyone on the machine.
    fd = os.open(CREDENTIALS_FILE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(
            "# GameAnalytics credentials for publish_release.py.\n"
            "# internal/ is gitignored; never move this file out of it.\n"
            "GA_GAME_KEY=\n"
            "GA_GAME_SECRET=\n"
        )
    print(f"wrote {rel(CREDENTIALS_FILE)} (mode 600) — fill in the two values")


def load_credentials():
    """
    Reads the key and secret, or returns None if the file is absent.

    Refuses to read a file git is tracking. internal/ is ignored, so that
    should be impossible — but `git add -f` is one command away, and a secret
    committed once is committed forever.
    """
    if not os.path.exists(CREDENTIALS_FILE):
        return None

    tracked = git("ls-files", "--error-unmatch", rel(CREDENTIALS_FILE), check=False)
    if tracked.returncode == 0:
        fail(
            f"{rel(CREDENTIALS_FILE)} is tracked by git. Remove it from the index "
            "(`git rm --cached`) and rotate the credentials before publishing."
        )

    mode = os.stat(CREDENTIALS_FILE).st_mode
    if mode & (stat.S_IRGRP | stat.S_IROTH):
        print(f"  warning: {rel(CREDENTIALS_FILE)} is readable beyond its owner; chmod 600 it")

    values = {}
    with open(CREDENTIALS_FILE, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, _, value = line.partition("=")
            values[name.strip()] = value.strip()

    key = values.get("GA_GAME_KEY", "")
    secret = values.get("GA_GAME_SECRET", "")
    if not key or not secret:
        print(f"  {rel(CREDENTIALS_FILE)} is missing GA_GAME_KEY or GA_GAME_SECRET")
        return None
    return key, secret


def rel(path):
    return os.path.relpath(path, ROOT_DIR)


# --------------------------------------------------------------------------
# steps
# --------------------------------------------------------------------------

def preflight(version, allow_dirty):
    print("--- preflight ---")
    if not VERSION_RE.match(version):
        fail(f"version must be MAJOR.MINOR.PATCH, got {version!r}")

    if not allow_dirty:
        dirty = git("status", "--porcelain").stdout.strip()
        if dirty:
            fail("working tree is not clean:\n" + dirty + "\n(or pass --allow-dirty)")

    existing = git("tag", "--list", version).stdout.strip()
    if existing:
        fail(f"tag {version} already exists")

    current = read_versions()
    print(f"  current: .yy {current['yy']}, GameAnalytics.gml {current['gml']}")
    if current["yy"] != current["gml"]:
        fail("the two version strings already disagree — fix that before releasing")
    if current["yy"] == version:
        print(f"  note: already at {version}; the bump will be a no-op")


def read_versions():
    with open(YY_FILE, encoding="utf-8") as f:
        yy_match = re.search(r'"extensionVersion"\s*:\s*"([^"]*)"', f.read())
    with open(GML_FILE, encoding="utf-8") as f:
        gml_match = re.search(r'_sdkVersion\s*=\s*"gamemaker ([^"]*)"', f.read())
    if not yy_match:
        fail("no extensionVersion in GameAnalyticsExt.yy")
    if not gml_match:
        fail("no _sdkVersion in GameAnalytics.gml")
    return {"yy": yy_match.group(1), "gml": gml_match.group(1)}


def refresh_dependencies(dry_run):
    """Brings the JS bundle (and the C++ source tree) to what dependencies.json pins."""
    print("--- refreshing upstream dependencies ---")
    if dry_run:
        print("  (dry run) would run ./download_externals.py")
        return
    run([sys.executable, os.path.join(ROOT_DIR, "download_externals.py")])


def rebuild_desktop_binaries(dry_run, token, branch):
    """
    Dispatches the desktop workflow, waits for it, and collects the libraries.

    The libraries are rebuilt rather than taken from whatever is committed, so a
    release cannot quietly ship a stale one. The C++ SDK ref comes from
    dependencies.json, which CI reads itself.
    """
    print("--- rebuilding the desktop libraries on CI ---")
    if dry_run:
        print(f"  (dry run) would dispatch {WORKFLOW} and run ./fetch_desktop_binaries.py")
        return

    if not which("gh"):
        fail("gh is required to dispatch the workflow (or pass --skip-ci)")

    before = latest_run_id(branch)
    run(["gh", "workflow", "run", WORKFLOW, "--ref", branch])

    print("  waiting for the run to appear...")
    run_id = None
    for _ in range(30):
        time.sleep(4)
        candidate = latest_run_id(branch)
        if candidate and candidate != before:
            run_id = candidate
            break
    if not run_id:
        fail("the dispatched run did not appear; check `gh run list`")

    print(f"  watching run {run_id}")
    watched = run(["gh", "run", "watch", run_id, "--exit-status"], check=False)
    if watched.returncode != 0:
        fail(f"the desktop build failed; see `gh run view {run_id} --log-failed`")

    fetch = [sys.executable, os.path.join(ROOT_DIR, "fetch_desktop_binaries.py"),
             "--run-id", run_id]
    if token:
        fetch += ["--token", token]
    run(fetch)


def latest_run_id(branch):
    result = run(
        ["gh", "run", "list", "--workflow", WORKFLOW, "--branch", branch,
         "--limit", "1", "--json", "databaseId"],
        capture=True, check=False,
    )
    if result.returncode != 0:
        return None
    try:
        runs = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None
    return str(runs[0]["databaseId"]) if runs else None


def which(program):
    from shutil import which as _which
    return _which(program)


def verify_binaries():
    """Checks every shipped artifact is present before anything is tagged."""
    print("--- verifying shipped artifacts ---")
    missing = []
    for name in SHIPPED_BINARIES + ["GameAnalytics.js"]:
        path = os.path.join(EXTENSION_DIR, name)
        if os.path.exists(path):
            print(f"  ok      {name} ({os.path.getsize(path):,} bytes)")
        else:
            missing.append(name)
    ios_lib = os.path.join(EXTENSION_DIR, "iOSSource", "GameAnalyticsSDK", "libGameAnalytics.a")
    if os.path.exists(ios_lib):
        print(f"  ok      iOSSource/.../libGameAnalytics.a ({os.path.getsize(ios_lib):,} bytes)")
    else:
        missing.append("iOSSource/GameAnalyticsSDK/libGameAnalytics.a")

    if missing:
        fail("missing shipped artifacts: " + ", ".join(missing))


def bump_versions(version, dry_run):
    """
    Rewrites the two version strings.

    Both must change together: extensionVersion is what the IDE and the
    Marketplace show, and _sdkVersion is what reaches the backend on every
    event. They are the two halves of the same fact.
    """
    print("--- updating version strings ---")
    edits = [
        (YY_FILE, r'("extensionVersion"\s*:\s*")[^"]*(")', version),
        (GML_FILE, r'(_sdkVersion\s*=\s*"gamemaker )[^"]*(")', version),
    ]
    for path, pattern, value in edits:
        with open(path, encoding="utf-8") as f:
            source = f.read()
        updated, count = re.subn(pattern, lambda m: m.group(1) + value + m.group(2), source)
        if count != 1:
            fail(f"expected exactly one version string in {rel(path)}, found {count}")
        if dry_run:
            print(f"  (dry run) would set {rel(path)} to {value}")
            continue
        with open(path, "w", encoding="utf-8") as f:
            f.write(updated)
        print(f"  {rel(path)} -> {value}")


def smoke_test(version, credentials, required):
    """
    Asks the backend whether it accepts the new sdk_version string.

    Mirrors what the SDK does on init: POST the init annotations with
    `Authorization: base64(HMAC-SHA256(body, game_secret))`, which is
    GAHTTPApi::createAuth in the C++ SDK. A 401 means the credentials are
    wrong; a 400 means the payload — including the version string — was
    rejected. Network trouble is not treated as a release blocker.
    """
    print("--- backend check on the new sdk_version ---")
    if credentials is None:
        message = (
            f"no credentials at {rel(CREDENTIALS_FILE)} — skipping "
            "(--init-credentials writes a template)"
        )
        if required:
            fail(message)
        print(f"  {message}")
        return

    key, secret = credentials
    sdk_version = f"gamemaker {version}"
    body = json.dumps({
        "platform": "windows",
        "os_version": "windows 10",
        "sdk_version": sdk_version,
    }).encode("utf-8")
    auth = base64.b64encode(
        hmac.new(secret.encode("utf-8"), body, hashlib.sha256).digest()
    ).decode("ascii")

    url = (
        "https://api.gameanalytics.com/remote_configs/v1/init"
        f"?game_key={key}&interval_seconds=0&configs_hash=&config_vsn_supported=3"
    )
    request = urllib.request.Request(
        url, data=body, method="POST",
        headers={"Authorization": auth, "Content-Type": "application/json"},
    )

    print(f"  sending sdk_version={sdk_version!r} to api.gameanalytics.com")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print(f"  accepted (HTTP {response.status})")
            return
    except urllib.error.HTTPError as e:
        detail = e.read()[:200].decode("utf-8", "replace").strip()
        if e.code in (401, 403):
            fail(f"the backend rejected the credentials (HTTP {e.code}: {detail})")
        if e.code == 400:
            fail(f"the backend rejected the payload (HTTP 400: {detail}) — "
                 f"check that {sdk_version!r} is a version it knows")
        message = f"unexpected response (HTTP {e.code}: {detail})"
    except urllib.error.URLError as e:
        message = f"could not reach the backend ({e.reason})"

    if required:
        fail(message)
    print(f"  warning: {message} — continuing")


def update_changelog(version, changelog_raw, dry_run):
    """Inserts the entry directly below the CHANGELOG_TOP marker, newest first."""
    print("--- updating CHANGELOG.md ---")
    lines = [line.strip() for line in changelog_raw.split("::") if line.strip()]
    if not lines:
        fail("--changelog produced no entries")

    with open(CHANGELOG_FILE, encoding="utf-8") as f:
        source = f.read()
    if CHANGELOG_TOP_TAG not in source:
        fail(f"{CHANGELOG_TOP_TAG} not found in CHANGELOG.md")
    if f"\n**{version}**\n" in source:
        fail(f"CHANGELOG.md already has an entry for {version}")

    entry = f"**{version}**\n" + "".join(f"* {line}\n" for line in lines) + "\n"
    updated = source.replace(
        CHANGELOG_TOP_TAG + "\n", CHANGELOG_TOP_TAG + "\n" + entry, 1
    )
    if dry_run:
        print("  (dry run) would insert:")
        print("".join("    " + l + "\n" for l in entry.strip().splitlines()))
        return entry
    with open(CHANGELOG_FILE, "w", encoding="utf-8") as f:
        f.write(updated)
    print(f"  added {len(lines)} line(s) under {version}")
    return entry


def package(version, dry_run):
    """
    Zips what a GameMaker developer needs: the extension and the GML wrapper.

    GA_Sample* and obj_controller are left out — they are the demo app, not
    part of the SDK. The old
    script produced a GMS1 `.gmez` with 7z; this is a plain zip, because the
    Marketplace package is built by the IDE and this artifact exists for people
    downloading from GitHub.
    """
    print("--- packaging ---")
    zip_path = os.path.join(ROOT_DIR, f"GameAnalytics-GameMaker-{version}.zip")
    sources = [
        (EXTENSION_DIR, "extensions/GameAnalyticsExt"),
        (SCRIPTS_DIR, "scripts/GameAnalytics"),
        # ga_initialize() creates this; without it desktop uploads never go out.
        (OBJECT_DIR, "objects/obj_gameanalytics"),
    ]

    if dry_run:
        total = sum(len(files) for base, _ in sources for _, _, files in os.walk(base))
        print(f"  (dry run) would write {os.path.basename(zip_path)} with ~{total} files")
        return zip_path

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
        count = 0
        for base, prefix in sources:
            for dirpath, _, filenames in os.walk(base):
                for filename in sorted(filenames):
                    if filename == ".DS_Store":
                        continue
                    absolute = os.path.join(dirpath, filename)
                    arcname = os.path.join(
                        prefix, os.path.relpath(absolute, base)
                    )
                    archive.write(absolute, arcname)
                    count += 1
    print(f"  {os.path.basename(zip_path)} ({os.path.getsize(zip_path):,} bytes, {count} files)")
    return zip_path


def commit_and_tag(version, dry_run, branch):
    print("--- committing and tagging ---")
    paths = [rel(YY_FILE), rel(GML_FILE), rel(CHANGELOG_FILE),
             "sample/extensions/GameAnalyticsExt"]
    if dry_run:
        print(f"  (dry run) would commit {', '.join(paths)}, tag {version}, push to {branch}")
        return
    git("add", "--", *paths, capture=False)
    git("commit", "-m", f"Release {version}", capture=False)
    git("tag", "-a", version, "-m", f"Release {version}", capture=False)
    git("push", "origin", branch, capture=False)
    git("push", "origin", version, capture=False)


def create_release(version, zip_path, entry, dry_run):
    print("--- creating the GitHub release ---")
    notes = entry.replace(f"**{version}**\n", "").strip()
    if dry_run:
        print(f"  (dry run) would create release {version} with {os.path.basename(zip_path)}")
        return
    if not which("gh"):
        print("  gh not found — create the release by hand and attach "
              f"{os.path.basename(zip_path)}")
        return
    run(["gh", "release", "create", version, zip_path,
         "--title", f"GameAnalytics GameMaker SDK {version}",
         "--notes", notes])


# --------------------------------------------------------------------------

def main(argv):
    parser = argparse.ArgumentParser(
        description="Publish a GameAnalytics GameMaker SDK release.")
    parser.add_argument("-v", "--version", help="release version, e.g. 4.2.0")
    parser.add_argument("-c", "--changelog",
                        help="changelog lines separated by '::'")
    parser.add_argument("--branch", default="master", help="branch to push (default: master)")
    parser.add_argument("--token", help="GitHub token, passed to fetch_desktop_binaries.py")
    parser.add_argument("--dry-run", action="store_true",
                        help="report every step without writing, pushing or dispatching")
    parser.add_argument("--skip-deps", action="store_true",
                        help="do not refresh dependencies")
    parser.add_argument("--skip-ci", action="store_true",
                        help="do not rebuild on CI; use the committed libraries")
    parser.add_argument("--skip-release", action="store_true",
                        help="commit and tag, but do not create a GitHub release")
    parser.add_argument("--require-backend-check", action="store_true",
                        help="treat an unreachable backend as a failure")
    parser.add_argument("--allow-dirty", action="store_true",
                        help="proceed with uncommitted changes")
    parser.add_argument("--init-credentials", action="store_true",
                        help=f"write a {rel(CREDENTIALS_FILE)} template and exit")
    args = parser.parse_args(argv)

    if args.init_credentials:
        write_credentials_template()
        return

    if not args.version or not args.changelog:
        parser.error("-v/--version and -c/--changelog are both required")

    version = args.version.lstrip("v")
    print(f"=== publishing {version}" + (" (dry run)" if args.dry_run else "") + " ===\n")

    preflight(version, args.allow_dirty)
    credentials = load_credentials()

    if not args.skip_deps:
        refresh_dependencies(args.dry_run)
    if not args.skip_ci:
        rebuild_desktop_binaries(args.dry_run, args.token, args.branch)
    verify_binaries()

    bump_versions(version, args.dry_run)
    smoke_test(version, credentials, args.require_backend_check)
    entry = update_changelog(version, args.changelog, args.dry_run)
    zip_path = package(version, args.dry_run)
    commit_and_tag(version, args.dry_run, args.branch)
    if not args.skip_release:
        create_release(version, zip_path, entry, args.dry_run)

    print(f"\n=== {version} published ===")
    print("Remaining steps, which have no API and stay manual:")
    print("  1. GameMaker IDE: Marketplace -> Update Existing Package")
    print("     select Extensions/GameAnalyticsExt, scripts/GameAnalytics")
    print("     and objects/obj_gameanalytics")
    print("  2. accounts.yoyogames.com: Publisher -> GameAnalytics -> Versions -> Publish")


if __name__ == "__main__":
    main(sys.argv[1:])
