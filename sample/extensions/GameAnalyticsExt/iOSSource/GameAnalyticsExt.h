#pragma once
#import <Foundation/Foundation.h>

@interface GameAnalyticsExt : NSObject

// -------------------------------------------------------------------------
// Configuration
// -------------------------------------------------------------------------

- (void)ga_configure_build:(const char *)build;
- (void)ga_configure_user_id:(const char *)userId;
- (void)ga_configure_external_user_id:(const char *)extUserId;
- (void)ga_configure_dimensions01:(const char *)json;
- (void)ga_configure_dimensions02:(const char *)json;
- (void)ga_configure_dimensions03:(const char *)json;
- (void)ga_configure_resource_currencies:(const char *)json;
- (void)ga_configure_resource_item_types:(const char *)json;
- (void)ga_configure_sdk_version:(const char *)version;

// -------------------------------------------------------------------------
// Initialization
// -------------------------------------------------------------------------

- (void)ga_initialize:(const char *)gameKey gameSecret:(const char *)gameSecret;

// -------------------------------------------------------------------------
// Settings
// -------------------------------------------------------------------------

- (void)ga_set_info_log:(double)enabled;
- (void)ga_set_verbose_log:(double)enabled;
- (void)ga_set_event_submission:(double)enabled cacheLocally:(double)cacheLocally;
- (void)ga_set_error_reporting:(double)flag;
- (void)ga_set_manual_session:(double)enabled;

// -------------------------------------------------------------------------
// Session
// -------------------------------------------------------------------------

- (void)ga_start_session;
- (void)ga_end_session;
- (void)ga_on_quit;

// -------------------------------------------------------------------------
// Custom Dimensions
// -------------------------------------------------------------------------

- (void)ga_set_dimension01:(const char *)value;
- (void)ga_set_dimension02:(const char *)value;
- (void)ga_set_dimension03:(const char *)value;

// -------------------------------------------------------------------------
// Events
// -------------------------------------------------------------------------

- (void)ga_add_business_event:(const char *)currency
                       amount:(double)amount
                     itemType:(const char *)itemType
                       itemId:(const char *)itemId
                     cartType:(const char *)cartType
                       fields:(const char *)fields
                  mergeFields:(double)mergeFields;

- (void)ga_add_resource_event:(double)flowType
                     currency:(const char *)currency
                       amount:(double)amount
                     itemType:(const char *)itemType
                       itemId:(const char *)itemId
                       fields:(const char *)fields
                  mergeFields:(double)mergeFields;

- (void)ga_add_progression_event:(double)status
                            prog1:(const char *)prog1
                            prog2:(const char *)prog2
                            prog3:(const char *)prog3
                           fields:(const char *)fields
                      mergeFields:(double)mergeFields;

- (void)ga_add_progression_event_score:(double)status
                                  prog1:(const char *)prog1
                                  prog2:(const char *)prog2
                                  prog3:(const char *)prog3
                                  score:(double)score
                                 fields:(const char *)fields
                            mergeFields:(double)mergeFields;

- (void)ga_add_design_event:(const char *)eventId
                     fields:(const char *)fields
                mergeFields:(double)mergeFields;

- (void)ga_add_design_event_value:(const char *)eventId
                            value:(double)value
                           fields:(const char *)fields
                      mergeFields:(double)mergeFields;

- (void)ga_add_error_event:(double)severity
                   message:(const char *)message
                    fields:(const char *)fields
               mergeFields:(double)mergeFields;

- (void)ga_add_ad_event:(double)adAction
                 adType:(double)adType
              adSdkName:(const char *)adSdkName
            adPlacement:(const char *)adPlacement
                 fields:(const char *)fields
            mergeFields:(double)mergeFields;

- (void)ga_add_ad_event_duration:(double)adAction
                          adType:(double)adType
                       adSdkName:(const char *)adSdkName
                     adPlacement:(const char *)adPlacement
                        duration:(double)duration
                          fields:(const char *)fields
                     mergeFields:(double)mergeFields;

- (void)ga_add_ad_event_reason:(double)adAction
                        adType:(double)adType
                     adSdkName:(const char *)adSdkName
                   adPlacement:(const char *)adPlacement
                    noAdReason:(double)noAdReason
                        fields:(const char *)fields
                   mergeFields:(double)mergeFields;

// -------------------------------------------------------------------------
// Remote Configs
// -------------------------------------------------------------------------

- (const char *)ga_remote_configs_value:(const char *)key defaultValue:(const char *)defaultValue;
- (const char *)ga_remote_configs_json:(const char *)key;
- (const char *)ga_remote_configs_content;
- (double)ga_remote_configs_ready;

// -------------------------------------------------------------------------
// A/B Testing
// -------------------------------------------------------------------------

- (const char *)ga_ab_testing_id;
- (const char *)ga_ab_testing_variant_id;

@end
