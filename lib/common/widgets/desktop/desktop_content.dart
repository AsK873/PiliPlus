// =============================================================
// PiliPlus Windows 桌面化 · 内容限宽通用助手（纯 UI）
// 信息流/网格类页面共用：可用宽度超过 maxWidth 时内容居中排布，
// 不再横向铺满超宽屏；窄窗与非桌面端原样返回（无副作用）。
// =============================================================
import 'package:PiliPlus/common/style.dart' show Style;
import 'package:PiliPlus/common/widgets/desktop/hover_card.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_constrained_cross_axis.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面端把 [sliver] 限宽至 [maxWidth]（默认全桌面唯一来源
/// [Style.contentMaxWidth] = 1480）并居中；非桌面原样返回。
Widget desktopLimitSliver(
  Widget sliver, {
  double maxWidth = Style.contentMaxWidth,
}) => PlatformUtils.isDesktop
    ? CenteredSliverConstrainedCrossAxis(maxExtent: maxWidth, sliver: sliver)
    : sliver;

/// [desktopLimitSliver] 的盒子（非 sliver）版本：给 TabBar / 页头这类盒子类
/// 内容复现同一套内容限宽几何（可用宽度 > [maxWidth] 时限宽居中）。
///
/// - 未超限（或非桌面端）时**原样返回** [child]，不插入任何额外布局层，
///   窄窗视觉零变化；
/// - [leadingInset] / [trailingInset] 为正文自身的水平缩进（首页各列表页的
///   `margin: EdgeInsets.only(left: Style.safeSpace)`，以及桌面滚动条专用车道
///   desktopScrollbarLaneWidth，见 common/widgets/scroll_behavior.dart）：
///   限宽生效时一并复现，使调用方的左右缘与限宽后的正文（网格）完全重合。
Widget desktopLimitBox(
  Widget child, {
  double maxWidth = Style.contentMaxWidth,
  double leadingInset = 0,
  double trailingInset = 0,
}) {
  if (!PlatformUtils.isDesktop) {
    return child;
  }
  return LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth) {
        return child;
      }
      final avail = constraints.maxWidth - leadingInset - trailingInset;
      if (avail <= maxWidth) {
        return child;
      }
      final offset = (avail - maxWidth) / 2;
      return Padding(
        padding: EdgeInsets.only(
          left: leadingInset + offset,
          right: trailingInset + offset,
        ),
        child: child,
      );
    },
  );
}

/// 桌面端为卡片加 hover 反馈（视觉 + 可选悬停预取详情）；非桌面原样返回。
/// [prefetchBvid] 非空时，鼠标在卡片上停留约 400ms 后预取该视频详情。
Widget desktopCard(Widget card, {String? prefetchBvid}) =>
    PlatformUtils.isDesktop
    ? HoverCard(
        onHoverDelay: prefetchBvid == null
            ? null
            : () => PageUtils.prefetchVideoDetail(prefetchBvid),
        child: card,
      )
    : card;
