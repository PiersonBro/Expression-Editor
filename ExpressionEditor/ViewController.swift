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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextEditorLayout()
        configureResultsPaneLayout()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
