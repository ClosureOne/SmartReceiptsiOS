//
//  DebugView.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 03/09/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import UIKit
import Viperit
import RxSwift
import RxCocoa

//MARK: - Public Interface Protocol
protocol DebugViewInterface {
    var loginTap: Observable<Void> { get }
    var subscriptionChange: Observable<Bool> { get }
}

//MARK: DebugView Class
final class DebugView: UserInterface {
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    fileprivate var formView: DebugFormView?
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        
        formView = DebugFormView()
        
        addChildViewController(formView!)
        view.addSubview(formView!.view)
        configureUIActions()
        
        super.viewDidLoad()
    }
    
    private func configureUIActions() {
        closeButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: bag)
    }
    
    
    
}

//MARK: - Public interface
extension DebugView: DebugViewInterface {
    var loginTap: Observable<Void> { return formView!.rx.loginTap }
    var subscriptionChange: Observable<Bool> { return formView!.rx.subscriptionChange }
}

// MARK: - VIPER COMPONENTS API (Auto-generated code)
private extension DebugView {
    var presenter: DebugPresenter {
        return _presenter as! DebugPresenter
    }
    var displayData: DebugDisplayData {
        return _displayData as! DebugDisplayData
    }
}