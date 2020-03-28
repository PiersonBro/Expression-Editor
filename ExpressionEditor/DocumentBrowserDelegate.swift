//
//  DocumentBrowserDelegate.swift
//  ExpressionEditor
//
//  Created by Ezekiel Pierson on 3/17/20.
//  Copyright © 2020 EandZ. All rights reserved.
//

import UIKit

enum DocumentError: Error {
    case loadError
    case saveError
}
class Document: UIDocument {
    var text: String? = nil
    
    override init(fileURL url: URL) {
        super.init(fileURL: url)
        NotificationCenter.default.addObserver(self, selector: #selector(stateDidChange), name: UIDocument.stateChangedNotification, object: nil)
    }
    
    @objc func stateDidChange(notification: NSNotification) {
        print(notification.name)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        if let text = text {
            return text.data(using: .utf8) as Any
        }
        throw DocumentError.saveError
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let contents = contents as? Data else {
            throw DocumentError.loadError
        }
        text = String(bytes: contents, encoding: .utf8)
    }
}

class DocumentBrowserDelegate: NSObject, UIDocumentBrowserViewControllerDelegate {
    
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        let document = Document(fileURL: documentURLs.first!)
        let vc = ViewController(document: document)
        controller.present(vc, animated: true, completion: nil)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        let document = Document(fileURL: destinationURL)
        let vc = ViewController(document: document)
        controller.present(vc, animated: true, completion: nil)
    }
        
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        print("fail!", error!)
        print(documentURL)
        fatalError("Failed to import document: \(documentURL)")
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        getFileName(controller: controller) { string in
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(string ?? "untitled").appendingPathExtension("txt")
            let document = Document(fileURL: url)
            document.text = ""
            document.save(to: document.fileURL, for: .forCreating) { success in
                guard success else {
                    importHandler(nil, .none)
                    return
                }
                document.close { closeSucess in
                    guard closeSucess else {
                        importHandler(nil, .none)
                        return
                    }
                    importHandler(url, .move)
                }
            }
        }
        
    }
    
    func getFileName(controller: UIDocumentBrowserViewController, handler: @escaping (String?) -> ()) {
        let alert = UIAlertController(title: "Enter File Name", message: "Please name your file." , preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "File name";
        }
        let alertAction = UIAlertAction(title: "Done", style: .default) { [weak alert] _ in
            guard let alert = alert else {
                return
            }
            let text = alert.textFields![0].text
            handler(text)
            
        }
        alert.addAction(alertAction)
        controller.present(alert, animated: true)
    }
    
}
