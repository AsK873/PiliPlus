import 'package:material_ui/material_ui.dart';

/// WinUI 3 风格的弹层入场过渡：150ms 淡入 + 8px 上移（fastOutSlowIn）。
///
/// 轻量、无状态、可嵌套；桌面端由宿主决定是否启用（移动端传 enabled: false
/// 即完全等价于原样返回，不改变任何布局与交互）。
class WinUiEntrance extends StatelessWidget {
  const WinUiEntrance({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 150),
    this.offsetY = 8,
  });

  final Widget child;
  final bool enabled;
  final Duration duration;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.fastOutSlowIn,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offsetY),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
