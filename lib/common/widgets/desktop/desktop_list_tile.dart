// =============================================================
// PiliPlus Windows 桌面化 · DesktopListTile
// Fluent 风格列表行：高 48，[20 图标] — 12 — [标题/副标题] … — 12 — [尾部控件]，
// 行末可选 1px 分隔线（左右缩进 16，与卡片内边距对齐）。
// 行骨架与 WinUiRow 保持一致，另补齐：selected 选中态、悬停提亮、
// 手型光标、Widget 化 title/subtitle、可定制行高与内边距。
// 字号（2026-10-05 桌面字号阶）：主标题 15 / 副标题 13；图标 20（与侧栏同值）。
// 纯桌面组件：不做 PlatformUtils 平台判断，也不自动降级。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/desktop_tokens.dart';
import 'package:material_ui/material_ui.dart';

class DesktopListTile extends StatefulWidget {
  const DesktopListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.showDivider = false,
    this.height,
    this.padding,
    this.mouseCursor,
  });

  /// 行首控件（图标会被统一为 [DesktopTokens.iconSize] / 次级文字色）
  final Widget? leading;

  /// 标题：可为纯文本或自定义 Widget
  final Widget? title;

  /// 副标题（bodySmall + 次级文字色）
  final Widget? subtitle;

  /// 行尾控件
  final Widget? trailing;

  /// 选中态：secondaryContainer 底色 + onSecondaryContainer 文字（与侧栏选中态同一观感）
  final bool selected;

  final VoidCallback? onTap;

  /// 行末 1px 分隔线（默认关闭，成组使用时由 DesktopSection 统一插入）
  final bool showDivider;

  /// 行高；为空取 [DesktopTokens.rowHeight]（48）
  final double? height;

  /// 行内边距；为空取左右 [DesktopTokens.pad]（16）
  final EdgeInsetsGeometry? padding;

  /// 鼠标指针；为空时 onTap 非空即 click
  final MouseCursor? mouseCursor;

  @override
  State<DesktopListTile> createState() => _DesktopListTileState();
}

class _DesktopListTileState extends State<DesktopListTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = widget.selected;
    final radius = BorderRadius.circular(DesktopTokens.radius);
    final titleColor = DesktopTokens.titleColor(
      colorScheme,
      selected: selected,
    );
    final subtitleColor = DesktopTokens.subtitleColor(
      colorScheme,
      selected: selected,
    );

    final background = selected
        ? DesktopTokens.selectedSurface(colorScheme)
        : _hover && widget.onTap != null
        ? DesktopTokens.hoverSurface(colorScheme)
        : Colors.transparent;

    final leading = widget.leading;
    final trailing = widget.trailing;

    final row = Padding(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: DesktopTokens.pad),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(
                size: DesktopTokens.iconSize,
                color: subtitleColor,
              ),
              child: leading,
            ),
            const SizedBox(width: DesktopTokens.gap12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: DesktopTokens.fontRowTitle,
                      color: titleColor,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: widget.title!,
                  ),
                if (widget.subtitle != null)
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: DesktopTokens.fontSecondary,
                      color: subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: widget.subtitle!,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesktopTokens.gap12),
            trailing,
          ],
        ],
      ),
    );

    Widget tile = AnimatedContainer(
      duration: DesktopTokens.hoverDuration,
      curve: DesktopTokens.curve,
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          splashFactory: NoSplash.splashFactory,
          hoverColor: Colors.transparent,
          child: SizedBox(
            height: widget.height ?? DesktopTokens.rowHeight,
            child: row,
          ),
        ),
      ),
    );

    final cursor =
        widget.mouseCursor ??
        (widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer);
    tile = MouseRegion(
      cursor: cursor,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: tile,
    );

    if (!widget.showDivider) return tile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Divider(
          height: 1,
          thickness: 1,
          indent: DesktopTokens.pad,
          endIndent: DesktopTokens.pad,
          color: DesktopTokens.divider(colorScheme),
        ),
      ],
    );
  }
}
