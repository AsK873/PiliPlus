// =============================================================
// PiliPlus Windows 桌面化 · 主壳顶栏（纯 UI）
// 桌面顶栏（高 48，桌面 + 宽窗口启用；**只在首页显示**）：
//   只保留：右：全局搜索框（全应用唯一搜索入口，复用 DesktopSearchBox）
//       - 贴在顶栏右侧：与 Windows 应用（设置 / 商店 / 资源管理器）的
//         搜索位置一致；右侧没有侧栏，因此「贴右」无需任何跨容器补偿，
//         两个页面公式统一。
//       - 260×36、胶囊圆角 18、5% 填充、放大镜 20 在左、12+20+8 间距、
//         输入文字 14（整数 px；原 260×34 / 18 / 12.5）
//       - 点击即进入输入状态（不跳页、不新增第二个搜索框）
//       - 输入为空时下方浮层展示搜索历史；输入关键词时切换为联想推荐
//       - 回车直接执行搜索
//   非首页（动态 / 我的 / 桌面内容页）由壳层整体移除顶栏与其分隔线，
//   内容直接顶到原顶栏位置（见 pages/main/view.dart）。
//   另：Ctrl+K（desktop_shortcuts.dart）就地唤起同一个搜索框。
// 搜索框的实现（防抖/联想请求）在 desktop_search_box.dart；
// 浮层渲染在壳层（main/view.dart），与搜索框同一右边缘。
// 不含窗口管理/业务逻辑。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/desktop_search_box.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_search_panel.dart';
import 'package:material_ui/material_ui.dart';

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.searchPanelOpen,
    this.onOpenSearch,
    this.onCloseSearch,
    this.onOverlayChanged,
  });

  /// 顶栏高度
  static const double height = 48;

  /// 顶栏左右内边距（搜索框右边缘与该值对齐，浮层沿用同一值）
  static const double paddingH = 12;

  /// 搜索框尺寸（高 36 / 放大镜 20 / 文字 14，见 desktop_search_box.dart）
  static const double searchWidth = 260;
  static const double searchHeight = 36;
  static const double searchRadius = 18;

  /// 搜索框在顶栏内的上边距（顶栏垂直居中）
  static const double searchTop = (height - searchHeight) / 2;

  /// 搜索浮层是否展开（用于同步输入状态）
  final bool searchPanelOpen;

  /// 点击搜索框：进入搜索状态（不跳页，输入后展开联想浮层）
  final VoidCallback? onOpenSearch;

  /// 搜索已执行 / 浮层收起：退出输入状态
  final VoidCallback? onCloseSearch;

  /// 浮层状态回调：输入词 + 联想结果（输入为空时 query 为空串 → 展示历史）
  final ValueChanged<DesktopSearchOverlayState>? onOverlayChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingH),
        child: Row(
          // 顶栏只剩这一个搜索框：靠右对齐，右边缘仍距 paddingH，
          // 垂直仍由 Row 居中（= searchTop），观感与改动前一致。
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 唯一搜索框：贴在顶栏右侧；点击进入输入状态、回车直接搜索，
            // 浮层由壳层在搜索框正下方按同一右边缘展开。
            DesktopSearchBox(
              active: searchPanelOpen,
              width: searchWidth,
              height: searchHeight,
              hintText: '搜索视频 / UP主 / 番剧',
              onActivated: onOpenSearch,
              onSubmit: (value) {
                onCloseSearch?.call();
                desktopSearch(value);
              },
              onOverlayChanged: onOverlayChanged,
            ),
          ],
        ),
      ),
    );
  }
}
