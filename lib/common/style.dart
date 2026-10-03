import 'package:material_ui/material_ui.dart'
    show BorderRadius, Radius, BoxConstraints, ButtonStyle, VisualDensity;

abstract final class Style {
  static const cardSpace = 8.0;
  static const safeSpace = 12.0;

  /// 桌面端正文内容限宽（**全桌面唯一来源**：首页/推荐流网格、热门/排行榜、
  /// 动态、历史/稍后/收藏/订阅/私信、设置、搜索面板、以及
  /// `desktopLimitSliver` / `desktopLimitBox` 的默认值都取这里）。
  /// 超宽屏下内容居中，两侧留白；首页 TabBar 复用同一个值，保证左右缘一致。
  ///
  /// 取值依据（2026-10-05 桌面 1.00 基准）：首页/推荐流网格
  /// `SliverGridDelegateWithExtentAndRatio`（Pref.recommendCardWidth = 240、
  /// crossAxisSpacing = Style.cardSpace = 8）的列宽公式 ⇒ n 列所需宽度
  /// = 248n − 8；1480 = 248×6 − 8 ⇒ **正好 6 列 × 240.0**（命中
  /// maxCrossAxisExtent 240 的设计目标，卡宽不打折）。原 1560 会让
  /// ceil((1560−8)/248) = 7 列 × 216（低于 240，卡片偏小）。
  static const contentMaxWidth = 1480.0;
  static const mdRadius = BorderRadius.all(imgRadius);
  static const imgRadius = Radius.circular(10);
  static const aspectRatio = 16 / 10;
  static const aspectRatio16x9 = 16 / 9;
  static const imgMaxRatio = 2.6;
  static const bottomSheetRadius = BorderRadius.vertical(top: .circular(18));
  static const dialogFixedConstraints = BoxConstraints.tightFor(width: 420);
  static const topBarHeight = 52.0;
  static const buttonStyle = ButtonStyle(
    visualDensity: VisualDensity(horizontal: -2, vertical: -1.25),
    tapTargetSize: .shrinkWrap,
  );
  static const placeHolder = '\uFFFC';
}
