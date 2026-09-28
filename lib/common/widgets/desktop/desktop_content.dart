// =============================================================
// PiliPlus Windows PC 化 · M3 桌面呈现通用助手（纯 UI，2026-09-05）
// 供信息流各页共用：内容限宽居中 + 卡片 hover。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/hover_card.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_constrained_cross_axis.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面端把 [sliver] 限宽至 [maxWidth] 并居中；非桌面原样返回。
Widget desktopLimitSliver(Widget sliver, {double maxWidth = 1280}) =>
    PlatformUtils.isDesktop
        ? CenteredSliverConstrainedCrossAxis(maxExtent: maxWidth, sliver: sliver)
        : sliver;

/// 桌面端为卡片加 hover 反馈；非桌面原样返回。
Widget desktopCard(Widget card) =>
    PlatformUtils.isDesktop ? HoverCard(child: card) : card;
