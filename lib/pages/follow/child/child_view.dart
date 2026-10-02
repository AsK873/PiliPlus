import 'dart:math';

import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_content.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/follow/child/child_controller.dart';
import 'package:PiliPlus/pages/follow/controller.dart';
import 'package:PiliPlus/pages/follow/widgets/follow_item.dart';
import 'package:PiliPlus/pages/follow_type/follow_same/view.dart';
import 'package:PiliPlus/pages/share/view.dart' show UserModel;
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowChildPage extends StatefulWidget {
  const FollowChildPage({
    super.key,
    this.tag,
    this.controller,
    required this.mid,
    this.tagid,
    this.onSelect,
  });

  final String? tag;
  final FollowController? controller;
  final int mid;
  final int? tagid;
  final ValueChanged<UserModel>? onSelect;

  @override
  State<FollowChildPage> createState() => _FollowChildPageState();
}

class _FollowChildPageState extends State<FollowChildPage>
    with AutomaticKeepAliveClientMixin {
  late String _tag;
  late FollowChildController _followController;

  String get _newTag =>
      '${widget.tag ?? Utils.generateRandomString(8)}${widget.tagid}';

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _tag = _newTag;
    _followController = Get.put(
      FollowChildController(widget.controller, widget.mid, widget.tagid),
      tag: _tag,
    );
  }

  @override
  void didUpdateWidget(FollowChildPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tagid != widget.tagid) {
      final newTag = _newTag;
      if (Get.isRegistered<FollowChildController>(tag: newTag)) {
        _followController = Get.find<FollowChildController>(tag: newTag);
      } else {
        Get.delete<FollowChildController>(tag: _tag);
        _initController();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    // 用盒模型 LayoutBuilder 量出内容列宽（超宽屏时上层的限宽 sliver 会把它压到
    // maxWidth 以内），再把「是否两列」传进各 sliver——slivers 里不能放 LayoutBuilder。
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = _isTwoColumn(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.only(left: padding.left, right: padding.right),
          child: refreshIndicator(
            onRefresh: _followController.onRefresh,
            child: CustomScrollView(
              controller: _followController.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 桌面内容限宽居中：超宽屏下不再左右铺满
                desktopLimitSliver(
                  SliverMainAxisGroup(
                    slivers: [
                      if (_followController.loadSameFollow)
                        Obx(
                          () => _buildSameFollowing(
                            colorScheme,
                            _followController.sameState.value,
                            isTwoColumn,
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: PlatformUtils.isDesktop
                              ? 24
                              : padding.bottom + 100,
                        ),
                        sliver: Obx(
                          () => _buildBody(
                            _followController.loadingState.value,
                            isTwoColumn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== 桌面两列布局 =====
  // 桌面端关注列表改为两列等宽网格：行高与「我的粉丝」页一致（66），
  // 列间距 8、每列左右各 16 内边距，与「共同关注」标题的既有 16 缩进对齐。
  // 窄窗（<640）与移动端仍走原单列列表与原有 12/10 内边距，行为完全不变。

  /// 触发两列布局的最小可用宽度：低于此值两列过窄，回退单列
  static const double _twoColumnMinWidth = 640;

  /// 网格单行高度：45 头像 + 上下各 10 内边距（与单列视觉一致）
  static const double _rowExtent = 66;

  /// 两列网格中每列的左右内边距：桌面鼠标目标更宽松，也让相邻两列内容之间
  /// 留出 8(列间距) + 16 + 16 的呼吸空间。桌面单列的 16 缩进与之保持一致。
  static const double _inset = 16;

  /// 两列之间的列间距
  static const double _columnGap = 8;

  /// 两列之间的行间距
  static const double _rowGap = 4;

  /// 标题行左右外边距（与列表内容的 16 缩进对齐）
  static const double _headerInset = 16;

  bool _isTwoColumn(double width) =>
      PlatformUtils.isDesktop && width >= _twoColumnMinWidth;

  /// 两列等宽：列宽由可用宽度推出，行高固定，避免头像/文字被比例拉伸。
  /// 行内容高度 45 + 10*2 = 65，故 [_rowExtent] 取 66 留 1 像素余量。
  static const SliverGridDelegateWithFixedCrossAxisCount _twoColumnDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _columnGap,
        mainAxisSpacing: _rowGap,
        mainAxisExtent: _rowExtent,
      );

  /// 标题行左右外边距：与列表内容的 16 缩进对齐（移动/桌面一致）。
  static const EdgeInsets _headerPad = EdgeInsets.symmetric(
    horizontal: _headerInset,
  );

  /// 两列模式下，「共同关注」列表已由外层提供左右 16 外边距，
  /// 行内只保留上下 10；单列返回 null，沿用 [FollowItem] 原有的 12/10。
  EdgeInsets? _sameFollowItemPad(bool isTwoColumn) =>
      isTwoColumn ? const EdgeInsets.symmetric(vertical: 10) : null;

  /// 两列网格的行内边距：左右 16 让鼠标目标更宽松，上下沿用 [FollowItem]
  /// 原有的 10，故行内容高度仍为 45 + 10*2 = 65，与 [_rowExtent] 匹配。
  static const EdgeInsets _gridItemPad = EdgeInsets.symmetric(
    horizontal: _inset,
    vertical: 10,
  );

  Widget _buildBody(
    LoadingState<List<FollowItemModel>?> loadingState,
    bool isTwoColumn,
  ) {
    return switch (loadingState) {
      Loading() => const SliverPrototypeExtentList(
        prototypeItem: MsgFeedTopSkeleton(),
        delegate: SliverSingleChildDelegate(
          count: 12,
          child: MsgFeedTopSkeleton(),
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? (isTwoColumn
                  ? SliverGrid.builder(
                      gridDelegate: _twoColumnDelegate,
                      itemBuilder: (context, index) {
                        if (index == response.length - 1) {
                          _followController.onLoadMore();
                        }
                        return _buildItem(response[index], true);
                      },
                      itemCount: response.length,
                    )
                  : SliverList.builder(
                      itemCount: response.length,
                      itemBuilder: (context, index) {
                        if (index == response.length - 1) {
                          _followController.onLoadMore();
                        }
                        return _buildItem(response[index], false);
                      },
                    ))
            : HttpError(onReload: _followController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _followController.onReload,
      ),
    };
  }

  /// [grid] 为真时按两列网格的度量排布（左右 16 内边距、鼠标目标更宽松）。
  Widget _buildItem(FollowItemModel item, bool grid) => FollowItem(
    item: item,
    isOwner: widget.controller?.isOwner,
    onSelect: widget.onSelect,
    gridPadding: grid ? _gridItemPad : null,
    afterMod: (attr) {
      item.attribute = attr == 0 ? -1 : 0;
      _followController.loadingState.refresh();
    },
  );

  Widget _buildSameFollowing(
    ColorScheme colorScheme,
    LoadingState<List<FollowItemModel>?> state,
    bool isTwoColumn,
  ) {
    return switch (state) {
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: _headerPad.copyWith(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '我们的共同关注',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          moreTextButton(
                            onTap: () => FollowSamePage.toFollowSamePage(
                              mid: _followController.mid,
                              name: widget.controller?.name.value,
                            ),
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 桌面端「共同关注」列表与两列网格共用同一左缘：
                  // 两列时外层留 16、行内左右为 0；单列保持原有外层 0 + 行内 12
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTwoColumn ? _inset : 0,
                    ),
                    child: SliverList.builder(
                      itemCount: min(3, response.length),
                      itemBuilder: (_, index) => FollowItem(
                        item: response[index],
                        gridPadding: _sameFollowItemPad(isTwoColumn),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: _headerPad.copyWith(top: 16, bottom: 6),
                      child: Text(
                        '全部关注',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const SliverToBoxAdapter(),
      _ => const SliverToBoxAdapter(),
    };
  }

  @override
  bool get wantKeepAlive =>
      widget.onSelect != null || widget.controller?.tabController != null;
}
