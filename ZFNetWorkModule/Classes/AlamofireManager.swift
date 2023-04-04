//
//  AlamofireManager.swift
//  SwiftNetWorkArch
//
//  Created by macode on 2021/11/9.
//

import Alamofire
import Foundation

/// Alamofire 网络请求 SessionManager, 根据http或者 https 类型进行不同的Alamofire配置
/// 普通的业务网络请求可以使用 default 实例, 用于上传的请求可以单独构建一个实例
public class AlamofireManager: NSObject {
    public static let `default` = AlamofireManager()

    private var cerFileNames: [String] = []
    private var certificates: [SecCertificate] = []
    public var session: Alamofire.Session!
    
    override init() {
        super.init()
    }
    
    /// 初始化网络配置
    /// - Parameters:
    ///   - useHttp: 是否强制使用http请求
    ///   - cerFileNames: https公钥证书文件名
    ///   - serverTrustHost: 可信任的域名列表
    public func initialize(userHttp: Bool = false, cerFileNames: [String] = [], trustedHosts: [String] = []) {
        self.cerFileNames = cerFileNames
        let certificates = createCertificates()
        if certificates.count <= 0 || userHttp {
            /// 使用http
            session = Alamofire.Session.default
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.headers = Alamofire.HTTPHeaders.default
            /// 证书校验
            let serverPolicy = PinnedCertificatesTrustEvaluator(certificates: certificates, acceptSelfSignedCertificates: true, performDefaultValidation: true, validateHost: true)
            var serverTrustEvaluator: [String: PinnedCertificatesTrustEvaluator] = [:]
            trustedHosts.forEach({ serverTrustEvaluator[$0] = serverPolicy })
            session = Alamofire.Session(configuration: configuration, interceptor: ParameterRequestInterceptor())
        }
    }
    
    /// 创建https证书列表
    private func createCertificates() -> [SecCertificate] {
        guard certificates.count == 0 else { return certificates }
        certificates = cerFileNames.compactMap({ createCertificate(cerName: $0) })
        return certificates
    }
    
    /// 创建https单个证书
    private func createCertificate(cerName: String) -> SecCertificate? {
        guard let path = Bundle.main.path(forResource: cerName, ofType: "cer"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData else { return nil }
        let certificate = SecCertificateCreateWithData(nil, data)
        return certificate
    }
    
}

class ParameterRequestInterceptor: RequestInterceptor {
    
    /// 一种可以在必要时以某种方式检查和可选地调整 `URLRequest` 的类型。
    /// 以某种方式检查和调整指定的“URLRequest”，并使用结果调用完成处理程序。
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request: URLRequest = urlRequest
        let token = RequestTools.infoProvider.obtainUserToken()
        if !token.isEmpty {
            request.setValue("HIN " + token, forHTTPHeaderField: "Authorization")
        }
        if request.value(forHTTPHeaderField: "Content-type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
        }
        let finalURL = appendParamToUrl(url: request.url?.absoluteString ?? "", params: RequestTools.commonParameters())
        request.url = URL(string: finalURL)
        completion(.success(request))
    }
    
    func appendParamToUrl(url: String, params: [String: Any]) -> String {
        if url.count == 0 || params.count == 0 {
            return url
        }
        
        // common parameters
        var parameterURL = ""
        if url.contains("?") {
            if !url.hasSuffix("?") {
                parameterURL += "&"
            }
        } else {
            parameterURL += "?"
        }
        
        // append key=value
        params.forEach({ parameterURL += "\($0)=\("\($1)".urlEscaped)" })
        // remote last &
        if parameterURL.hasSuffix("&") {
            let index = parameterURL.index(before: parameterURL.endIndex)
            parameterURL = String(parameterURL[..<index])
        }
        return url + parameterURL
    }
    
    ///确定是否应通过调用“完成”闭包重试“请求”。 这个操作是完全异步的。可以花费任何时间来确定请求是否需要重试。一个要求是调用完成闭包以确保请求在之后被正确 /// 清理。
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}


extension String {
    public  var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}
