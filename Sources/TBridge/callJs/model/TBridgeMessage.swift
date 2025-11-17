//
//  TBridgeMessage.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation

/**
 * TBridge 消息结构（核心层）
 * 
 * 消息格式：
 * {
 *   "method": "方法名",
 *   "callbackId": "回调 ID（可选）",
 *   "params": "参数（任意类型，由业务层决定）"
 * }
 * 
 * 设计原则：
 * - 核心层只关心消息结构，不关心业务含义
 * - params 可以是任意类型，由业务层自行定义和解析
 */
public struct TBridgeMessage {
    /// 方法名
    public let method: String
    
    /// 回调 ID，如果有值，表示需要回调
    public let callbackId: String?
    
    /// 业务数据，由业务层决定结构
    public let params: Any?
}
