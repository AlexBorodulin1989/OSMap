//
//  TileRequest.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 28.09.2022.
//

import Combine
import Foundation

class RequestTileSubscriber: Subscriber {
    typealias Input = Data
    typealias Failure = Error

    var subscription: Subscription?

    func receive(subscription: Subscription) {
        print("Received subscription")
        self.subscription = subscription
        subscription.request(.max(1))
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        print("Received value: \(input)")
        return .none
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        print("Received completion \(completion)")
    }

    func cancel() {
        subscription?.cancel()
        subscription = nil
    }

    deinit {
        Swift.print("deinit RequestTileSubscriber subscriber")
    }
}

extension URLSession {
    struct RequestTilePublisher: Publisher {
        typealias Output = Data
        typealias Failure = Error

        let urlRequest: URLRequest

        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = RequestTileSubscription(urlRequest: urlRequest, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    func decodedDataTaskPublisher(for urlRequest: URLRequest) -> RequestTilePublisher {
        return RequestTilePublisher(urlRequest: urlRequest)
    }
}

extension URLSession.RequestTilePublisher {
    class RequestTileSubscription<S: Subscriber>: Subscription where S.Failure == Error
    {
        typealias Output = Data

        private let urlRequest: URLRequest
        private var subscriber: S?

        init(urlRequest: URLRequest, subscriber: S) {
            self.urlRequest = urlRequest
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            if demand > 0 {
                requestTile {[weak self] res, error in
                    guard let self = self,
                          let subscriber = self.subscriber
                    else {
                        return
                    }

                    if res == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
                            self?.request(demand)
                        }
                    } else {
                        let demand = subscriber.receive(res as! S.Input)
                        subscriber.receive(completion: .finished)

                        if demand == 0 {
                            self.cancel()
                        }
                    }
                }
            }
        }

        func requestTile(completion: @escaping ((Output?, Error?) -> Void)) {
            URLSession.shared.dataTask(with: urlRequest) {data, response, error in
                if let data = data {
                    completion(data, nil)
                } else {
                    completion(nil, error)
                }
            }.resume()
        }

        func cancel() {
            subscriber = nil
        }
    }
}