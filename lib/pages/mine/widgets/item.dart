import 'package:PiliPlus/common/widgets/desktop/winui_section.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({
    super.key,
    required this.item,
    required this.onPop,
    required this.heroTag,
    this.width,
  });

  final FavFolderInfo item;
  final VoidCallback onPop;
  final String heroTag;

  /// 桌面端网格卡片宽度；为空时按移动端的 180×110 渲染。
  final double? width;

  void _onTap() {
    Get.toNamed(
      '/favDetail',
      arguments: item,
      parameters: {
        'mediaId': item.id.toString(),
        'heroTag': heroTag,
      },
    )?.whenComplete(onPop);
  }

  @override
  Widget build(BuildContext context) {
    final w = width;
    if (PlatformUtils.isDesktop && w != null) {
      return _buildDesktop(context, w);
    }
    return _buildMobile(context);
  }

  /// 桌面端：Fluent 卡片 —— 1px 描边 + 圆角 8，无方向性阴影。
  Widget _buildDesktop(BuildContext context, double width) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(WinUi.radius);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: .55),
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Hero(
                  tag: heroTag,
                  child: NetworkImgLayer(
                    src: item.cover,
                    width: width,
                    height: width * 10 / 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: WinUi.gap8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: WinUi.gap4),
            Text(
              '共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 移动端：保持原有排版不变。
  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onInverseSurface.withValues(
                    alpha: 0.4,
                  ),
                  offset: const Offset(6, -8),
                  blurRadius: 0.0,
                  spreadRadius: 0.0,
                ),
              ],
            ),
            child: Hero(
              tag: heroTag,
              child: NetworkImgLayer(
                src: item.cover,
                width: 180,
                height: 110,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ' ${item.title}',
            overflow: TextOverflow.fade,
            maxLines: 1,
          ),
          Text(
            ' 共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
