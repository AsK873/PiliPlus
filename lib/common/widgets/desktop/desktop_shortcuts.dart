// =============================================================
// PiliPlus Windows PC 化 · M2 壳层桌面快捷键（UI 输入层，2026-09-05）
// Ctrl+1/2/3 → 首页/动态/我的（顺序随 navBarSort；不足则忽略）
// Ctrl+K → 全局搜索（跳既有 /search，页面内输入框自动聚焦）
// 仅包裹壳子树；文本输入内未消费的组合键会冒泡到此处（普通字符输入不受影响）。
// =============================================================
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({
    super.key,
    required this.mainController,
    required this.child,
  });

  final MainController mainController;
  final Widget child;

  void _selectIndex(int index) {
    final nav = mainController.navigationBars;
    if (index < nav.length) {
      mainController.setIndex(index);
    }
  }

  void _openSearch() {
    Get.toNamed('/search');
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
            () => _selectIndex(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true):
            () => _selectIndex(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true):
            () => _selectIndex(2),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openSearch,
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: child,
      ),
    );
  }
}
