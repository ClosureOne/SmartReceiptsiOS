//
//  ReceiptMoveCopyInteractor.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 22/06/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import Foundation
import Viperit
import RxSwift

class ReceiptMoveCopyInteractor: Interactor {
    
    let disposeBag = DisposeBag()
    
    func configureSubscribers() {
        presenter.tripTapSubject.subscribe(onNext: { [unowned self] trip in
            if self.presenter.isCopyOrMove {
                Database.sharedInstance().copy(self.presenter.receipt, to: trip)
            } else {
                Database.sharedInstance().move(self.presenter.receipt, to: trip)
            }
            self.presenter.close()
        }).disposed(by: disposeBag)
    }
    
    func fetchedModelAdapter(for receipt: WBReceipt) -> FetchedModelAdapter {
        return presenter.isCopyOrMove ?
            Database.sharedInstance().fetchedAdapterForAllTrips() :
            Database.sharedInstance().fetchedAdapter(forAllTripsExcluding: receipt.trip)
    }
    
}

// MARK: - VIPER COMPONENTS API (Auto-generated code)
private extension ReceiptMoveCopyInteractor {
    var presenter: ReceiptMoveCopyPresenter {
        return _presenter as! ReceiptMoveCopyPresenter
    }
}
