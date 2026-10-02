import 'dart:async';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_card.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_list_tile.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_section.dart';
import 'package:PiliPlus/common/widgets/desktop/winui_section.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/player_bar.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/mine/widgets/item.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  /// M5：桌面端内容限宽（>1080 时两侧留白，避免拉伸为超宽单列）。
  double _sidePad(BuildContext context) {
    if (!PlatformUtils.isDesktop) return 0;
    final double w = MediaQuery.sizeOf(context).width;
    return w > 1080 ? (w - 1080) / 2 : 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    return Column(
      children: [
        Padding(
          padding: const .symmetric(vertical: 10),
          child: _buildHeaderActions,
        ),
        Expanded(
          child: Material(
            type: .transparency,
            child: refreshIndicator(
              onRefresh: controller.onRefresh,
              child: onBuild(
                PlatformUtils.isDesktop
                    ? _buildDesktopList(theme)
                    : _buildMobileList(theme, secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 移动端：保持原有排版不变。
  Widget _buildMobileList(ThemeData theme, Color secondary) {
    return ListView(
      padding: EdgeInsets.only(
        left: _sidePad(context),
        right: _sidePad(context),
        bottom: PlatformUtils.isDesktop ? 24 : 100,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildUserInfo(theme, secondary),
        _buildActions(secondary),
        Obx(
          () => controller.loadingState.value is Loading
              ? const SizedBox.shrink()
              : _buildFav(theme, secondary),
        ),
      ],
    );
  }

  Widget _buildActions(Color primary) {
    return Row(
      mainAxisAlignment: .spaceEvenly,
      children: controller.list
          .map(
            (e) => Flexible(
              child: InkWell(
                onTap: e.onTap,
                borderRadius: Style.mdRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      spacing: 6,
                      mainAxisSize: .min,
                      mainAxisAlignment: .center,
                      children: [
                        Icon(e.icon, color: primary),
                        Text(
                          e.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget get _buildHeaderActions {
    const iconSize = 22.0;
    const padding = EdgeInsets.all(8);
    const style = ButtonStyle(tapTargetSize: .shrinkWrap);
    return PlayerBar(
      children: [
        if (widget.showBackBtn)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: BackButton(),
          )
        else
          const SizedBox.shrink(),
        Row(
          spacing: 5,
          mainAxisSize: .min,
          children: [
            // 桌面端不再提供 /search 入口：壳层顶栏搜索框是唯一的搜索入口
            if (!_mainController.hasHome && !PlatformUtils.isDesktop) ...[
              IconButton(
                iconSize: iconSize,
                padding: padding,
                style: style,
                tooltip: '搜索',
                onPressed: () => Get.toNamed('/search'),
                icon: const Icon(Icons.search),
              ),
              msgBadge(_mainController),
            ],
            if (GStorage.reply != null)
              IconButton(
                iconSize: iconSize,
                padding: padding,
                style: style,
                tooltip: '评论记录',
                onPressed: () => Get.toNamed('/myReply'),
                icon: const Icon(Icons.message_outlined),
              ),
            Obx(
              () {
                final anonymity = MineController.anonymity.value;
                return IconButton(
                  iconSize: iconSize,
                  padding: padding,
                  style: style,
                  tooltip: "${anonymity ? '退出' : '进入'}无痕模式",
                  onPressed: MineController.onChangeAnonymity,
                  icon: anonymity
                      ? const Icon(MdiIcons.incognito)
                      : const Icon(MdiIcons.incognitoOff),
                );
              },
            ),
            IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '切换账号',
              onPressed: () => LoginPageController.switchAccountDialog(context),
              icon: const Icon(Icons.switch_account_outlined),
            ),
            Obx(
              () => IconButton(
                iconSize: iconSize,
                padding: padding,
                style: style,
                tooltip: '切换至${controller.nextThemeType.label}主题',
                onPressed: controller.onChangeTheme,
                icon: controller.themeType.value.icon,
              ),
            ),
            IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '设置',
              onPressed: () =>
                  Get.toNamed('/setting', preventDuplicates: false),
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color secondary) {
    final style = TextStyle(
      fontSize: theme.textTheme.titleMedium!.fontSize,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.bold,
      color: secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: .opaque,
            onTap: controller.onLogin,
            onLongPress: () {
              Feedback.forLongPress(context);
              controller.onLogin(true);
            },
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => controller.onLogin(true),
            child: Row(
              mainAxisSize: .min,
              children: [
                const SizedBox(width: 20),
                userInfo.face != null
                    ? Stack(
                        clipBehavior: .none,
                        children: [
                          NetworkImgLayer(
                            src: userInfo.face,
                            type: .avatar,
                            width: 55,
                            height: 55,
                          ),
                          if (isVip)
                            Positioned(
                              right: -1,
                              bottom: -2,
                              child: SvgPicture.asset(
                                Assets.vipIcon,
                                height: 19,
                                semanticsLabel: "大会员",
                              ),
                            ),
                        ],
                      )
                    : ClipOval(
                        child: Image.asset(
                          width: 55,
                          height: 55,
                          cacheHeight: 55.cacheSize(context),
                          Assets.avatarPlaceHolder,
                          semanticLabel: "默认头像",
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              userInfo.uname ?? '点击登录',
                              style: theme.textTheme.titleMedium!.copyWith(
                                height: 1,
                                color: isVip && userInfo.vipType == 2
                                    ? theme.colorScheme.vipColor
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                          BiliUtils.levelPicture(
                            levelInfo?.currentLevel ?? 0,
                            isSeniorMember: userInfo.isSeniorMember == 1,
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '硬币 ',
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: userInfo.money?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "      经验 ",
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: levelInfo?.currentExp?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "/${levelInfo?.nextExp ?? '-'}",
                              style: coinLabelStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 225),
                        child: LinearProgressIndicator(
                          minHeight: 2.25,
                          value: hasLevel
                              ? levelInfo.currentExp! / levelInfo.nextExp!
                              : 0,
                          backgroundColor: theme.colorScheme.outline.withValues(
                            alpha: 0.4,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(secondary),
                          stopIndicatorColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              _btn(
                count: userStat.dynamicCount,
                countStyle: style,
                name: '动态',
                labelStyle: labelStyle,
                onTap: () => controller.push('memberDynamics'),
              ),
              _btn(
                count: userStat.following,
                countStyle: style,
                name: '关注',
                labelStyle: labelStyle,
                onTap: () => controller.push('follow'),
              ),
              _btn(
                count: userStat.follower,
                countStyle: style,
                name: '粉丝',
                labelStyle: labelStyle,
                onTap: () => controller.push('fan'),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _btn({
    required int? count,
    required TextStyle countStyle,
    required String name,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: Style.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              spacing: 4,
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Text(
                  count?.toString() ?? '-',
                  style: countStyle,
                ),
                Text(
                  name,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _autoRefresh() => Timer(
    const Duration(milliseconds: 150),
    () => controller.onRefresh(isManual: false),
  );

  Widget _buildFav(ThemeData theme, Color secondary) {
    return Column(
      children: [
        Divider(
          height: 20,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        ListTile(
          onTap: () => Get.toNamed('/fav')?.whenComplete(_autoRefresh),
          dense: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '我的收藏  ',
                    style: TextStyle(
                      fontSize: theme.textTheme.titleMedium!.fontSize,
                      fontWeight: .bold,
                    ),
                  ),
                  if (controller.favFolderCount != null)
                    TextSpan(
                      text: "${controller.favFolderCount}  ",
                      style: TextStyle(
                        fontSize: theme.textTheme.titleSmall!.fontSize,
                        color: secondary,
                      ),
                    ),
                  WidgetSpan(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: IconButton(
            tooltip: '刷新',
            onPressed: controller.onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        _buildFavBody(theme, secondary, controller.loadingState.value),
      ],
    );
  }

  Widget _buildFavBody(
    ThemeData theme,
    Color secondary,
    LoadingState loadingState,
  ) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          List<FavFolderInfo>? favFolderList = response.list;
          if (favFolderList == null || favFolderList.isEmpty) {
            return const SizedBox.shrink();
          }
          bool flag = (controller.favFolderCount ?? 0) > favFolderList.length;
          return SizedBox(
            height: 200,
            child: ListView.separated(
              controller: controller.scrollController,
              padding: const .only(left: 20, top: 10, right: 20),
              itemCount: response.list.length + (flag ? 1 : 0),
              itemBuilder: (context, index) {
                if (flag && index == favFolderList.length) {
                  return Padding(
                    padding: const .only(bottom: 35),
                    child: Center(
                      child: IconButton(
                        tooltip: '查看更多',
                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(.zero),
                          backgroundColor: WidgetStatePropertyAll(
                            theme.colorScheme.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        onPressed: () =>
                            Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: secondary,
                        ),
                      ),
                    ),
                  );
                } else {
                  return FavFolderItem(
                    heroTag: Utils.generateRandomString(8),
                    item: response.list[index],
                    onPop: _autoRefresh,
                  );
                }
              },
              scrollDirection: .horizontal,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
            ),
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 160,
        child: Center(
          child: Text(
            errMsg ?? '',
            textAlign: .center,
          ),
        ),
      ),
    };
  }

  // ===========================================================
  // 桌面端：WinUI(Fluent) 风格排版
  // 结构：用户卡片 → 「快捷入口」分组 → 「我的收藏」分组
  // 度量：4px 栅格 / 页面边距 24 / 卡片内边距 16 / 行高 48 / 圆角 8
  // 说明：仅桌面端生效，移动端走 _buildMobileList（原实现）。
  // ===========================================================
  Widget _buildDesktopList(ThemeData theme) {
    final double sidePad = _sidePad(context);
    return ListView(
      padding: EdgeInsets.only(
        left: sidePad + WinUi.padPage,
        right: sidePad + WinUi.padPage,
        top: WinUi.padPage,
        bottom: WinUi.padPage,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _winuiUserCard(theme),
        const SizedBox(height: WinUi.gap24),
        DesktopSection(
          title: '快捷入口',
          children: List.generate(controller.list.length, (index) {
            final item = controller.list[index];
            return DesktopListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              trailing: const WinUiChevron(),
              onTap: item.onTap,
            );
          }),
        ),
        const SizedBox(height: WinUi.gap24),
        Obx(() {
          if (controller.loadingState.value is Loading) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: controller.favFolderCount == null
                    ? '我的收藏'
                    : '我的收藏  ·  ${controller.favFolderCount}',
                card: false,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '刷新',
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                    ),
                    IconButton(
                      tooltip: '查看全部',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          Get.toNamed('/fav')?.whenComplete(_autoRefresh),
                      icon: const Icon(Icons.arrow_forward_ios, size: 15),
                    ),
                  ],
                ),
                children: [_winuiFavBody(theme)],
              ),
            ],
          );
        }),
      ],
    );
  }

  /// 用户卡片：头像 + 昵称/等级 + 硬币·经验 + 经验条，右侧三列统计。
  Widget _winuiUserCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall!.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return DesktopCard(
        padding: const EdgeInsets.all(WinUi.pad),
        child: Row(
            children: [
              _winuiUserArea(
                child: userInfo.face != null
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          NetworkImgLayer(
                            src: userInfo.face,
                            type: .avatar,
                            width: 64,
                            height: 64,
                          ),
                          if (isVip)
                            Positioned(
                              right: -1,
                              bottom: -2,
                              child: SvgPicture.asset(
                                Assets.vipIcon,
                                height: 20,
                                semanticsLabel: '大会员',
                              ),
                            ),
                        ],
                      )
                    : ClipOval(
                        child: Image.asset(
                          width: 64,
                          height: 64,
                          cacheHeight: 64.cacheSize(context),
                          Assets.avatarPlaceHolder,
                          semanticLabel: '默认头像',
                        ),
                      ),
              ),
              const SizedBox(width: WinUi.gap16),
              Expanded(
                child: _winuiUserArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              userInfo.uname ?? '点击登录',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isVip && userInfo.vipType == 2
                                    ? theme.colorScheme.vipColor
                                    : null,
                              ),
                            ),
                          ),
                          BiliUtils.levelPicture(
                            levelInfo?.currentLevel ?? 0,
                            isSeniorMember: userInfo.isSeniorMember == 1,
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: WinUi.gap8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '硬币 ', style: labelStyle),
                            TextSpan(
                              text: userInfo.money?.toString() ?? '-',
                              style: valueStyle,
                            ),
                            TextSpan(text: '    经验 ', style: labelStyle),
                            TextSpan(
                              text: levelInfo?.currentExp?.toString() ?? '-',
                              style: valueStyle,
                            ),
                            TextSpan(
                              text: '/${levelInfo?.nextExp ?? '-'}',
                              style: labelStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WinUi.gap12),
                      SizedBox(
                        width: 240,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(2),
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: hasLevel
                                ? levelInfo.currentExp! / levelInfo.nextExp!
                                : 0,
                            backgroundColor: colorScheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.secondary,
                            ),
                            stopIndicatorColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: WinUi.gap24),
              Container(
                width: 1,
                height: 44,
                color: colorScheme.outlineVariant.withValues(alpha: .5),
              ),
              _winuiStat(
                theme,
                '动态',
                userStat.dynamicCount,
                () => controller.push('memberDynamics'),
              ),
              _winuiStat(
                theme,
                '关注',
                userStat.following,
                () => controller.push('follow'),
              ),
              _winuiStat(
                theme,
                '粉丝',
                userStat.follower,
                () => controller.push('fan'),
              ),
            ],
        ),
      );
    });
  }

  /// 用户卡片的可点击区域（行为与原实现一致：点击/长按/右键 → 登录页或空间页）。
  Widget _winuiUserArea({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.onLogin,
      onLongPress: () {
        Feedback.forLongPress(context);
        controller.onLogin(true);
      },
      onSecondaryTap: () => controller.onLogin(true),
      child: child,
    );
  }

  /// 统计列：等宽、垂直居中，与左右各列共用 1px 竖分隔线。
  Widget _winuiStat(
    ThemeData theme,
    String label,
    int? count,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 84,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(WinUi.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: WinUi.gap8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count?.toString() ?? '-',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WinUi.gap4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 收藏区：自适应网格（列宽随可用宽度计算，卡片为 Fluent 卡片）。
  Widget _winuiFavBody(ThemeData theme) {
    return switch (controller.loadingState.value) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => Builder(
        builder: (context) {
          final List<FavFolderInfo>? favFolderList = response.list;
          if (favFolderList == null || favFolderList.isEmpty) {
            return const SizedBox.shrink();
          }
          final bool flag =
              (controller.favFolderCount ?? 0) > favFolderList.length;
          return LayoutBuilder(
            builder: (context, constraints) {
              const double gap = WinUi.gap16;
              final int columns = (constraints.maxWidth / 240)
                  .floor()
                  .clamp(2, 4)
                  .toInt();
              final double itemWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in favFolderList)
                    SizedBox(
                      width: itemWidth,
                      child: FavFolderItem(
                        heroTag: Utils.generateRandomString(8),
                        item: item,
                        onPop: _autoRefresh,
                        width: itemWidth,
                      ),
                    ),
                  if (flag)
                    SizedBox(width: itemWidth, child: _winuiMoreTile(theme)),
                ],
              );
            },
          );
        },
      ),
      Error(:final errMsg) => SizedBox(
        height: 160,
        child: Center(
          child: Text(errMsg ?? '', textAlign: .center),
        ),
      ),
    };
  }

  /// 「查看更多」磁贴：与收藏卡片同宽同高比，仅作跳转入口。
  Widget _winuiMoreTile(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(WinUi.radius),
        onTap: () => Get.toNamed('/fav')?.whenComplete(_autoRefresh),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WinUi.radius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: WinUi.gap8),
                Text(
                  '查看更多',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
