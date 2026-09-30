import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlay, DeviceOrientation;
import 'package:window_manager/window_manager.dart';

bool _isDesktopFullScreen = false;

/// M8-23：桌面全屏改由 window_manager 接管，切换过程不再出现原生窗口框。
///
/// 之前调的是 media_kit 的 `Utils.EnterNativeFullscreen`：它只把
/// WS_OVERLAPPEDWINDOW 从 GWL_STYLE 里摘掉再 SWP_FRAMECHANGED，而
/// window_manager 的原生插件并不知道这次状态变化（is_frameless_ /
/// g_is_window_fullscreen 都没动），于是 WM_NCCALCSIZE 落回系统默认处理 ——
/// 切换瞬间 DWM 仍会合成"带原生标题栏/边框"的窗口形态一段时间（实测切换后
/// 仍有数百毫秒是带标题栏的窗口形态），看起来就是全屏时闪出系统原生窗口框。
///
/// window_manager 自己的 setFullScreen 会先 SetAsFrameless()：把 is_frameless_
/// 置真，此后插件的 WM_NCCALCSIZE 直接 `return 0` —— 客户区始终铺满窗口、
/// 全程不绘制任何非客户区；随后在同一段原生调用里把窗口铺满显示器。
/// 整个过程只是一次合成，原生边框没有机会被画出来。
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
