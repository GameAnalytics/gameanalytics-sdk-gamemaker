# Changelog

All notable changes to the GameAnalytics GameMaker SDK.

<!--(CHANGELOG_TOP)-->
**4.1.0**
* rewrote the GML wrapper as a single `GameAnalytics.gml` that dispatches per platform
* added `customFields` / `mergeFields` to every event function
* added remote config and A/B testing getters: `ga_is_remote_configs_ready`, `ga_get_remote_configs_content`, `ga_get_ab_testing_id`, `ga_get_ab_testing_variant_id`
* added `ga_get_user_id` and `ga_get_external_user_id`
* rebuilt the macOS native library from the current C++ SDK, fixing an out-of-bounds read in the `add*EventJson` entry points that could crash the game
* desktop uploads now go through GameMaker's own HTTP stack (`ga_http_pump` / `ga_http_handle_async` / `ga_http_abort`), removing the cURL and OpenSSL dependency
* added a runnable sample project covering every event type
* added CI that builds and export-checks all four desktop libraries

Releases before 4.1.0 were published from the previous repository and are not
reproduced here.
