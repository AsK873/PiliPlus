import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_content.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/whisper/controller.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/extension/three_dot_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class WhisperPage extends StatefulWidget {
  const WhisperPage({
    super.key,
    this.desktopEmbedded = false,
    this.onBack,
    this.hideAppBar = false,
  });

  /// 桌面端：由主壳「主内容区」就地承载（与侧栏并排），而非独立路由页。
  /// 仅用于桌面嵌入时的排布微调，移动端 / 路由方式保持默认 false。
  final bool desktopEmbedded;

  /// 桌面嵌入时的「离开本页」回调（由主壳收起内容页 → 恢复进入前的主 Tab）。
  /// 为空时退回原有路由返回行为（移动端）。
  final VoidCallback? onBack;

  /// 桌面端「我的」页快捷入口**内嵌**时置 true：省略 AppBar（页面标题 /
  /// 返回按钮 / 顶栏操作），只渲染主体内容。默认 false，移动端、路由方式
  /// 与主壳内容区嵌入（[desktopEmbedded]）均不受影响。
  final bool hideAppBar;

  @override
  State<WhisperPage> createState() => _WhisperPageState();
}

class _WhisperPageState extends State<WhisperPage> {
  final _controller = Get.put(WhisperController());

  /// 返回按钮（桌面嵌入）：本页没有需要拦截的内部二级状态
  /// （无页面内搜索 / 无多选 / 无内层 Tab；会话详情与「回复我的」等
  /// 都是正常路由跳转，不由本页返回键接管），
  /// 离开时由主壳收起内容页，主 Tab 索引沿用 MainController.selectedIndex
  /// （进入时未改动）；路由方式退回原有 Get.back()。
  void _handleBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else {
      Get.back();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.desktopEmbedded) {
      // 接入主壳既有的鼠标返回侧键机制（main.dart 的 BackDetector → _onBack），
      // 复用同一个返回，不新增全局监听
      Get.find<MainController>().desktopContentBackHandler = _handleBack;
    }
  }

  @override
  void dispose() {
    if (widget.desktopEmbedded && Get.isRegistered<MainController>()) {
      final mainController = Get.find<MainController>();
      // 仅在本实例仍是注册者时清空，避免覆盖后进入实例的注册
      if (mainController.desktopContentBackHandler == _handleBack) {
        mainController.desktopContentBackHandler = null;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      // 「我的」页内嵌（hideAppBar）→ 整块顶栏（标题 / 返回按钮 / 新增粉丝 /
      // 更多）都不嵌入，只渲染主体内容；
      // 桌面嵌入：标题左侧为返回按钮；标题在原有间距上再左移 10px（36 → 26）
      appBar: widget.hideAppBar ? null : AppBar(
        leading: widget.desktopEmbedded
            ? BackButton(onPressed: _handleBack)
            : null,
        titleSpacing: widget.desktopEmbedded ? 26 : null,
        title: const Text('消息'),
        actions: [
          IconButton(
            tooltip: '新增粉丝',
            onPressed: () => Get.toNamed(
              '/webview',
              parameters: {
                'url':
                    'https://www.bilibili.com/h5/follow/newFans?navhide=1&${ThemeUtils.themeUrl(theme.isDark)}',
              },
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          Obx(() {
            final outsideItem = _controller.outsideItem.value;
            if (outsideItem != null && outsideItem.isNotEmpty) {
              return Row(
                mainAxisSize: .min,
                children: outsideItem.map((e) {
                  return IconButton(
                    tooltip: e.hasTitle() ? e.title : null,
                    onPressed: () => e.type.action(
                      context: context,
                      controller: _controller,
                      item: e,
                    ),
                    icon: e.type.icon,
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final threeDotItems = _controller.threeDotItems.value;
            if (threeDotItems != null && threeDotItems.isNotEmpty) {
              return PopupMenuButton(
                itemBuilder: (context) {
                  return threeDotItems
                      .map(
                        (e) => PopupMenuItem(
                          onTap: () => e.type.action(
                            context: context,
                            controller: _controller,
                            item: e,
                          ),
                          child: Row(
                            children: [
                              e.type.icon,
                              Text('  ${e.title}'),
                            ],
                          ),
                        ),
                      )
                      .toList();
                },
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 5),
        ],
      ),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 桌面端内容限宽（默认 1480 = Style.contentMaxWidth = 6 列 × 240 的
            // 同一唯一来源）：本页此前是唯一没有限宽的桌面主内容页（会话列表
            // 在超宽屏下会横向铺满），补齐后与历史/稍后/收藏/订阅一致。
            desktopLimitSliver(_buildTopItems(theme, padding)),
            SliverPadding(
              // 桌面端底部留白与其它桌面内容页一致（24），移动端保持原样。
              padding: EdgeInsets.only(
                bottom: PlatformUtils.isDesktop ? 24 : padding.bottom + 100,
              ),
              sliver: desktopLimitSliver(
                Obx(() => _buildBody(_controller.loadingState.value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<Session>?> loadingState) {
    switch (loadingState) {
      case Loading():
        return const SliverPrototypeExtentList(
          prototypeItem: WhisperItemSkeleton(),
          delegate: SliverSingleChildDelegate(
            count: 12,
            child: WhisperItemSkeleton(),
          ),
        );
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          final divider = Divider(
            indent: 72,
            endIndent: 20,
            height: 0,
            color: Colors.grey.withValues(alpha: 0.1),
          );
          return SliverList.separated(
            itemCount: response.length,
            itemBuilder: (context, index) {
              if (index == response.length - 1) {
                _controller.onLoadMore();
              }
              final item = response[index];
              return WhisperSessionItem(
                item: item,
                onSetTop: (isTop, id) =>
                    _controller.onSetTop(item, index, isTop, id),
                onSetMute: (isMuted, talkerUid) =>
                    _controller.onSetMute(item, isMuted, talkerUid),
                onRemove: (talkerId) => _controller.onRemove(index, talkerId),
              );
            },
            separatorBuilder: (context, index) => divider,
          );
        }
        return HttpError(onReload: _controller.onReload);
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _controller.onReload,
        );
    }
  }

  Widget _buildTopItems(ThemeData theme, EdgeInsets padding) {
    return SliverPadding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_controller.msgFeedTopItems.length, (index) {
            final item = _controller.msgFeedTopItems[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () {
                        final count = _controller.unreadCounts[index];
                        return Badge(
                          isLabelVisible: count > 0,
                          label: Text(" $count "),
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: theme.colorScheme.onInverseSurface,
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (!item.enabled) {
                  SmartDialog.showToast('已禁用');
                  return;
                }
                _controller.unreadCounts[index] = 0;
                Get.toNamed(item.route);
              },
            );
          }),
        ),
      ),
    );
  }
}
