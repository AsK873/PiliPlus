// =============================================================
// PiliPlus Windows 桌面化 · 顶栏搜索浮层（搜索历史 + 联想推荐）
// 搜索入口只有一处：顶栏那个搜索框（点击后就地展开，不跳转任何搜索页）。
// 浮层两种模式，由输入内容切换：
//   - 输入为空 → 搜索历史（原样保留：两列、倒序、点击即搜、可清空）
//   - 输入非空 → 关键词联想（顶栏 200ms 防抖后把结果传进来）
// 点击历史词或联想词 → 用该关键词执行搜索（进入 /searchResult）。
// Esc（浮层获得焦点时）/ 点击浮层外 → 收起。
// 视觉沿用桌面组件度量（DesktopTokens：容器圆角 10 / 内边距 16 / 4px 栅格）：
// 容器为 surfaceContainer 底色 + outlineVariant 描边 + 柔和阴影；
// 联想行使用 DesktopListTile，与其余桌面页面同一套悬停 / 按下反馈。
// 复用既有搜索接口与数据模型（SearchHttp.searchSuggest / SearchSuggestItem）
// 与既有历史存储（BaseSearchController.historyList），不新增请求类型。
// =============================================================
import 'package:PiliPlus/common/widgets/desktop/desktop_list_tile.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_tokens.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/models/search/suggest.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/utils/em.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 桌面端统一搜索入口：按既有规则记录历史 → 进入搜索结果页。
/// （与搜索页 `SSearchController.submit()` 使用同一套存储键与倒序规则）
/// [replace] 为 true 时替换当前路由（已在搜索结果页内再次搜索时用，
/// 避免结果页层层堆叠）。
void desktopSearch(String word, {bool replace = false}) {
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
  final params = {'keyword': text};
  if (replace) {
    Get.offNamed('/searchResult', parameters: params);
  } else {
    Get.toNamed('/searchResult', parameters: params);
  }
}

/// 顶栏搜索浮层的展示状态：输入词 + 联想结果。
class DesktopSearchOverlayState {
  const DesktopSearchOverlayState({
    this.query = '',
    this.suggestions = const [],
  });

  /// 当前输入词（为空 = 展示搜索历史）
  final String query;

  /// 联想结果（`query` 非空时展示）
  final List<SearchSuggestItem> suggestions;

  /// 输入为空 → 展示搜索历史
  bool get showHistory => query.isEmpty;

  /// 是否有内容可展示：空输入展示历史；有输入时需已拿到联想结果
  bool get visible => showHistory || suggestions.isNotEmpty;

  static const DesktopSearchOverlayState empty = DesktopSearchOverlayState();
}

/// 搜索框下方的浮层：输入为空显示搜索历史，输入非空显示联想推荐。
class DesktopSearchPanel extends StatelessWidget {
  const DesktopSearchPanel({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onClose,
  });

  /// 当前浮层状态（历史 / 联想）
  final DesktopSearchOverlayState state;

  /// 选中某个关键词（历史词或联想词）
  final ValueChanged<String> onSelect;

  /// Esc 收起浮层
  final VoidCallback onClose;

  /// 面板宽度（与顶栏搜索框右对齐）
  static const double width = 420;

  /// 内容区最大高度（超出滚动）
  static const double maxHeight = 320;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(DesktopTokens.radius);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: GestureDetector(
        // 面板整块吸收点击：点面板区域（含标题、空白、间距）不会穿透到
        // 背景遮罩，因此不会误触发「收起」。
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: DesktopTokens.surface(colorScheme),
            borderRadius: radius,
            border: Border.all(color: DesktopTokens.border(colorScheme)),
            // 与桌面端 hover 卡片使用同一套柔和阴影
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
            child: state.showHistory
                ? _buildHistory(theme, colorScheme)
                : _buildSuggestions(colorScheme),
          ),
        ),
      ),
    );
  }

  // ===== 模式一：搜索历史（输入为空）=====

  Widget _buildHistory(ThemeData theme, ColorScheme colorScheme) {
    final baseCtr = Get.putOrFind(BaseSearchController.new);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesktopTokens.pad,
            DesktopTokens.gap12,
            DesktopTokens.pad,
            DesktopTokens.gap8,
          ),
          child: Row(
            children: [
              Text(
                '搜索历史',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: DesktopTokens.fontSectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // 与搜索页「清空」同一个语义：弹确认框后一次性清空全部搜索历史
              Obx(
                () => baseCtr.historyList.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        style: const ButtonStyle(
                          visualDensity: .compact,
                          tapTargetSize: .shrinkWrap,
                          padding: WidgetStatePropertyAll(
                            .symmetric(horizontal: 10),
                          ),
                        ),
                        onPressed: () => _clearHistory(baseCtr),
                        icon: Icon(
                          Icons.clear_all_outlined,
                          size: DesktopTokens.iconSize,
                          color: colorScheme.secondary,
                        ),
                        label: Text(
                          '清空历史记录',
                          style: TextStyle(
                            height: 1,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: maxHeight),
          child: Obx(() {
            final list = baseCtr.historyList;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DesktopTokens.gap16),
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
              padding: const EdgeInsets.only(bottom: DesktopTokens.gap8),
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i += 2)
                    Row(
                      children: [
                        Expanded(child: _historyItem(list[i])),
                        Expanded(
                          child: i + 1 < list.length
                              ? _historyItem(list[i + 1])
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
    );
  }

  /// 单条搜索历史：点击直接执行该搜索。
  Widget _historyItem(String word) =>
      _SearchHistoryItem(word: word, onTap: () => onSelect(word));

  /// 一键清空全部搜索历史：确认后清空内存列表与本地存储
  void _clearHistory(BaseSearchController baseCtr) {
    showConfirmDialog(
      context: Get.context!,
      title: const Text('确定清空搜索历史？'),
      onConfirm: () {
        baseCtr.historyList.clear();
        GStorage.historyWord.delete('cacheList');
      },
    );
  }

  // ===== 模式二：联想推荐（输入非空）=====

  Widget _buildSuggestions(ColorScheme colorScheme) {
    final items = state.suggestions
        .where((e) => e.term?.isNotEmpty ?? false)
        .toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: DesktopTokens.gap4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items) _suggestItem(item, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 单条联想词：命中片段用主题色加粗，行反馈复用 DesktopListTile。
  Widget _suggestItem(SearchSuggestItem item, ColorScheme colorScheme) {
    final term = item.term!;
    return DesktopListTile(
      leading: const Icon(Icons.search_outlined),
      title: Text.rich(
        TextSpan(
          children: [
            for (final e in Em.regTitle(item.textRich))
              TextSpan(
                text: e.text,
                style: e.isEm
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onSelect(term),
    );
  }
}

/// 单条搜索历史条目：悬停/按下反馈与桌面 hover 卡片（hover_card.dart）
/// 完全同一套 —— 悬停 surfaceContainerHighest 微提亮 + 1px 细边、
/// 按下 primary 略深、无涟漪（NoSplash）、120ms fastOutSlowIn。
/// 只改反馈表现，内边距/字号/点击行为与原先一致。
class _SearchHistoryItem extends StatefulWidget {
  const _SearchHistoryItem({required this.word, required this.onTap});

  final String word;
  final VoidCallback onTap;

  @override
  State<_SearchHistoryItem> createState() => _SearchHistoryItemState();
}

class _SearchHistoryItemState extends State<_SearchHistoryItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(DesktopTokens.radius - 2);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: DesktopTokens.hoverDuration,
        curve: DesktopTokens.curve,
        decoration: BoxDecoration(
          color: _hover
              ? DesktopTokens.hoverSurface(colorScheme)
              : Colors.transparent,
          borderRadius: radius,
        ),
        // 细边用 foregroundDecoration 绘制，完全不参与布局
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: _hover ? colorScheme.outlineVariant : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            // 悬停提亮已由外层承担，这里只保留按下态
            hoverColor: Colors.transparent,
            highlightColor: colorScheme.primary.withValues(alpha: .14),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesktopTokens.pad,
                vertical: DesktopTokens.gap8,
              ),
              child: Text(
                widget.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: DesktopTokens.fontInput),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
