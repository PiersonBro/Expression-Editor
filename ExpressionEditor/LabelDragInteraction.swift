//
//  LabelDragInteraction.swift
//  ExpressionEditor
//
//  Created by EandZ on 8/12/17.
//  Copyright © 2017 EandZ. All rights reserved.
//

import UIKit

extension ViewController: UIDragInteractionDelegate {
    public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        if let view = resultsPane.hitTest(session.location(in: interaction.view!), with: nil) {
            if let label = view as? UILabel {
                let itemProvider = NSItemProvider(object: label.text! as NSString)
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
}
