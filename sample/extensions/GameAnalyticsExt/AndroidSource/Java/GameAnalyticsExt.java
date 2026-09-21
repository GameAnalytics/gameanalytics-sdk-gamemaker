package ${YYAndroidPackageName};

import ${YYAndroidPackageName}.RunnerActivity;
import com.gameanalytics.sdk.GameAnalytics;
import com.gameanalytics.sdk.GAAdAction;
import com.gameanalytics.sdk.GAAdError;
import com.gameanalytics.sdk.GAAdType;
import com.gameanalytics.sdk.GAErrorSeverity;
import com.gameanalytics.sdk.GAProgressionStatus;
import com.gameanalytics.sdk.GAResourceFlowType;
import org.json.JSONArray;
import java.util.ArrayList;

public class GameAnalyticsExt {

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private String[] parseStringArray(String json) {
        try {
            JSONArray arr = new JSONArray(json);
            String[] result = new String[arr.length()];
            for (int i = 0; i < arr.length(); i++) {
                result[i] = arr.getString(i);
            }
            return result;
        } catch (Exception e) {
            return new String[0];
        }
    }

    // -------------------------------------------------------------------------
    // Configuration
    // -------------------------------------------------------------------------

    public void ga_configure_build(String build) {
        GameAnalytics.configureBuild(build);
    }

    public void ga_configure_user_id(String userId) {
        GameAnalytics.configureUserId(userId);
    }

    public void ga_configure_external_user_id(String extUserId) {
        GameAnalytics.setExternalUserId(extUserId);
    }

    public void ga_configure_dimensions01(String json) {
        String[] dimensions = parseStringArray(json);
        ArrayList<String> list = new ArrayList<String>();
        for (String d : dimensions) list.add(d);
        GameAnalytics.configureAvailableCustomDimensions01(list.toArray(new String[0]));
    }

    public void ga_configure_dimensions02(String json) {
        String[] dimensions = parseStringArray(json);
        ArrayList<String> list = new ArrayList<String>();
        for (String d : dimensions) list.add(d);
        GameAnalytics.configureAvailableCustomDimensions02(list.toArray(new String[0]));
    }

    public void ga_configure_dimensions03(String json) {
        String[] dimensions = parseStringArray(json);
        ArrayList<String> list = new ArrayList<String>();
        for (String d : dimensions) list.add(d);
        GameAnalytics.configureAvailableCustomDimensions03(list.toArray(new String[0]));
    }

    public void ga_configure_resource_currencies(String json) {
        String[] currencies = parseStringArray(json);
        ArrayList<String> list = new ArrayList<String>();
        for (String c : currencies) list.add(c);
        GameAnalytics.configureAvailableResourceCurrencies(list.toArray(new String[0]));
    }

    public void ga_configure_resource_item_types(String json) {
        String[] types = parseStringArray(json);
        ArrayList<String> list = new ArrayList<String>();
        for (String t : types) list.add(t);
        GameAnalytics.configureAvailableResourceItemTypes(list.toArray(new String[0]));
    }

    public void ga_configure_sdk_version(String version) {
        GameAnalytics.configureSdkGameEngineVersion(version);
    }

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    public void ga_initialize(String gameKey, String gameSecret) {
        GameAnalytics.initialize(RunnerActivity.CurrentActivity, gameKey, gameSecret);
    }

    // -------------------------------------------------------------------------
    // Settings
    // -------------------------------------------------------------------------

    public void ga_set_info_log(double enabled) {
        GameAnalytics.setEnabledInfoLog(enabled != 0.0);
    }

    public void ga_set_verbose_log(double enabled) {
        GameAnalytics.setEnabledVerboseLog(enabled != 0.0);
    }

    public void ga_set_event_submission(double enabled, double cacheLocally) {
        GameAnalytics.setEnabledEventSubmission(enabled != 0.0);
    }

    public void ga_set_error_reporting(double flag) {
        GameAnalytics.setEnabledErrorReporting(flag != 0.0);
    }

    public void ga_set_manual_session(double enabled) {
        GameAnalytics.setEnabledManualSessionHandling(enabled != 0.0);
    }

    // -------------------------------------------------------------------------
    // Session
    // -------------------------------------------------------------------------

    public void ga_start_session() {
        GameAnalytics.startSession(RunnerActivity.CurrentActivity);
    }

    public void ga_end_session() {
        GameAnalytics.endSession();
    }

    public void ga_on_quit() {
        GameAnalytics.onStop();
    }

    // -------------------------------------------------------------------------
    // Custom Dimensions
    // -------------------------------------------------------------------------

    public void ga_set_dimension01(String value) {
        GameAnalytics.setCustomDimension01(value);
    }

    public void ga_set_dimension02(String value) {
        GameAnalytics.setCustomDimension02(value);
    }

    public void ga_set_dimension03(String value) {
        GameAnalytics.setCustomDimension03(value);
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    public void ga_add_business_event(String currency, double amount, String itemType, String itemId, String cartType, String fields, double mergeFields) {
        GameAnalytics.addBusinessEvent(currency, (int) amount, itemType, itemId, cartType, fields, mergeFields != 0.0);
    }

    public void ga_add_resource_event(double flowType, String currency, double amount, String itemType, String itemId, String fields, double mergeFields) {
        GAResourceFlowType flow = GAResourceFlowType.values()[(int) flowType - 1];
        GameAnalytics.addResourceEvent(flow, currency, (float) amount, itemType, itemId, fields, mergeFields != 0.0);
    }

    public void ga_add_progression_event(double status, String prog1, String prog2, String prog3, String fields, double mergeFields) {
        GAProgressionStatus ps = GAProgressionStatus.values()[(int) status - 1];
        GameAnalytics.addProgressionEvent(ps, prog1, prog2, prog3, fields, mergeFields != 0.0);
    }

    public void ga_add_progression_event_score(double status, String prog1, String prog2, String prog3, double score, String fields, double mergeFields) {
        GAProgressionStatus ps = GAProgressionStatus.values()[(int) status - 1];
        GameAnalytics.addProgressionEvent(ps, prog1, prog2, prog3, (int) score, fields, mergeFields != 0.0);
    }

    public void ga_add_design_event(String eventId, String fields, double mergeFields) {
        GameAnalytics.addDesignEvent(eventId, fields, mergeFields != 0.0);
    }

    public void ga_add_design_event_value(String eventId, double value, String fields, double mergeFields) {
        GameAnalytics.addDesignEvent(eventId, value, fields, mergeFields != 0.0);
    }

    public void ga_add_error_event(double severity, String message, String fields, double mergeFields) {
        GAErrorSeverity sev = GAErrorSeverity.values()[(int) severity - 1];
        GameAnalytics.addErrorEvent(sev, message, fields, mergeFields != 0.0);
    }

    public void ga_add_ad_event(double adAction, double adType, String adSdkName, String adPlacement, String fields, double mergeFields) {
        GAAdAction action = GAAdAction.values()[(int) adAction - 1];
        GAAdType type = GAAdType.values()[(int) adType - 1];
        GameAnalytics.addAdEvent(action, type, adSdkName, adPlacement, fields, mergeFields != 0.0);
    }

    public void ga_add_ad_event_duration(double adAction, double adType, String adSdkName, String adPlacement, double duration, String fields, double mergeFields) {
        GAAdAction action = GAAdAction.values()[(int) adAction - 1];
        GAAdType type = GAAdType.values()[(int) adType - 1];
        GameAnalytics.addAdEvent(action, type, adSdkName, adPlacement, (long) duration, fields, mergeFields != 0.0);
    }

    public void ga_add_ad_event_reason(double adAction, double adType, String adSdkName, String adPlacement, double noAdReason, String fields, double mergeFields) {
        GAAdAction action = GAAdAction.values()[(int) adAction - 1];
        GAAdType type = GAAdType.values()[(int) adType - 1];
        GAAdError reason = GAAdError.values()[(int) noAdReason - 1];
        GameAnalytics.addAdEvent(action, type, adSdkName, adPlacement, reason, fields, mergeFields != 0.0);
    }

    // -------------------------------------------------------------------------
    // Remote Configs
    // -------------------------------------------------------------------------

    public String ga_remote_configs_value(String key, String defaultValue) {
        return GameAnalytics.getRemoteConfigsValueAsString(key, defaultValue);
    }

    public String ga_remote_configs_json(String key) {
        return GameAnalytics.getRemoteConfigsValueAsJson(key);
    }

    public String ga_remote_configs_content() {
        return GameAnalytics.getRemoteConfigsContentAsString();
    }

    public double ga_remote_configs_ready() {
        return GameAnalytics.isRemoteConfigsReady() ? 1.0 : 0.0;
    }

    // -------------------------------------------------------------------------
    // A/B Testing
    // -------------------------------------------------------------------------

    public String ga_ab_testing_id() {
        return GameAnalytics.getABTestingId();
    }

    public String ga_ab_testing_variant_id() {
        return GameAnalytics.getABTestingVariantId();
    }
}
