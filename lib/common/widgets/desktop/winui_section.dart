// =============================================================
// PiliPlus Windows PC 化 · WinUI(Fluent) 风格排版组件（仅桌面端）
// 统一：4px 栅格间距 / 大卡片圆角 10（[WinUi.radius]）/ 1px 描边卡片 /
// 48px 列表行；小控件圆角 8（[WinUiRow] 行的 InkWell、搜索历史条目）。
// 度量与 desktop_side_bar 对齐的部分：icon 20、内边距 16；
// 行内图标与文字的间距见 [WinUiRow]（12），侧栏自身用 10（见 _Dimens.iconGap）。
// 字号：2026-10-05 桌面化第二轮改为「桌面字号阶」整数 px
// （见 [WinUi.fontPageTitle] 等），不再直接取 textTheme 默认档：
//   分组/卡片标题 16（原 bodyMedium 14）→ [WinUi.fontSectionTitle]
//   行主标题     15（原 bodyMedium 14）→ [WinUi.fontRowTitle]
//   次要信息     13（原 bodySmall  12）→ [WinUi.fontSecondary]
// =============================================================
import 'package:PiliPlus/common/style.dart' show Style;
import 'package:material_ui/material_ui.dart';

/// WinUI（Fluent）度量：所有数值均落在 4px 栅格上。
abstract final class WinUi {
  static const double gap4 = 4;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap24 = 24;

  /// 卡片内边距 / 列表行左右内边距
  static const double pad = 16;

  /// 页面外边距
  static const double padPage = 24;

  /// 大卡片 / 分组区块 / 主容器圆角（10；桌面 1.00 基准第三批统一取值）。
  /// 小控件圆角 8 的两处实现：[WinUiRow] 行的 InkWell 只做按压反馈、圆角
  /// 视觉上不可见，保持 8；搜索历史条目
  /// （`DesktopSearchPanel`，`DesktopTokens.radius - 2`）随本值收敛为 8。
  static const double radius = 10;

  /// 列表行高
  static const double rowHeight = 48;

  /// 行内图标尺寸（与侧栏 [_Dimens.icon] 同值 20，全桌面统一）
  static const double iconSize = 20;

  /// 内容限宽（**唯一来源** = [Style.contentMaxWidth] = 1480；桌面各页与
  /// `desktopLimitSliver` / `desktopLimitBox` 默认值都取同一个数）
  static const double contentWidth = Style.contentMaxWidth;

  // ===== 桌面字号阶（整数 px，1.00 基准，2026-10-05 桌面化第二轮）=====
  // 层级：页面标题 18 > 分组/Tab 标题 16 > 行主标题 15 > 输入/正文 14 > 次要 13。
  // 全部为整数 px（替换掉原先散落的 12.5 / 13.5 小数档）；侧栏字号已验收，
  // 不在本阶内（侧栏自己的 [_Dimens.labelFont] 等保持 14/12）。

  /// 桌面页面标题（AppBar 标题，见 utils/theme_utils.dart 的桌面分支）
  static const double fontPageTitle = 18;

  /// 分组 / 卡片 / Tab 标题（SectionHeader、DesktopSection.title、
  /// 快捷入口选项卡、搜索浮层「搜索历史」）
  static const double fontSectionTitle = 16;

  /// 列表行主标题 / 行内正文（WinUiRow、DesktopListTile、用户卡数值行）
  static const double fontRowTitle = 15;

  /// 输入框文字（桌面搜索框）
  static const double fontInput = 14;

  /// 次要信息（副标题、统计标签、卡片内标签文字）
  static const double fontSecondary = 13;
}

/// Fluent 卡片：surfaceContainer 底色 + 1px outlineVariant 描边 + 圆角 10，
/// 不使用 Material 阴影（WinUI 用描边而非高度投影表达层级）。
class FluentCard extends StatelessWidget {
  const FluentCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final radius = BorderRadius.circular(WinUi.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// 分组标题（桌面字号阶「分组/卡片标题」：16 / w600），尾部可放操作控件。
class WinUiSectionHeader extends StatelessWidget {
  const WinUiSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        right: 2,
        bottom: WinUi.gap8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: WinUi.fontSectionTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Fluent 行尾箭头。
class WinUiChevron extends StatelessWidget {
  const WinUiChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right,
    size: WinUi.iconSize,
    color: ColorScheme.of(context).onSurfaceVariant.withValues(alpha: .85),
  );
}

/// 分组内列表行：高 48，[20 图标] — 12 — [标题/副标题] … [尾部控件]，
/// 行末 1px 分隔线（左右缩进 [WinUi.pad]，与卡片内边距对齐）。
/// 行的 InkWell 用 8（小控件档；仅按压反馈，圆角不参与视觉）。
class WinUiRow extends StatelessWidget {
  const WinUiRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(WinUi.radius - 2),
            onTap: onTap,
            child: SizedBox(
              height: WinUi.rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: WinUi.pad),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(
                          size: WinUi.iconSize,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        child: leading!,
                      ),
                      const SizedBox(width: WinUi.gap12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: WinUi.fontRowTitle,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: WinUi.fontSecondary,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: WinUi.gap12),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: WinUi.pad,
            endIndent: WinUi.pad,
            color: colorScheme.outlineVariant.withValues(alpha: .45),
          ),
      ],
    );
  }
}
