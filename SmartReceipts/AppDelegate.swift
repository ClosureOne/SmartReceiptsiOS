//
//  AppDelegate.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 28/09/2017.
//  Copyright © 2017 Will Baumann. All rights reserved.
//

import Foundation
import Viperit
import Firebase
import UIAlertView_Blocks
import RxSwift
import Crashlytics
import SwiftyStoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static private(set) var instance: AppDelegate!
    
    private let purchaseService = PurchaseService()
    
    fileprivate(set) var filePathToAttach: String?
    fileprivate(set) var isFileImage: Bool = false
    fileprivate var dataImport: DataImport!
    
    var window: UIWindow?
    
    let dataQueue = DispatchQueue(label: "wb.dataAccess")
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        AppDelegate.instance = self
        AppMonitorServiceFactory().createAppMonitor().configure()
        
        AppTheme.customizeOnAppLoad()
        Crashlytics.sharedInstance().debugMode = DebugStates.isDebug
        
        _ = FileManager.initTripsDirectory()
        
        if !Database.sharedInstance().open() {
            NSException(name: NSExceptionName(rawValue: "DBOpenFail"), reason: nil, userInfo: [:]).raise()
        }
        
        RecentCurrenciesCache.shared.update()
        
        Logger.info("Language: \(Locale.preferredLanguages.first!)")
        
        setupCustomExceptionHandler()
        
        purchaseService.cacheSubscriptionValidation()
        purchaseService.logPurchases()
        purchaseService.completeTransactions()
        
        RateApplication.sharedInstance().markAppLaunch()
        PushNotificationService.shared.initialize()
        ScansPurchaseTracker.shared.initialize()
        MigrationService().migrate()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        freeFilePathToAttach()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Database.sharedInstance().close()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.isFileURL {
            if url.pathExtension.isStringIgnoreCaseIn(array: ["png", "jpg", "jpeg"]) {
                Logger.info("Launched for image")
                if DataValidationService().isValidImage(url: url) {
                    isFileImage = true
                    handlePDForImage(url: url)
                } else {
                    Logger.error("Invalid Image for import")
                }
            } else if url.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame {
                Logger.info("Launched for pdf")
                if DataValidationService().isValidPDF(url: url) {
                    isFileImage = false
                    handlePDForImage(url: url)
                } else {
                    Logger.error("Invalid PDF for import")
                }
            } else if url.pathExtension.caseInsensitiveCompare("smr") == .orderedSame {
                Logger.info("Launched for smr")
                handleSMR(url: url)
            } else {
                Logger.info("Loaded with unknown file")
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate {
    func freeFilePathToAttach() {
        guard let path = filePathToAttach else { return }
        FileManager.deleteIfExists(filepath: path)
        filePathToAttach = nil
    }
}

// MARK: Help Methods
extension AppDelegate {
    func handlePDForImage(url: URL) {
        var path = url.path
        
        path = path.hasSuffix("/") ? path.substring(to: path.index(before: path.endIndex)) : path
        filePathToAttach = path
        
        if isFileImage {
            UIAlertView(title: LocalizedString("app.delegate.attach.image.alert.title"),
                        message: LocalizedString("app.delegate.attach.image.alert.message"),
                        delegate: nil,
                        cancelButtonTitle: LocalizedString("generic.button.title.ok")).show()
        } else {
            UIAlertView(title: LocalizedString("app.delegate.attach.pdf.alert.title"),
                        message: LocalizedString("app.delegate.attach.pdf.alert.message"),
                        delegate: nil,
                        cancelButtonTitle: LocalizedString("generic.button.title.ok")).show()
        }
    }
    
    func handleSMR(url: URL) {
        let alert = UIAlertController(title: LocalizedString("app.delegate.import.alert.title"),
          message: LocalizedString("dialog_import_text"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: LocalizedString("generic.button.title.cancel"), style: .cancel, handler: { _ in
            FileManager.deleteIfExists(filepath: url.path)
        }))
        
        alert.addAction(UIAlertAction(title: LocalizedString("generic.button.title.yes"), style: .default, handler: { _ in
            self.importZip(from: url, overwrite: true)
        }))
        
        alert.addAction(UIAlertAction(title: LocalizedString("generic.button.title.no"), style: .default, handler: { _ in
            self.importZip(from: url, overwrite: false)
        }))
        AdNavigationEntryPoint.navigationController?.visibleViewController?.present(alert, animated: true)
    }
    
    func importZip(from: URL, overwrite: Bool) {
        guard let viewController = AdNavigationEntryPoint.navigationController?.visibleViewController else { return }
        let hud = PendingHUDView.show(on: viewController.view)
        dataQueue.async {
            self.dataImport = DataImport(inputFile: from.path, output: FileManager.documentsPath)
            _ = self.dataImport.execute(overwrite: overwrite)
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    hud.hide()
                    NotificationCenter.default.post(name: NSNotification.Name.SmartReceiptsImport, object: nil)
                    let text = LocalizedString("app.delegate.import.success.alert.message")
                    _ = UIAlertController.showInfo(text: text, on: viewController).subscribe()
                    Logger.debug("app.delegate.import.success")
                }, onError: { _ in
                    hud.hide()
                    let text = LocalizedString("app.delegate.import.error.alert.message")
                    _ = UIAlertController.showInfo(text: text, on: viewController).subscribe()
                    Logger.error("app.delegate.import.error")
                })
        }
    }
    
    fileprivate func setupCustomExceptionHandler() {
        // Catches most but not all fatal errors
        NSSetUncaughtExceptionHandler { exception in
            RateApplication.sharedInstance().markAppCrash()
            
            var message = exception.description
            message += "\n"
            message += exception.callStackSymbols.description
            Logger.error(message, file: "UncaughtExcepetion", function: "onUncaughtExcepetion", line: 0)
            Crashlytics.sharedInstance().recordCustomExceptionName(exception.name.rawValue, reason: exception.reason, frameArray: [])
            
            let errorEvent = ErrorEvent(exception: exception)
            AnalyticsManager.sharedManager.record(event: errorEvent)
        }
    }
}
