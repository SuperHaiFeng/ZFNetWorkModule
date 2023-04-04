//
//  ArrayEncoding.swift
//  SwiftNetWorkArch
//
//  Created by macode on 2022/1/13.
//

import UIKit
import Alamofire

//MARK:  post请求参数为数组时的请求

private let arrayParametersKey = "arrayParametersKey"

extension Array {
    func asParameters() -> Parameters {
        return [arrayParametersKey: self]
    }
}

class ArrayEncoding: ParameterEncoding {
    public static let `default` = ArrayEncoding()
 
    public let options: JSONSerialization.WritingOptions
 
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }
 
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
 
        guard let parameters = parameters,
            let array = parameters[arrayParametersKey] else {
                return urlRequest
        }
 
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: options)
 
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
 
            urlRequest.httpBody = data
 
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
 
        return urlRequest
    }
}
