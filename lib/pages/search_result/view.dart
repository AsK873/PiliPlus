import 'package:PiliPlus/common/widgets/desktop/desktop_search_box.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_search_panel.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_tokens.dart';
import 'package:PiliPlus/common/widgets/desktop/desktop_top_bar.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search_panel/all/view.dart';
import 'package:PiliPlus/pages/search_panel/article/view.dart';
import 'package:PiliPlus/pages/search_panel/live/view.dart';
import 'package:PiliPlus/pages/search_panel/pgc/view.dart';
import 'package:PiliPlus/pages/search_panel/user/view.dart';
import 'package:PiliPlus/pages/search_panel/video/view.dart';
import 'package:PiliPlus/pages/search_result/controller.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchResultController _searchResultController;
  late TabController _tabController;
  final String _tag = DateTime.now().millisecondsSinceEpoch.toString();
  final bool _isFromSearch = Get.arguments?['fromSearch'] ?? false;
  SSearchController? sSearchController;

  /// 桌面浮层是否展开（仅桌面使用）
  bool _searchActive = false;

  /// 桌面浮层状态（历史 / 联想）
  final ValueNotifier<DesktopSearchOverlayState> _searchOverlay = ValueNotifier(
    DesktopSearchOverlayState.empty,
  );

  @override
  void initState() {
    super.initState();
    _searchResultController = Get.put(
      SearchResultController(),
      tag: _tag,
    );

    _tabController = TabController(
      vsync: this,
      initialIndex: Get.arguments?['initIndex'] ?? 0,
      length: SearchType.values.length,
    );

    if (_isFromSearch) {
      try {
        sSearchController = Get.find<SSearchController>(
          tag: Get.parameters['tag'],
        );
        _tabController.addListener(listener);
      } catch (_) {}
    }
  }

  void listener() {
    sSearchController?.initIndex = _tabController.index;
  }

  @override
  void dispose() {
    _searchOverlay.dispose();
    _tabController
      ..removeListener(listener)
      ..dispose();
    super.dispose();
  }

  /// 收起桌面搜索浮层：回到「输入为空」状态
  void _closeSearch() {
    _searchOverlay.value = DesktopSearchOverlayState.empty;
    setState(() => _searchActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffold = SimpleScaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        // 桌面：返回按钮右侧给出当前搜索上下文 —— 辅助标题「搜索结果」+ 关键词，
        // 填掉左上空白；字号层级与主页顶栏标题一致（14 / w600 / onSurface），
        // 间距走 4px 栅格。移动端维持原有「点标题回到搜索页继续编辑」的行为。
        title: PlatformUtils.isDesktop
            ? Row(
                children: [
                  Text(
                    '搜索结果',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesktopTokens.subtitleColor(theme.colorScheme),
                    ),
                  ),
                  const SizedBox(width: DesktopTokens.gap8),
                  Flexible(
                    child: Text(
                      _searchResultController.keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DesktopTokens.titleColor(theme.colorScheme),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: () {
                  if (_isFromSearch) {
                    Get.back(result: true);
                  } else {
                    Get.offNamed(
                      '/search',
                      parameters: {'text': _searchResultController.keyword},
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _searchResultController.keyword,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                  ),
                ),
              ),
        // 桌面：搜索框放在 AppBar 原生 actions 槽（右侧），不覆盖内容布局；
        // 点击只展开联想浮层，绝不跳转 /search。
        actions: PlatformUtils.isDesktop
            ? [
                DesktopSearchBox(
                  active: _searchActive,
                  width: DesktopTopBar.searchWidth,
                  height: DesktopTopBar.searchHeight,
                  initialText: _searchResultController.keyword,
                  hintText: _searchResultController.keyword,
                  fallbackQuery: _searchResultController.keyword,
                  onActivated: () => setState(() => _searchActive = true),
                  onSubmit: (value) {
                    _closeSearch();
                    desktopSearch(value, replace: true);
                  },
                  onOverlayChanged: (state) => _searchOverlay.value = state,
                ),
                const SizedBox(width: DesktopTopBar.paddingH),
              ]
            : null,
      ),
      body: ViewSafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              overlayColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              splashFactory: NoSplash.splashFactory,
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              controller: _tabController,
              tabs: SearchType.values
                  .map(
                    (item) => Obx(
                      () {
                        int count = _searchResultController.count[item.index];
                        return Tab(
                          text:
                              '${item.label}${count != -1 ? ' ${count > 99 ? '99+' : count}' : ''}',
                        );
                      },
                    ),
                  )
                  .toList(),
              isScrollable: true,
              indicatorWeight: 0,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 8,
              ),
              indicator: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: theme.colorScheme.onSecondaryContainer,
              labelStyle:
                  TabBarTheme.of(
                    context,
                  ).labelStyle?.copyWith(fontSize: 13) ??
                  const TextStyle(fontSize: 13),
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              unselectedLabelColor: theme.colorScheme.outline,
              tabAlignment: TabAlignment.start,
              onTap: (index) {
                if (!_tabController.indexIsChanging) {
                  if (_searchResultController.toTopIndex.value == index) {
                    _searchResultController.toTopIndex.refresh();
                  } else {
                    _searchResultController.toTopIndex.value = index;
                  }
                }
              },
            ),
            Expanded(
              child: tabBarView(
                controller: _tabController,
                children: SearchType.values
                    .map(
                      (item) => switch (item) {
                        .all => SearchAllPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        .video => SearchVideoPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        .media_bangumi || .media_ft => SearchPgcPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        .live_room => SearchLivePanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        .bili_user => SearchUserPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        .article => SearchArticlePanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                      },
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (!PlatformUtils.isDesktop) return scaffold;

    // 桌面：透明遮罩 + 关键词联想浮层，与主页面搜索历史浮层同一套关闭机制。
    // 遮罩覆盖「除搜索框矩形以外」的整页（含 AppBar：返回按钮、标题区都算空白），
    // 点任意空白即收起浮层并保持当前结果页；浮层叠在遮罩之上，点击不穿透。
    // AppBar 高度按「顶部安全区 + 工具栏高」推导（与 theme/AppBar 默认值一致）。
    final double topPad = MediaQuery.paddingOf(context).top;
    final double toolbarH = theme.appBarTheme.toolbarHeight ?? kToolbarHeight;
    final double appBarHeight = topPad + toolbarH;
    final double boxTop = topPad + (toolbarH - DesktopTopBar.searchHeight) / 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        scaffold,
        if (_searchActive)
          ValueListenableBuilder<DesktopSearchOverlayState>(
            valueListenable: _searchOverlay,
            builder: (context, state, _) {
              if (!state.visible) return const SizedBox.shrink();
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: boxTop,
                    child: _searchDismissBarrier(),
                  ),
                  Positioned(
                    top: boxTop + DesktopTopBar.searchHeight,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _searchDismissBarrier(),
                  ),
                  Positioned(
                    top: boxTop,
                    left: 0,
                    right: DesktopTopBar.searchWidth + DesktopTopBar.paddingH,
                    height: DesktopTopBar.searchHeight,
                    child: _searchDismissBarrier(),
                  ),
                  Positioned(
                    top: boxTop,
                    right: 0,
                    width: DesktopTopBar.paddingH,
                    height: DesktopTopBar.searchHeight,
                    child: _searchDismissBarrier(),
                  ),
                  // 联想浮层：AppBar 正下方，右边缘与搜索框一致
                  // （结果页只显示关键词联想，不显示搜索历史）
                  Positioned(
                    top: appBarHeight + 1,
                    right: DesktopTopBar.paddingH,
                    child: DesktopSearchPanel(
                      state: state,
                      onSelect: (word) {
                        _closeSearch();
                        desktopSearch(word, replace: true);
                      },
                      onClose: _closeSearch,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// 点击空白 / 返回按钮 / 标题区域收起联想浮层的透明遮罩
  Widget _searchDismissBarrier() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _closeSearch,
  );
}
