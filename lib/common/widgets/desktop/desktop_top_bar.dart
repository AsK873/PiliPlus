// =============================================================
// PiliPlus Windows PC 化 · M2 主壳（UI 呈现层，2026-09-05）
// 桌面顶栏（高 48，desktop && 宽窗口启用）：
//   左：返回/前进（复用 Get.back / canPop，与 Esc 全局返回一致）
//   中：当前主入口标题（由 NavigationBarType 提供，仅展示）
//   右：全局搜索入口（跳 /search，跳转后自动聚焦输入框，见 /search 页逻辑）
// 纯 UI；不触碰窗口管理/业务逻辑。
// =============================================================
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.mainController,
    required this.colorScheme,
  });

  final MainController mainController;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              tooltip: '后退 (Esc)',
              visualDensity: VisualDensity.compact,
              onPressed: Get.key.currentState != null &&
                      Get.key.currentState!.canPop()
                  ? Get.back
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
            IconButton(
              tooltip: '刷新当前页',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final nav = mainController.navigationBars[
                    mainController.selectedIndex.value];
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
            const SizedBox(width: 8),
            SizedBox(
              width: 240,
              height: 34,
              child: Material(
                borderRadius: BorderRadius.circular(17),
                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => Get.toNamed('/search'),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search_outlined,
                        size: 18,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '搜索视频 / UP主 / 番剧',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
