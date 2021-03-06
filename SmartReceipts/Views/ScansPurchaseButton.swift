//
//  ScansPurchaseButton.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 27/10/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import UIKit
import RxSwift

class ScansPurchaseButton: UIButton {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet fileprivate weak var price: UILabel!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
 
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        layer.cornerRadius = 7
        
        rx.controlEvent(.touchDown)
            .subscribe(onNext: { [unowned self] in
                self.backgroundColor  = AppTheme.buttonStyle1PressedColor
            }).disposed(by: bag)
    
        rx.controlEvent([.touchUpInside, .touchUpOutside])
            .subscribe(onNext: { [unowned self] in
                self.backgroundColor  = AppTheme.buttonStyle1NormalColor
            }).disposed(by: bag)
    }
    
    func setScans(count: Int) {
        let titleFormat = LocalizedString("ocr.configuration.module.purchase.title")
        title.text = String(format: titleFormat, count)
        
        let subtitleFormat = LocalizedString("ocr.configuration.module.purchase.subtitle")
        subtitle.text = String(format: subtitleFormat, count)
    }
}

extension Reactive where Base: ScansPurchaseButton {
    var price: AnyObserver<String> {
        return AnyObserver<String>(onNext: { [unowned base] price in
            base.price.text = price
            base.activityIndicator.stopAnimating()
        })
    }
}
