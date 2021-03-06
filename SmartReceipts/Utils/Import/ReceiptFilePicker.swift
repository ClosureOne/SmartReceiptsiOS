//
//  FilePicker.swift
//  SmartReceipts
//
//  Created by Bogdan Evsenev on 20/01/2018.
//  Copyright © 2018 Will Baumann. All rights reserved.
//

import RxSwift
import Toaster

fileprivate let JPEG_TYPE = "public.jpeg"
fileprivate let PNG_TYPE = "public.png"
fileprivate let PDF_TYPE = "com.adobe.pdf"

class ReceiptFilePicker: NSObject {
    static let sharedInstance = ReceiptFilePicker()
    fileprivate var pickSubject: PublishSubject<ReceiptDocument>?
    fileprivate var openedViewController: UIViewController?
    
    private let allowedTypes = [JPEG_TYPE, PNG_TYPE, PDF_TYPE]  //Temporarily disabled pdf imports from the "Files" screen for `Issue 5`
    
    private override init() {}
    
    func openFilePicker(on viewController: UIViewController) -> Observable<ReceiptDocument> {
        pickSubject = PublishSubject<ReceiptDocument>()
        if #available(iOS 11.0, *) {
            let title = LocalizedString("receipt_import_action_sheet_title")
            let actionFilesTitle = LocalizedString("receipt_import_action_files")
            let actionCameraRollTitle = LocalizedString("receipt_import_action_camera_roll")
            let cancelActionTitle = LocalizedString("receipt_import_action_cancel")
            
            let actionSheet = UIAlertController(title: nil, message: title, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: actionCameraRollTitle, style: .default, handler: { _ in
                self.openedViewController = self.imagePicker()
                self.openPicker(on: viewController)
            }))
            
            actionSheet.addAction(UIAlertAction(title: actionFilesTitle, style: .default, handler: { _ in
                let fvc = FilesViewController(forOpeningFilesWithContentTypes: self.allowedTypes)
                fvc.delegate = self
                self.openedViewController = fvc
                self.openPicker(on: viewController)
            }))
            
            actionSheet.addAction(UIAlertAction(title: cancelActionTitle, style: .destructive, handler: nil))
            
            if let popoverController = actionSheet.popoverPresentationController {
                let sourceView = viewController.view!
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(actionSheet, animated: true, completion: nil)
            
        } else {
            openedViewController = imagePicker()
            openPicker(on: viewController)
        }
        return pickSubject!.asObservable()
    }
    
    private func openPicker(on viewController: UIViewController) {
        viewController.present(openedViewController!, animated: true, completion: nil)
    }
    
    private func imagePicker() -> UIImagePickerController {
        let ipc = UIImagePickerController()
        ipc.sourceType = .photoLibrary
        ipc.delegate = self
        return ipc
    }
    
    fileprivate func close(completion: VoidBlock? = nil) {
        openedViewController?.dismiss(animated: true, completion: completion)
    }
}

extension ReceiptFilePicker: UIDocumentBrowserViewControllerDelegate {
    @available(iOS 11.0, *)
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        if let url = documentURLs.first {
            close(completion: {
                var document = ReceiptDocument(fileURL: url)
                guard let fileType = document.fileType else { return }
                if fileType == PNG_TYPE || fileType == JPEG_TYPE {
                    if let data = try? Data(contentsOf: url), DataValidationService().isValidImage(data: data) {
                        let img = UIImage(data: data)
                        let compressedImage = WBImageUtils.compressImage(img, withRatio: kImageCompression)
                        let compressedURL = ReceiptDocument.makeDocumentFrom(image: compressedImage!).localURL!
                        document = ReceiptDocument(fileURL: compressedURL)
                    } else {
                        self.emitImportError()
                        return
                    }
                } else if fileType == PDF_TYPE {
                    if let data = try? Data(contentsOf: url), !DataValidationService().isValidPDF(data: data) {
                        self.emitImportError()
                        return
                    }
                }
                
                return document.open()
            })
        } else {
            close()
        }
    }
    
    private func emitImportError() {
        let errorInfo = [NSLocalizedDescriptionKey : LocalizedString("receipt_file_picker_cant_import_error")]
        let error = NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL), userInfo: errorInfo)
        ReceiptFilePicker.sharedInstance.pickSubject?.onError(error)
    }
}

extension ReceiptFilePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let img = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        let resultImage = WBImageUtils.compressImage(img, withRatio: kImageCompression)
        
        close(completion: { ReceiptDocument.makeDocumentFrom(image: resultImage!).open() })
    }
}


class ReceiptDocument: UIDocument {
    private(set) var rawData: Data?
    private(set) var localURL: URL?
    private(set) var isPDF = false
    
    static let PDF_TEMP_NAME = "pdf_temp.pdf"
    static let IMG_TEMP_NAME = "img_temp.jpg"
    
    static var pdfTempURL: URL { return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(PDF_TEMP_NAME)! }
    static var imgTempURL: URL { return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(IMG_TEMP_NAME)! }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data, let fileType = typeName else { return }
        forceLoad(data: data, fileType: fileType)
        ReceiptFilePicker.sharedInstance.pickSubject?.onNext(self)
    }
    
    fileprivate func forceLoad(data: Data, fileType: String) {
        rawData = data
        
        if fileType == PNG_TYPE || fileType == JPEG_TYPE {
            isPDF = false
            localURL = ReceiptDocument.imgTempURL
        } else if fileType == PDF_TYPE {
            isPDF = true
            localURL = ReceiptDocument.pdfTempURL
        }
        try? data.write(to: localURL!)
    }
    
    class func makeDocumentFrom(image: UIImage) -> ReceiptDocument {
        let img = WBImageUtils.processImage(image)!
        let imgWithoutScale = WBImageUtils.withoutScreenScale(img)!
        let imgData = UIImageJPEGRepresentation(imgWithoutScale, 1)!
        let doc = ReceiptDocument(fileURL: ReceiptDocument.imgTempURL)
        doc.forceLoad(data: imgData, fileType: JPEG_TYPE)
        return doc
    }
}
