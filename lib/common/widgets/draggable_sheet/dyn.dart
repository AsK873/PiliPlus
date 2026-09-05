// M0 兼容垫片（2026-09-05，用户批准"混合：少量应用侧行为等价垫片"）：
// 原实现覆写了作者 fork 中新公开的 DraggableScrollableSheet 内部状态/滚动位置
// （DraggableScrollableSheetState.initScrollController / …ScrollController /
// …ScrollPosition：当内容列表滚动到顶时把拖动交给面板本身，避免拖动穿透）。
// 本 SDK（legacy 架构）中 DraggableScrollableSheet 内建"内容滚动 + 面板拉伸"
// 联动：builder 提供的 scrollController 驱动面板，列表到达 min/max 后继续拖动
// 由框架自带的滚动-面板协调处理，交互效果与原目标一致。
// 因此此处退化为纯透传子类（仅保留原有构造参数形态），不再依赖任何私有框架成员。
// 差异登记：原自定义 position 的“面板区直接拖动时机”细粒度由框架默认行为近似替代，
// 需在 Phase3 动态/私信/话题面板回归时人工核对（见 analysis/m0-patch-register.md C2）。
import 'package:material_ui/material_ui.dart';

class DynDraggableScrollableSheet extends DraggableScrollableSheet {
  const DynDraggableScrollableSheet({
    super.key,
    super.initialChildSize,
    super.minChildSize,
    super.maxChildSize,
    super.expand,
    super.snap,
    super.snapSizes,
    super.snapAnimationDuration,
    super.controller,
    super.shouldCloseOnMinExtent,
    required super.builder,
  });
}
