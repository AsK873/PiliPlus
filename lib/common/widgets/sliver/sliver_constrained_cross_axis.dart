// M0 兼容垫片（2026-09-05，用户批准"混合：少量应用侧行为等价垫片"）：
// 原实现继承作者 fork 中新公开的内部件（SliverConstrainedCrossAxis_/SliverZeroFlexParentDataWidget），
// 本 SDK 中对应物为私有 `_SliverConstrainedCrossAxis`/`_SliverZeroFlexParentDataWidget`。
// 改为基于本 SDK 公开件（SliverConstrainedCrossAxis / SingleChildRenderObjectWidget /
// RenderSliverConstrainedCrossAxis）的等价实现：功能 = 子 sliver 限宽 + 横向居中，
// 布局/绘制/命中/变换语义与原实现一致（见类注释）。
import 'package:flutter/rendering.dart' show RenderSliverConstrainedCrossAxis, SliverHitTestResult, RenderSliver, Matrix4;
import 'package:material_ui/material_ui.dart';

/// A sliver that constrains its child's cross axis extent to [maxExtent] and
/// centers the child along the cross axis.
///
/// Wraps [RenderSliverConstrainedCrossAxis] and offsets both painting and hit
/// testing by half of the remaining cross-axis space.
class CenteredSliverConstrainedCrossAxis extends SliverConstrainedCrossAxis {
  const CenteredSliverConstrainedCrossAxis({
    super.key,
    required super.maxExtent,
    required super.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredSliverConstrainedCrossAxis(
      maxExtent: maxExtent,
      sliver: sliver,
    );
  }
}

class _CenteredSliverConstrainedCrossAxis extends SingleChildRenderObjectWidget {
  const _CenteredSliverConstrainedCrossAxis({
    required this.maxExtent,
    required Widget sliver,
  }) : assert(maxExtent >= 0.0),
       super(child: sliver);

  final double maxExtent;

  @override
  CenteredRenderSliverConstrainedCrossAxis createRenderObject(
    BuildContext context,
  ) {
    return CenteredRenderSliverConstrainedCrossAxis(maxExtent: maxExtent);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    CenteredRenderSliverConstrainedCrossAxis renderObject,
  ) {
    renderObject.maxExtent = maxExtent;
  }
}

class CenteredRenderSliverConstrainedCrossAxis
    extends RenderSliverConstrainedCrossAxis {
  CenteredRenderSliverConstrainedCrossAxis({required super.maxExtent});

  Offset _offset = Offset.zero;

  @override
  void performLayout() {
    super.performLayout();
    _offset = Offset(
      (constraints.crossAxisExtent - geometry!.crossAxisExtent!) / 2,
      0.0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + _offset);
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return super.hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition - _offset.dx,
    );
  }

  @override
  void applyPaintTransform(RenderSliver child, Matrix4 transform) {
    if (_offset.dx != 0) {
      transform.translateByDouble(_offset.dx, 0.0, 0.0, 1.0);
    }
    super.applyPaintTransform(child, transform);
  }
}
