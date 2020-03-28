//
//  ViewController.swift
//  ExpressionEditor
//
//  Created by EandZ on 10/19/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import UIKit
import VascularKit
import FangraphsDataKit

class TextChangeManager: NSObject, UITextViewDelegate {
    let document: Document
    init(document: Document) {
        self.document = document
    }
    func textViewDidChange(_ textView: UITextView) {
        self.document.text = textView.text
    }
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, UIDragInteractionDelegate {
    let textEditor = UITextView(frame: CGRect())
    let resultsPane = UIView(frame: CGRect())
    let validDragArea = UIView()
    var drag: UIPanGestureRecognizer? = nil
    var teams = [Team]()
    var providerSupplier = ProviderSupplier()
    let document: Document
    let textChangeManager: TextChangeManager
    
    init(document: Document) {
        self.document = document
        self.textChangeManager = TextChangeManager(document: self.document)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureDragGestureRecognizer()
        loadTeamsData()
        registerProviders()
        openDocument()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        document.close(completionHandler: nil)
    }
    
    func openDocument() {
        document.open { success in
            if !success {
                fatalError("Failed")
            }
            
            self.document.undoManager = self.textEditor.undoManager
            self.textEditor.text = self.document.text!
        }
    }
    
    func registerProviders() {
        providerSupplier.register(type: MathProvider.self)
        providerSupplier.register(type: DebugProvider.self)
        providerSupplier.register(type: DataInterchangeLoader.self)
        providerSupplier.register(type: FangraphsProvider.self)
    }
    
    //FIXME: Factor this out.
    func loadTeamsData() {
        Team.fetchTeams() { teams in
            DispatchQueue.main.sync {
                self.teams = teams
            }
        }
    }
   
    func configureDragGestureRecognizer() {
        let SEL = #selector(dragResultsView(gestureRecognizer:))
        drag = UIPanGestureRecognizer(target: self, action: SEL)
        drag?.delegate = self
        view.addGestureRecognizer(drag!)
    }
    
    func configureTextEditorLayout() {
        view.backgroundColor = .white
        view.addSubview(textEditor)
        textEditor.translatesAutoresizingMaskIntoConstraints = false
        textEditor.autocapitalizationType = .none
        textEditor.autocorrectionType = .no
        textEditor.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        configureResultsPaneLayout()
        textEditor.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        textEditor.rightAnchor.constraint(equalTo: resultsPane.leftAnchor).isActive = true
        textEditor.backgroundColor = .white
        textEditor.textColor = .black
        textEditor.delegate = textChangeManager
    }
    
    override func viewDidLayoutSubviews() {
        textEditor.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        resultsPane.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    var dragEdgeConstraint: NSLayoutConstraint? = nil
    func configureResultsPaneLayout() {
        //Update document state
        //FIXME: Hacky!
        textEditor.text = document.text
        view.addSubview(resultsPane)
        resultsPane.translatesAutoresizingMaskIntoConstraints = false
        resultsPane.backgroundColor = .gray

        resultsPane.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        let rightAnchor = resultsPane.rightAnchor.constraint(equalTo: view.rightAnchor)
        rightAnchor.isActive = true
        
        dragEdgeConstraint = NSLayoutConstraint(item: resultsPane, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.7, constant: 0)
        dragEdgeConstraint!.isActive = true
        dragEdgeConstraint = rightAnchor
        resultsPane.layer.masksToBounds = true
        resultsPane.layer.cornerRadius = 15.0
        configureValidDragArea()
    }
    
    var validAreaConstraints = [NSLayoutConstraint]()
    func configureValidDragArea() {
        if !validDragArea.isDescendant(of: resultsPane) {
            resultsPane.addSubview(validDragArea)
            validDragArea.translatesAutoresizingMaskIntoConstraints = false
            validDragArea.isUserInteractionEnabled = false
        }
        #if DEBUG
            validDragArea.alpha = 0.2
            validDragArea.backgroundColor = .red
            validDragArea.isOpaque = false
        #endif
        if validAreaConstraints.count == 0 {
            validAreaConstraints.append(validDragArea.leftAnchor.constraint(equalTo: resultsPane.leftAnchor))
            validAreaConstraints.append(validDragArea.heightAnchor.constraint(equalTo: resultsPane.heightAnchor))
            validAreaConstraints.append(validDragArea.widthAnchor.constraint(equalTo: resultsPane.widthAnchor, multiplier: 0.2))
        }
        validAreaConstraints.forEach { $0.isActive = true }
    }
    
    func deactivateValidDragArea() {
        validAreaConstraints.forEach { $0.isActive = false }
    }
    
    var startingConstant: CGFloat = 0
    @objc func dragResultsView(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
            case .began:
                startingConstant = dragEdgeConstraint!.constant
                deactivateValidDragArea()
            case .changed:
                let translation = gestureRecognizer.translation(in: self.view)
                if (startingConstant - translation.x >= 0) {
                    dragEdgeConstraint!.constant = startingConstant - translation.x
                }
            case .ended:
                    self.process()
                    self.configureValidDragArea()
            default:
                return
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if validDragArea.frame.contains(gestureRecognizer.location(in: validDragArea)) {
            return true
        } else {
            return false
        }
    }
    
    var dragAdded = false
    var labels = [UILabel]()
    func process() {
        resultsPane.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        //Find positional info for the text and add the label to the gray view.
        let glyphRange = textEditor.layoutManager.glyphRange(for: textEditor.layoutManager.textContainers.first!)
        var lineFragmentLocation = [Identity: CGRect]()
        var identities: [Identity] = [Identity]()
        textEditor.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (firstRect, secondRect, container, range, bool) in
            if let r = Range(range) {
                let start = self.textEditor.text.index(self.textEditor.text.startIndex, offsetBy: r.lowerBound)
                let end = self.textEditor.text.index(self.textEditor.text.startIndex, offsetBy: r.upperBound)
                let substringRange = start..<end
                let inputString = String(self.textEditor.text[substringRange])
                if self.providerSupplier.canCreateCriteria(inputString) {
                    let identity = Identity(inputString)
                    identities.append(identity)
                    lineFragmentLocation[identity] = secondRect
                }
            }
        }
        
        let keys = Array(lineFragmentLocation.keys)
        providerSupplier.parse(input: textEditor.text, identities: identities) { token in
            if let token = token {
                DispatchQueue.main.async {
                    let linePositionRectIndex = keys.firstIndex { $0 === token.identity }
                    let linePositionCriteria = keys[linePositionRectIndex!]
                    let linePositionRect = lineFragmentLocation[linePositionCriteria]!
                    let rect = linePositionRect.offsetBy(dx: 10, dy: 0)
                    let finalRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: self.resultsPane.bounds.width, height: CGFloat(ceilf(Float(rect.size.height))))
                    let label = UILabel(frame: finalRect)
                    label.font = .systemFont(ofSize: 15)
                    if let resultProperty = token.evaluateResult() {
                        label.text = resultProperty
                    } else {
                        label.text = token.result!.initialResult
                    }
                    label.isUserInteractionEnabled = true
                    label.backgroundColor = .gray
                    label.sizeToFit()
                    label.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: label.frame.width, height: CGFloat(ceilf(Float(rect.size.height))))
                    self.resultsPane.addSubview(label)
                }
            }
        }
        
        if !dragAdded {
            let dragInteraction = UIDragInteraction(delegate: self)
            resultsPane.addInteraction(dragInteraction)
            dragAdded = true
        }
    }
    
    public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        if let view = resultsPane.hitTest(session.location(in: interaction.view!), with: nil) {
            if let label = view as? UILabel {
                let item = "L\(String(describing: providerSupplier.lineNumber(result: label.text!)))" as NSString
                let itemProvider = NSItemProvider(object: item)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                return [dragItem]
            }
        }
        
        return []
    }
    
    public func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        let label = resultsPane.hitTest(session.location(in: interaction.view!), with: nil) as! UILabel
        return UITargetedDragPreview(view: label)
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
//        configureValidDragArea()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
        
    }
}
