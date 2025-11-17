//
//  TBridgeMethods.swift
//  TBridge
//
//  Created by lee on 2025/11/12.
//

import Foundation

/**
 * TBridge 方法常量定义
 * 
 * 定义 JS 端需要调用的方法名，保持与 JS 端一致
 */
public struct TBridgeMethods {
    /// 显示 Toast
    public static let SHOW_TOAST = "showToast"
    
    /// 获取设备信息
    public static let GET_DEVICE_INFO = "getDeviceInfo"
    
    /// 原生回调方法（用于有 callbackId 的调用）
    public static let ON_NATIVE_CALLBACK = "onNativeCallback"
    
    /// 原生调用方法（用于无 callbackId 的调用）
    public static let ON_CALL_FROM_NATIVE = "onCallFromNative"
}
