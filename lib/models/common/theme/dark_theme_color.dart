import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面端深色模式的背景配色方案（仅深色模式 + 桌面端生效）。
///
/// 只描述两块「大面积背景」：
///   - [sidebar]：左侧导航侧栏（侧栏 Tab）
///   - [content]：主功能区（顶栏 / 内容区 / 各类内容页）
/// 卡片、弹窗、搜索框、文字与图标仍走 ColorScheme，不在此列。
enum DarkThemeColor implements EnumWithLabel {
  /// 深灰色：侧栏比主功能区略深一档
  gray('深灰色', Color(0xFF1E2022), Color(0xFF17181A)),

  /// 黑色：侧栏与主功能区统一为近黑
  black('黑色', Color(0xFF0E1114), Color(0xFF0E1114)),
  ;

  const DarkThemeColor(this.label, this.sidebar, this.content);

  @override
  final String label;

  /// 侧栏 Tab 背景色
  final Color sidebar;

  /// 主功能区背景色
  final Color content;
}
