// 自定义 Flutter Web 启动模板（Flutter 会把 {{...}} 占位替换成生成内容）。
// 目的：让 CanvasKit 引擎从【同源本地 canvaskit/】加载，而不是默认的 Google CDN
// (www.gstatic.com/flutter-canvaskit/...)。国内不挂 VPN 也能起，否则白屏。
// 本地 canvaskit 资源：dev(flutter run) 由 dev server 从 SDK 缓存提供；
// release(flutter build web) 由构建复制到 build/web/canvaskit/。
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
