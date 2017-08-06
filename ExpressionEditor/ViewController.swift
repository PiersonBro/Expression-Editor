//
//  ViewController.swift
//  ExpressionEditor
//
//  Created by EandZ on 10/19/16.
//  Copyright © 2016 EandZ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let textEditor = UITextView(frame: CGRect())
    let resultsPane = UIView(frame: CGRect())
    let statusBarView = UIView(frame: CGRect())
    var drag: UIPanGestureRecognizer? = nil
    var teams = [Team]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureResultsPaneLayout()
        configureDragGestureRecognizer()
        loadTeamsData()
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
        textEditor.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        resultsPane.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        configureStatusBarView()
    }
    
    func configureStatusBarView() {
        statusBarView.backgroundColor = .white
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBarView)
        statusBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusBarView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        statusBarView.bottomAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        statusBarView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).isActive = true
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
    
    func process() {
        resultsPane.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let glyphRange = textEditor.layoutManager.glyphRange(for: textEditor.layoutManager.textContainers.first!)

        //Find positional info for the text and add the label to the gray view.
        var labels = [UILabel]()
        textEditor.layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (firstRect, secondRect, container, range, bool) in
            if let r = Range(range) {
                let start = self.textEditor.text.utf16.index(self.textEditor.text.utf16.startIndex, offsetBy: r.lowerBound)
                let end = self.textEditor.text.utf16.index(self.textEditor.text.utf16.startIndex, offsetBy: r.upperBound)
                let substringRange = start..<end
                let string = self.textEditor.text.utf16[substringRange].description
               
                if let input = self.process(input: string) {
                    let rect = secondRect.offsetBy(dx: 10, dy: 0)
                    let finalRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: self.resultsPane.bounds.width, height: rect.size.height)
                    let view = UILabel(frame: finalRect)
                    view.font = .systemFont(ofSize: 8)
                    view.text = input
                    view.backgroundColor = .randomColor()
                    labels.append(view)
                }
            }
        }
        
        labels.forEach {
            resultsPane.addSubview($0)
        }
    }
    
    func sanatize(_ string: String) -> String? {
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
    }
    
    var parsedInputs: [String: String?] = [:]
    
    // This function will serve as the entrance point for the parser.
    func process(input: String) -> String? {
        // If we have already parsed this result return it, otherwise parse.
        let parsedInput: String?
        if let storedValue = parsedInputs[input] {
            parsedInput = storedValue
        } else {
            parsedInput = parse(input)
            parsedInputs[input] = parsedInput
        }
        
        return parsedInput
    }
}

public extension UIColor {
    static func randomColor() -> UIColor {
        let colors: [UIColor] = [.red, .green, .cyan, .yellow, .orange, .purple, .brown]
        let randomIndex = Int(arc4random() % UInt32(colors.count))
        
        return colors[randomIndex]
    }
}
