//
//  ViewController.swift
//  ExpressionEditor
//
//  Created by EandZ on 10/19/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import UIKit
import VascularKit

class ViewController: UIViewController {
    let textEditor = UITextView(frame: CGRect())
    let resultsPane = UIView(frame: CGRect())
    let statusBarView = UIView(frame: CGRect())
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
    }
    
    var previousPoint = CGPoint()
    @objc func dragResultsView(gestureRecognizer: UIPanGestureRecognizer) {
        let p1 = gestureRecognizer.location(in: resultsPane)
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
                }
            
            default:
                return
        }
        
        previousPoint = p1
    }
    
    var dragAdded = false
    var labels = [UILabel]()
    func process() {
        resultsPane.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let glyphRange = textEditor.layoutManager.glyphRange(for: textEditor.layoutManager.textContainers.first!)

        //Find positional info for the text and add the label to the gray view.
        var labels = [UILabel]()
        var firstIterate = true
        textEditor.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (firstRect, secondRect, container, range, bool) in
            if let r = Range(range) {
                let start = self.textEditor.text.index(self.textEditor.text.startIndex, offsetBy: r.lowerBound)
                let end = self.textEditor.text.index(self.textEditor.text.startIndex, offsetBy: r.upperBound)
                let substringRange = start..<end
                let string = String(self.textEditor.text[substringRange])
               
                if let input = self.parse(string, first: firstIterate) {
                    let rect = secondRect.offsetBy(dx: 10, dy: 0)
                    let finalRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: self.resultsPane.bounds.width, height: CGFloat(ceilf(Float(rect.size.height))))
                    let view = UILabel(frame: finalRect)
                    view.font = .systemFont(ofSize: 15)
                    view.text = input
                    view.isUserInteractionEnabled = true
                    view.backgroundColor = .gray
                    labels.append(view)
                    firstIterate = false
                }
            }
        }
        
        labels.forEach {
            resultsPane.addSubview($0)
        }
        
        if !dragAdded {
            let dragInteraction = UIDragInteraction(delegate: self)
            dragInteraction.allowsSimultaneousRecognitionDuringLift = true
            resultsPane.addInteraction(dragInteraction)
            dragAdded = true
        }
    }
    
    func parse(_ data: String, first: Bool) -> String? {
        if first {
            providerSupplier.beginParse()
        }
        let result = providerSupplier.parse(data)
        return result?.initialResult
    }
    
    /*func sanatize(_ string: String) -> String? {
     if string.isEmpty || string == "\n" {
     return nil
     }
     
     return string
     }
     func parse(_ data: String) -> String? {
        guard var data = sanatize(data) else {
            return nil
        }
        
        guard self.teams.isEmpty != true else {
            return nil
        }
        
        //FIXME: Have a more general solution to this problem.
        if let range = data.range(of: "+") {
            data.insert(" ", at: range.lowerBound)
        } else if let range = data.range(of: "-") {
            data.insert(" ", at: range.lowerBound)
        }
        
        let strings = data.components(separatedBy: " ")
        let tags = data.linguisticTags(in: data.startIndex..<data.endIndex, scheme: NSLinguisticTagScheme.lexicalClass.rawValue, options: .omitWhitespace, orthography: nil)
        
        let words = zip(strings, tags).flatMap { (arg) -> Criterion.Word? in
            
            let (word, tag) = arg
            if let grammer = Grammer(rawValue: tag) {
                return (word, grammer)
            } else {
                return nil
            }
        }
        
        if let subject = Subject(words: words, teams: teams) {
            var string = ""
            subject.execute() { result in
                string = result
            }
            return string
        } else {
            return "Error: Could Not Read Input."
            
        }
    }*/
}
