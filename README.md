# TBridge - iOS (Swift)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](../../LICENSE)
[![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)

TBridge 的 iOS Swift 实现，为 WKWebView 提供与 JavaScript 的双向通信能力。

## 📦 安装

### Swift Package Manager

在 Xcode 中选择 `File` > `Add Package Dependencies...`，输入：

```
https://github.com/KaJInL/tbridge-ios.git
```

或在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/KaJInL/tbridge-ios.git", from: "0.1.0")
]
```

## 🚀 快速开始

```swift
import TBridge
import WebKit

class ViewController: UIViewController {
    private var webView: WKWebView!
    private var bridge: TBridge!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)
        
        bridge = TBridge(webView: webView, messageHandler: self)
    }
    
    deinit {
        bridge.destroy()
    }
}

extension ViewController: OnTBridgeMessage {
    func onTBridgeMessage(
        method: String,
        params: String?,
        callbackId: String?,
        callback: TBridgeCallback
    ) throws {
        switch method {
        case "methodName":
            callback.onSuccess(params: ["result": "data"])
        default:
            callback.onError(params: ["error": "未知方法"])
        }
    }
}

// 调用 JS 方法
bridge.callJS(method: "methodName", params: ["key": "value"])
```

## 📊 调用流程

```
① 接收 JS 调用：
   onTBridgeMessage(method:params:callbackId:callback:)
   ↓
   处理业务逻辑
   ↓
   callback.onSuccess(params:)

② 调用 JS：
   bridge.callJS(method:params:)
```

## 📖 核心 API

### TBridge 类

#### 初始化

```swift
public init(webView: WKWebView, messageHandler: OnTBridgeMessage)
```

创建 TBridge 实例。

**参数:**
- `webView`: WKWebView 实例
- `messageHandler`: JS 消息处理器

#### callJS()

```swift
public func callJS(method: String, params: Any?)
```

调用 JavaScript 方法。

**示例:**

```swift
// 传递 Dictionary
bridge.callJS(method: "onUserLogin", params: ["userId": "123"])

// 传递 Array
bridge.callJS(method: "updateList", params: [1, 2, 3])

// 传递字符串
bridge.callJS(method: "showMessage", params: "Hello")

// 无参数
bridge.callJS(method: "refresh", params: nil)
```

#### destroy()

```swift
public func destroy()
```

清理资源，防止内存泄漏。在 ViewController 销毁时调用。

```swift
deinit {
    bridge.destroy()
}
```

#### getBridgeName()

```swift
public func getBridgeName() -> String
```

获取 Bridge 名称（返回 `"iOSBridge"`）。

### OnTBridgeMessage 协议

```swift
public protocol OnTBridgeMessage {
    func onTBridgeMessage(
        method: String,
        params: String?,
        callbackId: String?,
        callback: TBridgeCallback
    ) throws
}
```

处理来自 JavaScript 的调用。

### TBridgeCallback 协议

```swift
public protocol TBridgeCallback {
    func onSuccess(params: Any?)
    func onError(params: Any?)
}
```

用于返回结果给 JavaScript。

**示例:**

```swift
// 成功
callback.onSuccess(params: ["code": 0, "data": result])

// 失败
callback.onError(params: ["code": -1, "message": "错误信息"])
```

## 📚 完整文档

详细的使用指南、示例代码和 API 文档请查看：

- [📖 主文档](https://github.com/KaJInL/tbridge)
- [🔧 集成指南](https://github.com/KaJInL/tbridge/blob/main/packages/tbridge/docs/INTEGRATION_GUIDE.md)
- [📘 API 参考](https://github.com/KaJInL/tbridge/blob/main/packages/tbridge/docs/API_REFERENCE.md)
- [💡 示例代码](https://github.com/KaJInL/tbridge/blob/main/packages/tbridge/docs/EXAMPLES.md)

## 🔗 相关链接

- **GitHub**: https://github.com/KaJInL/tbridge-ios
- **主仓库**: https://github.com/KaJInL/tbridge

## 📄 许可证

MIT License

