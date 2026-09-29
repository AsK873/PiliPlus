// =============================================================
// PiliPlus Windows PC 化 · M2 壳层桌面快捷键（UI 输入层，2026-09-05）
// Ctrl+1/2/3 → 首页/动态/我的（顺序随 navBarSort；不足则忽略）
// Ctrl+K → 全局搜索（默认就地展开搜索面板；未提供回调时回退到 /search）
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
    this.onSearch,
  });

  final MainController mainController;
  final Widget child;

  /// Ctrl+K：就地展开搜索面板（为空时回退为进入 /search 页）。
  final VoidCallback? onSearch;

  void _selectIndex(int index) {
    final nav = mainController.navigationBars;
    if (index < nav.length) {
      mainController.setIndex(index);
    }
  }

  void _openSearch() {
    final onSearch = this.onSearch;
    if (onSearch != null) {
      onSearch();
    } else {
      Get.toNamed('/search');
    }
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
