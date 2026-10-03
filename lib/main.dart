import 'dart:io';

import 'package:PiliPlus/build_config.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/back_detector.dart';
import 'package:PiliPlus/common/widgets/custom_toast.dart';
import 'package:PiliPlus/common/widgets/desktop/winui_entrance.dart';
import 'package:PiliPlus/common/widgets/route_aware_mixin.dart';
import 'package:PiliPlus/common/widgets/scroll_behavior.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models/common/theme/theme_color_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:PiliPlus/router/app_pages.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/services/download/download_service.dart';
import 'package:PiliPlus/services/logger.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/cache_manager.dart';
import 'package:PiliPlus/utils/calc_window_position.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/extension/core_palettes_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/font_utils.dart';
import 'package:PiliPlus/utils/json_file_handler.dart';
import 'package:PiliPlus/utils/max_screen_size.dart';
import 'package:PiliPlus/utils/path_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';
import 'package:window_manager/window_manager.dart' hide calcWindowPosition;

WebViewEnvironment? webViewEnvironment;

EdgeInsets? tmpPadding;

Future<void> _initDownPath() async {
  if (PlatformUtils.isDesktop) {
    final customDownPath = Pref.downloadPath;
    if (customDownPath != null && customDownPath.isNotEmpty) {
      try {
        final dir = Directory(customDownPath);
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        downloadPath = customDownPath;
      } catch (e) {
        downloadPath = defDownloadPath;
        await GStorage.setting.delete(SettingBoxKey.downloadPath);
        if (kDebugMode) {
          debugPrint('download path error: $e');
        }
      }
    } else {
      downloadPath = defDownloadPath;
    }
  } else if (Platform.isAndroid) {
    final externalStorageDirPath = (await getExternalStorageDirectory())?.path;
    downloadPath = externalStorageDirPath != null
        ? path.join(externalStorageDirPath, PathUtils.downloadDir)
        : defDownloadPath;
  } else {
    downloadPath = defDownloadPath;
  }
}

Future<void> _initTmpPath() async {
  tmpDirPath = (await getTemporaryDirectory()).path;
}

Future<void> _initAppPath() async {
  appSupportDirPath = (await getApplicationSupportDirectory()).path;
}

/// 窗口最小尺寸的固定设计值（**外框**的 logical 值：window_manager 原生侧在
/// WM_GETMINMAXINFO 里再乘窗口真实 dpr，与应用内设置无关）。
///
/// 960x640 的推导（4px 栅格）：宽 —— 侧栏恒定 216（DesktopSideBar.width），
/// 正文可用宽 = 客户区宽 - 216；一个 240 宽的视频卡（Pref.smallCardWidth = 240，
/// 间距 8）要保证 2 列需 488 ⇒ 客户区 ≥ 216 + 488 = 704，再按 4px 栅格并留出内容
/// 限宽 1480 之外的常规留白 ⇒ 960（实测客户区 944 ⇒ 正文 728，首页 3 列）。
/// 高 —— 侧栏内容 ≈ 594 ⇒ 客户区 601 时正文剩约 7px（侧栏可滚动，账号区仍可见）；
/// 不得小于约 600。实测外框 960x640 ⇒ 客户区 944x601（不可见边框 16x39）。
/// 该尺寸已在本机 6 档分辨率审计中逐项验证可用（见 desktop100 审计报告）。
///
/// 该值为固定常量，不随任何应用内设置变化。
const Size kWindowMinimumSize = Size(960, 640);

/// 窗口最小尺寸（固定为 [kWindowMinimumSize]）。
/// 保留函数形式以便启动处与窗口几何写回判定复用同一来源
/// （`WindowOptions.minimumSize`、`pages/main/view.dart`）。
Size windowMinimumSize() => kWindowMinimumSize;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await _initAppPath();
  try {
    await GStorage.init();
  } catch (e) {
    await Utils.copyText(e.toString(), needToast: false);
    if (kDebugMode) debugPrint('GStorage init error: $e');
    exit(0);
  }
  await Future.wait([
    _initDownPath(),
    _initTmpPath(),
    CacheManager.ensureInitialized(),
    ?FontUtils.init(),
  ]);
  Get
    ..lazyPut(AccountService.new)
    ..lazyPut(DownloadService.new);
  HttpOverrides.global = _CustomHttpOverrides();

  if (PlatformUtils.isMobile) {
    if (Platform.isAndroid) MaxScreenSize.init();
    await Future.wait([
      if (Pref.horizontalScreen) ?fullMode() else ?portraitUpMode(),
      setupServiceLocator(),
    ]);
  } else if (Platform.isWindows) {
    if (await WebViewEnvironment.getAvailableVersion() != null) {
      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: path.join(appSupportDirPath, 'flutter_inappwebview'),
        ),
      );
    }
  } else if (Platform.isMacOS) {
    await setupServiceLocator();
  }

  Request();
  Request.setCookie();
  RequestUtils.syncHistoryStatus();

  SmartDialog.config.toast = SmartConfigToast(displayType: .onlyRefresh);

  if (PlatformUtils.isMobile) {
    SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    if (Platform.isAndroid) {
      FlutterDisplayMode.supported.then((mode) {
        final String? storageDisplay = GStorage.setting.get(
          SettingBoxKey.displayMode,
        );
        DisplayMode? displayMode;
        if (storageDisplay != null) {
          displayMode = mode.firstWhereOrNull(
            (e) => e.toString() == storageDisplay,
          );
        }
        FlutterDisplayMode.setPreferredMode(displayMode ?? DisplayMode.auto);
      });
    } else {
      ScreenBrightnessPlatform.instance.setAutoReset(false);
    }
  } else if (PlatformUtils.isDesktop) {
    FocusManager.instance.addEarlyKeyEventHandler(_onKeyEvent);

    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      // 最小窗口 960x640（4px 栅格）＝固定常量 kWindowMinimumSize。
      // 注意 window_manager 的 minimumSize 约束的是**外框尺寸**（实测 100% 缩放下
      // 外框 960x640 ⇒ 客户区 944x601，边框 16x39），下述算式按「客户区 = 窗口逻辑
      // 尺寸」给出，故实际客户区略小于 960x640（944x601），仍满足全部下限要求。
      //
      // 宽：侧栏恒定 216（DesktopSideBar.width）；正文可用宽 = 客户区宽 - 216。
      //   一个 240 宽的视频卡（maxCrossAxisExtent = Pref.smallCardWidth = 240，
      //   间距 8）在首页限宽内要保证 2 列：2x240 + 8 = 488（即仅 1 列会让
      //   卡片被拉宽或文字/封面比例劣化）；其余需求更小：
      //   顶栏搜索框 260 + 左右内边距 12 = 272、预览标题行 16 + 260 = 276、
      //   「我的」页 5 个选项卡 344 + 页面边距 24 = 368、用户卡 357 + 32 + 48
      //   = 437（窄窗另有响应式紧凑变体，见 pages/mine/view.dart）。
      //   取最大项 488 ⇒ 客户区 ≥ 216 + 488 = 704；再留出内容限宽 1480 之外的
      //   常规留白并按 4px 栅格对齐 ⇒ 960：此时正文 744，首页 3 列
      //   （3x240 + 2x8 = 736），「我的」页用户卡可用宽约 960-264=696
      //   （实测 944 客户区 ⇒ 卡内内容宽 648，走紧凑变体，无塌缩）。
      //   不取更小：< 960 时首页两列已无法在限宽内保证，视频卡会被压到 240
      //   以下；不取更大：上述各页在 960 下均已完整可用。
      // 高：侧栏内容（品牌区 40 + 主入口 3x31 + 分组头 22 + 快捷入口 5x31 +
      //   2 组分隔线 26 + 「我的」入口 4x31 + 无痕/切换账号/主题 3x31 +
      //   深色模式/设置 2x31 + 账号区 55）≈ 594 ⇒ 客户区 601 时正文剩约
      //   7px（侧栏可滚动，账号区仍在可视区内）；不得小于 ~600，
      //   否则账号区被挤出可视区。
      //
      // 不改默认窗口尺寸：下方 setBounds 仍用 Pref.windowSize（默认
      // 1180x720，本机实测配置值 1325x825），只是小于本最小值时被系统夹住。
      // 与 MainLayout 的耦合已确认安全：有侧栏时正文约束宽 =
      // 窗口宽 - 侧栏宽 = 944 - 216 = 728 > 0，不会出现负宽/异常
      // （main_layout.dart 用窗口宽计算，窗口 ≥ 217 即安全）。
      minimumSize: windowMinimumSize(),
      skipTaskbar: false,
      titleBarStyle: Pref.showWindowTitleBar
          ? TitleBarStyle.normal
          : TitleBarStyle.hidden,
      title: Constants.appName,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      final windowSize = Pref.windowSize;
      await windowManager.setBounds(
        await calcWindowPosition(windowSize) & windowSize,
      );
      if (Pref.isWindowMaximized) await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (Pref.dynamicColor) {
    await MyApp.initPlatformState();
  }

  if (Pref.enableLog) {
    // 异常捕获 logo记录
    final customParameters = {
      'Build Time': DateFormatUtils.format(
        BuildConfig.buildTime,
        format: DateFormatUtils.longFormatDs,
      ),
      'Commit Hash': BuildConfig.commitHash,
      'MPV Api Version':
          '${NativePlayer.apiVersion >> 16}.${NativePlayer.apiVersion & 0xFFFF}',
    };
    final fileHandler = await JsonFileHandler.init();

    Catcher2(
      [?fileHandler, const ConsoleHandler()],
      const MyApp(),
      logger: logger,
      customParameters: customParameters,
    );
  } else {
    runApp(const MyApp());
  }
}

KeyEventResult _onKeyEvent(KeyEvent event) {
  if (event.logicalKey == .escape && event is KeyDownEvent) {
    _onBack();
    return .handled;
  }
  return .ignored;
}

void _onBack() {
  // 1) 弹层优先：有 SmartDialog 时先关它
  if (SmartDialog.checkExist()) {
    SmartDialog.dismiss();
    return;
  }

  final route = Get.routing.route;

  // 2) 当前路由自己声明了「不可 pop」的内部态（popScope(canPop:false) 的多选态等）
  //    → 交回该路由处理（与改动前优先级一致：先退内部态，绝不强推出页面）。
  //    根路由（'/' 的主壳 MainApp）在**未承载桌面内容页**时同样在此兜底，维持原有
  //    「directExitOnBack 退出 / 其余主 Tab 切回首页」行为；
  //    承载内容页时主壳会撤掉自己的否决（见 main/view.dart 的 _syncRootCanPop），
  //    于是这里只剩内容页自己声明的多选态，正常态会继续走到第 4 步
  //    —— 这就是「从快捷入口进入的页面对鼠标侧键无反应」的根因所在。
  if (route is GetPageRoute) {
    if (route.popDisposition == .doNotPop) {
      route.onPopInvokedWithResult(false, null);
      return;
    }
  }

  // 3) 有压入的二级路由时优先 pop（保持本机制原有优先级：
  // 例如从嵌入页打开的搜索页 / 视频页，必须先退掉该路由）
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
    return;
  }

  // 4) 桌面主内容区就地承载的页面（历史记录等）已注册返回处理器 →
  //    调用它 = 与页面左上角返回按钮**完全一致**：搜索态 → 多选态 → 收起内容页
  //    回到进入前的主页 / Tab（统一走全局这份逻辑，不在各页面重复实现）。
  if (Get.isRegistered<MainController>()) {
    final desktopContentBackHandler =
        Get.find<MainController>().desktopContentBackHandler;
    if (desktopContentBackHandler != null) {
      desktopContentBackHandler();
      return;
    }
  }

  // 5) 兜底：根路由 doNotPop（主壳 PopScope）→ 维持原有行为
  //    （directExitOnBack 退出应用 / 其余主 Tab 时切回首页 Tab）。
  if (route is GetPageRoute && route.popDisposition == .doNotPop) {
    route.onPopInvokedWithResult(false, null);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ColorScheme? _light, _dark;

  static (ThemeData, ThemeData) getAllTheme() {
    final dynamicColor = _light != null && _dark != null && Pref.dynamicColor;

    final ColorScheme lightScheme, darkScheme;
    if (dynamicColor) {
      lightScheme = _light!;
      darkScheme = _dark!;
    } else {
      final customColor = Pref.customColor;
      final brandColor =
          colorThemeTypes.elementAtOrNull(customColor)?.color ??
          Color(customColor);
      final variant = Pref.schemeVariant;

      lightScheme = brandColor.asColorSchemeSeed(variant, .light);
      darkScheme = brandColor.asColorSchemeSeed(variant, .dark);
    }

    return (
      ThemeUtils.lightTheme = ThemeUtils.getThemeData(
        colorScheme: lightScheme,
        isDynamic: dynamicColor,
      ),
      ThemeUtils.darkTheme = ThemeUtils.getThemeData(
        isDark: true,
        colorScheme: darkScheme,
        isDynamic: dynamicColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (light, dark) = getAllTheme();
    return GetMaterialApp(
      title: Constants.appName,
      theme: light,
      darkTheme: dark,
      themeMode: ThemeUtils.themeMode = Pref.themeMode,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: const Locale("zh", "CN"),
      fallbackLocale: const Locale("zh", "CN"),
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      initialRoute: '/',
      getPages: Routes.getPages,
      defaultTransition: Pref.pageTransition,
      builder: FlutterSmartDialog.init(
        toastBuilder: CustomToast.new,
        loadingBuilder: LoadingWidget.new,
        notifyStyle: const FlutterSmartNotifyStyle(
          warningBuilder: NotifyWarning.new,
        ),
        builder: (context, child) => WinUiEntrance(
          // WinUI 3 风格：弹层 150ms 淡入 + 8px 上移（仅桌面，移动端原样）
          enabled: PlatformUtils.isDesktop,
          child: _builder(context, child),
        ),
      ),
      navigatorObservers: [
        routeObserver,
        FlutterSmartDialog.observer,
      ],
      scrollBehavior: PlatformUtils.isDesktop
          ? const CustomScrollBehavior()
          : null,
    );
  }

  static Widget _builder(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    child = MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(Pref.defaultTextScale),
        padding: tmpPadding,
        viewPadding: tmpPadding,
      ),
      child: child!,
    );
    if (PlatformUtils.isDesktop) {
      return BackDetector(
        onBack: _onBack,
        child: child,
      );
    }
    return child;
  }

  /// from [DynamicColorBuilderState.initPlatformState]
  static Future<bool> initPlatformState() async {
    if (_light != null || _dark != null) return true;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final colors = await DynamicColorPlugin.channel.invokeMethod(
        DynamicColorPlugin.methodName,
      );

      if (colors != null) {
        final corePalettes = CorePalettesExt.fromList(colors.toList());
        if (kDebugMode) {
          debugPrint('dynamic_color: Core palette detected.');
        }
        _light = corePalettes.toColorScheme();
        _dark = corePalettes.toColorScheme(brightness: Brightness.dark);
        return true;
      }
    } on PlatformException {
      if (kDebugMode) {
        debugPrint('dynamic_color: Failed to obtain core palette.');
      }
    }

    try {
      final Color? accentColor = await DynamicColorPlugin.getAccentColor();

      if (accentColor != null) {
        if (kDebugMode) {
          debugPrint('dynamic_color: Accent color detected.');
        }
        final variant = Pref.schemeVariant;
        _light = accentColor.asColorSchemeSeed(variant, .light);
        _dark = accentColor.asColorSchemeSeed(variant, .dark);
        return true;
      }
    } on PlatformException {
      if (kDebugMode) {
        debugPrint('dynamic_color: Failed to obtain accent color.');
      }
    }
    if (kDebugMode) {
      debugPrint('dynamic_color: Dynamic color not detected on this device.');
    }
    GStorage.setting.put(SettingBoxKey.dynamicColor, false);
    return false;
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // ..maxConnectionsPerHost = 32
    /// The default value is 15 seconds.
    //   ..idleTimeout = const Duration(seconds: 15);
    if (kDebugMode || Pref.badCertificateCallback) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
