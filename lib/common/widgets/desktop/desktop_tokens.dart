// =============================================================
// PiliPlus Windows 桌面化 · 桌面组件 token（仅服务 desktop_* 新组件）
// 数值与既有实现保持一致，只做「单一来源」集中：
//   WinUi（winui_section.dart）  → 间距/内边距/圆角/行高/图标尺寸
//   HoverCard（hover_card.dart） → 悬停提亮/细边透明度、动效时长与曲线
//   FluentCard（winui_section.dart）→ 卡片描边透明度
// 说明：本文件不修改、不替换上述既有实现，仅被
//   DesktopCard / DesktopListTile / DesktopSection 引用。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/winui_section.dart'
    show WinUi;
import 'package:material_ui/material_ui.dart';

abstract final class DesktopTokens {
  // ===== 栅格间距（4px 栅格，沿用 WinUi） =====
  static const double gap4 = WinUi.gap4;
  static const double gap8 = WinUi.gap8;
  static const double gap12 = WinUi.gap12;
  static const double gap16 = WinUi.gap16;
  static const double gap24 = WinUi.gap24;

  /// 卡片内边距 / 列表行左右内边距
  static const double pad = WinUi.pad;

  /// 页面外边距（供调用方排版使用）
  static const double padPage = WinUi.padPage;

  /// 大卡片 / 分组区块 / 主容器圆角（10）；小控件档 8 见
  /// `DesktopSearchPanel` 的搜索历史条目（本值 − 2）
  static const double radius = WinUi.radius;

  /// 列表行高（48）
  static const double rowHeight = WinUi.rowHeight;

  /// 行内图标尺寸（20）
  static const double iconSize = WinUi.iconSize;

  /// 内容限宽（**唯一来源** = [WinUi.contentWidth] = `Style.contentMaxWidth`
  /// = 1480；2026-10-05 由 1080 收敛而来）
  static const double contentWidth = WinUi.contentWidth;

  // ===== 桌面字号阶（整数 px；单一来源 = WinUi，见 winui_section.dart）=====

  /// 分组 / 卡片 / Tab 标题（16）
  static const double fontSectionTitle = WinUi.fontSectionTitle;

  /// 列表行主标题 / 行内正文（15）
  static const double fontRowTitle = WinUi.fontRowTitle;

  /// 次要信息（副标题、统计标签，13）
  static const double fontSecondary = WinUi.fontSecondary;

  /// 输入框文字（桌面搜索框，14）
  static const double fontInput = WinUi.fontInput;

  /// 桌面页面标题（AppBar，18）
  static const double fontPageTitle = WinUi.fontPageTitle;

  // ===== 描边 =====

  /// 卡片描边透明度（与 FluentCard 一致）
  static const double cardBorderAlpha = .55;

  /// 行末分隔线透明度（与 WinUiRow 一致）
  static const double dividerAlpha = .45;

  /// 悬停细边（不透明度 1，仅切换颜色）
  static const double hoverBorderAlpha = 1;

  // ===== 交互反馈 =====

  /// 悬停底色透明度（HoverCard：surfaceContainerHighest @ .5）
  static const double hoverAlpha = .5;

  /// 选中行底色透明度（desktop_side_bar 选中态同一观感：secondaryContainer @ .55）
  static const double selectedAlpha = .55;

  /// 悬停/选中态过渡时长与曲线（HoverCard：120ms fastOutSlowIn）
  static const Duration hoverDuration = Duration(milliseconds: 120);
  static const Curve curve = Curves.fastOutSlowIn;

  // ===== 语义色（只取 ColorScheme，天然兼容纯黑主题覆写） =====

  /// 卡片/面板底色
  static Color surface(ColorScheme cs) => cs.surfaceContainer;

  /// 悬停提亮底色
  static Color hoverSurface(ColorScheme cs) =>
      cs.surfaceContainerHighest.withValues(alpha: hoverAlpha);

  /// 选中行底色
  static Color selectedSurface(ColorScheme cs) =>
      cs.secondaryContainer.withValues(alpha: selectedAlpha);

  /// 卡片/控件描边
  static Color border(ColorScheme cs) =>
      cs.outlineVariant.withValues(alpha: cardBorderAlpha);

  /// 行末分隔线
  static Color divider(ColorScheme cs) =>
      cs.outlineVariant.withValues(alpha: dividerAlpha);

  /// 主文字
  static Color titleColor(ColorScheme cs, {bool selected = false}) =>
      selected ? cs.onSecondaryContainer : cs.onSurface;

  /// 次级文字（副标题、未选中图标）
  static Color subtitleColor(ColorScheme cs, {bool selected = false}) =>
      selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;

  // ===== BottomSheet（桌面弹层，见 theme_utils 的 bottomSheetTheme） =====

  /// 桌面 BottomSheet 最大宽度
  /// （与既有调用点 `min(640, shortestSide)` 同值，保证新旧调用点宽窄一致）
  static const double sheetMaxWidth = 640;

  /// 桌面 BottomSheet 最大高度（超过则浮层内部滚动）
  static const double sheetMaxHeight = 640;

  /// 桌面 BottomSheet 尺寸约束（由 theme_utils 统一注入主题，无需逐个调用点传参）
  static const BoxConstraints sheetConstraints = BoxConstraints(
    maxWidth: sheetMaxWidth,
    maxHeight: sheetMaxHeight,
  );

  /// 桌面 BottomSheet 内容推荐内边距
  /// （新写的 sheet 统一沿用；存量 sheet 的水平边距已由子组件自身达成，不强制回填）
  static const EdgeInsets sheetContentPadding = EdgeInsets.symmetric(
    horizontal: gap16,
    vertical: gap8,
  );
}
