// =============================================================
// PiliPlus Windows 桌面化 · DesktopSection
// 分组区块：标题行（可选副标题 + 行尾控件）+ 卡片内的一组行。
// 布局等价于既有页面里手写的
//   Column[ 标题, gap8, FluentCard(Column(children)) ]
// 另补齐：subtitle、children 自动分隔线、可选不套卡片、sliver 形态。
// 纯桌面组件：不做 PlatformUtils 平台判断，也不自动降级。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/desktop_card.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_tokens.dart';
import 'package:material_ui/material_ui.dart';

class DesktopSection extends StatelessWidget {
  const DesktopSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.children = const <Widget>[],
    this.card = true,
    this.padding,
    this.spacing = DesktopTokens.gap4,
    this.showDividers = true,
    this.onTitleTap,
  });

  /// 分组标题（桌面字号阶「分组/卡片标题」：[DesktopTokens.fontSectionTitle]
  /// = 16 + w600，与既有 WinUiSectionHeader 一致）
  final String? title;

  /// 分组副标题（[DesktopTokens.fontSecondary] = 13 + 次级文字色）
  final String? subtitle;

  /// 标题行尾部控件（刷新按钮等）
  final Widget? trailing;

  /// 分组内容（通常是一组 DesktopListTile）
  final List<Widget> children;

  /// 是否用 [DesktopCard] 包住 [children]（默认包，等价既有页面写法）
  final bool card;

  /// 卡片内边距；为空时各行自带内边距
  final EdgeInsetsGeometry? padding;

  /// children 之间的间距（默认 4，4px 栅格）
  final double spacing;

  /// 是否自动在 children 之间插入 1px 分隔线（最后一条不插）
  final bool showDividers;

  /// 点击标题行
  final VoidCallback? onTitleTap;

  /// sliver 形态：便于在 CustomScrollView 页面里直接放入 slivers
  static Widget sliver({Key? key, required DesktopSection section}) =>
      SliverToBoxAdapter(child: section);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final header = _header(theme, colorScheme);

    if (children.isEmpty) {
      return header ?? const SizedBox.shrink();
    }

    final List<Widget> rows;
    if (showDividers && children.length > 1) {
      rows = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        rows.add(children[i]);
        if (i != children.length - 1) {
          rows.add(
            Divider(
              height: 1,
              thickness: 1,
              indent: DesktopTokens.pad,
              endIndent: DesktopTokens.pad,
              color: DesktopTokens.divider(colorScheme),
            ),
          );
        }
      }
    } else {
      rows = children;
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );

    final body = card
        ? DesktopCard(
            padding: padding,
            child: content,
          )
        : content;

    if (header == null) return body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: DesktopTokens.gap8),
        body,
      ],
    );
  }

  Widget? _header(ThemeData theme, ColorScheme colorScheme) {
    final title = this.title;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    if (title == null && subtitle == null && trailing == null) return null;

    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: DesktopTokens.fontSectionTitle,
              fontWeight: FontWeight.w600,
              color: DesktopTokens.titleColor(colorScheme),
            ),
          ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: DesktopTokens.fontSecondary,
              color: DesktopTokens.subtitleColor(colorScheme),
            ),
          ),
      ],
    );

    final row = Row(
      children: [
        Expanded(child: texts),
        ?trailing,
      ],
    );

    final onTitleTap = this.onTitleTap;
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: onTitleTap == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: row,
            ),
    );
  }
}
