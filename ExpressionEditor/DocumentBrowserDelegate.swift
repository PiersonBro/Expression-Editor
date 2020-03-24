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
        print(typeName!)
        guard let contents = contents as? Data else {
            throw DocumentError.loadError
        }
        text = String(bytes: contents, encoding: .utf8)
    }
}


class DocumentBrowserDelegate: NSObject, UIDocumentBrowserViewControllerDelegate {
    
    var document: Document? = nil
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        print(documentURLs)
        let document = Document(fileURL: documentURLs.first!)
        self.document = document
        let vc = ViewController(document: document)
        controller.present(vc, animated: true, completion: nil)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
    }
    
    
}
