//
//  Character+unichar.swift
//  MacDown
//
//  Created by Foster Yin on 7/8/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//


import Foundation

//https://raw.githubusercontent.com/practicalswift/CoreLib/master/CoreLib/Character.swift
extension Character
{
    func toUnichar() -> unichar {
        var cstring = String(self).cStringUsingEncoding(NSUTF8StringEncoding)!
        var cchar = cstring[0]
        var unsigned = cchar.asUnsigned()
        return unichar(unsigned)
    }
}


@infix func == (left:Character, right:Character) -> Bool {
    return left.toUnichar() == right.toUnichar()
}

@infix func != (left:Character, right:Character) -> Bool {
    return left.toUnichar() != right.toUnichar()
}