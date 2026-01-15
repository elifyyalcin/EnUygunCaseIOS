//
//  ProductService.swift
//  EnUygunCaseIOS
//
//  Created by Elif Alaboyun on 14.01.2026.
//

import Foundation
import RxSwift

// MARK: - Service Protocol

protocol ProductsServiceType {
    func fetchAll() -> Observable<[Product]>
    func search(query: String) -> Observable<[Product]>
}

// MARK: - Response Models

private struct ProductsResponse: Decodable {
    let products: [Product]
}

// MARK: - Product Model

struct Product: Decodable, Equatable {
    let id: Int
    let title: String
    let price: Double
    let description: String?
    let discountPercentage: Double?
    let thumbnail: String?
    let images: [String]?
}

// MARK: - Service Implementation

final class ProductsService: ProductsServiceType {
    
    private let baseURL = URL(string: "https://dummyjson.com")!

    func fetchAll() -> Observable<[Product]> {
        
        let url = baseURL.appendingPathComponent("products")
        return request(url: url).map { $0.products }
    }

    func search(query: String) -> Observable<[Product]> {

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .just([])
        }

        var comps = URLComponents(url: baseURL.appendingPathComponent("products/search"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "q", value: trimmed)
        ]

        guard let url = comps.url else {
            return .error(NSError(domain: "BadURL", code: -2))
        }

        return request(url: url).map { $0.products }
    }

    private func request(url: URL) -> Observable<ProductsResponse> {

        Observable.create { observer in

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.timeoutInterval = 30

            let task = URLSession.shared.dataTask(with: req) { data, response, error in

                if let error {
                    observer.onError(error)
                    return
                }

                if let http = response as? HTTPURLResponse,
                   !(200...299).contains(http.statusCode) {
                    observer.onError(NSError(domain: "HTTPError", code: http.statusCode))
                    return
                }

                guard let data else {
                    observer.onError(NSError(domain: "NoData", code: -1))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode(ProductsResponse.self, from: data)

                    observer.onNext(decoded)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
