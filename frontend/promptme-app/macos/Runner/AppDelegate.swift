import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // tray 常驻：发完即隐（windowManager.hide）会让可见窗口归零，
  // 默认 true 会令 AppKit 直接退出整个 App（菜单栏图标消失）。改 false 保活，只走 tray「退出」。
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
