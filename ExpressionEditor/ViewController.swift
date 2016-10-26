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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureResultsPaneLayout()
        configureButton()
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
        NSLayoutConstraint(item: resultsPane, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 0.3, constant: 0).isActive = true
        NSLayoutConstraint(item: resultsPane, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 2.0, constant: 0).isActive = true
    }
    
    func configureButton() {
        button.setTitle("Execute", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        textEditor.addSubview(button)
        NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 0.5, constant: 0).isActive = true
        NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.3, constant: 0).isActive = true
    }
    
    func buttonTapped() {
        process()
    }
    
    func process() {
        resultsPane.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        print(textEditor.layoutManager.textContainers)
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
                    let view = UILabel(frame: rect)
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
