//
//  ChartRequests.swift
//  BillboardSwiftLibrary
//
//  Created by Fitzgerald Afful on 16/11/2018.
//

import Foundation


let BASE_URL = "http://www.billboard.com/charts/"

struct ChartParameter {
	var name: String
	var date: String
}

struct ChartRequest: ApiRequest {
	let parameter: ChartParameter
	
	var urlRequest: URLRequest {
		let url: URL! = URL(string: BASE_URL + parameter.name + "/" + parameter.date)
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		
		return request
	}
}





protocol ApiRequest {
	var urlRequest: URLRequest { get }
}

protocol ApiClient {
	func execute<T>(request: ApiRequest, completionHandler: @escaping (_ result: Result<ApiResponse<T>>) -> Void)
	func execute(request: ApiRequest, completionHandler: @escaping (_ result: Result<String>) -> Void)
}

protocol URLSessionProtocol {
	func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol { }

class ApiClientImplementation: ApiClient {
	let urlSession: URLSessionProtocol
	
	init(urlSessionConfiguration: URLSessionConfiguration, completionHandlerQueue: OperationQueue) {
		urlSession = URLSession(configuration: urlSessionConfiguration, delegate: nil, delegateQueue: completionHandlerQueue)
	}
	
	// This should be used mainly for testing purposes
	init(urlSession: URLSessionProtocol) {
		self.urlSession = urlSession
	}
	
	// MARK: - ApiClient
	
	func execute<T>(request: ApiRequest, completionHandler: @escaping (Result<ApiResponse<T>>) -> Void) {
		let dataTask = urlSession.dataTask(with: request.urlRequest) { (data, response, error) in
			guard let httpUrlResponse = response as? HTTPURLResponse else {
				completionHandler(.failure(NetworkRequestError(error: error)))
				return
			}
			
			let successRange = 200...299
			if successRange.contains(httpUrlResponse.statusCode) {
				do {
					let response = try ApiResponse<T>(data: data, httpUrlResponse: httpUrlResponse)
					completionHandler(.success(response))
				} catch {
					completionHandler(.failure(error))
				}
			} else {
				completionHandler(.failure(ApiError(data: data, httpUrlResponse: httpUrlResponse)))
			}
		}
		dataTask.resume()
	}
	
	func execute(request: ApiRequest, completionHandler: @escaping (Result<String>) -> Void) {
		let dataTask = urlSession.dataTask(with: request.urlRequest) { (data, response, error) in
			guard let httpUrlResponse = response as? HTTPURLResponse else {
				completionHandler(.failure(NetworkRequestError(error: error)))
				return
			}
			
			let successRange = 200...299
			if successRange.contains(httpUrlResponse.statusCode) {
				if let response:String = String(data: data!, encoding: .utf8) {
					completionHandler(.success(response))
				}else {
					completionHandler(.failure(error!))
				}
			} else {
				completionHandler(.failure(ApiError(data: data, httpUrlResponse: httpUrlResponse)))
			}
		}
		dataTask.resume()
	}
}
