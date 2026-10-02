// =============================================================
// PiliPlus Windows 桌面化 · 主壳顶栏（纯 UI）
// 桌面顶栏（高 48，桌面 + 宽窗口启用）：
//   左：后退（复用 Get.back / canPop，与 Esc 返回一致）；刷新当前主入口
//   左：当前主入口标题（由导航配置提供，仅展示）
//   右：全局搜索框（全应用唯一搜索入口，复用 DesktopSearchBox）
//       - 贴在顶栏右侧：与左侧的操作/标题形成「左操作 · 右搜索」结构，
//         与 Windows 应用（设置 / 商店 / 资源管理器）的搜索位置一致；
//         右侧没有侧栏，因此「贴右」无需任何跨容器补偿，两个页面公式统一。
//       - 260×34、胶囊圆角 17、5% 填充、放大镜在左、12+18+8 间距
//       - 点击即进入输入状态（不跳页、不新增第二个搜索框）
//       - 输入为空时下方浮层展示搜索历史；输入关键词时切换为联想推荐
//       - 回车直接执行搜索
//   另：Ctrl+K（desktop_shortcuts.dart）就地唤起同一个搜索框。
// 搜索框的实现（防抖/联想请求）在 desktop_search_box.dart；
// 浮层渲染在壳层（main/view.dart），与搜索框同一右边缘。
// 不含窗口管理/业务逻辑。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/desktop_search_box.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_search_panel.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.mainController,
    required this.colorScheme,
    required this.searchPanelOpen,
    this.onOpenSearch,
    this.onCloseSearch,
    this.onOverlayChanged,
  });

  /// 顶栏高度
  static const double height = 48;

  /// 顶栏左右内边距（搜索框右边缘与该值对齐，浮层沿用同一值）
  static const double paddingH = 12;

  /// 搜索框尺寸
  static const double searchWidth = 260;
  static const double searchHeight = 34;
  static const double searchRadius = 17;

  /// 搜索框在顶栏内的上边距（顶栏垂直居中）
  static const double searchTop = (height - searchHeight) / 2;

  /// 标题与搜索框之间的间距
  static const double gapBeforeSearch = 8;

  final MainController mainController;
  final ColorScheme colorScheme;

  /// 搜索浮层是否展开（用于同步输入状态）
  final bool searchPanelOpen;

  /// 点击搜索框：进入搜索状态（不跳页，输入后展开联想浮层）
  final VoidCallback? onOpenSearch;

  /// 搜索已执行 / 浮层收起：退出输入状态
  final VoidCallback? onCloseSearch;

  /// 浮层状态回调：输入词 + 联想结果（输入为空时 query 为空串 → 展示历史）
  final ValueChanged<DesktopSearchOverlayState>? onOverlayChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingH),
        child: Row(
          children: [
            IconButton(
              // WinUI 3 风格：悬停=表面微提亮、按下=略深，无涟漪
              style: IconButton.styleFrom(
                hoverColor: colorScheme.primary.withValues(alpha: 0.08),
                highlightColor: colorScheme.primary.withValues(alpha: 0.14),
                splashFactory: NoSplash.splashFactory,
              ),
              tooltip: '后退 (Esc)',
              visualDensity: VisualDensity.compact,
              onPressed:
                  Get.key.currentState != null && Get.key.currentState!.canPop()
                  ? Get.back
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
            IconButton(
              // 与后退按钮同一套 WinUI 悬停/按下反馈
              style: IconButton.styleFrom(
                hoverColor: colorScheme.primary.withValues(alpha: 0.08),
                highlightColor: colorScheme.primary.withValues(alpha: 0.14),
                splashFactory: NoSplash.splashFactory,
              ),
              tooltip: '刷新当前页',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final nav = mainController
                    .navigationBars[mainController.selectedIndex.value];
                if (nav == NavigationBarType.home) {
                  mainController.refreshRecommendations();
                } else if (nav == NavigationBarType.dynamics) {
                  mainController.dynamicController.onRefresh();
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 19),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Obx(
                () => Text(
                  mainController.navigationBars.isEmpty
                      ? ''
                      : mainController
                            .navigationBars[mainController.selectedIndex.value]
                            .label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: gapBeforeSearch),
            // 唯一搜索框：贴在顶栏右侧；点击进入输入状态、回车直接搜索，
            // 浮层由壳层在搜索框正下方按同一右边缘展开。
            DesktopSearchBox(
              active: searchPanelOpen,
              width: searchWidth,
              height: searchHeight,
              hintText: '搜索视频 / UP主 / 番剧',
              onActivated: onOpenSearch,
              onSubmit: (value) {
                onCloseSearch?.call();
                desktopSearch(value);
              },
              onOverlayChanged: onOverlayChanged,
            ),
          ],
        ),
      ),
    );
  }
}
