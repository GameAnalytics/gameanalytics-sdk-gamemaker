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
| Windows x86 | `GameAnalytics.dll`                                       |
| Windows x64 | `GameAnalytics_x64.dll`                                   |
| macOS       | `libGameAnalytics.dylib`                                  |
| Linux x64   | `libGameAnalytics.so`                                     |
| HTML5       | `GameAnalytics.js`                                        |

Android is the one platform with no binary in this repository: the extension
declares a Gradle dependency, so the Android SDK is fetched from
`maven.gameanalytics.com` when your project builds.

Not every call is implemented on every platform — see
[Platform support](#platform-support) and [Known issues](#known-issues).

## Requirements

- GameMaker 2024.2 or newer. The sample project was last saved with IDE
  `2026.0.0.16`.

## Installation

The SDK is two resources inside the sample project:

- `sample/extensions/GameAnalyticsExt` — the extension: native libraries, the
  platform bridges and the function declarations.
- `sample/scripts/GameAnalytics` — `GameAnalytics.gml`, the cross-platform GML
  API that dispatches to whichever backend the current platform uses.

Copy both into your own project, or open `sample/sample.yyp`, select the two
resources and use **Tools → Create Local Package** to make a `.yymps` you can
import elsewhere.

You need both. The script calls the extension's declared functions directly, so
importing the extension on its own leaves you with raw per-platform bindings.

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

### Desktop: you must pump the HTTP client

On desktop the native library routes its uploads through GameMaker's own
`http_request` rather than linking cURL and OpenSSL. That needs driving from
GML — **without these two calls nothing your game records is ever submitted**:

```gml
// Step event
ga_http_pump();

// Async HTTP event
ga_http_handle_async();

// Game End event, so shutdown doesn't wait out the request timeout
ga_http_abort();
```

Both are no-ops on platforms whose native SDK does its own networking, so it is
safe to call them unconditionally. `sample/objects/obj_controller` shows the
wiring.

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

```gml
ga_http_pump()          // Step event
ga_http_handle_async()  // Async HTTP event
ga_http_abort()         // Game End event
```

## Platform support

Calls with no native implementation on a platform are safe no-ops — they log a
message to the debug output rather than failing. Everything not listed here is
supported everywhere.

| Function | Supported on |
|----------|--------------|
| `ga_add_ad_event`, `..._with_duration`, `..._with_reason` | Android, iOS, HTML5 |
| `ga_set_error_reporting` | Windows, macOS, Linux |
| `ga_configure_external_user_id` | Android, iOS, HTML5, macOS |
| `ga_get_user_id`, `ga_get_external_user_id` | macOS |
| `ga_http_pump`, `ga_http_handle_async`, `ga_http_abort` | macOS |

The macOS-only rows are a consequence of [Known issues](#known-issues) — they
extend to Windows and Linux as soon as those libraries are rebuilt.

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
  is why `ga_http_pump()` and `ga_http_handle_async()` exist.

  | Where | What |
  |-------|------|
  | SDK worker thread | `sendRequest()` queues the request and blocks |
  | Game thread, per step | `ga_http_pump()` issues it via `http_request` |
  | Async HTTP event | `ga_http_handle_async()` returns status and body to the SDK |
  | Game end | `ga_http_abort()` so shutdown doesn't wait out the timeout |

### CI

`.github/workflows/desktop-binaries.yml` builds all four desktop libraries:

| Job | Runner | Produces |
|-----|--------|----------|
| `macos-universal` | macos-14 | `libGameAnalytics.dylib` (x86_64 + arm64) |
| `linux-x64` | ubuntu-22.04 | `libGameAnalytics.so` |
| `windows-x64` | windows-2022 | `GameAnalytics_x64.dll` |
| `windows-x86` | windows-2022 | `GameAnalytics.dll` |

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

## Known issues

**The Windows and Linux libraries have not been rebuilt yet.**
`GameAnalytics.dll`, `GameAnalytics_x64.dll` and `libGameAnalytics.so` are still
the February 2022 builds, which contain an out-of-bounds read in the
`add*EventJson` entry points that can crash the game. macOS has been rebuilt and
is not affected. The cause, the reproduction and the fix are written up in
[docs/native-json-event-bindings-off-by-one.md](docs/native-json-event-bindings-off-by-one.md).

Until those libraries are replaced, on Windows and Linux:

- `ga_add_business_event`, `ga_add_resource_event` and
  `ga_add_progression_event_with_score` can crash the game. The crash depends on
  heap state, so it is intermittent — a call that works at startup can fail
  later in the same session.
- `ga_http_pump()` and friends are inert, because the old libraries do their own
  networking and do not export the entry points the bridge needs.
- `ga_get_user_id()`, `ga_get_external_user_id()` and
  `ga_configure_external_user_id()` are unavailable for the same reason.

Design events, error events, custom dimensions, sessions and remote configs go
through bindings whose declared signature matches the shipped binary and are
unaffected.

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
