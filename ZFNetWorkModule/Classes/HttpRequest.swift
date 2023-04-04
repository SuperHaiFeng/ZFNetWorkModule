//
//  HttpRequest.swift
//  SwiftNetWorkArch
//
//  Created by macode on 2021/11/9.
//

import UIKit
import HandyJSON
import RxSwift
import RxCocoa
import Alamofire
import ZFCommonModule

protocol RequestDataProtocol {
    var dataRequest: DataRequest { get }
}

public class RequestDataHandle<T: HandyJSON>: RequestDataProtocol {
    public let dataRequest: DataRequest
    public let observerData: Single<T>
    
    public init(request: DataRequest, observer: Single<T>) {
        self.dataRequest = request
        self.observerData = observer
    }
}

public class RequestDataHandles<T: HandyJSON>: RequestDataProtocol {
    public let dataRequest: DataRequest
    public let observerData: Single<[T]>
    
    public init(request: DataRequest, observer: Single<[T]>) {
        self.dataRequest = request
        self.observerData = observer
    }
}

open class HttpRequest {
    let host: String
    public init(host: String) {
        self.host = host
    }
    
    private func url(url: String) -> String {
        if url.hasPrefix("http") {
            return url
        }
        return host + url
    }
    
    /// http request
    /// - Parameters:
    ///   - url: 请求的地址
    ///   - method: 请求的方法, 默认POST
    ///   - parameters: 请求参数
    ///   - header: 请求的header
    ///   - designatedPath: json解析为model时从哪个字段下开始解析, 默认为""
    @discardableResult
    public func request<T: HandyJSON>(url: String,
                                      method: HTTPMethod = .get,
                                      parameters: [String: Any]? = nil,
                                      header: HTTPHeaders? = nil,
                                      designatedPath: String = "") -> RequestDataHandle<T> {
        let encoding: ParameterEncoding = method == .get ? URLEncoding.default : JSONEncoding.default
        let task = AlamofireManager.default.session.request(self.url(url: url), method: method, parameters: parameters, encoding: encoding, headers: header, interceptor: nil, requestModifier: nil)
        let observer = Single<T>.create { observer in
            task.responseData { response in
                self.processData(data: response, designatedPath: designatedPath, observer: observer)
            }
            return Disposables.create {
                task.cancel()
            }
        }
        return RequestDataHandle(request: task, observer: observer)
    }
    
    /// 请求参数为数组的网络请求
    /// - Parameters:
    ///   - url: 请求的地址
    ///   - method: 请求的方法, 默认POST
    ///   - parameters: 请求参数
    ///   - header: 请求的header
    ///   - designatedPath: json解析为model时从哪个字段下开始解析, 默认为""
    @discardableResult
    public func request<T: HandyJSON>(url: String,
                                      method: HTTPMethod = .get,
                                      parameters: [Any],
                                      header: HTTPHeaders? = nil,
                                      designatedPath: String = "") -> RequestDataHandle<T> {
        let task = AlamofireManager.default.session.request(self.url(url: url), method: method, parameters: parameters.asParameters(), encoding: ArrayEncoding.default, headers: header, interceptor: nil, requestModifier: nil)
        let observer = Single<T>.create { observer in
            task.responseData { response in
                self.processData(data: response, designatedPath: designatedPath, observer: observer)
            }
            return Disposables.create {
                task.cancel()
            }
        }
        return RequestDataHandle(request: task, observer: observer)
    }

    /// 请求返回数据为数组
    /// - Parameters:
    ///   - url: 请求的地址
    ///   - method: 请求的方法, 默认POST
    ///   - parameters: 请求参数
    ///   - header: 请求的header
    ///   - designatedPath: json解析为model时从哪个字段下开始解析, 默认为""
    @discardableResult
    public func request<T: HandyJSON>(url: String,
                                      method: HTTPMethod = .get,
                                      parameters: [String: Any]? = nil,
                                      header: HTTPHeaders? = nil,
                                      designatedPath: String = "") -> RequestDataHandles<T> {
        let encoding: ParameterEncoding = method == .get ? URLEncoding.default : JSONEncoding.default
        let task = AlamofireManager.default.session.request(self.url(url: url), method: method, parameters: parameters, encoding: encoding, headers: header, interceptor: nil, requestModifier: nil)
        let observer = Single<[T]>.create { observer in
            task.responseData { response in
                self.processDataArray(data: response, designatedPath: designatedPath, observer: observer)
            }
            return Disposables.create {
                task.cancel()
            }
        }
        return RequestDataHandles(request: task, observer: observer)
    }
    
    /// 上传图片
    /// - parameters: 上传图片的组合model
    /// - Returns: 返回task和监听数据
    @discardableResult
    public func updateImage<T: HandyJSON>(upload: UploadImageModel) -> RequestDataHandle<T> {
        let imageName = "image.\(upload.imageFormat)"
        var parameters = ["type": upload.type.data(using: .utf8)!]
        parameters["format"] = upload.imageFormat.rawValue.data(using: .utf8)!
        parameters["from_camera"] = (upload.fromCamera ? "true" : "false").data(using: .utf8)!
        if let usescence = upload.usescenes {
            parameters["usescence"] = usescence.data(using: .utf8)!
        }
        return update(url: upload.uploadUrl, data: upload.imageData, fileName: imageName, parameters: parameters)
    }
    
    
    /// 上传文件
    /// - Parameters:
    ///   - url: 上传的url
    ///   - data:  数据
    ///   - fileName: 文件名
    ///   - parameters: 参数
    /// - Returns: 上传任务task 和 可监听数据
    @discardableResult
    public func update<T: HandyJSON>(url: String,
                                     data: Data,
                                     fileName: String,
                                     parameters: [String: Data]) -> RequestDataHandle<T> {
        let headers: HTTPHeaders
        headers = ["Content-type": "multipart/form-data",
                   "Content-Disposition": "form-data"]
        let task = AlamofireManager.default.session.upload(multipartFormData: { formdata in
            formdata.append(data, withName: "file", fileName: fileName, mimeType: "multipart/form-data")
            parameters.forEach({ formdata.append($0.value, withName: $0.key) })
        }, to: url, headers: headers)
        
        let observer = Single<T>.create { observer in
            task.responseData { response in
                self.processData(data: response, observer: observer)
            }
            return Disposables.create {
                task.cancel()
            }
        }
        return RequestDataHandle(request: task, observer: observer)
    }
    
    /// 下载文件
    /// - Parameters:
    ///   - downloadUrl: 要下载文件的url
    ///   - destinationPath: 将下载的文件要保存在本地的路径包括文件名和extensino
    ///   - parameters 参数
    @discardableResult
    public func download<Parameters: Encodable>(downloadUrl: String,
                                                destinationPath: String,
                                                parameters: Parameters) -> DownloadRequest {
        return AlamofireManager.default.session.download(downloadUrl, parameters: parameters, to: createDestination(destinationPath: destinationPath))
    }
    
    /// 创建下载文件到目的地路径
    /// - Parameter destinationPath: 目的地路径
    /// - Returns: <#description#>
    public func createDestination(destinationPath: String) -> DownloadRequest.Destination {
        let destination: DownloadRequest.Destination = { _, response in
            let destinationUrl: URL = URL(fileURLWithPath: destinationPath)
            return (destinationUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }
}

extension HttpRequest {
    /// 数据解析
    func processData<T: HandyJSON>(data: AFDataResponse<Data>,
                                   designatedPath: String = "",
                                   observer: (Result<T, Error>) -> Void) {
        if data.response?.statusCode == 200 {
            if let model: T = self.jsonToModel(data: data.value, designatedPath: designatedPath) {
                observer(.success(model))
            } else {
                observer(.failure(processError(data: data)))
            }
        } else {
            observer(.failure(processError(data: data)))
        }
    }
    
    /// 请求失败解析
    func processError(data: AFDataResponse<Data>) -> Error {
        guard let error = data.error else {
            let unknownError = NSError(domain: "", code: -1, userInfo: ["msg": "unknown http error"])
            return unknownError
        }
        let tipMsg = ResponseError.tipMsg(errorCode: data.response?.statusCode ?? 0)
        print("toast\(tipMsg)")
        return error
    }
    
    /// 解析数据为数组的数据
    func processDataArray<T: HandyJSON>(data: AFDataResponse<Data>,
                                        designatedPath: String = "",
                                        observer: (Result<[T], Error>) -> Void) {
        if data.response?.statusCode == 200 {
            let model: [T] = self.jsonToModels(data: data.value, designatedPath: designatedPath)
            observer(.success(model))
        } else {
            observer(.failure(processError(data: data)))
        }
    }
    
    /// 序列化数组
    func jsonToModels<T: HandyJSON>(data: Data?,
                                   designatedPath: String = "") -> [T] {
        guard let data = data, let jsonStr = String(data: data, encoding: .utf8) else { return [] }
        let model: [T] = [T].deserialize(from: jsonStr, designatedPath: designatedPath) as? [T] ?? []
        return model
    }
    
    /// 序列化数据
    open func jsonToModel<T: HandyJSON>(data: Data?,
                                        designatedPath: String = "") -> T? {
        guard let data = data, let jsonStr = String(data: data, encoding: .utf8) else { return nil }
        if let model: T = T.deserialize(from: jsonStr, designatedPath: designatedPath) {
            return model
        }
        return nil
    }
}

open class ResponseError: NSObject {
    public static let errorMultideviceLogin = 92016     // 多设备登录
    
    class func tipMsg(errorCode: Int) -> String {
        var errorMsg = ""
        switch errorCode {
        case 80003: errorMsg = "参数不对"
        case 80005: errorMsg = "验证码不对"
        case 82001: errorMsg = "feed不存在"
        case 82002: errorMsg = "用户没有权限发feed"
        case 82003: errorMsg = "用户没有权限评论"
        case 82004: errorMsg = "feed不允许评论"
        case 82005: errorMsg = "feed不允许分享"
        case 83001: errorMsg = "tag不存在"
        case 83002: errorMsg = "category不存在"
        case 83003: errorMsg = "非法tag"
        case 84001: errorMsg = "图片不存在"
        default:
            errorMsg = "\(errorCode) unknown"
        }
        return errorMsg
    }
}


