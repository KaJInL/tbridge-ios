//
//  CallJsHandler.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation
import WebKit

/**
 * 调用 JS 的处理器
 * 
 * 功能：
 * - 将 iOS 消息封装成标准格式
 * - 通过 evaluateJavaScript 执行 JS 代码
 * 
 * 消息格式：
 * {
 *   "method": "方法名",
 *   "callbackId": "回调 ID（可选）",
 *   "params": "参数（任意类型）"
 * }
 */
class CallJsHandler {
    private weak var webView: WKWebView?
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    /**
     * 调用 JS 方法
     * 
     * - Parameters:
     *   - method: JS 方法名
     *   - params: 传递给 JS 的参数（任意类型）
     *   - callbackId: 回调 ID，如果有值，JS 执行完后会回调
     * 
     * 调用方式：
     * - 有 callbackId：调用 window.TBridge.onNativeCallback()
     * - 无 callbackId：调用 window.TBridge.onCallFromNative()
     */
    func callJS(method: String, params: Any?, callbackId: String? = nil) {
        guard let webView = webView else {
            print("TBridge: WebView 已释放，无法调用 JS")
            return
        }
        
        // 构建消息字典
        var messageDict: [String: Any] = ["method": method]
        messageDict["callbackId"] = callbackId ?? NSNull()
        messageDict["params"] = serializeParams(params)
        
        // 转换为 JSON 字符串
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("TBridge: 消息序列化失败")
            return
        }
        
        // 转义特殊字符，防止 JS 执行错误
        let escapedJson = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        // 构建 JS 代码
        let jsCode: String
        if let callbackId = callbackId, !callbackId.isEmpty {
            jsCode = "window.TBridge?.onNativeCallback(JSON.parse('\(escapedJson)'))"
        } else {
            jsCode = "window.TBridge?.onCallFromNative(JSON.parse('\(escapedJson)'))"
        }
        
        // 在主线程执行 JS
        DispatchQueue.main.async {
            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("TBridge: JS 执行失败 - \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * 序列化参数
     * 
     * 支持类型：
     * - 字典、数组（直接使用）
     * - 基本类型（String, Int, Double, Bool, NSNull）
     * - 其他类型（转换为字符串）
     */
    private func serializeParams(_ params: Any?) -> Any {
        guard let params = params else { return NSNull() }
        
        // 检查是否可以直接序列化
        if JSONSerialization.isValidJSONObject(params) {
            return params
        } else if params is String || params is Int || params is Double || params is Bool || params is NSNull {
            return params
        } else {
            // 无法序列化，转换为字符串
            return String(describing: params)
        }
    }
}
