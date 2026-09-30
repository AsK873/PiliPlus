import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlay, DeviceOrientation;
import 'package:window_manager/window_manager.dart';

bool _isDesktopFullScreen = false;

/// M8-22：桌面全屏改由 window_manager 接管（不再走 media_kit 的原生通道）。
///
/// 原实现调用 media_kit 的 `Utils.EnterNativeFullscreen`：它直接改 GWL_STYLE
/// （去掉 WS_OVERLAPPEDWINDOW）再 SWP_FRAMECHANGED，而 window_manager 的原生
/// 插件并不知道这次状态变化（它的 is_frameless_ / g_is_window_fullscreen 都没变），
/// WM_NCCALCSIZE 于是落到系统默认处理 —— 切换瞬间原生标题栏/边框被重新绘制，
/// 就是那个"一闪而过的主题框"。
///
/// window_manager 自己的 setFullScreen 会先把窗口置为 frameless
/// （is_frameless_ = true），此后插件的 WM_NCCALCSIZE 直接 return 0：
/// 客户区始终铺满窗口、全程不绘制非客户区，因此不会有边框回闪。
///
/// 网页全屏（inAppFullScreen）依旧完全不动系统窗口，只改 Dart 层播放器状态。
@pragma('vm:notify-debugger-on-exception')
Future<void> enterDesktopFullScreen({bool inAppFullScreen = false}) async {
  if (!inAppFullScreen && !_isDesktopFullScreen) {
    _isDesktopFullScreen = true;
    try {
      await windowManager.setFullScreen(true);
    } catch (_) {}
  }
}

@pragma('vm:notify-debugger-on-exception')
Future<void> exitDesktopFullScreen() async {
  if (_isDesktopFullScreen) {
    _isDesktopFullScreen = false;
    try {
      await windowManager.setFullScreen(false);
    } catch (_) {}
  }
}

List<DeviceOrientation>? _lastOrientation;
Future<void>? _setPreferredOrientations(List<DeviceOrientation> orientations) {
  if (_lastOrientation == orientations) {
    return null;
  }
  _lastOrientation = orientations;
  return SystemChrome.setPreferredOrientations(orientations);
}

Future<void>? portraitUpMode() {
  return _setPreferredOrientations(const [.portraitUp]);
}

Future<void>? portraitDownMode() {
  return _setPreferredOrientations(const [.portraitDown]);
}

Future<void>? landscapeLeftMode() {
  return _setPreferredOrientations(const [.landscapeLeft]);
}

Future<void>? landscapeRightMode() {
  return _setPreferredOrientations(const [.landscapeRight]);
}

Future<void>? fullMode() {
  return _setPreferredOrientations(
    const [.portraitUp, .portraitDown, .landscapeLeft, .landscapeRight],
  );
}

bool _showSystemBar = true;
bool get showSystemBar_ => _showSystemBar;
Future<void>? hideSystemBar() {
  if (!_showSystemBar) {
    return null;
  }
  _showSystemBar = false;
  return SystemChrome.setEnabledSystemUIMode(.immersiveSticky);
}

//退出全屏显示
Future<void>? showSystemBar() {
  if (_showSystemBar) {
    return null;
  }
  _showSystemBar = true;
  return SystemChrome.setEnabledSystemUIMode(
    Platform.isAndroid && DeviceUtils.sdkInt < 29 ? .manual : .edgeToEdge,
    overlays: SystemUiOverlay.values,
  );
}
