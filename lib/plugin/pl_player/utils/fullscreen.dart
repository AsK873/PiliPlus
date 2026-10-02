import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlay, DeviceOrientation;
import 'package:window_manager/window_manager.dart';

bool _isDesktopFullScreen = false;

/// 本次桌面全屏是否走了 `TitleBarStyle.hidden` 兜底。
///
/// 只有"进入全屏前窗口已最大化"时才需要：那条路 window_manager 会跳过
/// SetAsFrameless()，插件 WM_NCCALCSIZE 只能靠 title_bar_style_ != "normal"
/// 收敛。此时原生保存的 title_bar_style_ 是 hidden，退出全屏后必须显式恢复
/// normal，否则标题栏会一直不见。
bool _usedHiddenFallback = false;

/// 桌面全屏：改用 window_manager 控制。
///
/// 原实现调用 media_kit 的 `Utils.EnterNativeFullscreen`：它只摘掉
/// GWL_STYLE 里的 WS_OVERLAPPEDWINDOW，而 window_manager 的原生插件并不知道
/// 这次变化（title_bar_style_ 仍为 normal、is_frameless_ 仍为 false），
/// WM_NCCALCSIZE 于是落回系统默认处理，原生标题栏/边框照旧被绘制。
///
/// 现在只调 window_manager.setFullScreen：窗口未最大化时它会先
/// SetAsFrameless()，把 is_frameless_ 置真，插件 WM_NCCALCSIZE 随即 return 0
/// —— 客户区铺满窗口、不绘制非客户区，原生标题栏自然消失。
/// 窗口"已最大化"时该分支会被跳过，WM_NCCALCSIZE 只剩
/// `IsFullScreen() && title_bar_style_ != "normal"` 这一条收敛路径，
/// 所以仅这一种情况补一次 hidden。
///
/// 这样每次切换全屏少掉一次 `DwmExtendFrameIntoClientArea` +
/// `SWP_FRAMECHANGED` 的非客户区全量重算（实测 13~53ms）。
///
/// 网页全屏（inAppFullScreen）依旧完全不动系统窗口。
@pragma('vm:notify-debugger-on-exception')
Future<void> enterDesktopFullScreen({bool inAppFullScreen = false}) async {
  if (!inAppFullScreen && !_isDesktopFullScreen) {
    _isDesktopFullScreen = true;
    try {
      _usedHiddenFallback =
          Pref.showWindowTitleBar && await windowManager.isMaximized();
      if (_usedHiddenFallback) {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      }
      await windowManager.setFullScreen(true);
    } catch (_) {
      _usedHiddenFallback = false;
    }
  }
}

@pragma('vm:notify-debugger-on-exception')
Future<void> exitDesktopFullScreen() async {
  if (_isDesktopFullScreen) {
    _isDesktopFullScreen = false;
    try {
      await windowManager.setFullScreen(false);
      // 原生 SetFullScreen(false) 结尾已自行恢复 title_bar_style_ 并做完
      // DwmExtendFrameIntoClientArea + SWP_FRAMECHANGED。只有进入时走了
      // hidden 兜底（原生保存的样式是 hidden）才需要再显式恢复 normal。
      if (_usedHiddenFallback) {
        _usedHiddenFallback = false;
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      }
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
