// =============================================================
// PiliPlus Windows PC 化 · WinUI(Fluent) 风格排版组件（仅桌面端）
// 统一：4px 栅格间距 / 8px 圆角 / 1px 描边卡片 / 48px 列表行。
// 度量与 desktop_side_bar 保持一致（icon 20、间距 12、内边距 16）。
// 字号映射（Fluent → 本项目 textTheme）：
//   Caption 12   → bodySmall
//   Body 14      → bodyMedium
//   Body Strong  → bodyMedium + w600
//   Subtitle     → titleMedium + w600
// =============================================================
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

  /// 卡片与控件圆角
  static const double radius = 8;

  /// 列表行高
  static const double rowHeight = 48;

  /// 行内图标尺寸
  static const double iconSize = 20;

  /// 内容限宽（沿用「我的」页既有的 1080 决定）
  static const double contentWidth = 1080;
}

/// Fluent 卡片：surfaceContainer 底色 + 1px outlineVariant 描边 + 圆角 8，
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

/// 分组标题（Fluent Body Strong：14 / w600），尾部可放操作控件。
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
    size: 18,
    color: ColorScheme.of(context).onSurfaceVariant.withValues(alpha: .85),
  );
}

/// 分组内列表行：高 48，[20 图标] — 12 — [标题/副标题] … [尾部控件]，
/// 行末 1px 分隔线（左右缩进 [WinUi.pad]，与卡片内边距对齐）。
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
            borderRadius: BorderRadius.circular(WinUi.radius),
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
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
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
