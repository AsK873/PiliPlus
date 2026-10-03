import 'dart:io' show Platform;

import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

const Set<PointerDeviceKind> desktopDragDevices = {
  .touch,
  .mouse,
  .trackpad,
  .stylus,
  .invertedStylus,
  .unknown,
};

/// 桌面端竖向滚动视口的右侧「滚动条专用车道」宽度：滚动条画在车道内，
/// 视口整体让出这条带（不覆盖内容）。也是首页正文内容区的右边界缩进，
/// 首页 TabBar 复用同一常量才能与正文左右缘对齐。
const double desktopScrollbarLaneWidth = 10.0;

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  // P0-1 桌面滚动条：极简「常显细条」。
  // 仅竖向（横向列表不加，避免视频卡/标签横向列表出现大量滚动条）；
  // 仅宽屏桌面（沿用项目统一 breakpoint：context.showNavbar = width > 800）；
  // 常显细条、无轨道、hover 不变粗；不占布局宽度（绘制在内容之上）。
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final isVertical =
        details.direction == AxisDirection.down ||
        details.direction == AxisDirection.up;
    if (!isVertical) return child;
    if (!context.showNavbar) return child;
    final controller = details.controller;
    if (controller == null) return child;
    // 右侧「专用车道」：为滚动条预留固定宽度（10 逻辑 px），滚动条画在车道内，
    // 不覆盖内容、也不改变内容自身排版（仅视口整体让出这条带）。
    // 车道宽度 0（见 [OverlayScrollbarBehavior]）时不内缩：滚动条覆盖式画在内容之上。
    final laneWidth = scrollbarLaneWidth;
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        crossAxisMargin: 2,
        thumbColor: WidgetStatePropertyAll(
          ColorScheme.of(context).outline.withValues(alpha: .55),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        child: laneWidth > 0
            ? Padding(
                padding: EdgeInsets.only(right: laneWidth),
                child: child,
              )
            : child,
      ),
    );
  }

  /// 竖视口为滚动条让出的右侧车道宽度（逻辑 px）。
  /// [desktopScrollbarLaneWidth] 为默认值；返回 0 的子类改成**覆盖式**滚动条
  /// （滚动条画在内容之上，视口不缩窄）。滚动条本体（常显 / 6px / 圆角 /
  /// 颜色 / hover 不变粗）与滚动行为都不随本值改变。
  double get scrollbarLaneWidth => desktopScrollbarLaneWidth;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (Platform.isAndroid) {
      return StretchingOverscrollIndicator(
        axisDirection: details.direction,
        clipBehavior: details.decorationClipBehavior ?? .hardEdge,
        child: child,
      );
    }
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => desktopDragDevices;
}

/// **覆盖式**滚动条：滚动条本体与 [CustomScrollBehavior] 完全一致（常显 6px
/// 细条、圆角 3、无轨道、hover 不变粗、同一 thumb 配色），唯一区别是
/// **不预留右侧车道**（[scrollbarLaneWidth] = 0）：滚动条画在内容之上，
/// 视口宽度 == 内容宽度。
///
/// 用于紧贴视口右缘的窄列表——桌面侧栏导航列表：预留 10px 车道会让导航行
/// （药丸）的可用宽比分隔线窄 10px，左右内边距变成 8 / 18 不对称
/// （实测 180 宽侧栏：药丸 154 = 180 − 16 − 10，右缘 161 而分隔线 180）。
/// 侧栏行的左右外边距各 8px，6px 拇指 + 2px margin 正好落在右 8px 外边距内，
/// 不会压到药丸；其余页面仍走全局 [CustomScrollBehavior]，车道不变。
class OverlayScrollbarBehavior extends CustomScrollBehavior {
  const OverlayScrollbarBehavior();

  @override
  double get scrollbarLaneWidth => 0;
}

class NoOverscrollIndicator extends CustomScrollBehavior {
  const NoOverscrollIndicator();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
