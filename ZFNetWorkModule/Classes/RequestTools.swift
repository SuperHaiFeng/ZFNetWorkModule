//
//  RequestTools.swift
//  SwiftNetWorkArch
//
//  Created by macode on 2021/11/9.
//

import UIKit

public class RequestTools: NSObject {
    public static let `default` = RequestTools()
    private static var theDefaultParams: [String: Any] = [:]
    private static var theCommonParameters: [String: Any] = [:]
    // path 缓存
    var pathCacheDic: [String: Any] = [:]
    // 网络请求token、基本参数 Provider
    static var infoProvider: NetworkInfoProvider! = DefaultNetworkParamsProvider()
    
    private override init() {
        super.init()
    }
    
    /// 设置NetworkInfoProvider [必须设置]
    /// - Parameter provider: provider description
    public class func setInfoProvider(provider: NetworkInfoProvider) {
        RequestTools.infoProvider = provider
    }

    public class var defaultParams: [String: Any] {
        get {
            if theDefaultParams.keys.count == 0 {
                theDefaultParams.merge(commonParameters(), uniquingKeysWith: { $1 })
                // screen size
                theDefaultParams["size"] = RequestTools.calcScreenSize()
                // 分辨率
                theDefaultParams["resolution"] = RequestTools.calcScreenResolution()
            }
            // 设置默认参数
            RequestTools.infoProvider.setupDefaultParams(defaultParams: theDefaultParams)
            return theDefaultParams
        }
        set {
            theDefaultParams.removeAll()
            theDefaultParams.merge(newValue, uniquingKeysWith: { $1 })
        }
    }

    // 公共参数
    class func commonParameters() -> [String: Any] {
        if theCommonParameters.count == 0 {
            // 客户端系统
            theCommonParameters["os"] = "iOS"
            // 系统版本号
            theCommonParameters["os_v"] = UIDevice.current.systemVersion
            if let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")  {
                // app版本号
                theCommonParameters["version"] = shortVersion
                // app版本号和安卓统一参数
                theCommonParameters["app_v"] = shortVersion
            }
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") {
                // app vcode
                theCommonParameters["vcode"] = version
            }
            if let timeZone = NSTimeZone.system.abbreviation() {
                // 时区
                theCommonParameters["timezone"] = timeZone
            }
            // 设备品牌
            theCommonParameters["brand"] = UIDevice.current.model
            if let bundleId = Bundle.main.bundleIdentifier {
                // app bundleID
                theCommonParameters["pkg"] = bundleId
            }
            // channel
            theCommonParameters["channel"] = "appStore"
            // 登录用户的id
//            if loginUserModel.id.isEmpty == false {
//                theCommonParameters.setValue(loginUserModel.id, forKey: "uid")
//            }
        }
        
        if theCommonParameters["uid"] == nil {
//            if loginUserModel.id.isEmpty == false {
//                theCommonParameters.setValue(loginUserModel.id, forKey: "uid")
//            }
        }
        
        RequestTools.infoProvider.setupCommonParams(commonParams: theCommonParameters)
        
        return theCommonParameters
    }

    @discardableResult
    public class func calcScreenResolution() -> String {
        let width = UIScreen.main.nativeBounds.width
        let height = UIScreen.main.nativeBounds.height
        return "\(width)*\(height)"
    }

    public class func calcScreenSize() -> CGFloat {
        let scale = UIScreen.main.scale
        let ppi = scale * (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 132 : 163)
        let width = UIScreen.main.bounds.size.width * scale
        let height = UIScreen.main.bounds.size.height * scale
        let horizontal = width / ppi
        let vertical = height / ppi
        return sqrt(pow(horizontal, 2) + pow(vertical, 2))
    }

    public func path(_ type: String) -> String? {
        return pathCacheDic[type] as? String
    }

    public func setPath(_ type: String, path: String) {
        pathCacheDic[type] = path
    }

    public func deletePath(_ type: String) {
        pathCacheDic.removeValue(forKey: type)
    }
}
