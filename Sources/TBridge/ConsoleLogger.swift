//
//  ConsoleLogger.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation
import WebKit

/**
 * Console Logger
 * 
 * 功能：
 * - 捕获 JS 的 console.log/error/warn/info/debug
 * - 将日志输出到 Xcode 控制台，方便调试
 */
class ConsoleLogger: NSObject {
    /// 日志标签
    static let TAG = "JSConsole"
    
    /// MessageHandler 名称
    static let HANDLER_NAME = "consoleLogger"
    
    /**
     * 注入 console.log 捕获脚本
     * 
     * - Parameter webView: 要注入脚本的 WebView
     * 
     * 工作原理：
     * 1. 重写 console 的各个方法（log, error, warn, info, debug）
     * 2. 在调用原始方法的同时，通过 messageHandler 发送到原生
     * 3. 原生端接收后输出到 Xcode 控制台
     */
    static func injectConsoleLogger(to webView: WKWebView) {
        let script = """
        (function() {
            var originalLog = console.log;
            var originalError = console.error;
            var originalWarn = console.warn;
            var originalInfo = console.info;
            var originalDebug = console.debug;
            
            function sendToNative(level, args) {
                try {
                    var message = Array.from(args).map(function(arg) {
                        if (typeof arg === 'object') {
                            try {
                                return JSON.stringify(arg, null, 2);
                            } catch (e) {
                                return String(arg);
                            }
                        }
                        return String(arg);
                    }).join(' ');
                    
                    window.webkit.messageHandlers.\(HANDLER_NAME).postMessage({
                        level: level,
                        message: message,
                        timestamp: new Date().toISOString()
                    });
                } catch (e) {
                    // 如果发送失败，使用原始方法
                    originalLog.apply(console, args);
                }
            }
            
            console.log = function() {
                sendToNative('log', arguments);
                originalLog.apply(console, arguments);
            };
            
            console.error = function() {
                sendToNative('error', arguments);
                originalError.apply(console, arguments);
            };
            
            console.warn = function() {
                sendToNative('warn', arguments);
                originalWarn.apply(console, arguments);
            };
            
            console.info = function() {
                sendToNative('info', arguments);
                originalInfo.apply(console, arguments);
            };
            
            console.debug = function() {
                sendToNative('debug', arguments);
                originalDebug.apply(console, arguments);
            };
        })();
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        
        // 注册消息处理器
        webView.configuration.userContentController.add(ConsoleLogger(), name: HANDLER_NAME)
    }
}

// MARK: - WKScriptMessageHandler
extension ConsoleLogger: WKScriptMessageHandler {
    /**
     * 接收来自 JS 的日志消息
     */
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == ConsoleLogger.HANDLER_NAME else { return }
        
        if let body = message.body as? [String: Any],
           let level = body["level"] as? String,
           let logMessage = body["message"] as? String {
            let timestamp = body["timestamp"] as? String ?? ""
            let prefix = "[\(timestamp)] JS \(level.uppercased()):"
            print("\(ConsoleLogger.TAG) \(prefix) \(logMessage)")
        } else if let messageBody = message.body as? String {
            print("\(ConsoleLogger.TAG) [JS]: \(messageBody)")
        }
    }
}
