import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/desktop/hover_card.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_constrained_cross_axis.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RcmdPage extends StatefulWidget {
  const RcmdPage({super.key});

  @override
  State<RcmdPage> createState() => _RcmdPageState();
}

class _RcmdPageState extends State<RcmdPage>
    with AutomaticKeepAliveClientMixin {
  final controller = Get.put(RcmdController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);
    return Container(
      clipBehavior: .hardEdge,
      margin: const .symmetric(horizontal: Style.safeSpace),
      decoration: const BoxDecoration(borderRadius: Style.mdRadius),
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: Style.cardSpace,
                // M3: 桌面不再为悬浮底栏预留 100 底部留白。
                bottom: PlatformUtils.isDesktop ? 24 : 100,
              ),
              sliver: _contentWidth(
                Obx(
                  () => _buildBody(colorScheme, controller.loadingState.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Pref.recommendCardWidth,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<dynamic>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => _buildSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  if (controller.lastRefreshAt != null) {
                    if (controller.lastRefreshAt == index) {
                      return GestureDetector(
                        onTap: () => controller
                          ..animateToTop()
                          ..onRefresh(),
                        child: Card(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const .symmetric(horizontal: 10),
                            child: Text(
                              '上次看到这里\n点击刷新',
                              textAlign: .center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final actualIndex = index > controller.lastRefreshAt!
                        ? index - 1
                        : index;
                    return _card(
                      VideoCardV(
                        videoItem: response[actualIndex],
                        onRemove: () {
                          if (controller.lastRefreshAt != null &&
                              actualIndex < controller.lastRefreshAt!) {
                            controller.lastRefreshAt =
                                controller.lastRefreshAt! - 1;
                          }
                          controller.loadingState
                            ..value.data!.removeAt(actualIndex)
                            ..refresh();
                        },
                      ),
                    );
                  } else {
                    return _card(
                      VideoCardV(
                        videoItem: response[index],
                        onRemove: () => controller.loadingState
                          ..value.data!.removeAt(index)
                          ..refresh(),
                      ),
                    );
                  }
                },
                itemCount: controller.lastRefreshAt != null
                    ? response.length + 1
                    : response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget get _buildSkeleton => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: VideoCardVSkeleton(),
    ),
  );

  // ---- M3 桌面呈现辅助（纯 UI）----

  /// 桌面端内容限宽居中：可用宽度超过 [maxExtent] 时网格不再横向铺满，
  /// 而是以 maxExtent 宽居中排布（避免 4K 下出现 10+ 列超窄卡）。
  Widget _contentWidth(Widget sliver) => PlatformUtils.isDesktop
      ? CenteredSliverConstrainedCrossAxis(maxExtent: 1560, sliver: sliver)
      : sliver;

  /// 桌面端卡片 hover 视觉反馈。
  Widget _card(Widget card) =>
      PlatformUtils.isDesktop ? HoverCard(child: card) : card;
}
