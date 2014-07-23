//
//  MUSPreferencesViewController.swift
//  MacDown
//
//  Created by Foster Yin on 7/23/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Cocoa

class MUSPreferencesViewController : NSViewController
{
    let preferences:MPPreferences = MPPreferences.sharedInstance()
    
    init()
    {
        super.init(nibName:self.className, bundle:nil)

    }
}
