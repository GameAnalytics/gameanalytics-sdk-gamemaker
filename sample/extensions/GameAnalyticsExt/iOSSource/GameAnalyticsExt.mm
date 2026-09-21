#import "GameAnalyticsExt.h"
#import "GameAnalytics.h"

#define TO_NSSTRING(s) (s ? [NSString stringWithUTF8String:s] : nil)

@implementation GameAnalyticsExt

// -------------------------------------------------------------------------
// Private helpers
// -------------------------------------------------------------------------

- (NSArray<NSString *> *)parseStringArray:(const char *)json {
    if (!json) return @[];
    NSData *data = [[NSString stringWithUTF8String:json] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![arr isKindOfClass:[NSArray class]]) return @[];
    return arr;
}

- (const char *)toCString:(NSString *)str {
    if (!str) return "";
    return [str UTF8String];
}

// -------------------------------------------------------------------------
// Configuration
// -------------------------------------------------------------------------

- (void)ga_configure_build:(const char *)build {
    [GameAnalytics configureBuild:TO_NSSTRING(build)];
}

- (void)ga_configure_user_id:(const char *)userId {
    [GameAnalytics configureUserId:TO_NSSTRING(userId)];
}

- (void)ga_configure_external_user_id:(const char *)extUserId {
    [GameAnalytics setExternalUserId:TO_NSSTRING(extUserId)];
}

- (void)ga_configure_dimensions01:(const char *)json {
    NSArray<NSString *> *arr = [self parseStringArray:json];
    [GameAnalytics configureAvailableCustomDimensions01:arr];
}

- (void)ga_configure_dimensions02:(const char *)json {
    NSArray<NSString *> *arr = [self parseStringArray:json];
    [GameAnalytics configureAvailableCustomDimensions02:arr];
}

- (void)ga_configure_dimensions03:(const char *)json {
    NSArray<NSString *> *arr = [self parseStringArray:json];
    [GameAnalytics configureAvailableCustomDimensions03:arr];
}

- (void)ga_configure_resource_currencies:(const char *)json {
    NSArray<NSString *> *arr = [self parseStringArray:json];
    [GameAnalytics configureAvailableResourceCurrencies:arr];
}

- (void)ga_configure_resource_item_types:(const char *)json {
    NSArray<NSString *> *arr = [self parseStringArray:json];
    [GameAnalytics configureAvailableResourceItemTypes:arr];
}

- (void)ga_configure_sdk_version:(const char *)version {
    [GameAnalytics configureSdkGameEngineVersion:TO_NSSTRING(version)];
}

// -------------------------------------------------------------------------
// Initialization
// -------------------------------------------------------------------------

- (void)ga_initialize:(const char *)gameKey gameSecret:(const char *)gameSecret {
    [GameAnalytics initializeWithGameKey:TO_NSSTRING(gameKey) gameSecret:TO_NSSTRING(gameSecret)];
}

// -------------------------------------------------------------------------
// Settings
// -------------------------------------------------------------------------

- (void)ga_set_info_log:(double)enabled {
    [GameAnalytics setEnabledInfoLog:(enabled != 0.0)];
}

- (void)ga_set_verbose_log:(double)enabled {
    [GameAnalytics setEnabledVerboseLog:(enabled != 0.0)];
}

- (void)ga_set_event_submission:(double)enabled cacheLocally:(double)cacheLocally {
    [GameAnalytics setEnabledEventSubmission:(enabled != 0.0)];
}

- (void)ga_set_error_reporting:(double)flag {
    [GameAnalytics setEnabledErrorReporting:(flag != 0.0)];
}

- (void)ga_set_manual_session:(double)enabled {
    [GameAnalytics setEnabledManualSessionHandling:(enabled != 0.0)];
}

// -------------------------------------------------------------------------
// Session
// -------------------------------------------------------------------------

- (void)ga_start_session {
    [GameAnalytics startSession];
}

- (void)ga_end_session {
    [GameAnalytics endSession];
}

- (void)ga_on_quit {
    [GameAnalytics onStop];
}

// -------------------------------------------------------------------------
// Custom Dimensions
// -------------------------------------------------------------------------

- (void)ga_set_dimension01:(const char *)value {
    [GameAnalytics setCustomDimension01:TO_NSSTRING(value)];
}

- (void)ga_set_dimension02:(const char *)value {
    [GameAnalytics setCustomDimension02:TO_NSSTRING(value)];
}

- (void)ga_set_dimension03:(const char *)value {
    [GameAnalytics setCustomDimension03:TO_NSSTRING(value)];
}

// -------------------------------------------------------------------------
// Events
// -------------------------------------------------------------------------

- (void)ga_add_business_event:(const char *)currency
                       amount:(double)amount
                     itemType:(const char *)itemType
                       itemId:(const char *)itemId
                     cartType:(const char *)cartType
                       fields:(const char *)fields
                  mergeFields:(double)mergeFields {
    [GameAnalytics addBusinessEventWithCurrency:TO_NSSTRING(currency)
                                         amount:(NSInteger)amount
                                       itemType:TO_NSSTRING(itemType)
                                         itemId:TO_NSSTRING(itemId)
                                       cartType:TO_NSSTRING(cartType)
                                         fields:TO_NSSTRING(fields)
                                    mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_resource_event:(double)flowType
                     currency:(const char *)currency
                       amount:(double)amount
                     itemType:(const char *)itemType
                       itemId:(const char *)itemId
                       fields:(const char *)fields
                  mergeFields:(double)mergeFields {
    [GameAnalytics addResourceEventWithFlowType:(GAResourceFlowType)((int)flowType)
                                       currency:TO_NSSTRING(currency)
                                         amount:(float)amount
                                       itemType:TO_NSSTRING(itemType)
                                         itemId:TO_NSSTRING(itemId)
                                         fields:TO_NSSTRING(fields)
                                    mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_progression_event:(double)status
                            prog1:(const char *)prog1
                            prog2:(const char *)prog2
                            prog3:(const char *)prog3
                           fields:(const char *)fields
                      mergeFields:(double)mergeFields {
    [GameAnalytics addProgressionEventWithProgressionStatus:(GAProgressionStatus)((int)status)
                                               progression01:TO_NSSTRING(prog1)
                                               progression02:TO_NSSTRING(prog2)
                                               progression03:TO_NSSTRING(prog3)
                                                     fields:TO_NSSTRING(fields)
                                                mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_progression_event_score:(double)status
                                  prog1:(const char *)prog1
                                  prog2:(const char *)prog2
                                  prog3:(const char *)prog3
                                  score:(double)score
                                 fields:(const char *)fields
                            mergeFields:(double)mergeFields {
    [GameAnalytics addProgressionEventWithProgressionStatus:(GAProgressionStatus)((int)status)
                                               progression01:TO_NSSTRING(prog1)
                                               progression02:TO_NSSTRING(prog2)
                                               progression03:TO_NSSTRING(prog3)
                                                      score:(NSInteger)score
                                                     fields:TO_NSSTRING(fields)
                                                mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_design_event:(const char *)eventId
                     fields:(const char *)fields
                mergeFields:(double)mergeFields {
    [GameAnalytics addDesignEventWithEventId:TO_NSSTRING(eventId)
                                      fields:TO_NSSTRING(fields)
                                 mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_design_event_value:(const char *)eventId
                            value:(double)value
                           fields:(const char *)fields
                      mergeFields:(double)mergeFields {
    [GameAnalytics addDesignEventWithEventId:TO_NSSTRING(eventId)
                                       value:value
                                      fields:TO_NSSTRING(fields)
                                 mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_error_event:(double)severity
                   message:(const char *)message
                    fields:(const char *)fields
               mergeFields:(double)mergeFields {
    [GameAnalytics addErrorEventWithSeverity:(GAErrorSeverity)((int)severity)
                                     message:TO_NSSTRING(message)
                                      fields:TO_NSSTRING(fields)
                                 mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_ad_event:(double)adAction
                 adType:(double)adType
              adSdkName:(const char *)adSdkName
            adPlacement:(const char *)adPlacement
                 fields:(const char *)fields
            mergeFields:(double)mergeFields {
    [GameAnalytics addAdEventWithAction:(GAAdAction)((int)adAction)
                                 adType:(GAAdType)((int)adType)
                              adSdkName:TO_NSSTRING(adSdkName)
                            adPlacement:TO_NSSTRING(adPlacement)
                                 fields:TO_NSSTRING(fields)
                            mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_ad_event_duration:(double)adAction
                          adType:(double)adType
                       adSdkName:(const char *)adSdkName
                     adPlacement:(const char *)adPlacement
                        duration:(double)duration
                          fields:(const char *)fields
                     mergeFields:(double)mergeFields {
    [GameAnalytics addAdEventWithAction:(GAAdAction)((int)adAction)
                                 adType:(GAAdType)((int)adType)
                              adSdkName:TO_NSSTRING(adSdkName)
                            adPlacement:TO_NSSTRING(adPlacement)
                                 noAdReason:GAAdErrorUnknown
                                 duration:(NSInteger)duration
                                 fields:TO_NSSTRING(fields)
                            mergeFields:(mergeFields != 0.0)];
}

- (void)ga_add_ad_event_reason:(double)adAction
                        adType:(double)adType
                     adSdkName:(const char *)adSdkName
                   adPlacement:(const char *)adPlacement
                    noAdReason:(double)noAdReason
                        fields:(const char *)fields
                   mergeFields:(double)mergeFields {
    [GameAnalytics addAdEventWithAction:(GAAdAction)((int)adAction)
                                 adType:(GAAdType)((int)adType)
                              adSdkName:TO_NSSTRING(adSdkName)
                            adPlacement:TO_NSSTRING(adPlacement)
                             noAdReason:(GAAdError)((int)noAdReason)
                                 fields:TO_NSSTRING(fields)
                            mergeFields:(mergeFields != 0.0)];
}

// -------------------------------------------------------------------------
// Remote Configs
// -------------------------------------------------------------------------

- (const char *)ga_remote_configs_value:(const char *)key defaultValue:(const char *)defaultValue {
    NSString *result = [GameAnalytics getRemoteConfigsValueAsString:TO_NSSTRING(key) withDefaultValue:TO_NSSTRING(defaultValue)];
    return [self toCString:result];
}

- (const char *)ga_remote_configs_json:(const char *)key {
    NSString *result = [GameAnalytics getRemoteConfigsValueAsJson:TO_NSSTRING(key)];
    return [self toCString:result];
}

- (const char *)ga_remote_configs_content {
    NSString *result = [GameAnalytics getRemoteConfigsContentAsString];
    return [self toCString:result];
}

- (double)ga_remote_configs_ready {
    return [GameAnalytics isRemoteConfigsReady] ? 1.0 : 0.0;
}

// -------------------------------------------------------------------------
// A/B Testing
// -------------------------------------------------------------------------

- (const char *)ga_ab_testing_id {
    NSString *result = [GameAnalytics getABTestingId];
    return [self toCString:result];
}

- (const char *)ga_ab_testing_variant_id {
    NSString *result = [GameAnalytics getABTestingVariantId];
    return [self toCString:result];
}

@end
