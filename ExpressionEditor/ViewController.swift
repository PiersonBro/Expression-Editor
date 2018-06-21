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

class ViewController: UIViewController, UIGestureRecognizerDelegate, UIDragInteractionDelegate {
    let textEditor = UITextView(frame: CGRect())
    let resultsPane = UIView(frame: CGRect())
    let validDragArea = UIView()
    var drag: UIPanGestureRecognizer? = nil
    var teams = [Team]()
    var providerSupplier = ProviderSupplier()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureResultsPaneLayout()
        configureDragGestureRecognizer()
        loadTeamsData()
        registerProviders()
    }
    
    func registerProviders() {
        providerSupplier.register(type: MathProvider.self)
        providerSupplier.register(type: DebugProvider.self)
        providerSupplier.register(type: DataInterchangeLoader.self)
        providerSupplier.register(type: FangraphsProvider.self)
//        providerSupplier.register(type: TeamProvider.self)
        //FIXME: Add Teams.
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
        
        textEditor.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        configureResultsPaneLayout()
        textEditor.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        textEditor.rightAnchor.constraint(equalTo: resultsPane.leftAnchor).isActive = true
        
        resultsPane.layer.masksToBounds = true
        resultsPane.layer.cornerRadius = 15.0
    }
    
    override func viewDidLayoutSubviews() {
        textEditor.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        resultsPane.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    func configureResultsPaneLayout() {
        view.addSubview(resultsPane)
        resultsPane.translatesAutoresizingMaskIntoConstraints = false
        resultsPane.backgroundColor = .gray

        resultsPane.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        let rightAnchor = resultsPane.rightAnchor.constraint(equalTo: view.rightAnchor)
        rightAnchor.isActive = true
        let centerXConstriant = NSLayoutConstraint(item: resultsPane, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.7, constant: 0)
        centerXConstriant.isActive = true
        centerXConstriant.identifier = "centerXRP"
        configureValidDragArea()
    }
    
    var validAreaConstraints = [NSLayoutConstraint]()
    func configureValidDragArea() {
        resultsPane.addSubview(validDragArea)
        validDragArea.translatesAutoresizingMaskIntoConstraints = false
        validDragArea.isUserInteractionEnabled = false
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
    
    var previousPoint = CGPoint()
    @objc func dragResultsView(gestureRecognizer: UIPanGestureRecognizer) {
        let p1 = gestureRecognizer.location(in: view)
        let distance: CGFloat = { () -> CGFloat in
            let magnitude = abs(p1.x - self.previousPoint.x)
            let vector: CGFloat
            if gestureRecognizer.velocity(in: self.resultsPane).x > 0 {
                vector = magnitude
            } else {
                vector = -(magnitude)
            }
            return vector
        }()
        var origin = resultsPane.frame.origin

        
        switch gestureRecognizer.state {
            case .began:
                deactivateValidDragArea()
                previousPoint = gestureRecognizer.location(in: resultsPane)
            case .changed:
                origin.x = origin.x + distance
                
                resultsPane.frame = CGRect(origin: origin, size: CGSize(width: resultsPane.frame.height, height: resultsPane.frame.height))
            case .ended:
                UIView.animate(withDuration: 0) {
                    self.view.constraints.filter {
                        $0.identifier == "centerXRP"
                    }.forEach {
                        self.view.removeConstraint($0)
                    }
              
                    origin.x = origin.x + distance
                
                    self.resultsPane.frame = CGRect(origin: origin, size: CGSize(width: self.resultsPane.frame.height, height: self.resultsPane.frame.height))
                    let point = self.resultsPane.convert(self.resultsPane.bounds, to: self.view)
                    let xMultiplier = (point.origin.x / self.view.frame.maxX) + 0.9998047352

                    let centerXConstriant = NSLayoutConstraint(item: self.resultsPane, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: xMultiplier, constant: 0)
                    centerXConstriant.isActive = true
                    centerXConstriant.identifier = "centerXRP"
                    self.view.layoutIfNeeded()
                    self.process()
                    self.configureValidDragArea()
                }
            
            default:
                return
        }
        
        previousPoint = p1
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
        providerSupplier.parse(input: textEditor.text, identities: identities) { input in
            if let input = input {
                DispatchQueue.main.async {
                    let linePositionRectIndex = keys.index { $0 === input.inputCriteria.identity }
                    let linePositionCriteria = keys[linePositionRectIndex!]
                    let linePositionRect = lineFragmentLocation[linePositionCriteria]!
                    let rect = linePositionRect.offsetBy(dx: 10, dy: 0)
                    let finalRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: self.resultsPane.bounds.width, height: CGFloat(ceilf(Float(rect.size.height))))
                    let label = UILabel(frame: finalRect)
                    label.font = .systemFont(ofSize: 15)
                    label.text = input.initialResult
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
        configureValidDragArea()
    }
}
