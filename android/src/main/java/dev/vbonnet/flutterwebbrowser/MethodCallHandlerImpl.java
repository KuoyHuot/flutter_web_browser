package dev.vbonnet.flutterwebbrowser;

import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;

import androidx.annotation.AnimRes;
import androidx.annotation.NonNull;
import androidx.browser.customtabs.CustomTabColorSchemeParams;
import androidx.browser.customtabs.CustomTabsClient;
import androidx.browser.customtabs.CustomTabsIntent;
import java.util.Arrays;
import java.util.HashMap;
import java.util.regex.Pattern;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MethodCallHandlerImpl implements MethodCallHandler {

  private Activity activity;

  public void setActivity(Activity activity) {
    this.activity = activity;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "openWebPage":
        openUrl(call, result);
        break;
      case "warmup":
        warmup(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void openUrl(MethodCall call, Result result) {
    if (activity == null) {
      result.error("no_activity", "Plugin is only available within an activity context", null);
      return;
    }
    String url = call.argument("url");
    HashMap<String, Object> options = call.<HashMap<String, Object>>argument("android_options");

    CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();

    builder.setColorScheme((Integer) options.get("colorScheme"));

    HashMap<String, Object> lightColorSchemeParamsMap = (HashMap<String, Object>) options.get("lightColorSchemeParams");
    if (lightColorSchemeParamsMap != null) {
      CustomTabColorSchemeParams lightColorSchemeParams = mapColorSchemeParams(lightColorSchemeParamsMap);
      builder.setColorSchemeParams(CustomTabsIntent.COLOR_SCHEME_LIGHT, lightColorSchemeParams);
    }

    HashMap<String, Object> darkColorSchemeParamsMap = (HashMap<String, Object>) options.get("darkColorSchemeParams");
    if (darkColorSchemeParamsMap != null) {
      CustomTabColorSchemeParams darkColorSchemeParams = mapColorSchemeParams(darkColorSchemeParamsMap);
      builder.setColorSchemeParams(CustomTabsIntent.COLOR_SCHEME_DARK, darkColorSchemeParams);
    }

    HashMap<String, Object> defaultColorSchemeParamsMap = (HashMap<String, Object>) options.get("defaultColorSchemeParams");
    if (defaultColorSchemeParamsMap != null) {
      CustomTabColorSchemeParams defaultColorSchemeParams = mapColorSchemeParams(defaultColorSchemeParamsMap);
      builder.setDefaultColorSchemeParams(defaultColorSchemeParams);
    }

    builder.setInstantAppsEnabled((Boolean) options.get("instantAppsEnabled"));

    Integer shareState = (Integer) options.get("shareState");
    if (shareState != null) {
      builder.setShareState(shareState);
    }

    // Animation
    int startEnterResId = -1;
    int startExitResId = 1;
    int exitEnterResId = -1;
    int exitExitResId = 1;

    HashMap<String, Object> animationParamsMap = (HashMap<String, Object>) options.get("animation");

    if(animationParamsMap != null) {
      String startEnter = (String) animationParamsMap.get("startEnter");
      startEnterResId = resolveAnimationIdentifierIfNeeded((startEnter));

      String startExit = (String) animationParamsMap.get("startExit");
      startExitResId = resolveAnimationIdentifierIfNeeded((startExit));

      String exitEnter = (String) animationParamsMap.get("exitEnter");
      exitEnterResId = resolveAnimationIdentifierIfNeeded((exitEnter));

      String exitExit = (String) animationParamsMap.get("exitExit");
      exitExitResId = resolveAnimationIdentifierIfNeeded((exitExit));

      builder.setStartAnimations(activity, startEnterResId, startExitResId);
      builder.setExitAnimations(activity, exitEnterResId, exitExitResId);
    }

    builder.setShowTitle((Boolean) options.get("showTitle"));

    builder.setUrlBarHidingEnabled((Boolean) options.get("urlBarHidingEnabled"));

    CustomTabsIntent customTabsIntent = builder.build();
    customTabsIntent.intent.setPackage(getPackageName());
    customTabsIntent.launchUrl(activity, Uri.parse(url));

    result.success(null);
  }

  private CustomTabColorSchemeParams mapColorSchemeParams(HashMap<String, Object> options) {
    CustomTabColorSchemeParams.Builder builder = new CustomTabColorSchemeParams.Builder();

    String toolbarColor = (String) options.get("toolbarColor");
    if (toolbarColor != null) {
      builder.setToolbarColor(Color.parseColor(toolbarColor));
    }

    String secondaryToolbarColor = (String) options.get("secondaryToolbarColor");
    if (secondaryToolbarColor != null) {
      builder.setSecondaryToolbarColor(Color.parseColor(secondaryToolbarColor));
    }

    String navigationBarColor = (String) options.get("navigationBarColor");
    if (navigationBarColor != null) {
      builder.setNavigationBarColor(Color.parseColor(navigationBarColor));
    }

    String navigationBarDividerColor = (String) options.get("navigationBarDividerColor");
    if (navigationBarDividerColor != null) {
      builder.setNavigationBarDividerColor(Color.parseColor(navigationBarDividerColor));
    }

    return builder.build();
  }


  @AnimRes
  private int resolveAnimationIdentifierIfNeeded(@NonNull String identifier) {
    final Pattern animationIdentifierPattern = Pattern.compile("^android:anim/");
    if (animationIdentifierPattern.matcher(identifier).find()) {
      return activity.getResources().getIdentifier(identifier, null, null);
    } else {
      return activity.getResources().getIdentifier(identifier, "anim", activity.getPackageName());
    }
  }

  private void warmup(Result result) {
    boolean success = CustomTabsClient.connectAndInitialize(activity, getPackageName());
    result.success(success);
  }

  private String getPackageName() {
    return CustomTabsClient.getPackageName(activity, Arrays.asList("com.android.chrome"));
  }
}
