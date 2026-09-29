// =============================================================
// PiliPlus Windows PC 化 · 顶栏搜索历史面板
// 搜索入口只有一处：顶栏那个搜索框（点击后自身进入输入状态）。
// 本面板不含任何输入框，只在搜索框下方展示「搜索历史」：
//   - 两列布局、按搜索时间倒序（最新在最前）
//   - 无「热/新」等热榜标签，也不显示排名
//   - 点击历史词 → 直接执行搜索；Esc / 点击面板外 → 关闭
// 视觉规范与整体界面统一（复用 winui_section.dart 的度量）：
//   surfaceContainer 底色 + outlineVariant 1px 描边 + 圆角 8
//   + 16 内边距 + 项目统一的柔和阴影；列表字号沿用侧栏的 13.5。
// 说明：历史复用既有本地存储（BaseSearchController.historyList），不新增网络请求。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/winui_section.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面端统一搜索入口：按既有规则记录历史 → 进入搜索结果页。
/// （原搜索页 `SSearchController.submit()` 的同一套存储键与倒序规则）
void desktopSearch(String word) {
  final text = word.trim();
  if (text.isEmpty) return;
  final baseCtr = Get.putOrFind(BaseSearchController.new);
  if (baseCtr.recordSearchHistory.value) {
    final list = baseCtr.historyList;
    final index = list.indexOf(text);
    if (index != 0) {
      if (index != -1) list.removeAt(index);
      list.insert(0, text);
      GStorage.historyWord.put('cacheList', list);
    }
  }
  Get.toNamed('/searchResult', parameters: {'keyword': text});
}

class DesktopSearchPanel extends StatelessWidget {
  const DesktopSearchPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  /// 面板宽度（与顶栏搜索框右对齐）
  static const double width = 420;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseCtr = Get.putOrFind(BaseSearchController.new);
    final radius = BorderRadius.circular(WinUi.radius);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: GestureDetector(
        // 面板整块吸收点击：点击「搜索历史」区域（含标题、空白、间距）
        // 不会穿透到背景遮罩，因此不会触发「取消搜索」。
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: .55),
            ),
            // 与桌面端 hover 卡片使用同一套柔和阴影，避免突兀的独立设计
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WinUi.pad,
                    WinUi.gap12,
                    WinUi.pad,
                    WinUi.gap8,
                  ),
                  child: Text(
                    '搜索历史',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Obx(() {
                    final list = baseCtr.historyList;
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: WinUi.gap16),
                        child: Center(
                          child: Text(
                            '暂无搜索历史',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: WinUi.gap8),
                      child: Column(
                        children: [
                          for (var i = 0; i < list.length; i += 2)
                            Row(
                              children: [
                                Expanded(child: _item(list[i])),
                                Expanded(
                                  child: i + 1 < list.length
                                      ? _item(list[i + 1])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 单条搜索历史：点击直接执行该搜索（内边距/字号与侧栏列表保持一致）。
  Widget _item(String word) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(WinUi.radius - 2),
        onTap: () {
          onClose();
          desktopSearch(word);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WinUi.pad,
            vertical: WinUi.gap8,
          ),
          child: Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}
