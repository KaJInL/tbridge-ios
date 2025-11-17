//
//  OnTBridgeMessage.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation

/**
 * TBridge 消息处理协议
 * 
 * 业务层需要实现此协议来处理来自 JS 的调用
 * 
 * 示例：
 * ```swift
 * class MessageHandler: OnTBridgeMessage {
 *     func onTBridgeMessage(method: String, params: String?, callbackId: String?, callback: TBridgeCallback) throws {
 *         switch method {
 *         case "getDeviceInfo":
 *             // 处理逻辑
 *             callback.onSuccess(params: deviceInfo)
 *         default:
 *             callback.onError(params: ["error": "Unknown method"])
 *         }
 *     }
 * }
 * ```
 */
public protocol OnTBridgeMessage {
    /**
     * 处理来自 JS 的调用
     * 
     * - Parameters:
     *   - method: 方法名
     *   - params: 参数字符串（JSON 格式），需要业务层自行解析
     *   - callbackId: 回调 ID，如果有值，TBridge 会自动处理回调
     *   - callback: 回调接口，用于返回结果给 JS
     * 
     * - Throws: 如果处理过程中发生错误，可以抛出异常
     * 
     * 注意：
     * - 如果有 callbackId，必须调用 callback.onSuccess() 或 callback.onError()
     * - 如果没有 callbackId，可以不调用回调（单向调用）
     */
    func onTBridgeMessage(
        method: String,
        params: String?,
        callbackId: String?,
        callback: TBridgeCallback
    ) throws
}

/**
 * TBridge 回调协议
 * 
 * 用于将处理结果返回给 JS
 * 
 * 设计原则：
 * - 只传递业务数据（params），不包含业务字段（code, message, isSuccess）
 * - 业务字段由业务层在 params 中自行定义
 */
public protocol TBridgeCallback {
    /**
     * 成功回调
     * 
     * - Parameter params: 返回的业务数据（任意类型）
     * 
     * 示例：
     * ```swift
     * callback.onSuccess(params: [
     *     "code": 20000,
     *     "message": "Success",
     *     "isSuccess": true,
     *     "data": result
     * ])
     * ```
     */
    func onSuccess(params: Any?)
    
    /**
     * 失败回调
     * 
     * - Parameter params: 错误信息（任意类型，业务层自己定义结构）
     * 
     * 示例：
     * ```swift
     * callback.onError(params: [
     *     "code": 40000,
     *     "message": "Error message",
     *     "isSuccess": false,
     *     "data": NSNull()
     * ])
     * ```
     */
    func onError(params: Any?)
}
