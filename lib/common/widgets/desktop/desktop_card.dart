// =============================================================
// PiliPlus Windows 桌面化 · DesktopCard
// Fluent/WinUI 风格卡片：surfaceContainer 底色 + 1px outlineVariant 描边
// + 圆角 10，不用 Material 阴影表达层级（与 FluentCard 同一套视觉）。
// 在 FluentCard 的基础上补齐：padding / margin / radius / hover / onTap。
// 纯桌面组件：不做 PlatformUtils 平台判断，也不自动降级。
// =============================================================
import 'dart:async' show Timer;

import 'package:PiliPlus/common/widgets/desktop/desktop_tokens.dart';
import 'package:material_ui/material_ui.dart';

class DesktopCard extends StatefulWidget {
  const DesktopCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.hover = true,
    this.onTap,
    this.color,
    this.border = true,
    this.onHoverDelay,
    this.hoverDelay = const Duration(milliseconds: 400),
  });

  final Widget child;

  /// 卡片内边距；为空时不额外加内边距（与 FluentCard 一致）
  final EdgeInsetsGeometry? padding;

  /// 卡片外边距；为空时不加外边距
  final EdgeInsetsGeometry? margin;

  /// 圆角半径；为空时取 [DesktopTokens.radius]（10，大卡片档）
  final double? radius;

  /// 鼠标悬停时提亮 + 细边（默认开）
  final bool hover;

  /// 点击回调；非空时可点击（手型光标 + InkWell 按压反馈）
  final VoidCallback? onTap;

  /// 卡片底色；为空时取 `colorScheme.surfaceContainer`
  final Color? color;

  /// 是否绘制 1px 描边
  final bool border;

  /// 悬停停留 [hoverDelay] 后触发一次（用于预取等低优先级动作）
  final VoidCallback? onHoverDelay;
  final Duration hoverDelay;

  @override
  State<DesktopCard> createState() => _DesktopCardState();
}

class _DesktopCardState extends State<DesktopCard> {
  bool _hover = false;
  Timer? _timer;

  void _onEnter() {
    setState(() => _hover = true);
    final onHoverDelay = widget.onHoverDelay;
    if (onHoverDelay != null) {
      _timer?.cancel();
      _timer = Timer(widget.hoverDelay, onHoverDelay);
    }
  }

  void _onExit() {
    _timer?.cancel();
    _timer = null;
    setState(() => _hover = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final radius = BorderRadius.circular(widget.radius ?? DesktopTokens.radius);
    final base = widget.color ?? DesktopTokens.surface(colorScheme);
    final highlighted = widget.hover && _hover;
    final onTap = widget.onTap;

    Widget card = AnimatedContainer(
      duration: DesktopTokens.hoverDuration,
      curve: DesktopTokens.curve,
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(DesktopTokens.hoverSurface(colorScheme), base)
            : base,
        borderRadius: radius,
        border: widget.border
            ? Border.all(
                color: highlighted
                    ? colorScheme.outlineVariant
                    : DesktopTokens.border(colorScheme),
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: widget.padding == null
            ? widget.child
            : Padding(padding: widget.padding!, child: widget.child),
      ),
    );

    if (onTap != null) {
      card = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          hoverColor: Colors.transparent,
          child: card,
        ),
      );
    }

    if (widget.hover || onTap != null) {
      card = MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: widget.hover ? (_) => _onEnter() : null,
        onExit: widget.hover ? (_) => _onExit() : null,
        child: card,
      );
    }

    final margin = widget.margin;
    return margin == null ? card : Padding(padding: margin, child: card);
  }
}
