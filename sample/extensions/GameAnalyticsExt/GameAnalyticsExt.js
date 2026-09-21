// GameAnalytics HTML5 Bridge
// Version: 4.1.0

// -------------------------------------------------------------------------
// Configuration
// -------------------------------------------------------------------------

function ga_configure_build(build) {
    gameanalytics.GameAnalytics.configureBuild(build);
}

function ga_configure_user_id(userId) {
    gameanalytics.GameAnalytics.configureUserId(userId);
}

function ga_configure_external_user_id(extUserId) {
    gameanalytics.GameAnalytics.setExternalUserId(extUserId);
}

function ga_configure_dimensions01(json) {
    gameanalytics.GameAnalytics.configureAvailableCustomDimensions01(JSON.parse(json));
}

function ga_configure_dimensions02(json) {
    gameanalytics.GameAnalytics.configureAvailableCustomDimensions02(JSON.parse(json));
}

function ga_configure_dimensions03(json) {
    gameanalytics.GameAnalytics.configureAvailableCustomDimensions03(JSON.parse(json));
}

function ga_configure_resource_currencies(json) {
    gameanalytics.GameAnalytics.configureAvailableResourceCurrencies(JSON.parse(json));
}

function ga_configure_resource_item_types(json) {
    gameanalytics.GameAnalytics.configureAvailableResourceItemTypes(JSON.parse(json));
}

function ga_configure_sdk_version(version) {
    gameanalytics.GameAnalytics.configureSdkGameEngineVersion(version);
}

// -------------------------------------------------------------------------
// Initialization
// -------------------------------------------------------------------------

function ga_initialize(gameKey, gameSecret) {
    gameanalytics.GameAnalytics.initialize(gameKey, gameSecret);
}

// -------------------------------------------------------------------------
// Settings
// -------------------------------------------------------------------------

function ga_set_info_log(enabled) {
    gameanalytics.GameAnalytics.setEnabledInfoLog(!!enabled);
}

function ga_set_verbose_log(enabled) {
    gameanalytics.GameAnalytics.setEnabledVerboseLog(!!enabled);
}

function ga_set_event_submission(enabled, cacheLocally) {
    gameanalytics.GameAnalytics.setEnabledEventSubmission(!!enabled);
}

function ga_set_error_reporting(flag) {
    gameanalytics.GameAnalytics.setEnabledErrorReporting(!!flag);
}

function ga_set_manual_session(enabled) {
    gameanalytics.GameAnalytics.setEnabledManualSessionHandling(!!enabled);
}

// -------------------------------------------------------------------------
// Session
// -------------------------------------------------------------------------

function ga_start_session() {
    gameanalytics.GameAnalytics.startSession();
}

function ga_end_session() {
    gameanalytics.GameAnalytics.endSession();
}

function ga_on_quit() {
    gameanalytics.GameAnalytics.onStop();
}

// -------------------------------------------------------------------------
// Custom Dimensions
// -------------------------------------------------------------------------

function ga_set_dimension01(value) {
    gameanalytics.GameAnalytics.setCustomDimension01(value);
}

function ga_set_dimension02(value) {
    gameanalytics.GameAnalytics.setCustomDimension02(value);
}

function ga_set_dimension03(value) {
    gameanalytics.GameAnalytics.setCustomDimension03(value);
}

// -------------------------------------------------------------------------
// Events
// -------------------------------------------------------------------------

function ga_add_business_event(currency, amount, itemType, itemId, cartType, fields, mergeFields) {
    gameanalytics.GameAnalytics.addBusinessEvent(currency, amount, itemType, itemId, cartType, fields, !!mergeFields);
}

function ga_add_resource_event(flowType, currency, amount, itemType, itemId, fields, mergeFields) {
    gameanalytics.GameAnalytics.addResourceEvent(parseInt(flowType), currency, amount, itemType, itemId, fields, !!mergeFields);
}

function ga_add_progression_event(status, prog1, prog2, prog3, fields, mergeFields) {
    gameanalytics.GameAnalytics.addProgressionEvent(parseInt(status), prog1, prog2, prog3, fields, !!mergeFields);
}

function ga_add_progression_event_score(status, prog1, prog2, prog3, score, fields, mergeFields) {
    gameanalytics.GameAnalytics.addProgressionEvent(parseInt(status), prog1, prog2, prog3, score, fields, !!mergeFields);
}

function ga_add_design_event(eventId, fields, mergeFields) {
    gameanalytics.GameAnalytics.addDesignEvent(eventId, fields, !!mergeFields);
}

function ga_add_design_event_value(eventId, value, fields, mergeFields) {
    gameanalytics.GameAnalytics.addDesignEvent(eventId, value, fields, !!mergeFields);
}

function ga_add_error_event(severity, message, fields, mergeFields) {
    gameanalytics.GameAnalytics.addErrorEvent(parseInt(severity), message, fields, !!mergeFields);
}

function ga_add_ad_event(adAction, adType, adSdkName, adPlacement, fields, mergeFields) {
    gameanalytics.GameAnalytics.addAdEvent(parseInt(adAction), parseInt(adType), adSdkName, adPlacement, fields, !!mergeFields);
}

function ga_add_ad_event_duration(adAction, adType, adSdkName, adPlacement, duration, fields, mergeFields) {
    gameanalytics.GameAnalytics.addAdEvent(parseInt(adAction), parseInt(adType), adSdkName, adPlacement, duration, fields, !!mergeFields);
}

function ga_add_ad_event_reason(adAction, adType, adSdkName, adPlacement, noAdReason, fields, mergeFields) {
    gameanalytics.GameAnalytics.addAdEvent(parseInt(adAction), parseInt(adType), adSdkName, adPlacement, parseInt(noAdReason), fields, !!mergeFields);
}

// -------------------------------------------------------------------------
// Remote Configs
// -------------------------------------------------------------------------

function ga_remote_configs_value(key, defaultValue) {
    return gameanalytics.GameAnalytics.getRemoteConfigsValueAsString(key, defaultValue);
}

function ga_remote_configs_json(key) {
    return gameanalytics.GameAnalytics.getRemoteConfigsValueAsJson(key);
}

function ga_remote_configs_content() {
    return gameanalytics.GameAnalytics.getRemoteConfigsContentAsString();
}

function ga_remote_configs_ready() {
    return gameanalytics.GameAnalytics.isRemoteConfigsReady();
}

// -------------------------------------------------------------------------
// A/B Testing
// -------------------------------------------------------------------------

function ga_ab_testing_id() {
    return gameanalytics.GameAnalytics.getABTestingId();
}

function ga_ab_testing_variant_id() {
    return gameanalytics.GameAnalytics.getABTestingVariantId();
}
