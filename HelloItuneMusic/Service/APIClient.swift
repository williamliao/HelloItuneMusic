//
//  APIClient.swift
//  HelloItuneMusic
//
//  Created by 雲端開發部-廖彥勛 on 2022/1/20.
//

import Foundation

enum NetworkError: Error {
    case apiSuccess
    case requestFailed
    case jsonConversionFailure
    case invalidData
    case responseUnsuccessful
    case jsonParsingFailure
    case sessionError(Error)
    case backendError(Error)
    case generic(Error)
    case network(Error?)
    case statusCodeError(Int)
    case unsupportedURL
    case noHTTPResponse
    case badData
    case queryTimeLimit
    case notModified // 304
    case badRequest //400
    case unAuthorized //401
    case forbidden //403
    case notFound //404
    case methodNotAllowed // 405
    case timeOut //408
    case unSupportedMediaType //415
    case validationFailed // 422
    case rateLimitted //429
    case serverError //500
    case serverUnavailable //503
    case gatewayTimeout //504
    case networkAuthenticationRequired //511
    case invalidImage
    case invalidMetadata
    case invalidToken
    case invalidURLRequest
    case invalidURL
    case unKnown
}

class APIClient {
    
    let session: URLSession
    let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    let successCodes: CountableRange<Int> = 200..<299
    let failureClientCodes: CountableRange<Int> = 400..<499
    let failureBackendCodes: CountableRange<Int> = 500..<511
    
    func fetch<T: Decodable>(_ endpoint: URL, decode: @escaping (Decodable) -> T?) async throws -> Result<T, NetworkError> {
        
        try Task.checkCancellation()
        
        do {
            return try await withCheckedThrowingContinuation({
                (continuation: CheckedContinuation<(Result<T, NetworkError>), Error>) in
                loadRequest(endpoint, decode: decode) { result in
                    switch result {
                        case .success(let data):
                            continuation.resume(returning: .success(data))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                    }
                }
            })
        } catch {
            print("fetch error \(error)")
            return Result.failure(NetworkError.unKnown)
        }
    }
}

// MARK: - Private
extension APIClient {
    
    private func loadRequest<T: Decodable>(_ endpoint: URL, decode: @escaping (Decodable) -> T?, then handler: @escaping (Result<T, NetworkError>) -> Void) {
        
        let request = clientURLRequest(url: endpoint)
        
        let task = decodingTask(with: request, decodingType: T.self) { (json , error) in
            
            DispatchQueue.main.async {
                guard let json = json else {
                    if let error = error {
                        handler(Result.failure(error))
                    }
                    return
                }

                if let value = decode(json) {
                    handler(.success(value))
                }
            }
        }
        task.resume()
    }
    
    private func clientURLRequest(url: URL) -> URLRequest {
        
        let request = NSMutableURLRequest(url: url,
                                              cachePolicy: .useProtocolCachePolicy,
                                              timeoutInterval: 10.0)
        return request as URLRequest
    }
    
    private func decodingTask<T: Decodable>(with request: URLRequest, decodingType: T.Type, completionHandler completion: @escaping (Decodable?, NetworkError?) -> ()) -> URLSessionDataTask {
     
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            
            guard error == nil else {
                let errorString = (error! as NSError).userInfo["NSLocalizedDescription"]
                let code = (error! as NSError).code
                let LocalizedError = NSError(domain:"NetworkService", code:code, userInfo:[ NSLocalizedDescriptionKey: errorString ?? "URLSession Error"])
                print("Error: \(String(describing: errorString))")
                completion(nil, .sessionError(LocalizedError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, .requestFailed)
                return
            }
          
            if self.successCodes.contains(httpResponse.statusCode) {
                if let data = data {
                    do {
                        let genericModel = try decoder.decode(decodingType, from: data)
                        completion(genericModel, nil)
                    } catch DecodingError.dataCorrupted(let context) {
                        print(context.debugDescription)
                        completion(nil, .jsonParsingFailure)
                    } catch DecodingError.keyNotFound(let key, let context) {
                        print("\(key.stringValue) was not found, \(context.debugDescription)")
                        completion(nil, .jsonParsingFailure)
                    } catch DecodingError.typeMismatch(let type, let context) {
                        print("\(type) was expected, \(context.debugDescription)")
                        completion(nil, .jsonParsingFailure)
                    } catch DecodingError.valueNotFound(let type, let context) {
                        print("no value was found for \(type), \(context.debugDescription)")
                        completion(nil, .jsonParsingFailure)
                    } catch {
                        print(error)
                        completion(nil, .jsonParsingFailure)
                    }
                } else {
                    completion(nil, .invalidData)
                }
            } else {
                completion(nil, handleHTTPResponse(statusCode: httpResponse.statusCode))
            }
        }
            return task
    }
    
    private func handleHTTPResponse(statusCode: Int) -> NetworkError {
        
        if failureClientCodes.contains(statusCode) { //400..<499
            switch statusCode {
                case 401:
                    return NetworkError.unAuthorized
                case 403:
                    return NetworkError.forbidden
                case 404:
                    return NetworkError.notFound
                case 405:
                    return NetworkError.methodNotAllowed
                case 408:
                    return NetworkError.timeOut
                case 415:
                    return NetworkError.unSupportedMediaType
                case 422:
                    return NetworkError.validationFailed
                case 429:
                    return NetworkError.rateLimitted
                default:
                    return NetworkError.statusCodeError(statusCode)
            }
            
        } else if failureBackendCodes.contains(statusCode) { //500..<511
            switch statusCode {
                case 500:
                    return NetworkError.serverError
                case 503:
                    return NetworkError.serverUnavailable
                case 504:
                    return NetworkError.gatewayTimeout
                case 511:
                    return NetworkError.networkAuthenticationRequired
                default:
                    return NetworkError.statusCodeError(statusCode)
            }
        } else {
            
            if statusCode == 999 {
                return NetworkError.unKnown
            }
            
            // Server returned response with status code different than expected `successCodes`.
            let info = [
                NSLocalizedDescriptionKey: "Request failed with code \(statusCode)",
                NSLocalizedFailureReasonErrorKey: "Wrong handling logic, wrong endpoint mapping."
            ]
            let error = NSError(domain: "NetworkService", code: statusCode, userInfo: info)
            return NetworkError.network(error)
        }
    }
}
