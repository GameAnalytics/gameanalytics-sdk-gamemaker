# GameAnalytics SDK for GameMaker

The official [GameAnalytics](https://gameanalytics.com) SDK for GameMaker.

Documentation is located [here](https://gameanalytics.com/docs/item/gamemaker-studio-sdk).

If you have any issues or feedback regarding the SDK, please contact our friendly
support team [here](https://gameanalytics.com/contact).

## Supported platforms

| Platform    | Native library                                            |
|-------------|-----------------------------------------------------------|
| Android     | `com.gameanalytics.sdk:gameanalytics-android` (via Gradle) |
| iOS         | `libGameAnalytics.a`                                      |
| Windows x64 | `GameAnalytics.dll`                                       |
| macOS       | `libGameAnalytics.dylib`                                  |
| Linux x64   | `libGameAnalytics.so`                                     |
| HTML5       | `GameAnalytics.js`                                        |

Android is the one platform with no binary in this repository: the extension
declares a Gradle dependency, so the Android SDK is fetched from
`maven.gameanalytics.com` when your project builds.

Not every call is implemented on every platform — see
[Platform support](#platform-support).

## Requirements

- GameMaker 2024.2 or newer. The sample project was last saved with IDE
  `2026.0.0.16`.

## Installation

The SDK is three resources inside the sample project:

- `sample/extensions/GameAnalyticsExt` — the extension: native libraries, the
  platform bridges and the function declarations.
- `sample/scripts/GameAnalytics` — `GameAnalytics.gml`, the cross-platform GML
  API that dispatches to whichever backend the current platform uses.
- `sample/objects/obj_gameanalytics` — drives the desktop HTTP bridge.
  `ga_initialize()` creates it; you never reference it yourself.

Copy all three into your own project, or open `sample/sample.yyp`, select them
and use **Tools → Create Local Package** to make a `.yymps` you can import
elsewhere.

The script calls the extension's declared functions directly, so importing the
extension on its own leaves you with raw per-platform bindings. Leaving out
`obj_gameanalytics` costs you desktop uploads — the SDK logs a message saying
so at `ga_initialize()` rather than failing silently.

### Android

No extra steps. The extension injects the Gradle repositories and dependencies
it needs; building the project fetches them.

### HTML5

Add the JavaScript SDK to your HTML5 export — the extension ships
`GameAnalytics.js` and the `GameAnalyticsExt.js` bridge, and GameMaker includes
them automatically once the extension is in the project.

## Quick start

```gml
// Create event of a persistent controller object
ga_configure_build("1.0.0");
ga_configure_resource_currencies(["gems", "coins"]);
ga_configure_resource_item_types(["lives", "boosts"]);
ga_initialize("YOUR_GAME_KEY", "YOUR_GAME_SECRET");

// Game End event
ga_on_quit();
```

Your game key and secret are on your game's Settings page on
[gameanalytics.com](https://gameanalytics.com).

## API reference

All functions live in `scripts/GameAnalytics/GameAnalytics.gml`.

Every event function takes two optional trailing arguments:

- `fields` — a JSON object string of custom fields, e.g. `"{\"mode\":\"hard\"}"`.
  Defaults to `"{}"`.
- `mergeFields` — whether to merge `fields` with the global custom fields rather
  than replace them. Defaults to `false`.

### Initialization

```gml
ga_initialize(gameKey, gameSecret)
```

### Configuration — call before `ga_initialize`

```gml
ga_configure_build(build)                        // e.g. "alpha 1.0"
ga_configure_user_id(userId)
ga_configure_external_user_id(extUserId)
ga_configure_dimensions_01(dimensions)           // Array<String>
ga_configure_dimensions_02(dimensions)
ga_configure_dimensions_03(dimensions)
ga_configure_resource_currencies(currencies)     // Array<String>
ga_configure_resource_item_types(types)          // Array<String>
```

### Runtime settings

```gml
ga_set_info_log(enabled)
ga_set_verbose_log(enabled)
ga_set_event_submission(enabled, cacheLocally = false)
ga_set_error_reporting(flag)
ga_set_manual_session_handling(enabled)
```

### Session management

```gml
ga_start_session()   // manual session mode only
ga_end_session()     // manual session mode only
ga_on_quit()         // call in the Game End event
```

### Custom dimensions

```gml
ga_set_custom_dimension_01(value)
ga_set_custom_dimension_02(value)
ga_set_custom_dimension_03(value)
```

### Events

```gml
// Business (IAP)
ga_add_business_event(currency, amount, itemType, itemId, cartType,
                      fields = "{}", mergeFields = false)

// Virtual economy
ga_add_resource_event(flowType, currency, amount, itemType, itemId,
                      fields = "{}", mergeFields = false)
// flowType: GA_RESOURCEFLOWTYPE_SOURCE | GA_RESOURCEFLOWTYPE_SINK

// Progression / levels
ga_add_progression_event(status, prog1, prog2 = "", prog3 = "",
                         fields = "{}", mergeFields = false)
ga_add_progression_event_with_score(status, prog1, prog2 = "", prog3 = "",
                                    score = 0, fields = "{}", mergeFields = false)
// status: GA_PROGRESSIONSTATUS_START | _COMPLETE | _FAIL

// Design
ga_add_design_event(eventId, fields = "{}", mergeFields = false)
ga_add_design_event_with_value(eventId, value, fields = "{}", mergeFields = false)

// Errors
ga_add_error_event(severity, message, fields = "{}", mergeFields = false)
// severity: GA_ERRORSEVERITY_DEBUG | _INFO | _WARNING | _ERROR | _CRITICAL

// Ads — mobile and HTML5 only, see Platform support
ga_add_ad_event(adAction, adType, adSdkName, adPlacement,
                fields = "{}", mergeFields = false)
ga_add_ad_event_with_duration(adAction, adType, adSdkName, adPlacement, duration,
                              fields = "{}", mergeFields = false)
ga_add_ad_event_with_reason(adAction, adType, adSdkName, adPlacement, noAdReason,
                            fields = "{}", mergeFields = false)
// adAction:   GA_ADACTION_CLICKED | _SHOW | _FAILEDSHOW | _REWARDRECEIVED | _REQUEST | _LOADED
// adType:     GA_ADTYPE_VIDEO | _REWARDEDVIDEO | _PLAYABLE | _INTERSTITIAL | _OFFERWALL | _BANNER
// noAdReason: GA_ADERROR_UNKNOWN | _OFFLINE | _NOFILL | _INTERNALERROR | _INVALIDREQUEST | _UNABLETOPRECACHE
```

### Remote configs and A/B testing

```gml
ga_is_remote_configs_ready()                     // Bool
ga_get_remote_configs_value(key, defaultValue = "")  // String
ga_get_remote_configs_value_as_json(key)         // JSON String
ga_get_remote_configs_content()                  // the whole payload, JSON String
ga_get_ab_testing_id()                           // String
ga_get_ab_testing_variant_id()                   // String
```

Remote configs and A/B assignment arrive asynchronously after `ga_initialize`,
so poll `ga_is_remote_configs_ready()` rather than reading them straight after
initializing.

### Identity

```gml
ga_get_user_id()           // String
ga_get_external_user_id()  // String
```

### Desktop HTTP bridge

On desktop the native library routes its uploads through GameMaker's own
`http_request` rather than linking cURL and OpenSSL, which needs an instance to
receive the Async HTTP event. `ga_initialize()` creates `obj_gameanalytics` for
that, so there is nothing to wire up.

```gml
ga_http_pump()          // Step event
ga_http_handle_async()  // Async HTTP event
ga_http_abort()         // Game End event
```

These stay public so a game can drive the bridge from its own object instead,
for example to issue requests on a different schedule. Calling them as well as
`obj_gameanalytics` is harmless: whichever comes first in a step claims the
queued request and the other finds nothing.

## Platform support

Calls with no native implementation on a platform are safe no-ops — they log a
message to the debug output rather than failing. Everything not listed here is
supported everywhere.

| Function | Supported on |
|----------|--------------|
| `ga_add_ad_event`, `..._with_duration`, `..._with_reason` | Android, iOS, HTML5 |
| `ga_set_error_reporting` | Windows, macOS, Linux |
| `ga_configure_external_user_id` | Android, iOS, HTML5, Windows, macOS, Linux |
| `ga_get_user_id`, `ga_get_external_user_id` | Windows, macOS, Linux |
| `ga_http_pump`, `ga_http_handle_async`, `ga_http_abort` (optional) | Windows, macOS, Linux |

The last three are desktop-only by design: they exist because the desktop
extension routes the SDK's HTTP through GameMaker rather than linking cURL, and
the mobile and HTML5 SDKs do their own networking.

## Sample app

`sample/sample.yyp` fires every event type and shows the SDK's live state on
screen. Open it and press Run. It starts on a setup screen asking for your game
key and secret; nothing is hardcoded. The keys are remembered between runs in
the game's save area, so it is a one-time step per machine.

| Key     | Action                                                   |
|---------|----------------------------------------------------------|
| `Enter` | Business event (99c gold pack IAP)                       |
| `Space` | Complete level — progression, resource and design events  |
| `D`     | Design events, with and without a value                  |
| `E`     | Error event (warning severity)                           |
| `A`     | Ad events (rewarded video shown, then reward received)   |
| `R`     | Read the `test_key` remote config value                  |
| `F`     | Refresh the identity / A/B / remote-config panels        |
| `C`     | Clear the event log                                      |
| `Tab`   | Move between the key fields on the setup screen          |

The UI is drawn in `obj_controller`'s Draw GUI event using flat rectangles and
the built-in font, so the sample needs no sprite or font assets.

> The sample stores the keys you type in plain text under the game's save area
> (`ga_sample.ini`) so it is not a retyping exercise. That is fine for a local
> sample; don't copy the pattern into a shipped game.

## Building the desktop libraries

`sample/extensions/GameAnalyticsExt/DesktopSource/` builds the desktop native
library from the [GameAnalytics C++ SDK](https://github.com/GameAnalytics/gameanalytics-sdk-cpp).

```bash
cd sample/extensions/GameAnalyticsExt/DesktopSource
./build_macos.sh       # or build_linux.sh, or build_windows.bat
```

It produces a dynamic library — GameMaker loads desktop extensions with
`dlopen`/`LoadLibrary` — with the C++ SDK linked in statically, so there is one
file to ship and no external dependencies. `GA_HTTP_USE_CURL=OFF` keeps libcurl,
OpenSSL and vcpkg out of it entirely.

Two source files:

- **`GameAnalyticsGM.cpp`** — the entry points the extension declares. GameMaker
  allows at most 4 arguments to a native function once any of them is a string,
  while the SDK's event calls take 6-7 with `customFields`/`mergeFields`, so the
  wide ones are exposed as single-string JSON-array entry points with every
  array access bounds-checked.
- **`GameAnalyticsHttpGM.cpp`** — a `GAHttpClient` that performs the SDK's
  requests with GameMaker's own HTTP stack. This is what removes the cURL and
  OpenSSL dependency and gives one implementation for every desktop target. It
  is why `ga_http_pump()` and `ga_http_handle_async()` exist, and why
  `obj_gameanalytics` is created by `ga_initialize()` — GameMaker delivers
  `async_load` only to instances that define the event, so the bridge cannot
  live in a script or a time source.

  | Where | What |
  |-------|------|
  | SDK worker thread | `sendRequest()` queues the request and blocks |
  | `obj_gameanalytics`, per step | `ga_http_pump()` issues it via `http_request` |
  | `obj_gameanalytics`, Async HTTP | `ga_http_handle_async()` returns status and body to the SDK |
  | `obj_gameanalytics`, Game End | `ga_http_abort()` so shutdown doesn't wait out the timeout |

### CI

`.github/workflows/desktop-binaries.yml` builds every desktop library:

| Job | Runner | Produces |
|-----|--------|----------|
| `macos-universal` | macos-14 | `libGameAnalytics.dylib` (x86_64 + arm64) |
| `linux-x64` | ubuntu-22.04 | `libGameAnalytics.so` |
| `windows-x64` | windows-2022 | `GameAnalytics.dll` |

Each job checks the export table before uploading
(`.github/workflows/required-exports.txt`), because GameMaker resolves extension
functions lazily — a library missing an entry point loads fine and only fails
when a game calls it.

Pull the result into the project with:

```bash
./fetch_desktop_binaries.py              # latest successful run on the current branch
./fetch_desktop_binaries.py --list       # recent runs, newest first
./fetch_desktop_binaries.py --dry-run    # report without writing
```

Two things the workflow pins deliberately:

- **The C++ SDK ref.** `v5.4.1` predates the commit that builds the static
  library with `-fPIC`, without which the Linux `.so` fails to link, so
  `sdk_ref` defaults to that commit instead of a tag.
- **ubuntu-22.04, not ubuntu-latest.** The runner's glibc becomes the minimum
  glibc of every game that ships this library.

### Upstream SDK versions

Each platform target binds to a different GameAnalytics SDK.
`dependencies.json` records which version of each one the shipped artifacts came
from, and `./download_externals.py` brings the tree back in line with it — bump
a version there to upgrade.

| Dependency | Version | Where it lands |
|------------|---------|----------------|
| `GA-SDK-CPP` | 5.4.1 (a later commit, see above) | `external/gameanalytics-sdk-cpp`, the source tree `DesktopSource` builds |
| `GA-SDK-JAVASCRIPT` | 4.4.5 | `GameAnalytics.js`, a drop-in replacement |
| `GA-SDK-IOS` | 4.6.10 | `iOSSource/GameAnalyticsSDK/libGameAnalytics.a` |
| `GA-SDK-ANDROID` | 7.0.1 | a Maven coordinate in `GameAnalyticsExt.yy`, resolved by Gradle |

```bash
./download_externals.py                    # every dependency
./download_externals.py GA-SDK-JAVASCRIPT  # just one
```

The first two are fetched. The last two are reported on instead: the iOS
releases publish no static library (5.x ships an `.xcframework`, which the
extension's `.yy` would have to be reworked for), and the Android version is a
coordinate rather than a file — the script checks that coordinate against the
manifest and leaves the IDE-managed `.yy` alone.

### Releasing

`./publish_release.py` does the mechanical half of a release:

```bash
./publish_release.py -v 4.2.0 -c "first line::second line"
./publish_release.py -v 4.2.0 -c "..." --dry-run   # report every step, change nothing
```

In order, it refreshes the upstream dependencies, rebuilds the desktop
libraries on CI and collects them, checks every shipped artifact is present,
bumps both version strings, asks the backend whether it accepts the new
`sdk_version`, prepends the changelog entry, zips the extension and the GML
wrapper, then commits, tags and creates the GitHub release.

The two Marketplace steps have no API and stay manual; the script prints them
when it finishes.

It deliberately does **not** download the old prebuilt libraries from
`download.gameanalytics.com` the way the previous script did. Those are the
February 2022 builds, which carry an out-of-bounds read in the `add*EventJson`
entry points; taking them again would reintroduce that crash.

The backend check needs a game key and secret, which are read from a file that
is never committed — `internal/` is gitignored, and the script refuses to run if
the file has somehow become tracked:

```bash
./publish_release.py --init-credentials   # writes internal/release-credentials.env, mode 600
```

```
GA_GAME_KEY=...
GA_GAME_SECRET=...
```

It is used for one thing: `_sdkVersion` identifies this SDK in every event a
game sends, and a version string the backend rejects is invisible until the data
stops arriving. Without the file the check is skipped; the values are never
printed.

## Contributing

Issues and pull requests are welcome. When changing the SDK interface, these are
the files that have to move together:

| File | Purpose |
|------|---------|
| `sample/scripts/GameAnalytics/GameAnalytics.gml` | Cross-platform GML wrappers |
| `sample/extensions/GameAnalyticsExt/GameAnalyticsExt.yy` | Extension and function declarations |
| `sample/extensions/GameAnalyticsExt/DesktopSource/GameAnalyticsGM.cpp` | Desktop entry points |
| `sample/extensions/GameAnalyticsExt/GameAnalyticsExt.js` | HTML5 bridge |
| `sample/extensions/GameAnalyticsExt/AndroidSource/Java/GameAnalyticsExt.java` | Android bridge |
| `sample/extensions/GameAnalyticsExt/iOSSource/GameAnalyticsExt.mm` | iOS bridge |
| `.github/workflows/required-exports.txt` | Entry points CI asserts are present |

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE).
