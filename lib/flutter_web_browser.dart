import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

enum SafariViewControllerDismissButtonStyle {
  done,
  close,
  cancel,
}

class SafariViewControllerOptions {
  final bool barCollapsingEnabled;
  final bool entersReaderIfAvailable;
  final Color? preferredBarTintColor;
  final Color? preferredControlTintColor;
  final bool modalPresentationCapturesStatusBarAppearance;
  final SafariViewControllerDismissButtonStyle? dismissButtonStyle;

  const SafariViewControllerOptions({
    this.barCollapsingEnabled = false,
    this.entersReaderIfAvailable = false,
    this.preferredBarTintColor,
    this.preferredControlTintColor,
    this.modalPresentationCapturesStatusBarAppearance = false,
    this.dismissButtonStyle,
  });
}

enum CustomTabsColorScheme {
  system, // 0x00000000
  light, // 0x00000001
  dark, // 0x00000002
}

enum CustomTabsShareState {
  default_, // 0x00000000
  on, // 0x00000001
  off, // 0x00000002
}

extension CustomTabsShareStateExtension on CustomTabsShareState {
  static CustomTabsShareState? fromAddDefaultShareMenuItem(
      {bool? addDefaultShareMenuItem}) {
    if (addDefaultShareMenuItem != null) {
      if (addDefaultShareMenuItem) {
        return CustomTabsShareState.on;
      } else {
        return CustomTabsShareState.off;
      }
    }

    return null;
  }
}

class CustomTabsAnimationParams {
  final String? startEnter;
  final String? startExit;
  final String? exitEnter;
  final String? exitExit;

  const CustomTabsAnimationParams({
    this.startEnter: 'android:anim/fade_in',
    this.startExit: 'android:anim/fade_out',
    this.exitEnter: 'android:anim/fade_in',
    this.exitExit: 'android:anim/fade_out',
  });

  Map<String, dynamic> toMethodChannelArgumentMap() {
    return {
      'startEnter': startEnter,
      'startExit': startExit,
      'exitEnter': exitEnter,
      'exitExit': exitExit,
    };
  }
}

class CustomTabsColorSchemeParams {
  final Color? toolbarColor;
  final Color? secondaryToolbarColor;
  final Color? navigationBarColor;
  final Color? navigationBarDividerColor;

  const CustomTabsColorSchemeParams({
    this.toolbarColor,
    this.secondaryToolbarColor,
    this.navigationBarColor,
    this.navigationBarDividerColor,
  });

  Map<String, dynamic> toMethodChannelArgumentMap({
    Color? deprecatedToolbarColor,
    Color? deprecatedSecondaryToolbarColor,
    Color? deprecatedNavigationBarColor,
  }) {
    return {
      'toolbarColor': (toolbarColor ?? deprecatedToolbarColor)?.hexColor,
      'secondaryToolbarColor':
          (secondaryToolbarColor ?? deprecatedSecondaryToolbarColor)?.hexColor,
      'navigationBarColor':
          (navigationBarColor ?? deprecatedNavigationBarColor)?.hexColor,
      'navigationBarDividerColor': navigationBarDividerColor?.hexColor,
    };
  }
}

class CustomTabsOptions {
  final CustomTabsColorScheme colorScheme;
  final Color? toolbarColor;
  final Color? secondaryToolbarColor;
  final Color? navigationBarColor;
  final CustomTabsColorSchemeParams? lightColorSchemeParams;
  final CustomTabsColorSchemeParams? darkColorSchemeParams;
  final CustomTabsColorSchemeParams? defaultColorSchemeParams;
  final CustomTabsAnimationParams? animationParams;
  final bool instantAppsEnabled;
  final bool? addDefaultShareMenuItem;
  final CustomTabsShareState? shareState;
  final bool showTitle;
  final bool urlBarHidingEnabled;

  const CustomTabsOptions({
    this.colorScheme = CustomTabsColorScheme.system,
    @Deprecated('Use defaultColorSchemeParams.toolbarColor instead')
        this.toolbarColor,
    @Deprecated('Use defaultColorSchemeParams.secondaryToolbarColor instead')
        this.secondaryToolbarColor,
    @Deprecated('Use defaultColorSchemeParams.navigationBarColor instead')
        this.navigationBarColor,
    this.lightColorSchemeParams,
    this.darkColorSchemeParams,
    this.defaultColorSchemeParams,
    this.animationParams,
    this.instantAppsEnabled = false,
    @Deprecated('Use shareState instead') this.addDefaultShareMenuItem,
    this.shareState,
    this.showTitle = false,
    this.urlBarHidingEnabled = false,
  });
}

extension _hexColor on Color {
  /// Returns the color value as ARGB hex value.
  String get hexColor {
    return '#' + value.toRadixString(16).padLeft(8, '0');
  }
}

/// When supported, the built-in browser can notify of various events.
abstract class BrowserEvent {
  // Convenience constructor.
  static BrowserEvent? fromMap(Map<String, dynamic> map) {
    if (map['event'] == 'redirect') {
      return RedirectEvent(Uri.parse(map['url']));
    }
    if (map['event'] == 'close') {
      return CloseEvent();
    }

    return null;
  }
}

/// Describes a redirect.
class RedirectEvent extends BrowserEvent {
  RedirectEvent(this.url);

  /// New URL which is now visible.
  final Uri url;
}

/// Describes a close event (e.g. when the user closes the tab
/// or the [FlutterWebBrowser.close] method was invoked).
class CloseEvent extends BrowserEvent {}

class FlutterWebBrowser {
  static const _NS = 'flutter_web_browser';
  static const MethodChannel _channel = const MethodChannel(_NS);
  static const EventChannel _eventChannel = const EventChannel('$_NS/events');

  static Future<bool> warmup() async {
    return await _channel.invokeMethod<bool>('warmup') ?? true;
  }

  /// Closes the currently open browser.
  ///
  /// This function will emit a [CloseEvent], which can be observed using [events].
  ///
  /// Only supported on iOS. Will not do anything on other platforms.
  static Future<void> close() async {
    if (!Platform.isIOS) {
      return;
    }

    await _channel.invokeMethod<void>('close');
  }

  /// Returns a stream of browser events which were observed while it was open.
  ///
  /// See [CloseEvent] & [RedirectEvent] for details on the events.
  ///
  /// Only supported on iOS. Returns a empty stream other platforms.
  static Stream<BrowserEvent> events() {
    if (!Platform.isIOS) {
      return Stream.empty();
    }

    return _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, String>>((event) => Map<String, String>.from(event))
        .map((event) => BrowserEvent.fromMap(event)!);
  }

  static Future<void> openWebPage({
    required String url,
    CustomTabsOptions customTabsOptions = const CustomTabsOptions(),
    SafariViewControllerOptions safariVCOptions =
        const SafariViewControllerOptions(),
  }) {
    final CustomTabsColorSchemeParams customTabsDefaultColorSchemeParams =
        customTabsOptions.defaultColorSchemeParams ??
            CustomTabsColorSchemeParams(
              toolbarColor: customTabsOptions.toolbarColor,
              secondaryToolbarColor: customTabsOptions.secondaryToolbarColor,
              navigationBarColor: customTabsOptions.navigationBarColor,
            );
    final CustomTabsShareState customTabsShareState =
        customTabsOptions.shareState ??
            CustomTabsShareStateExtension.fromAddDefaultShareMenuItem(
              addDefaultShareMenuItem:
                  customTabsOptions.addDefaultShareMenuItem,
            ) ??
            CustomTabsShareState.default_;

    final CustomTabsAnimationParams customTabsAnimationParams =
        customTabsOptions.animationParams ?? const CustomTabsAnimationParams();

    return _channel.invokeMethod('openWebPage', {
      "url": url,
      'android_options': {
        'colorScheme': customTabsOptions.colorScheme.index,
        'lightColorSchemeParams': customTabsOptions.lightColorSchemeParams
            ?.toMethodChannelArgumentMap(),
        'darkColorSchemeParams': customTabsOptions.darkColorSchemeParams
            ?.toMethodChannelArgumentMap(),
        'defaultColorSchemeParams':
            customTabsDefaultColorSchemeParams.toMethodChannelArgumentMap(),
        'animation': customTabsAnimationParams.toMethodChannelArgumentMap(),
        'instantAppsEnabled': customTabsOptions.instantAppsEnabled,
        'shareState': customTabsShareState.index,
        'showTitle': customTabsOptions.showTitle,
        'urlBarHidingEnabled': customTabsOptions.urlBarHidingEnabled,
      },
      'ios_options': {
        'barCollapsingEnabled': safariVCOptions.barCollapsingEnabled,
        'entersReaderIfAvailable': safariVCOptions.entersReaderIfAvailable,
        'preferredBarTintColor':
            safariVCOptions.preferredBarTintColor?.hexColor,
        'preferredControlTintColor':
            safariVCOptions.preferredControlTintColor?.hexColor,
        'modalPresentationCapturesStatusBarAppearance':
            safariVCOptions.modalPresentationCapturesStatusBarAppearance,
        'dismissButtonStyle': safariVCOptions.dismissButtonStyle?.index,
      },
    });
  }
}
