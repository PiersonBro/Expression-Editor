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
    let button = UIButton(type: .system)
    var drag: UIPanGestureRecognizer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureResultsPaneLayout()
        configureButton()
        configureDragGestureRecognizer()
    }
   
    func configureDragGestureRecognizer() {
        let SEL = #selector(dragResultsView(gestureReocognizer:))
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
    
    var origin = CGPoint()
    
    override func viewDidLayoutSubviews() {
        textEditor.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        resultsPane.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        configureStatusBarView()
        print(resultsPane.frame)
        print("------")
        origin = CGPoint(x: 653.0, y: 20.0)
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
        let widthConstraint = NSLayoutConstraint(item: resultsPane, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.3, constant: 0)
        widthConstraint.isActive = true
        widthConstraint.identifier = "widthRP"
        
        let centerXConstriant = NSLayoutConstraint(item: resultsPane, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 2.0, constant: 0)
        centerXConstriant.isActive = true
        centerXConstriant.identifier = "centerXRP"
    }
    
    func configureButton() {
        button.setTitle("Execute", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        textEditor.addSubview(button)
        NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.4, constant: 0).isActive = true
        let constraint = NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.3, constant: 0)
        constraint.identifier = "hello!"
        constraint.isActive = true
    }
    
    func buttonTapped() {
        view.constraints.filter {
            $0.identifier == "widthRP" || $0.identifier == "centerXRP"
        }.forEach {
            view.removeConstraint($0)
        }
    
        let widthConstraint = NSLayoutConstraint(item: resultsPane, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.5, constant: 0)
            widthConstraint.isActive = true
            widthConstraint.identifier = "widthRP"

            UIView.animate(withDuration: 2) {
                self.view.layoutIfNeeded()
            }
        process()
    }
    
    
    var previousPoint = CGPoint()
    var constraints = [NSLayoutConstraint]()
    func dragResultsView(gestureReocognizer: UIPanGestureRecognizer) {
        let p1 = gestureReocognizer.location(in: resultsPane)
        let distance = p1.x - previousPoint.x
        
        switch gestureReocognizer.state {
            case .began:
                previousPoint = gestureReocognizer.location(in: resultsPane)
                constraints = view.constraints.filter {
                    $0.identifier == "widthRP" || $0.identifier == "centerXRP"
                }
                constraints.forEach {
                    view.removeConstraint($0)
                }

            case .changed:
//                let calcDistance = resultsPane.frame.width + distance
                let calcDistance = view.frame.width - (resultsPane.frame.width + distance)
                print(calcDistance)
                resultsPane.frame = CGRect(origin: resultsPane.frame.origin, size: CGSize(width: calcDistance, height: resultsPane.frame.height))
            case .ended:
                let multiplier = (view.frame.width - (resultsPane.frame.width + distance)) / view.frame.width
                let widthConstraint = NSLayoutConstraint(item: resultsPane, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: multiplier, constant: 0)
                widthConstraint.isActive = true
                widthConstraint.identifier = "widthRP"
            
               constraints.filter {
                    $0.identifier == "centerXRP"
                }.forEach {
                    view.addConstraint($0)
                }
        
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
                process()
            
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
            if let r = range.toRange() {
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
    
    // This function will serve as the entrance point for the parser.
    func process(input: String) -> String? {
        if !input.isEmpty && input != "\n" {
            return input
        } else {
            return nil
        }
    }
}

public extension UIColor {
    static func randomColor() -> UIColor {
        let colors: [UIColor] = [.red, .blue, .green, .gray, .cyan, .yellow, .orange, .purple, .brown]
        let randomIndex = Int(arc4random() % UInt32(colors.count))
        
        return colors[randomIndex]
    }
}
