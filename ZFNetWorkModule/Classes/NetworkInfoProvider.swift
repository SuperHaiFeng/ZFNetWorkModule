//
//  NetworkInfoProvider.swift
//  SwiftNetWorkArch
//
//  Created by macode on 2021/11/9.
//

import UIKit

/// 网络请求信息 Provider
public protocol NetworkInfoProvider {
    
    /// 获取用户token
    func obtainUserToken() -> String
    
    /// 设置默认参数
    /// - Parameter defaultParams: defaultParams description
    func setupDefaultParams(defaultParams: [String: Any])
    
    /// 设置通用参数
    /// - Parameter commonParams: commonParams description
    func setupCommonParams(commonParams: [String: Any])
}


/// 默认的网络参数 Provider
open class DefaultNetworkParamsProvider : NetworkInfoProvider {
    
    open func obtainUserToken() -> String {
        return "loginUserModel.token"
    }
    
    open func setupDefaultParams(defaultParams: [String: Any]) {
        // ui language
//        defaultParams.setValue(CommonMethods.getLanguageCode(), forKey: "ui_lang")
//        // uid
//        defaultParams.setValue(loginUserModel.id, forKey: "uid")
    }
    
    open func setupCommonParams(commonParams: [String: Any]) {
        // 下面都是通用参数, 必须添加
        // 广告唯一标识,作为苹果设备唯一标识参数
//        commonParams.setValue(CommonMethods.deviceDid, forKey: "aid")
//        // 设备名称
//        commonParams.setValue(CommonMethods.deviceName(), forKey: "device")
//        // 唯一标识
//        commonParams.setValue(loginUserModel.did, forKey: "did")
//        // 广告标识
//        commonParams.setValue(MRKeychainManager.appleIDFV(), forKey: "idfv")
//        // 手机语言 (目前Talla项目的lang字段只能取en, 其他语言不能传递)
//
//        commonParams.setValue(UserDefaults.CountryLanguage.string(forKey: .LangToServerKey) , forKey: "lang")
//        // 国家
//        commonParams.setValue(UserDefaults.CountryLanguage.string(forKey: .CountryToServerKey), forKey: "country_code")
//        commonParams.setValue(CommonMethods.getLanguageCode(), forKey: "ui_lang")
//        // 用户id
//        if !loginUserModel.id.isEmpty {
//            commonParams.setValue(loginUserModel.id, forKey: "dud")
//        }
//        commonParams.setValue(MRGeolocationManager.default.codeBySim, forKey: "code_by_sim")
    }
}

