// =============================================================
// PiliPlus Windows 桌面化 · 可复用桌面搜索框
// 桌面端所有「搜索框」共用这一个组件（顶栏、搜索结果页 AppBar）：
//   - 点击即进入输入状态，不跳转任何页面（跳转由宿主的 onSubmit 决定）
//   - 输入为空 → 通知宿主展示搜索历史
//   - 输入关键词 → 200ms 尾部防抖后请求联想词（SearchHttp.searchSuggest），
//     结果通过 onOverlayChanged 交给宿主渲染浮层
//   - 回车 → onSubmit（宿主执行搜索）
// 浮层本身由宿主渲染（见 desktop_search_panel.dart 的 DesktopSearchPanel）。
// 复用既有搜索接口与数据模型，不新增请求类型。
// =============================================================
import 'dart:async';

import 'package:PiliPlus/common/widgets/desktop/desktop_search_panel.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/search/suggest.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

class DesktopSearchBox extends StatefulWidget {
  const DesktopSearchBox({
    super.key,
    required this.active,
    this.initialText = '',
    this.fallbackQuery,
    this.hintText = '搜索视频 / UP主 / 番剧',
    this.width,
    this.height = 34,
    this.fontSize = 12.5,
    this.iconSize = 18,
    this.padH = 12,
    this.gap = 8,
    this.onActivated,
    this.onSubmit,
    this.onOverlayChanged,
  });

  /// 浮层是否展开（由宿主控制）；由 true 变 false 时清空输入并失焦
  final bool active;

  /// 初始输入内容（仅初始化时读取一次）
  final String initialText;

  /// 输入为空时的回退检索词。
  /// 非空时「输入为空」不再走搜索历史，而是直接对该词请求联想
  /// （搜索结果页据此直接进入联想模式，不展示历史列表）。
  final String? fallbackQuery;

  final String hintText;

  /// 固定宽度；为空则占满可用宽度
  final double? width;

  final double height;
  final double fontSize;
  final double iconSize;

  /// 左右内边距
  final double padH;

  /// 图标与输入框间距
  final double gap;

  /// 点击搜索框（宿主据此展开浮层）
  final VoidCallback? onActivated;

  /// 回车提交
  final ValueChanged<String>? onSubmit;

  /// 浮层状态变化（输入词 + 联想结果）
  final ValueChanged<DesktopSearchOverlayState>? onOverlayChanged;

  @override
  State<DesktopSearchBox> createState() => _DesktopSearchBoxState();
}

class _DesktopSearchBoxState extends State<DesktopSearchBox> {
  final TextEditingController _ctr = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// 联想词防抖计时器（与搜索页一致的 200ms 尾部防抖）
  Timer? _debounce;

  /// 请求序号：只采纳最后一次输入对应的响应
  int _seq = 0;

  /// 最近一次拿到的联想结果（新一轮请求在途时先沿用，避免浮层闪烁）
  List<SearchSuggestItem> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialText.isNotEmpty) _ctr.text = widget.initialText;
  }

  @override
  void didUpdateWidget(DesktopSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      // 展开：聚焦，并按当前输入内容决定展示历史还是联想
      _focus.requestFocus();
      final query = _resolve(_ctr.text);
      _report(query);
      _requestNow(query);
    } else {
      // 收起：回到初始内容（主页 initialText 为空 → 只留占位文字；
      // 搜索结果页 initialText 为当前关键词 → 输入框继续显示该关键词），
      // 并作废在途请求。
      _focus.unfocus();
      _ctr.text = widget.initialText;
      _debounce?.cancel();
      _debounce = null;
      _seq++;
      _suggestions = const [];
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctr.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 把当前输入词与联想结果交给宿主渲染浮层
  void _report(String query) {
    widget.onOverlayChanged?.call(
      DesktopSearchOverlayState(query: query, suggestions: _suggestions),
    );
  }

  /// 点击搜索框：进入输入状态（是否展开由宿主决定）
  void _onActivate() {
    _focus.requestFocus();
    widget.onActivated?.call();
  }

  /// 立即请求一次联想词（展开时同步当前输入用，不走防抖）
  void _requestNow(String term) {
    _debounce?.cancel();
    final seq = ++_seq;
    if (term.isEmpty || !Pref.searchSuggestion) return;
    _querySuggest(term, seq);
  }

  /// 展开展示用的检索词：输入优先；为空时回退到 [fallbackQuery]。
  /// 回退词也为空 → 返回空串 → 宿主展示搜索历史。
  String _resolve(String value) {
    final term = value.trim();
    return term.isNotEmpty ? term : (widget.fallbackQuery?.trim() ?? '');
  }

  /// 输入变化：空输入 → 回到搜索历史；非空 → 切到联想并 200ms 防抖请求。
  void _onChanged(String value) {
    _debounce?.cancel();
    final seq = ++_seq;
    final query = _resolve(value);
    if (query.isEmpty) {
      _suggestions = const [];
      _report('');
      return;
    }
    // 立即切到联想模式（沿用上一次结果，避免请求在途时浮层闪烁）
    _report(query);
    if (!Pref.searchSuggestion) return;
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => _querySuggest(query, seq),
    );
  }

  /// 请求联想词；只把最后一次输入的响应交给宿主展示。
  Future<void> _querySuggest(String term, int seq) async {
    final res = await SearchHttp.searchSuggest(term: term);
    if (!mounted || seq != _seq) return;
    _suggestions = switch (res) {
      Success(:final response) => response.tag ?? const <SearchSuggestItem>[],
      _ => const <SearchSuggestItem>[],
    };
    _report(term);
  }

  /// 回车：作废在途请求后交给宿主执行搜索
  void _submit(String value) {
    _debounce?.cancel();
    _debounce = null;
    _seq++;
    _suggestions = const [];
    widget.onSubmit?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final radius = BorderRadius.circular(widget.height / 2);
    final box = SizedBox(
      height: widget.height,
      child: Material(
        borderRadius: radius,
        color: colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onActivate,
          child: Row(
            children: [
              SizedBox(width: widget.padH),
              Icon(
                Icons.search_outlined,
                size: widget.iconSize,
                color: colorScheme.onSecondaryContainer,
              ),
              SizedBox(width: widget.gap),
              Expanded(
                child: TextField(
                  controller: _ctr,
                  focusNode: _focus,
                  onTap: _onActivate,
                  onChanged: _onChanged,
                  onSubmitted: _submit,
                  textInputAction: TextInputAction.search,
                  cursorColor: colorScheme.primary,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: widget.fontSize,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
              SizedBox(width: widget.padH),
            ],
          ),
        ),
      ),
    );
    final width = widget.width;
    return width == null ? box : SizedBox(width: width, child: box);
  }
}
