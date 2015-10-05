//
//  BorderedView.swift
//  Guinder
//
//  Created by Andre Siviero on 02/07/15.
//  Copyright (c) 2015 Resultate. All rights reserved.
//  License: MIT

import Foundation
import UIKit

struct BorderedViewDrawOptions : OptionSetType, BooleanType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    init(rawValue value: UInt) { self.value = value }
    init(nilLiteral: ()) { self.value = 0 }
    static var allZeros: BorderedViewDrawOptions { return self.init(0) }
    static func fromMask(raw: UInt) -> BorderedViewDrawOptions { return self.init(raw) }
    var rawValue: UInt { return self.value }
    var boolValue: Bool { return self.value != 0 }
    
    
    static var None: BorderedViewDrawOptions { return self.init(0) }
    static var DrawTop: BorderedViewDrawOptions   { return self.init(1 << 0) }
    static var DrawRight: BorderedViewDrawOptions  { return self.init(1 << 1) }
    static var DrawBottom: BorderedViewDrawOptions   { return self.init(1 << 2) }
    static var DrawLeft: BorderedViewDrawOptions  { return self.init(1 << 3) }
    static var DrawAll: BorderedViewDrawOptions  { return self.init(0b1111) }
}

class BorderedView : UIView {
    
    var borderColor = UIColor.darkGrayColor()
    var borderWidth = CGFloat(0.0)
    var borderDrawOptions = BorderedViewDrawOptions.None
    
    // Optionals to allow further customization
    var borderColorLeft:UIColor?
    var borderColorTop:UIColor?
    var borderColorRight:UIColor?
    var borderColorBottom:UIColor?
    
    var borderWidthLeft:CGFloat?
    var borderWidthTop:CGFloat?
    var borderWidthRight:CGFloat?
    var borderWidthBottom:CGFloat?
    
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor)
        CGContextSetLineWidth(context, borderWidth);
        
        if(borderDrawOptions.intersect(BorderedViewDrawOptions.DrawLeft)) {
            CGContextSetStrokeColorWithColor(context, borderColorLeft?.CGColor != nil ? borderColorLeft!.CGColor : borderColor.CGColor)
            CGContextSetLineWidth(context, borderWidthLeft != nil ? borderWidthLeft! : borderWidth);
            
            CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
            CGContextStrokePath(context);
            borderResetDefaultColorWidth(context!)
        }
        
        if(borderDrawOptions.intersect(BorderedViewDrawOptions.DrawTop)) {
            CGContextSetLineWidth(context, borderWidthTop != nil ? borderWidthTop! : borderWidth);
            CGContextSetStrokeColorWithColor(context, borderColorTop?.CGColor != nil ? borderColorTop!.CGColor : borderColor.CGColor)
            CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
            CGContextStrokePath(context);
            borderResetDefaultColorWidth(context!)
            
        }
        
        if(borderDrawOptions.intersect(BorderedViewDrawOptions.DrawRight)) {
            CGContextSetLineWidth(context, borderWidthRight != nil ? borderWidthRight! : borderWidth);
            CGContextSetStrokeColorWithColor(context, borderColorRight?.CGColor != nil ? borderColorRight!.CGColor : borderColor.CGColor)
            CGContextMoveToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
            CGContextStrokePath(context);
            borderResetDefaultColorWidth(context!)
            
        }
        
        if(borderDrawOptions.intersect(BorderedViewDrawOptions.DrawBottom)) {
            CGContextSetLineWidth(context, borderWidthBottom != nil ? borderWidthBottom! : borderWidth);
            CGContextSetStrokeColorWithColor(context, borderColorBottom?.CGColor != nil ? borderColorBottom!.CGColor : borderColor.CGColor)
            CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
            CGContextStrokePath(context);
            borderResetDefaultColorWidth(context!)
        }
        
    }
    
    func borderResetDefaultColorWidth(context: CGContextRef) -> Void {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor)
        CGContextSetLineWidth(context, borderWidth);
    }
}