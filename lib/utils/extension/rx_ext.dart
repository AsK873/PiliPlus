import 'package:get/get_rx/src/rx_types/rx_types.dart' show RxList;

extension RxListExt<E> on RxList<E> {
  // M0 兼容垫片(2026-09-05, 用户批准)：作者的 getx fork 有未发布的 `rawValue`(底层 list 直读直写)，
  // 本 SDK 的 getx 以 `value` 提供同一底层 list。改为一次性批量替换并触发一次通知，
  // 与“静默逐项写 + 调用方随后 refresh”语义等价（最终 UI 状态一致）。
  void fillRangeOnly(int start, int end, [E? fill]) {
    final fillValue = fill as E;
    final updated = List<E>.of(this);
    for (int i = start; i < end; i++) {
      updated[i] = fillValue;
    }
    clear();
    addAll(updated);
  }
}
