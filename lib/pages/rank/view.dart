import 'package:PiliPlus/common/widgets/flutter/vertical_tabs.dart';
import 'package:PiliPlus/models/common/rank_type.dart';
import 'package:PiliPlus/pages/rank/controller.dart';
import 'package:PiliPlus/pages/rank/zone/view.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin {
  final RankController _rankController = Get.put(RankController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    // M8：桌面宽窗下左侧“分区树”加宽常驻 + 右内容；窄窗保持原 51px 窄树。
    final desktop =
        PlatformUtils.isDesktop &&
        MediaQuery.sizeOf(context).width >= 900;
    final leftRail = Container(
      width: desktop ? 176 : null,
      decoration: desktop
          ? BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.6,
              ),
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
            )
          : null,
      child: _buildTab(theme, desktop),
    );
    return Row(
      children: [
        leftRail,
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _rankController.tabController,
            children: RankType.values
                .map(
                  (item) => ZonePage(
                    rid: item.rid,
                    seasonType: item.seasonType,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(ThemeData theme, bool desktop) {
    return VerticalTabBar(
      dividerWidth: 0,
      isScrollable: true,
      indicatorWeight: 3,
      indicatorSize: .tab,
      controller: _rankController.tabController,
      padding: .only(bottom: MediaQuery.paddingOf(context).bottom + 105),
      tabs: RankType.values.map((e) {
        final label = Text(e.label);
        return VerticalTab(
          // 桌面宽树：整行可点、文字左对齐，观感类似官方“分区树”。
          width: desktop ? 176 : null,
          child: desktop
              ? Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: label,
                  ),
                )
              : label,
        );
      }).toList(),
      onTap: (index) {
        if (!_rankController.tabController.indexIsChanging) {
          _rankController.animateToTop();
        } else {
          _rankController
            ..tabIndex.value = index
            ..tabController.animateTo(index);
        }
      },
    );
  }
}
