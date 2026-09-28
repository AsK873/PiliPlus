// =============================================================
// PiliPlus Windows PC 化 · M2 主壳导航（UI 呈现层，2026-09-05）
// 桌面专用扩展侧栏（图标+文字，宽 216px）：
//   - 主入口：首页 / 动态 / 我的（顺序、显隐仍尊重用户 navBarSort）
//   - 快捷区：搜索/历史/稍后再看/收藏/订阅/消息/设置（全部跳既有路由）
//   - 底部：账号入口（未登录=登录）
// 行为全部复用现有 MainController.setIndex / Get.toNamed / 未读角标逻辑，
// 不含任何业务/数据改动；移动/平板分支不受影响（仅 PlatformUtils.isDesktop 且宽度≥900 时启用）。
// =============================================================
import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面导航实体（与主壳数据同源，仅 UI 组装）。
class DesktopNavEntry {
  const DesktopNavEntry(this.label, this.route, {this.icon, this.selectedIcon});
  final String label;
  final String route;
  final IconData? icon;
  final IconData? selectedIcon;
}

class DesktopSideBar extends StatelessWidget {
  const DesktopSideBar({
    super.key,
    required this.mainController,
    required this.colorScheme,
    required this.onSelect,
  });

  final MainController mainController;
  final ColorScheme colorScheme;
  final ValueChanged<int> onSelect;

  static const double width = 216;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 品牌区
          _brand(),
          const Divider(height: 1),
          // 主入口
          Expanded(child: _primaryNav()),
          const Divider(height: 1),
          // 底部账号区
          _accountArea(context),
        ],
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Image.asset(
            Assets.logo,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stack) => Icon(
              Icons.play_circle_fill,
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'PiliPlus',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryNav() {
    return Obx(() {
      final selected = mainController.selectedIndex.value;
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (var i = 0; i < mainController.navigationBars.length; i++)
            _navItem(
              icon: mainController.navigationBars[i].icon,
              selectedIcon: mainController.navigationBars[i].selectIcon,
              label: mainController.navigationBars[i].label,
              selected: i == selected,
              showDynamicBadge: mainController.navigationBars[i] ==
                  NavigationBarType.dynamics,
              onTap: () => onSelect(i),
            ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '快捷入口',
              style: TextStyle(fontSize: 11, letterSpacing: 0.5),
            ),
          ),
          for (final entry in _shortcuts) _shortcutItem(entry),
        ],
      );
    });
  }

  static final List<DesktopNavEntry> _shortcuts = [
    const DesktopNavEntry('搜索', '/search', icon: Icons.search_outlined),
    const DesktopNavEntry('历史记录', '/history', icon: Icons.history_outlined),
    const DesktopNavEntry('稍后再看', '/later', icon: Icons.schedule_outlined),
    const DesktopNavEntry('我的收藏', '/fav', icon: Icons.star_border_outlined),
    const DesktopNavEntry('订阅', '/subscription', icon: Icons.subscriptions_outlined),
    const DesktopNavEntry('私信', '/whisper', icon: Icons.chat_bubble_outline),
    const DesktopNavEntry('设置', '/setting', icon: Icons.settings_outlined),
  ];

  Widget _navItem({
    required Icon icon,
    required Icon selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showDynamicBadge = false,
  }) {
    return _tile(
      selected: selected,
      onTap: onTap,
      leading: showDynamicBadge
          ? Obx(() {
              final count = mainController.dynCount.value;
              final show = count > 0 &&
                  mainController.dynamicBadgeMode != DynamicBadgeMode.hidden;
              return Badge(
                isLabelVisible: show,
                label: Text(count > 99 ? '99+' : '$count'),
                child: selected ? selectedIcon : icon,
              );
            })
          : (selected ? selectedIcon : icon),
      label: label,
    );
  }

  Widget _shortcutItem(DesktopNavEntry entry) {
    return _tile(
      selected: false,
      onTap: () => Get.toNamed(entry.route),
      leading: Icon(entry.icon ?? Icons.chevron_right),
      label: entry.label,
    );
  }

  Widget _tile({
    required bool selected,
    required VoidCallback onTap,
    required Widget leading,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selected
            ? colorScheme.secondaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountArea(BuildContext context) {
    return Obx(() {
      final accountService = mainController.accountService;
      final isLogin = accountService.isLogin.value;
      final unread = mainController.msgUnReadCount.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          children: [
            if (isLogin)
              ClipOval(
                child: NetworkImgLayer(
                  type: ImageType.avatar,
                  width: 36,
                  height: 36,
                  src: accountService.face.value,
                ),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.onInverseSurface,
                child: Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: mainController.toMinePage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLogin ? '我的主页' : '点击登录',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isLogin)
                      Text(
                        '查看资料与空间',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isLogin)
              IconButton(
                tooltip: '消息',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  mainController
                    ..clearUnreadMsg()
                    ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
                  Get.toNamed('/whisper');
                },
                icon: Badge(
                  isLabelVisible:
                      mainController.msgBadgeMode != DynamicBadgeMode.hidden &&
                          unread != null,
                  child: const Icon(Icons.notifications_none, size: 20),
                ),
              ),
          ],
        ),
      );
    });
  }
}
