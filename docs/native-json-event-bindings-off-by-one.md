# Desktop `add*EventJson` bindings read one array element too many

**Status:** fixed on macOS by rebuilding the binary from the current C++ SDK
(see [Desktop native library](../README.md#desktop-native-library)). Still open
on Windows and Linux, which ship the February 2022 builds.
**Found:** 2026-09-07, while the sample's "Complete level" button froze and killed the game
**Affects:** `GameAnalytics.dll`, `GameAnalytics_x64.dll` and
`libGameAnalytics.so` as shipped in `sample/extensions/GameAnalyticsExt/`.
`libGameAnalytics.dylib` was affected and has been rebuilt.

## Symptom

Clicking the sample's "Complete level" button (or calling
`ga_add_progression_event_with_score` any other way) freezes the game for a few
seconds and then kills it. It is intermittent: the same call succeeds at startup
and crashes later in the session.

## Root cause

Each `add*EventJson` entry point parses its JSON array, checks the element count,
and then reads one element **past** that count to get the `fields` argument for
the C++ SDK. From `otool -arch arm64 -tvV -p _addProgressionEventWithScoreJson`:

```
1250c0  ldr  w8, [sp, #0x10]     ; parsed array's element count
1250c4  cmp  w8, #0x5            ; must be exactly 5
1250c8  b.ne 0x125214            ; ...or return without doing anything
...
1251b8  ldrb w9, [x8, #0x8f]     ; flags of element[5] — past the end of a 5-element array
1251f4  ldr  x5, [x8, #0x80]     ; ...used as `const char* fields`
125210  bl   GameAnalytics::addProgressionEvent(status, p1, p2, p3, int, char const*, bool)
```

`element[5]` is unallocated pool memory, so `fields` is whatever was last on the
heap. When it is non-zero garbage, the SDK's own `snprintf` of that pointer
segfaults, GA's `GAUncaughtExceptionHandler::signalHandler` catches SIGSEGV and
calls `backtrace_symbols()`, which spends seconds in `dyld` resolving symbols —
that is the "freeze" — and the process then dies. Captured stack:

```
addProgressionEventWithScoreJson (libGameAnalytics.dylib) + 468
  gameanalytics::GameAnalytics::addProgressionEvent(..., int, char const*, bool) + 304
    snprintf + 68
      _sigtramp + 56
        gameanalytics::errorreporter::GAUncaughtExceptionHandler::signalHandler + 92
          backtrace_symbols + 152
            dyld4::APIs::dladdr ...
```

Whether it crashes depends on heap history, which is why it survives a call at
startup (fresh, zeroed pool → `fields == NULL` → `snprintf` prints `(null)`) and
fails once memory has been reused.

The same size-check/read mismatch is present in all four JSON entry points:

| Entry point                        | Element count required | Highest element read |
|------------------------------------|------------------------|----------------------|
| `addBusinessEventJson`             | 5                      | 5                    |
| `addResourceEventJson`             | 5                      | 5                    |
| `addProgressionEventJson`          | 4                      | 4                    |
| `addProgressionEventWithScoreJson` | 5                      | 5                    |

So `ga_add_business_event` and `ga_add_resource_event` carry the same latent
crash — they just have not been unlucky yet.

## Why this cannot be fixed from GML

The binaries look like they were built after the C++ SDK gained the
`fields`/`mergeFields` parameters, while the extension declarations were not
updated. The non-JSON exports show the same story — the shipped
`_addProgressionEvent` expects `(status, p1, p2, p3, fields, mergeFields)`, but
`GameAnalyticsExt.yy` declares it with four arguments, so `fields` and
`mergeFields` arrive as uninitialised registers.

Neither of the obvious GML-side fixes works:

- **Send a 6-element array** (append `fields`): rejected by the stale
  `cmp w8, #0x5` check, so the event is silently dropped.
- **Declare the sound non-JSON exports** (`addBusinessEvent`,
  `addResourceEvent`, `addProgressionEventWithScore` — all three exist in every
  desktop binary and take their arguments directly): GameMaker refuses them —
  `ERROR :: Extension function addBusinessEvent has more than 4 parameters and
  they are not all numbers`. That 4-parameter ABI limit is exactly why the JSON
  entry points exist. Verified by declaring and calling them; the runner logs
  the error and the calls become no-ops.

## Confirmed in the C++ SDK source

The binaries were built from `GameAnalyticsExtern.cpp` in the C++ SDK as it was
before commit `74b1022` ("external declarations", Aug 2024), which removed these
JSON entry points. That revision reads:

```cpp
void addProgressionEventWithScoreJson(const char *jsonArgs)
{
    rapidjson::Document json;
    json.Parse(jsonArgs);

    if(json.IsArray() && json.Size() == 5)
    {
        int progressionStatusInt = (int)(json[0].GetDouble());
        gameanalytics::GameAnalytics::addProgressionEvent(..., json[1].GetString(),
            json[2].GetString(), json[3].GetString(), (int)(json[4].GetDouble()),
            json[5].GetString());
    }
}
```

`Size() == 5` guarded, then `json[5]` read — rapidjson's `operator[]` does not
bounds-check in release builds. Same shape in the business and resource
variants. The current SDK has no JSON entry points at all; its C API is
`gameAnalytics_*` with `customFields`/`mergeFields` per event, which GameMaker
cannot call directly (6-7 parameters, see the ABI limit below).

## How it was fixed here

`sample/extensions/GameAnalyticsExt/DesktopSource/` now builds the macOS
binary from the current C++ SDK, with the JSON entry points reimplemented in
this repo (`GameAnalyticsGM.cpp`) so that every array access is bounds-checked
and the trailing `customFields`/`mergeFields` elements are optional. The
crashing calls — business, resource and progression-with-score — were exercised
594 times in one session against the new binary without a fault, and events now
reach the API (200/201, with remote configs coming back).

The same rebuild is still needed for Windows and Linux.

## What the underlying fix would be

In the C++ SDK (a separate repo — nothing here patches it), one of:

1. Change each `add*EventJson` size check to `N+1` and document that the last
   array element is the `fields` JSON object, then update `GameAnalyticsExt.yy`
   and `GameAnalytics.gml` to append `fields` (and pass `mergeFields`, which
   currently has nowhere to go on desktop); or
2. Stop reading the `fields` element and pass `"{}"`/`false` to the C++ SDK,
   matching what the current declarations promise.

Option 1 also fixes the long-standing "fields/mergeFields accepted for API
compatibility but not forwarded" gap noted throughout `GameAnalytics.gml`.

Until then, on desktop only design events, error events, custom dimensions,
sessions and remote configs go through a binding whose declared signature
matches the shipped binary. `ga_add_ad_event*` is already a documented no-op in
this build.

## Reproducing

`sample/` with `GA_SampleActions.gml` restored to call
`ga_add_progression_event_with_score`, then fire it from a Step event a couple of
seconds after `ga_initialize` (not from Create — at startup the heap is still
clean and the call survives):

```gml
if (probe_frames == 120) {
    ga_add_progression_event_with_score(GA_PROGRESSIONSTATUS_COMPLETE, "World01", "Level01", "", 1250);
}
```

The game hangs, and `sample <pid>` shows the stack above. The sample calls all
of these events unguarded, exactly as the SDK intends, so it will keep hitting
this until the binaries are rebuilt.
