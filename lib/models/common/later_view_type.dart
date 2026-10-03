import 'package:PiliPlus/pages/later/child_view.dart';
import 'package:material_ui/material_ui.dart';

enum LaterViewType {
  all(0, '全部'),
  // toView(1, '未看'),
  unfinished(2, '未看完'),
  // viewed(3, '已看完'),
  ;

  /// 页面工厂方法（原为 `Widget get page`）。
  /// [instanceSuffix]：GetX 实例命名空间后缀，由宿主逐级下发
  /// （「我的」页内嵌预览实例为 `@preview`；移动端 / 路由方式 / 主壳内容区
  /// 嵌入为 `''`，与改动前的 key 逐字一致）。
  Widget page({String instanceSuffix = ''}) => LaterViewChildPage(
    laterViewType: this,
    instanceSuffix: instanceSuffix,
  );

  final int type;
  final String title;
  const LaterViewType(this.type, this.title);
}
