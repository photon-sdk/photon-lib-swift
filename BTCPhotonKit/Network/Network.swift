//
//  Network.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 05/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

/// Network class is singleton instance wich adds open api to ensure the all third part calls wrapped to create rerquest from here
struct NetWork{

    // private instance
    private static var shared:NetworkingLayer  = NetworkingLayer()

    /// if you want to make a mock session as of now you cam add it here
    /// then onwords all the calls will use the same mock session , until updated
    public static func addCustomSession(_ session:URLSession){
        NetWork.shared.session = session
    }


    /// If you have to use a body from a class data
    /// or struct use this method
    @discardableResult
    public static func request<ResponseDecodable: Decodable,
                        RequestEncodable:Encodable>(
        _ url: String,
        path:String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        body:RequestEncodable? = nil,
        encoding:NetworkEncodingType = .json,
        headers: [String: Any]? = nil,
        responseType:ResponseDecodable.Type,
        completion :@escaping (Result<ResponseDecodable, APIError>) -> Void) -> APIRequest{
        // create a requestBody with the given object
        // if the object exists
        var requestBody:NetworkBody? = nil
        if let body = body {
            requestBody = try? NetworkBody(object: body, encoding:encoding )
        }
        // invoke the request with request body
        return request(url, path: path,
                       method: method,
                       parameters: parameters,
                       requestBody: requestBody,
                       headers: headers,
                       responseType:responseType,
                       completion: completion)


    }
    // If you have to use a body from a diction0ry
    // use the this method
    @discardableResult
    public static func request<ResponseDecodable: Decodable>(
        _ url: String,
        path:String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        body:[String: Any]?,
        encoding:NetworkEncodingType = .json,
        headers: [String: Any]? = nil,
        responseType:ResponseDecodable.Type,
        completion :@escaping (Result<ResponseDecodable, APIError>) -> Void) -> APIRequest{

        // create a requestBody with the given dictionary
        // if the dictionary exists
        var requestBody:NetworkBody? = nil
        if let body = body {
            requestBody = try? NetworkBody(dictionary: body, encoding:encoding )
        }
        // invoke the request with request body
        return request(url, path: path,
                       method: method,
                       parameters: parameters,
                       requestBody: requestBody,
                       headers: headers,
                       responseType:responseType,
                       completion: completion)



    }

    // If you have to use a custom network body
    // use the this method
    @discardableResult
    public static func request<ResponseDecodable: Decodable>(
        _ url: String,
        path:String = "",
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        requestBody:NetworkBody? = nil,
        headers: [String: Any]? = nil,
        responseType:ResponseDecodable.Type,
        completion :@escaping (Result<ResponseDecodable, APIError>) -> Void ) -> APIRequest{


        // Create an APi request out network client can use
        let request  = APIRequest(url:url,
                                  path: path,
                                  method: method,
                                  parameters: parameters,
                                  body: requestBody)


        // use the shared networklayer to call the api
        shared.sendRequest(request: request,
                           responseType: responseType,
                           completion: completion)


        return request;


    }
}
