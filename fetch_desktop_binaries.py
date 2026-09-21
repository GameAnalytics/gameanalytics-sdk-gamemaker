#!/usr/bin/env python3
"""Download the desktop native libraries built by the "Desktop binaries" workflow.

The extension's native libraries are built in CI (see
.github/workflows/desktop-binaries.yml) because releasing them otherwise needs a
Windows box, a Linux box and a Mac. This pulls the result of a run and drops the
four libraries into both GameMaker projects.

    ./fetch_desktop_binaries.py                  # latest successful run on this branch
    ./fetch_desktop_binaries.py --branch master
    ./fetch_desktop_binaries.py --run-id 123456789
    ./fetch_desktop_binaries.py --list           # recent runs, newest first
    ./fetch_desktop_binaries.py --dry-run

Authentication, in order of preference: --token, $GITHUB_TOKEN, `gh auth token`.
GitHub requires a token to download workflow artifacts even on a public
repository, so one of those three must be available.
"""

import argparse
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile

API = "https://api.github.com"
WORKFLOW_FILE = "desktop-binaries.yml"
ARTIFACT_NAME = "desktop-binaries"

REPO_DIR = os.path.abspath(os.path.dirname(__file__))

# Every GameMaker project that ships the extension.
DESTINATIONS = [
    os.path.join(REPO_DIR, "sample", "extensions", "GameAnalyticsExt"),
]

# What a complete run produces; a partial set means a job failed.
EXPECTED_FILES = [
    "libGameAnalytics.dylib",
    "libGameAnalytics.so",
    "GameAnalytics.dll",
    "GameAnalytics_x64.dll",
]


def fail(message):
    sys.stdout.flush()
    print("error: " + message, file=sys.stderr)
    sys.exit(1)


def run_git(*args):
    try:
        out = subprocess.run(["git", "-C", REPO_DIR] + list(args),
                             capture_output=True, text=True, check=True)
        return out.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def resolve_repo():
    """owner/repo from the origin remote."""
    url = run_git("remote", "get-url", "origin")
    match = re.search(r"github\.com[:/]+([^/]+)/([^/.]+)", url)
    if not match:
        fail("could not work out the GitHub repository from origin (%r)" % url)
    return match.group(1), match.group(2)


def resolve_token(explicit):
    if explicit:
        return explicit
    if os.environ.get("GITHUB_TOKEN"):
        return os.environ["GITHUB_TOKEN"]
    try:
        out = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, check=True)
        token = out.stdout.strip()
        if token:
            return token
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    fail("no credentials: pass --token, set GITHUB_TOKEN, or run `gh auth login`")


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Artifact downloads redirect to signed blob storage, which rejects the
    request if the GitHub Authorization header tags along."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Client:
    def __init__(self, owner, repo, token):
        self.owner, self.repo = owner, repo
        self.headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": "Bearer " + token,
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "ga-fetch-desktop-binaries",
        }

    def get(self, path, not_found=None, **params):
        url = API + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        request = urllib.request.Request(url, headers=self.headers)
        try:
            with urllib.request.urlopen(request) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code == 401:
                fail("GitHub rejected the credentials (401)")
            if error.code == 404:
                fail(not_found or
                     "not found: %s — check the repository name and that the token can read it"
                     % path)
            fail("GitHub returned %s for %s" % (error.code, path))
        except urllib.error.URLError as error:
            fail("could not reach GitHub: %s" % error.reason)

    def runs(self, branch=None, limit=10, only_successful=True):
        params = {"per_page": limit}
        if branch:
            params["branch"] = branch
        if only_successful:
            params["status"] = "success"
        path = "/repos/%s/%s/actions/workflows/%s/runs" % (self.owner, self.repo, WORKFLOW_FILE)
        hint = ("%s is not on %s/%s yet — push the branch containing "
                ".github/workflows/%s and run it once from the Actions tab"
                % (WORKFLOW_FILE, self.owner, self.repo, WORKFLOW_FILE))
        return self.get(path, not_found=hint, **params).get("workflow_runs", [])

    def run(self, run_id):
        return self.get("/repos/%s/%s/actions/runs/%s" % (self.owner, self.repo, run_id))

    def artifacts(self, run_id):
        path = "/repos/%s/%s/actions/runs/%s/artifacts" % (self.owner, self.repo, run_id)
        return self.get(path, per_page=100).get("artifacts", [])

    def download(self, artifact_id):
        url = "%s/repos/%s/%s/actions/artifacts/%s/zip" % (API, self.owner, self.repo, artifact_id)
        request = urllib.request.Request(url, headers=self.headers)
        opener = urllib.request.build_opener(_NoRedirect)
        try:
            with opener.open(request) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            location = error.headers.get("Location") if error.headers else None
            if error.code in (301, 302, 303, 307, 308) and location:
                with urllib.request.urlopen(location) as response:   # unauthenticated, by design
                    return response.read()
            fail("could not download the artifact (HTTP %s)" % error.code)


def describe(run):
    return "run %s  %s  %s  %s  %s" % (
        run["id"],
        run.get("head_branch", "?"),
        (run.get("head_sha") or "")[:8],
        run.get("created_at", "?"),
        run.get("conclusion", run.get("status", "?")),
    )


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--run-id", help="use this run instead of the latest successful one")
    parser.add_argument("--branch", help="branch to take the latest run from (default: current)")
    parser.add_argument("--token", help="GitHub token (else $GITHUB_TOKEN, else `gh auth token`)")
    parser.add_argument("--dest", action="append",
                        help="extension directory to install into (repeatable; "
                             "default: both GameMaker projects)")
    parser.add_argument("--list", action="store_true", help="list recent runs and exit")
    parser.add_argument("--dry-run", action="store_true", help="report without writing files")
    parser.add_argument("--allow-partial", action="store_true",
                        help="install even if the run produced fewer than four libraries")
    args = parser.parse_args()

    owner, repo = resolve_repo()
    client = Client(owner, repo, resolve_token(args.token))
    print("repository: %s/%s" % (owner, repo))

    if args.list:
        runs = client.runs(branch=args.branch, limit=15, only_successful=False)
        if not runs:
            print("no runs of %s yet" % WORKFLOW_FILE)
            return
        for run in runs:
            print("  " + describe(run))
        return

    # --- pick a run ------------------------------------------------------
    if args.run_id:
        run = client.run(args.run_id)
        if run.get("conclusion") != "success":
            print("warning: run %s concluded %r" % (run["id"], run.get("conclusion")))
    else:
        branch = args.branch or run_git("rev-parse", "--abbrev-ref", "HEAD") or None
        runs = client.runs(branch=branch, limit=1)
        if not runs:
            fail("no successful run of %s on %s yet — start one from the Actions tab "
                 "(or pass --run-id / --branch)" % (WORKFLOW_FILE, branch or "any branch"))
        run = runs[0]
    print("using:      " + describe(run))

    head = run_git("rev-parse", "HEAD")
    if head and run.get("head_sha") and run["head_sha"] != head:
        print("note:       built from %s, local HEAD is %s" % (run["head_sha"][:8], head[:8]))

    # --- fetch the artifact ----------------------------------------------
    artifacts = {a["name"]: a for a in client.artifacts(run["id"])}
    if ARTIFACT_NAME not in artifacts:
        fail("run %s has no %r artifact (found: %s) — the build jobs may have failed"
             % (run["id"], ARTIFACT_NAME, ", ".join(sorted(artifacts)) or "none"))
    artifact = artifacts[ARTIFACT_NAME]
    if artifact.get("expired"):
        fail("the artifact for run %s has expired; re-run the workflow" % run["id"])

    print("downloading %s (%.1f MB)" % (ARTIFACT_NAME, artifact.get("size_in_bytes", 0) / 1e6))
    archive = zipfile.ZipFile(io.BytesIO(client.download(artifact["id"])))
    libraries = {os.path.basename(n): archive.read(n)
                 for n in archive.namelist() if not n.endswith("/")}

    missing = [f for f in EXPECTED_FILES if f not in libraries]
    if missing:
        message = "run %s produced %d of %d libraries, missing: %s" % (
            run["id"], len(libraries), len(EXPECTED_FILES), ", ".join(missing))
        if not args.allow_partial:
            fail(message + " (pass --allow-partial to install anyway)")
        print("warning: " + message)

    # --- install ----------------------------------------------------------
    destinations = [os.path.abspath(d) for d in (args.dest or DESTINATIONS)]
    changed = 0
    for destination in destinations:
        if not os.path.isdir(destination):
            fail("destination does not exist: " + destination)
        print("\n" + os.path.relpath(destination, REPO_DIR))
        for name in EXPECTED_FILES:
            if name not in libraries:
                continue
            data = libraries[name]
            path = os.path.join(destination, name)
            old = open(path, "rb").read() if os.path.exists(path) else b""
            if old == data:
                print("  %-26s unchanged (%d bytes)" % (name, len(data)))
                continue
            changed += 1
            print("  %-26s %s (%d bytes, sha256 %s)" % (
                name, "would update" if args.dry_run else "updated", len(data), sha256(data)[:12]))
            if not args.dry_run:
                with open(path, "wb") as handle:
                    handle.write(data)

    print("\n%d file(s) %s." % (changed, "would change" if args.dry_run else "written"))
    if changed and not args.dry_run:
        print("Remember to re-enable the Windows and Linux bindings in "
              "GameAnalytics.gml (__ga_http_uses_gm_stack and the identity getters) "
              "in the same commit.")


if __name__ == "__main__":
    main()
