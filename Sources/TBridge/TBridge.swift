//
//  TBridge.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation
import WebKit

/**
 * TBridge 核心类
 * 
 * 功能：
 * - 处理 JavaScript 和 iOS 原生之间的双向通信
 * - 自动管理回调机制（通过 callbackId）
 * 
 * 设计原则：
 * - 核心层只处理消息结构（method, callbackId, params）
 * - 不处理业务字段（code, message, isSuccess 等），由业务层决定
 */
public class TBridge: NSObject {
    /// 日志标签
    static let TAG = "TBridge"
    
    /// Bridge 名称，对应 JS 端的 window.webkit.messageHandlers.iOSBridge
    static let BRIDGE_NAME = "iOSBridge"
    
    /// WebView 弱引用，防止循环引用
    private weak var webView: WKWebView?
    
    /// 消息处理器，由业务层实现
    private let messageHandler: OnTBridgeMessage
    
    /**
     * 初始化 TBridge
     * 
     * - Parameters:
     *   - webView: 要注入 Bridge 的 WebView
     *   - messageHandler: 处理来自 JS 的消息的处理器
     */
    public init(webView: WKWebView, messageHandler: OnTBridgeMessage) {
        self.webView = webView
        self.messageHandler = messageHandler
        super.init()
        setupBridge()
    }
    
    /**
     * 设置 Bridge
     * 
     * 功能：
     * 1. 注入 console.log 捕获脚本（用于调试）
     * 2. 注册 messageHandler，接收来自 JS 的消息
     */
    private func setupBridge() {
        guard let webView = webView else { return }
        
        // 注入 console.log 捕获，将 JS 日志输出到 Xcode 控制台
        ConsoleLogger.injectConsoleLogger(to: webView)
        
        // 注册 messageHandler
        // JS 端通过 window.webkit.messageHandlers.iOSBridge.postMessage() 发送消息
        webView.configuration.userContentController.add(self, name: TBridge.BRIDGE_NAME)
    }
    
    /**
     * iOS 调用 JS 方法
     * 
     * - Parameters:
     *   - method: JS 方法名
     *   - params: 传递给 JS 的参数（任意类型）
     * 
     * 注意：此方法用于单向调用，不等待 JS 回调
     */
    public func callJS(method: String, params: Any?) {
        guard let webView = webView else {
            print("\(TBridge.TAG): WebView 已释放，无法调用 JS")
            return
        }
        
        CallJsHandler(webView: webView).callJS(method: method, params: params, callbackId: nil)
    }
    
    /**
     * 清理资源
     * 
     * 应在 WebView 销毁时调用，防止内存泄漏
     */
    public func destroy() {
        guard let webView = webView else { return }
        webView.configuration.userContentController.removeScriptMessageHandler(forName: TBridge.BRIDGE_NAME)
        self.webView = nil
    }
    
    /**
     * 获取 Bridge 名称
     */
    public func getBridgeName() -> String {
        return TBridge.BRIDGE_NAME
    }
}

// MARK: - WKScriptMessageHandler
extension TBridge: WKScriptMessageHandler {
    /**
     * 接收来自 JS 的消息
     * 
     * 消息格式：
     * {
     *   "method": "方法名",
     *   "params": "参数字符串（JSON）或对象",
     *   "callbackId": "回调 ID（可选）"
     * }
     */
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 验证消息名称
        guard message.name == TBridge.BRIDGE_NAME else { return }
        
        // 解析消息体
        guard let messageBody = parseMessageBody(message.body) else {
            print("\(TBridge.TAG): 无效的消息格式")
            return
        }
        
        // 提取消息字段
        let method = messageBody["method"] as? String ?? ""
        let paramsString = extractParamsString(from: messageBody["params"])
        let callbackId = messageBody["callbackId"] as? String
        
        // 验证 WebView 是否有效
        guard let webView = webView else {
            print("\(TBridge.TAG): WebView 已释放，忽略调用: \(method)")
            return
        }
        
        // 创建回调包装器，自动处理 callbackId
        let callback = TBridgeCallbackWrapper(webView: webView, callbackId: callbackId)
        
        // 调用业务层处理器
        do {
            try messageHandler.onTBridgeMessage(
                method: method,
                params: paramsString,
                callbackId: callbackId,
                callback: callback
            )
        } catch {
            print("\(TBridge.TAG): 处理消息失败 - method: \(method), error: \(error.localizedDescription)")
            callback.onError(params: ["error": error.localizedDescription])
        }
    }
    
    /**
     * 解析消息体
     * 
     * 支持格式：
     * - 字典类型（直接使用）
     * - 字符串类型（JSON 解析）
     */
    private func parseMessageBody(_ body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] {
            return dict
        } else if let jsonString = body as? String,
                  let jsonData = jsonString.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return dict
        }
        return nil
    }
    
    /**
     * 提取参数字符串
     * 
     * 如果 params 是字符串，直接返回；如果是对象，转换为 JSON 字符串
     */
    private func extractParamsString(from params: Any?) -> String? {
        guard let params = params else { return nil }
        
        if let str = params as? String {
            return str
        } else if JSONSerialization.isValidJSONObject(params),
                  let jsonData = try? JSONSerialization.data(withJSONObject: params),
                  let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            return String(describing: params)
        }
    }
}

// MARK: - TBridgeCallbackWrapper
/**
 * TBridge 回调包装器
 * 
 * 功能：
 * - 自动处理 callbackId
 * - 将业务层的回调结果传递给 JS
 */
private class TBridgeCallbackWrapper: TBridgeCallback {
    private weak var webView: WKWebView?
    private let callbackId: String?
    
    init(webView: WKWebView, callbackId: String?) {
        self.webView = webView
        self.callbackId = callbackId
    }
    
    /**
     * 成功回调
     * 
     * 如果有 callbackId，自动调用 JS 的 onNativeCallback
     */
    func onSuccess(params: Any?) {
        guard let callbackId = callbackId, let webView = webView else { return }
        
        CallJsHandler(webView: webView).callJS(
            method: TBridgeMethods.ON_NATIVE_CALLBACK,
            params: params,
            callbackId: callbackId
        )
    }
    
    /**
     * 失败回调
     * 
     * 如果有 callbackId，自动调用 JS 的 onNativeCallback
     */
    func onError(params: Any?) {
        guard let callbackId = callbackId, let webView = webView else { return }
        
        CallJsHandler(webView: webView).callJS(
            method: TBridgeMethods.ON_NATIVE_CALLBACK,
            params: params,
            callbackId: callbackId
        )
    }
}
