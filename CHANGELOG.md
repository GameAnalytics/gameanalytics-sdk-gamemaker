# Changelog

All notable changes to the GameAnalytics GameMaker SDK.

<!--(CHANGELOG_TOP)-->
**5.0.0**

Breaking:
* 32-bit Windows is no longer supported, and `GameAnalytics_x64.dll` is gone — the Windows library is `GameAnalytics.dll` and is 64-bit
* the SDK is three resources, not two: `obj_gameanalytics` ships alongside the extension and the scripts

Added:
* rewrote the GML wrapper as a single `GameAnalytics.gml` that dispatches per platform
* added `customFields` / `mergeFields` to every event function
* added remote config and A/B testing getters: `ga_is_remote_configs_ready`, `ga_get_remote_configs_content`, `ga_get_ab_testing_id`, `ga_get_ab_testing_variant_id`
* added `ga_get_user_id` and `ga_get_external_user_id`
* added a runnable sample project covering every event type
* added CI that builds and export-checks every desktop library
* added `dependencies.json`, recording the upstream SDK version behind each shipped artifact

Changed:
* rebuilt all three desktop libraries from the current C++ SDK, fixing an out-of-bounds read in the `add*EventJson` entry points that could crash the game — previously only macOS had been rebuilt
* desktop uploads go through GameMaker's own HTTP stack, removing the cURL and OpenSSL dependency
* `ga_initialize()` now starts the desktop HTTP bridge itself; `ga_http_pump`, `ga_http_handle_async` and `ga_http_abort` are no longer something you wire up, and remain public and safe to call

Releases before 5.0.0 were published from the previous repository and are not
reproduced here.
