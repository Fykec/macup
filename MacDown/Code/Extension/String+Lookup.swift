
//
//  String+Lookup.swift
//  MacDown
//
//  Created by Foster Yin on 7/1/14.
//  Copyright (c) 2014 MacUp, MarkDown, Swift. All rights reserved.
//

import Foundation

extension String
{
    subscript (r: Range<Int>) -> String {
        get {
            let subStart = advance(self.startIndex, r.startIndex, self.endIndex)
            let subEnd = advance(subStart, r.endIndex - r.startIndex, self.endIndex)
            return self.substringWithRange(Range(start: subStart, end: subEnd))
        }
    }

    subscript (i: Int) -> String {
        return String(Array(self)[i])
    }

    subscript(integerIndex: Int) -> Character
        {
        let index = advance(startIndex, integerIndex)
            return self[index]
    }

    func substring(from: Int) -> String {
        let end = countElements(self)
        return self[from..<end]
    }
    func substring(from: Int, length: Int) -> String {
        let end = from + length
        return self[from..<end]
    }

    func substringToIndex(idx:Int) -> String!
    {
        return self.substringToIndex(advance(self.startIndex, idx))
    }

    func substringFromIndex(idx:Int) -> String!
    {
        return self.substringFromIndex(advance(self.startIndex, idx))
    }

    func NSRangeToRange(ocRange:NSRange) -> Range<String.Index>
    {
        let startIndex = advance(self.startIndex, ocRange.location)
        let endIndex = advance(self.startIndex, ocRange.location + ocRange.length)

        return Range(start: startIndex, end: endIndex)
    }

    func RangeToNSRange(range:Range<String.Index>) -> NSRange
    {
        let sub = self.substringWithRange(range)
        return self.bridgeToObjectiveC().rangeOfString(sub)
    }

    func lengthOfUTF8() -> Int
    {
        return self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    }


    func titleString() -> String?
    {
        var pattern = "\\s+(\\S.*)$"

        for (var i = 0; i < 6; i++)
        {
            pattern = "#".stringByAppendingString(pattern)

            let p = "^".stringByAppendingString(pattern)
            let opt:NSRegularExpressionOptions = NSRegularExpressionOptions.AnchorsMatchLines

            let regex:NSRegularExpression = NSRegularExpression(pattern:p, options:opt, error:nil)

            let length = countElements(self)

            let result:NSTextCheckingResult! = regex.firstMatchInString(self, options: NSMatchingOptions.fromMask(0), range: NSMakeRange(0, length))

            if (result)
            {
                let range = result.rangeAtIndex(1)

                return self.substring(range.location, length: range.length)
            }
        }
        return nil
    }

    func locationOfFirstNewlineBefore(location:Int) -> Int
    {
        let string = self as NSString

        let length = string.length
        var loc = location
        if (loc > length)
        {
            loc = length
        }
        var p = loc - 1

        while (p >= 0 && !MPCharacterIsNewline(string.characterAtIndex(p)))
        {
            p--
        }
        return p
    }

    func locationOfFirstNewlineAfter(location:Int) -> Int
    {
        let string = self as NSString

        let length = string.length
        if (location >= length)
        {
            return length
        }
        var p = location + 1
        while (p < length && !MPCharacterIsNewline(string.characterAtIndex(p)))
        {
            p++
        }
        return p
    }


    func locationOfFirstNonWhitespaceCharacterInLineBefore(location:Int) -> Int
    {
        let string = self as NSString


        var p = self.locationOfFirstNewlineBefore(location) + 1
        var loc = location

        let length = string.length
        if (loc > length)
        {
            loc = length
        }
        while (p < loc && MPCharacterIsWhitespace(string.characterAtIndex(p)))
        {
            p++
        }
        return p
    }

    func rangeOfLinesInRange(range:NSRange) ->NSRange
    {
        let string = self

        if (string.lengthOfUTF8() == 0)
        {
            return NSMakeRange(0, 0)
        }

        let location = range.location
        let length = range.length
        let start = string.locationOfFirstNewlineBefore(location) + 1
        var end = location + length - 1

        if (end >= string.lengthOfUTF8() - 1)
        {
            end = string.lengthOfUTF8() - 2
        }
        if (!MPCharacterIsNewline((string[end]).toUnichar()))
        {
            end = string.locationOfFirstNonWhitespaceCharacterInLineBefore(end)
        }
        if (end < start)
        {
            end = start
        }
        if (end < string.lengthOfUTF8())
        {
            end++
        }
        return NSMakeRange(start, end - start)

    }

}