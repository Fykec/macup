//
//  MUSExportPanelAccessoryViewController.swift
//  MacDown
//
//  Created by Foster Yin on 6/27/14.
//  Copyright (c) 2014 Foster Yin. All rights reserved.
//

import Foundation

class MUSExportPanelAccessoryViewController : NSViewController {
    var stylesIncluded:Bool!

    var highlightingIncluded:Bool!

    func isStylesIncluded() -> Bool
    {
        return self.stylesIncluded
    }

    func isHighlightingIncluded() -> Bool
    {
        return self.highlightingIncluded
    }

    init()
    {
        super.init(nibName:self.className, bundle:nil)
        
    }
}
