// =============================================================
// PiliPlus Windows PC 化 · M2 主壳导航（UI 呈现层，2026-09-05）
// 桌面专用扩展侧栏（图标+文字）：
//   - 主入口：首页 / 动态 / 我的（顺序、显隐仍尊重用户 navBarSort）
//   - 快捷区：历史/稍后再看/收藏/订阅/消息（搜索改由顶栏搜索框就地展开）
//   - 2026-10-03：快捷区下方（设置上方）新增「深色模式 / 浅色模式」快捷切换，
//     图标与悬停提示随当前模式变化；点击写入同一 Pref.themeType，与设置页「主题模式」同源。
//   - 底部：账号入口（未登录=登录）
// 行为全部复用现有 MainController.setIndex / Get.toNamed / 未读角标逻辑，
// 不含任何业务/数据改动；移动/平板分支不受影响（仅 PlatformUtils.isDesktop 且宽度≥900 时启用）。
// 2026-10-01 收紧尺寸与间距（参照紧凑型侧栏）：宽度 216→180，行距/内边距/图标同步收小，
// 全部度量集中在 [_Dimens]，仅影响本侧栏，不触碰其它 UI。
// =============================================================
import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 侧栏度量（4px 栅格）。收窄后仍保留「图标 + 文字」结构，只缩小尺寸与间距。
abstract final class _Dimens {
  /// 侧栏宽度（原 216）
  static const double width = 180;

  /// 侧栏左右内边距基准
  static const double pad = 8;

  /// 品牌区
  static const double logo = 20;
  static const EdgeInsets brandPad = EdgeInsets.fromLTRB(12, 10, 8, 8);
  static const double brandGap = 8;
  static const double brandFont = 14;

  /// 主入口 / 快捷入口列表
  static const double navPadV = 6;
  static const double shortcutHeaderGap = 6;
  static const EdgeInsets tileMargin = EdgeInsets.symmetric(
    horizontal: pad,
    vertical: 1,
  );
  static const EdgeInsets tilePad = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 5,
  );
  static const double tileRadius = 6;
  static const double icon = 18;
  static const double iconGap = 10;
  static const double labelFont = 12.5;
  static const double headerFont = 10.5;

  /// 底部账号区
  static const EdgeInsets accountPad = EdgeInsets.fromLTRB(10, 8, 10, 10);
  static const double avatar = 30;
  static const double accountGap = 8;
  static const double accountFont = 12.5;
  static const double accountSubFont = 10.5;
  static const double accountIcon = 18;
}

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

  static const double width = _Dimens.width;

  @override
  Widget build(BuildContext context) {
    // 依赖 Theme：主题模式切换后本侧栏随之重建（图标/提示同步更新）
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 品牌区
          _brand(),
          const Divider(height: 1),
          // 主入口
          Expanded(child: _primaryNav(isDark)),
          const Divider(height: 1),
          // 底部账号区
          _accountArea(context),
        ],
      ),
    );
  }

  Widget _brand() {
    return Padding(
      padding: _Dimens.brandPad,
      child: Row(
        children: [
          Image.asset(
            Assets.logo,
            width: _Dimens.logo,
            height: _Dimens.logo,
            errorBuilder: (context, error, stack) => Icon(
              Icons.play_circle_fill,
              size: _Dimens.logo,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: _Dimens.brandGap),
          Text(
            'PiliPlus',
            style: TextStyle(
              fontSize: _Dimens.brandFont,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryNav(bool isDark) {
    return Obx(() {
      final selected = mainController.selectedIndex.value;
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: _Dimens.navPadV),
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
          const SizedBox(height: _Dimens.shortcutHeaderGap),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '快捷入口',
              style: TextStyle(
                fontSize: _Dimens.headerFont,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final entry in _shortcuts) _shortcutItem(entry),
          // 分隔线：把「深色模式切换 + 设置」与上面的快捷入口区分开
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: _Dimens.shortcutHeaderGap,
            ),
            child: Divider(height: 1),
          ),
          // 深色模式快捷切换（图标 / 文字 / 悬停提示均指向「将要切换到的模式」）
          _themeToggleItem(isDark),
          _shortcutItem(_setting),
        ],
      );
    });
  }

  static final List<DesktopNavEntry> _shortcuts = [
    const DesktopNavEntry('历史记录', '/history', icon: Icons.history_outlined),
    const DesktopNavEntry('稍后再看', '/later', icon: Icons.schedule_outlined),
    const DesktopNavEntry('我的收藏', '/fav', icon: Icons.star_border_outlined),
    const DesktopNavEntry('订阅', '/subscription', icon: Icons.subscriptions_outlined),
    const DesktopNavEntry('私信', '/whisper', icon: Icons.chat_bubble_outline),
  ];

  /// 设置（固定排在深色模式切换之后）
  static const DesktopNavEntry _setting = DesktopNavEntry(
    '设置',
    '/setting',
    icon: Icons.settings_outlined,
  );

  /// 深色模式快捷切换：浅色模式显示月亮（→深色），深色模式显示太阳（→浅色）
  Widget _themeToggleItem(bool isDark) {
    return _tile(
      selected: false,
      onTap: () => _toggleThemeMode(isDark),
      leading: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      label: isDark ? '浅色模式' : '深色模式',
      tooltip: isDark ? '切换至浅色模式' : '切换至深色模式',
    );
  }

  /// 写入与设置页「主题模式」相同的 Pref，立即生效（无需重启）
  void _toggleThemeMode(bool isDark) {
    final next = isDark ? ThemeType.light : ThemeType.dark;
    try {
      Get.find<MineController>().themeType.value = next;
    } catch (_) {}
    GStorage.setting.put(SettingBoxKey.themeMode, next.index);
    Get.changeThemeMode(ThemeUtils.themeMode = next.toThemeMode);
  }

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
    String? tooltip,
  }) {
    final Widget tile = Padding(
      padding: _Dimens.tileMargin,
      child: Material(
        color: selected
            ? colorScheme.secondaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(_Dimens.tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Dimens.tileRadius),
          onTap: onTap,
          child: Padding(
            padding: _Dimens.tilePad,
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: _Dimens.icon,
                  ),
                  child: leading,
                ),
                const SizedBox(width: _Dimens.iconGap),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _Dimens.labelFont,
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
    // 仅深色模式切换带悬停提示，其余条目保持原样
    if (tooltip == null) return tile;
    return Tooltip(message: tooltip, child: tile);
  }

  Widget _accountArea(BuildContext context) {
    return Obx(() {
      final accountService = mainController.accountService;
      final isLogin = accountService.isLogin.value;
      final unread = mainController.msgUnReadCount.value;
      return Padding(
        padding: _Dimens.accountPad,
        child: Row(
          children: [
            if (isLogin)
              ClipOval(
                child: NetworkImgLayer(
                  type: ImageType.avatar,
                  width: _Dimens.avatar,
                  height: _Dimens.avatar,
                  src: accountService.face.value,
                ),
              )
            else
              CircleAvatar(
                radius: _Dimens.avatar / 2,
                backgroundColor: colorScheme.onInverseSurface,
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(width: _Dimens.accountGap),
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
                        fontSize: _Dimens.accountFont,
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
                          fontSize: _Dimens.accountSubFont,
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
                  child: const Icon(
                    Icons.notifications_none,
                    size: _Dimens.accountIcon,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
