//
//  RxSwift+Extensions.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 24/09/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import RxSwift

extension AnyObserver {
    init(onNext: ((E) -> Swift.Void)? = nil, onError: ((Error) -> Swift.Void)? = nil, onCompleted: (() -> Swift.Void)? = nil) {
        self.init { event in
            switch event {
            case .next(let element):
                onNext?(element)
            case .error(let error):
                onError?(error)
            case .completed:
                onCompleted?()
            }
        }
    }
}
