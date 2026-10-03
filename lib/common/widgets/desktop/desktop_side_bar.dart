// =============================================================
// PiliPlus Windows PC 化 · M2 主壳导航（UI 呈现层，2026-09-05）
// 桌面专用扩展侧栏（图标+文字）：
//   - 主入口：首页 / 动态 / 我的（顺序、显隐仍尊重用户 navBarSort）
//   - 快捷区：历史/稍后再看/收藏/订阅/消息（搜索改由顶栏搜索框就地展开）
//   - 2026-10-03：快捷区下方（设置上方）新增「深色模式 / 浅色模式」快捷切换，
//     图标与悬停提示随当前模式变化；点击写入同一 Pref.themeType，与设置页「主题模式」同源。
//   - 2026-10-04：导航行的构建抽出为公开的 [DesktopNavTile]（本文件内 private 的 _tile
//     改为直接转发它），侧栏与「我的」页快捷入口共用同一实现 → 鼠标手势/悬停/按压/
//     圆角/cursor/Tooltip 天然一致；侧栏本体的外观与行为逐像素不变。
//   - 底部：账号入口（未登录=登录）
// 行为全部复用现有 MainController.setIndex / Get.toNamed / 未读角标逻辑，
// 不含任何业务/数据改动；移动/平板分支不受影响（桌面端只要 PlatformUtils.isDesktop
// 为真就启用本侧栏，没有宽度阈值——窄窗同样用图标+文字侧栏，不再回退移动布局）。
// 2026-10-01 曾把宽度收紧到 180（行距/内边距/图标同步收小）；该次收紧已于
// 2026-10-03 回退，现行宽度见 [_Dimens.width] = 216，全部度量集中在 [_Dimens]，
// 仅影响本侧栏，不触碰其它 UI。
// 2026-10-03 桌面 UI 正式迁移到 uiScale = 1.00（第一批，四项）：
//   1) 宽度 180→216（[_Dimens.width] 单点，[DesktopSideBar.width] 复用同一常量）；
//   2) 字号/图标回到 1.00 正式尺寸：图标 18→20、主文字 12.5→14、
//      分组头 10.5→12、账号区 12.5/10.5→14/12、账号图标 18→20；
//   3) 导航行节距 30→32 由「tileMargin 1 + tilePad.vertical 5 + icon 20 +
//      tilePad.vertical 5 + tileMargin 1」自然得出（tilePad 保持 5，不为凑高度加 padding）；
//   4) 侧栏导航列表改用覆盖式滚动条（[OverlayScrollbarBehavior]，不再预留 10px 车道）：
//      修复「药丸实际宽 = 侧栏宽 − 16 − 10」的错误缩进，药丸宽 = 侧栏宽 − 16
//      （216 − 16 = 200），左右内边距 8/8 对称。滚动条本体与滚动行为不变。
// 层级结构、hover/selected/点击逻辑、快捷入口结构、底部主题/设置功能均未改动。
// =============================================================
import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_behavior.dart'
    show OverlayScrollbarBehavior;
import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

/// 侧栏度量（uiScale = 1.00 下的正式尺寸）。
/// 注意：本组数值**不全是 4px 栅格成员**（含 6 / 5 / 10 / 1 等），
/// 历史上「4px 栅格」的表述与实际取值并不一致，以本类取值为准。
abstract final class _Dimens {
  /// 侧栏宽度（uiScale = 1.00：216；历史：216 → 180 → 216，现行值 216）
  static const double width = 216;

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
  /// 导航行（药丸）圆角（8）：与桌面小控件档（列表行 / 按钮 / 输入控件）一致，
  /// 第三批由 6 收敛而来；侧栏自身的间距/tilePad 不是 4px 栅格成员（见下方说明）。
  static const double tileRadius = 8;

  /// 行节距 = tileMargin.vertical 1 + tilePad.vertical 5 + icon 20 +
  /// tilePad.vertical 5 + tileMargin.vertical 1 = 32。
  /// 32 是 960x640（客户区 601）下的硬上限：tilePad 不能再加，
  /// 节距 ≥34 会把列表底部的「设置」挤出可视区。
  static const double icon = 20;
  static const double iconGap = 10;
  static const double labelFont = 14;
  static const double headerFont = 12;

  /// 底部账号区
  static const EdgeInsets accountPad = EdgeInsets.fromLTRB(10, 8, 10, 10);
  static const double avatar = 30;
  static const double accountGap = 8;
  static const double accountFont = 14;
  static const double accountSubFont = 12;
  static const double accountIcon = 20;
}

/// 桌面导航实体（与主壳数据同源，仅 UI 组装）。
class DesktopNavEntry {
  const DesktopNavEntry(this.label, this.route, {this.icon, this.selectedIcon});
  final String label;
  final String route;
  final IconData? icon;
  final IconData? selectedIcon;
}

/// 桌面导航行（**单一实现**：侧栏主入口 / 快捷入口 / 深色模式切换 与
/// 「我的」页快捷入口全部走这里）。
///
/// 由侧栏原有的 private `_tile` 原样抽出，度量取自本文件的 [_Dimens]：
/// `Padding(8,1)` → `Material`（选中底色 secondaryContainer@0.55 / 否则透明）
/// → `InkWell`（圆角 8 = [_Dimens.tileRadius]，自带悬停提亮、按压 highlight 与默认水波纹）
/// → `Padding(8,5)` → `[图标 20] — 10 — [文字 14]`。
/// 未显式设置 cursor，沿用 InkWell/InkResponse 在 onTap 非空时的
/// 手型指针（SystemMouseCursors.click）——与侧栏改动前完全一致。
///
/// [trailing] 为行尾控件：侧栏不使用（传 null 时 Row 子项与抽取前逐像素相同，
/// 不产生任何额外间距）；「我的」页用它保留原有的行尾箭头。
class DesktopNavTile extends StatelessWidget {
  const DesktopNavTile({
    super.key,
    required this.colorScheme,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.label,
    this.trailing,
    this.tooltip,
  });

  final ColorScheme colorScheme;

  /// 选中态：secondaryContainer@0.55 底色 + onSecondaryContainer 文字，w600
  final bool selected;

  final VoidCallback onTap;

  /// 行首控件（统一为 20px / 选中 onSecondaryContainer、否则 onSurfaceVariant）
  final Widget leading;

  final String label;

  /// 行尾控件（可选；为空时不占位、不加间距）
  final Widget? trailing;

  /// 悬停提示（可选；为空时不包 Tooltip）
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
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
                if (trailing != null) ...[
                  const SizedBox(width: _Dimens.iconGap),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
    // 未传提示时不包 Tooltip（与抽取前一致：只有深色模式切换带提示）
    if (tooltip == null) return tile;
    return Tooltip(message: tooltip, child: tile);
  }
}

class DesktopSideBar extends StatelessWidget {
  const DesktopSideBar({
    super.key,
    required this.mainController,
    required this.colorScheme,
    required this.onSelect,
    this.onSelectShortcut,
  });

  final MainController mainController;
  final ColorScheme colorScheme;
  final ValueChanged<int> onSelect;

  /// 快捷入口回调：宿主在桌面主内容区就地显示后返回 true（不走路由）；
  /// 返回 false / 未提供时，回退为原有 `Get.toNamed(entry.route)` 行为。
  final bool Function(DesktopNavEntry entry)? onSelectShortcut;

  /// 「我的」页那组入口（无痕模式 / 切换账号 / 主题切换）与「我的」页共用同一个
  /// [MineController]（`Get.putOrFind` 单例）：侧栏直接读写它，不复制一份实现。
  /// GetX 的 `putOrFind` 由 [GetExt] 提供，本文件已 import `get_ext.dart`。
  /// 桌面端侧栏一定在「我的」页之前构建，首次访问即创建该控制器，
  /// 与「我的」页自己 `Get.putOrFind` 得到的是同一个实例。
  /// 写成 getter（不缓存到字段）：本控件是 const 构造的 StatelessWidget，
  /// 不能持有非 const 的 late 字段。
  MineController get _mineController => Get.putOrFind(MineController.new);

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
          // 覆盖式滚动条：全局 CustomScrollBehavior 会为滚动条预留右侧 10px
          // 「车道」，导航行（药丸）可用宽因此比分隔线窄 10px（左右内边距
          // 8/18 不对称）。这里只对侧栏导航列表改用 OverlayScrollbarBehavior：
          // 滚动条仍常显、仍画在右缘 8px 外边距内，只是不再让视口内缩
          // ⇒ 药丸宽 = 侧栏宽 − 16（216 − 16 = 200），左右对称。
          // 作用域 = 本 Expanded（侧栏里唯一的滚动视口），其它页面不受影响。
          Expanded(
            child: ScrollConfiguration(
              behavior: const OverlayScrollbarBehavior(),
              child: _primaryNav(context, isDark),
            ),
          ),
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

  Widget _primaryNav(BuildContext context, bool isDark) {
    return Obx(() {
      final selected = mainController.selectedIndex.value;
      // 桌面内容页（如历史记录）展开时，选中态归内容页入口，主 Tab 不显示选中
      final hasContentPage = mainController.desktopContentRoute.value != null;
      // 覆盖式滚动条：见 build() 里 ScrollConfiguration(OverlayScrollbarBehavior)
      // 的说明 —— 本列表不得让全局 10px 滚动条车道缩窄行宽。
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: _Dimens.navPadV),
        children: [
          for (var i = 0; i < mainController.navigationBars.length; i++)
            _navItem(
              icon: mainController.navigationBars[i].icon,
              selectedIcon: mainController.navigationBars[i].selectIcon,
              label: mainController.navigationBars[i].label,
              selected: !hasContentPage && i == selected,
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
          for (final entry in shortcuts) _shortcutItem(entry),
          // 分隔线：把「快捷入口」整组与下面的「我的」页设置/功能入口区分开
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: _Dimens.shortcutHeaderGap,
            ),
            child: Divider(height: 1),
          ),
          // 「我的」页顶部那排设置/功能入口（整组，仅位置搬移、功能与交互不变）
          for (final entry in mineEntries) _entryItem(entry),
          Obx(
            () => _tile(
              selected: false,
              onTap: MineController.onChangeAnonymity,
              leading: Icon(
                MineController.anonymity.value
                    ? MdiIcons.incognito
                    : MdiIcons.incognitoOff,
              ),
              label: '${MineController.anonymity.value ? '退出' : '进入'}无痕模式',
            ),
          ),
          _tile(
            selected: false,
            onTap: () => LoginPageController.switchAccountDialog(context),
            leading: const Icon(Icons.switch_account_outlined),
            label: '切换账号',
          ),
          // 桌面端主题切换：循环**不含「跟随系统」**（该选项只在设置页「主题模式」
          // 里保留，见 setting/models/style_settings.dart）；浅色 ⇄ 深色。
          // 当前为 system 时按实际生效的明暗（isDark）解析目标与图标，
          // 保证入口不会把用户带回 system。移动端沿用 MineController.onChangeTheme。
          Obx(() {
            final next = _mineController.nextThemeTypeDesktop(isDark: isDark);
            return _tile(
              selected: false,
              onTap: () =>
                  _mineController.onChangeThemeDesktop(isDark: isDark),
              leading: _mineController.themeIconDesktop(isDark: isDark),
              label: '${next.label}主题',
              tooltip: '切换至${next.label}主题',
            );
          }),
          // 分隔线：把「我的」页入口整组与下面的「深色模式切换 + 设置」区分开
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

  /// 「我的」页顶部那排设置/功能入口中**静态**的一项（另三项「无痕模式」
  /// 「切换账号」「主题切换」随状态 / 需要 BuildContext，在 [_primaryNav] 里
  /// 就地构建）。
  ///
  /// 仅位置搬移：label / 图标 / 点击逻辑（`Get.toNamed`）与搬到侧栏之前逐字一致。
  /// 「设置」不在其中：侧栏原本就有 [_setting]（排在深色模式切换之后），
  /// 不再重复一份。
  static final List<DesktopNavEntry> mineEntries = [
    const DesktopNavEntry(
      '评论记录',
      '/myReply',
      icon: Icons.message_outlined,
    ),
  ];

  /// 快捷入口（单一数据源：侧栏与「我的」页共用同一份 label / route / icon）
  static final List<DesktopNavEntry> shortcuts = [
    const DesktopNavEntry('历史记录', '/history', icon: Icons.history_outlined),
    const DesktopNavEntry('稍后再看', '/later', icon: Icons.schedule_outlined),
    const DesktopNavEntry('我的收藏', '/fav', icon: Icons.star_border_outlined),
    const DesktopNavEntry('订阅', '/subscription', icon: Icons.subscriptions_outlined),
    const DesktopNavEntry('私信', '/whisper', icon: Icons.chat_bubble_outline),
  ];

  /// 快捷入口共用的点击逻辑（侧栏与「我的」页同一套）：
  /// 先交给宿主在桌面主内容区就地显示（返回 true 表示已处理，不走路由）；
  /// 未处理 / 未接入时回退为原有 `Get.toNamed(entry.route)`，行为不变。
  static bool openShortcut(
    DesktopNavEntry entry,
    bool Function(DesktopNavEntry entry)? onSelectShortcut,
  ) {
    if (onSelectShortcut?.call(entry) ?? false) {
      return true;
    }
    Get.toNamed(entry.route);
    return false;
  }

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
      // 该入口正在主内容区就地显示时，侧栏定位到它（与主 Tab 选中态互斥）
      selected: mainController.desktopContentRoute.value == entry.route,
      onTap: () {
        // 与「我的」页快捷入口共用同一套点击逻辑
        openShortcut(entry, onSelectShortcut);
      },
      leading: Icon(entry.icon ?? Icons.chevron_right),
      label: entry.label,
    );
  }

  /// 「我的」页设置/功能入口的静态行（见 [mineEntries]）：点击逻辑就是
  /// 搬到侧栏之前「我的」页上的那一句 `Get.toNamed(entry.route)`，
  /// 不走快捷入口的 `openShortcut`（那些 route 本就不在桌面内容页 switch 里）。
  Widget _entryItem(DesktopNavEntry entry) {
    return _tile(
      selected: false,
      onTap: () => Get.toNamed(entry.route),
      leading: Icon(entry.icon ?? Icons.chevron_right),
      label: entry.label,
    );
  }

  /// 行构建统一走 [DesktopNavTile]（抽取前这里是该控件的实现本体，
  /// 抽取后仅为转发，4 个调用点与外观/行为均不变）。
  Widget _tile({
    required bool selected,
    required VoidCallback onTap,
    required Widget leading,
    required String label,
    String? tooltip,
  }) {
    return DesktopNavTile(
      colorScheme: colorScheme,
      selected: selected,
      onTap: onTap,
      leading: leading,
      label: label,
      tooltip: tooltip,
    );
  }

  /// 底部账号区「我的主页」入口（本侧栏仅桌面端构建，移动端没有该入口）：
  /// 与侧栏主导航里的「我的」走**完全同一条**既有路径 —— [onSelect]
  /// （壳层 `closeDesktopContentPage()` + `MainController.setIndex(...)`），
  /// 不再走 `MainController.toMinePage`（它在本页不是主 Tab 时 `Get.to(MinePage)`），
  /// 因此**不 push 任何路由**，也不写 `desktopShortcutPreview` /
  /// `desktopShortcutLastRoute` —— 「我的」页记住的上一次预览选项原样保留。
  ///
  /// 索引按用户自定义后的实际导航栏顺序取（`navigationBars.indexOf`），
  /// 不硬编码数字（用户可能改过排序，也可能把「我的」隐藏掉）。
  /// 兜底：找不到「我的」时导航栏里没有可切换的目标，桌面端也不为此新开页面
  /// （保持「不 push 路由」），就地提示一句，不改动任何导航状态。
  void _toMineTab(BuildContext context) {
    final index = mainController.navigationBars.indexOf(NavigationBarType.mine);
    if (index >= 0) {
      onSelect(index);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导航栏中未显示「我的」，可在「设置 · Navbar编辑」中恢复')),
    );
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
                  // 未登录占位头像的人像与账号区图标同尺寸（原为写死的 18）
                  size: _Dimens.accountIcon,
                  color: colorScheme.primary,
                ),
              ),
            const SizedBox(width: _Dimens.accountGap),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(_Dimens.tileRadius),
                onTap: () => _toMineTab(context),
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
