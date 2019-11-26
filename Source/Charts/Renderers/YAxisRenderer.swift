//
//  YAxisRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
import UIKit
#endif

@objc(ChartYAxisRenderer)
open class YAxisRenderer: AxisRendererBase
{
    @objc public init(viewPortHandler: ViewPortHandler, yAxis: YAxis?, transformer: Transformer?)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer, axis: yAxis)
    }
    
    /// draws the y-axis labels to the screen
    open override func renderAxisLabels(context: CGContext)
    {
        guard let yAxis = self.axis as? YAxis else { return }
        
        if !yAxis.isEnabled || !yAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = yAxis.xOffset
        let yoffset = yAxis.labelFont.lineHeight / 2.5 + yAxis.yOffset
        
        let dependency = yAxis.axisDependency
        let labelPosition = yAxis.labelPosition
        
        var xPos = CGFloat(0.0)
        
        var textAlign: NSTextAlignment
        
        if dependency == .left
        {
            if labelPosition == .outsideChart
            {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - xoffset
            }
            else
            {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + xoffset
            }
            
        }
        else
        {
            if labelPosition == .outsideChart
            {
                textAlign = .left
                xPos = viewPortHandler.contentRight + xoffset
            }
            else
            {
                textAlign = .right
                xPos = viewPortHandler.contentRight - xoffset
            }
        }
        
        drawYLabels(
            context: context,
            fixedPosition: xPos,
            positions: transformedPositions(),
            offset: yoffset - yAxis.labelFont.lineHeight,
            textAlign: textAlign)
    }
    
    open override func renderAxisLine(context: CGContext)
    {
        guard let yAxis = self.axis as? YAxis else { return }
        
        if !yAxis.isEnabled || !yAxis.drawAxisLineEnabled
        {
            return
        }
        
        context.saveGState()
        
        context.setStrokeColor(yAxis.axisLineColor.cgColor)
        context.setLineWidth(yAxis.axisLineWidth)
        if yAxis.axisLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.axisLineDashPhase, lengths: yAxis.axisLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        if yAxis.axisDependency == .left
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    /// draws the y-labels on the specified x-position
    internal func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        let labelFont = yAxis.labelFont
        let labelTextColor = yAxis.labelTextColor
        
        let from = yAxis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = yAxis.isDrawTopYLabelEntryEnabled ? yAxis.entryCount : (yAxis.entryCount - 1)
        
        let limitLines = yAxis.limitLines //вытянули масив линий
        
        var yOffset = CGFloat(0.0)

        if limitLines.count == 0
        {
            yOffset = CGFloat(-6.0)
        }

        for i in stride(from: from, to: to, by: 1)
        {
            let text = yAxis.getFormattedLabel(i)

            ChartUtils.drawText(
                context: context,
                text: text,
                point: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                align: textAlign,
                attributes: [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: labelTextColor])
        }
        
        renderIndicatorBlock(
            context: context,
            fixedPosition: fixedPosition,
            positions: transformedPositions(),
            textAlign: textAlign)
    }
    
    
    internal func renderIndicatorBlock( context: CGContext,
                                        fixedPosition: CGFloat,
                                        positions: [CGPoint],
                                        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        //var [CGPoint] positions = transformedPositions() // получили значение по оси У
        var limitLines = yAxis.limitLines //вытянули масив линий
        
        if limitLines.count == 0
        {
            return
        }
        
        
        let l = limitLines[0] // вытянули одну линию
        let blockLimitNumber = CGFloat(l.limit) // получили значение лимит блока
        
        let limitFirstText = yAxis.getFormattedLabel(1)  //получили значение по осям У в формате текста
        let limitSecondText = yAxis.getFormattedLabel(2)  //получили значение по осям У в формате текста
        
        // let labelTextColor = yAxis.labelTextColor // вытянули цвет текста
        let labelFont = yAxis.labelFont // вытянули размер текста
        
        // let limitFirst = getCGFloat(from: limitFirstText) // нужно преобразовать в число значение оси
        let gradeFirst = positions[1].y
        
        // let limitSecond = getCGFloat(from:limitSecondText) // нужно преобразовать в число значение оси
        let gradeSecond = positions[2].y

        let limitFirstChanged = String(format:"%.5f", limitFirstText.doubleValue)
        let limitFirst = getCGFloat(from: limitFirstChanged)
        
        let limitSecondChanged = String(format:"%.5f", limitSecondText.doubleValue)
        let limitSecond = getCGFloat(from: limitSecondChanged)
        
        let limitDifferent: Float = Float(limitSecond ?? 0.0) - Float(limitFirst ?? 0.0)
        let gradeDifferent: Float = Float(gradeFirst ) - Float(gradeSecond )
        
        let different = Float(blockLimitNumber ) - Float(limitSecond ?? 0.0)
        let differentRangeFromZero = ((different * gradeDifferent) / limitDifferent)
        let positionYFloat = Float(gradeSecond) - differentRangeFromZero //задали позицию Y
        let positionYText = CGFloat(positionYFloat-6)
        let positionY = CGFloat(positionYFloat-10)
        
        var components = limitLines[0].lineColor.cgColor.components!
        
        let rectColor = UIColor(red: CGFloat(components[0]),
                                green: CGFloat(components[1]),
                                blue: CGFloat(components[2]),
                                alpha: CGFloat(components[3]))

        let labelTextColor = UIColor(red: CGFloat(0),
                                green: CGFloat(0),
                                blue: CGFloat(0),
                                alpha: CGFloat(1))
        
        drawRect(pointX: CGFloat(fixedPosition),
            pointY: CGFloat(positionY),
            context: UIGraphicsGetCurrentContext()!,
            strokeColor: rectColor,
            fillColor: rectColor)
        
        ChartUtils.drawText(
            context: context,
            text: getString(from: CGFloat(l.limit)),
            point: CGPoint(x: fixedPosition-1, y: positionYText),
            align: textAlign,
            attributes: [NSAttributedString.Key.font: labelFont,  NSAttributedString.Key.foregroundColor: labelTextColor])
    }
    
    
    //Method that you need to parse string to cgfloat
    private func getCGFloat(from string: String) -> CGFloat?{
        if let double = Double(string){
            return CGFloat(double)
        }
        
        return nil
    }
    
    private func getString(from cgFloat: CGFloat?) -> String{
        if let float = cgFloat{
            return float.description
        }
        
        return "nil"
    }
    
    private func getDouble(from string: String) -> Double?{
        if let double = Double(string){
            return double
        }
        return nil
    }
    
    
    //Method that you need to draw rectangle
    //If you have colors in another format (CGColor, RGB etc.. just conver them to UIColor)
    private func drawRect(pointX: CGFloat,pointY: CGFloat, context: CGContext, strokeColor: UIColor, fillColor: UIColor){
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x:pointX-4.0, y: pointY+10))
        path.addLine(to: CGPoint(x: pointX+2.0, y: pointY))
        path.addLine(to: CGPoint(x: pointX+52.0, y: pointY))
        path.addLine(to: CGPoint(x: pointX+52.0, y: pointY+20))
        path.addLine(to: CGPoint(x: pointX+2.0, y: pointY+20))
        path.addLine(to: CGPoint(x:pointX-4.0, y: pointY+10))
        path.close()
        
        let bezierPath = path.cgPath
        fillColor.setFill()
        strokeColor.setStroke()
        context.addPath(bezierPath)
        context.drawPath(using: .fillStroke)
    }   
    
    
    open override func renderGridLines(context: CGContext)
    {
        guard let
            yAxis = self.axis as? YAxis
            else { return }
        
        if !yAxis.isEnabled
        {
            return
        }
        
        if yAxis.drawGridLinesEnabled
        {
            let positions = transformedPositions()
            
            context.saveGState()
            defer { context.restoreGState() }
            context.clip(to: self.gridClippingRect)
            
            context.setShouldAntialias(yAxis.gridAntialiasEnabled)
            context.setStrokeColor(yAxis.gridColor.cgColor)
            context.setLineWidth(yAxis.gridLineWidth)
            context.setLineCap(yAxis.gridLineCap)
            
            if yAxis.gridLineDashLengths != nil
            {
                context.setLineDash(phase: yAxis.gridLineDashPhase, lengths: yAxis.gridLineDashLengths)
                
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            // draw the grid
            for i in 0 ..< positions.count
            {
                drawGridLine(context: context, position: positions[i])
            }
        }
        
        if yAxis.drawZeroLineEnabled
        {
            // draw zero line
            drawZeroLine(context: context)
        }
    }
    
    @objc open var gridClippingRect: CGRect
    {
        var contentRect = viewPortHandler.contentRect
        let dy = self.axis?.gridLineWidth ?? 0.0
        contentRect.origin.y -= dy / 2.0
        contentRect.size.height += dy
        return contentRect
    }
    
    @objc open func drawGridLine(
        context: CGContext,
        position: CGPoint)
    {
        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
        context.strokePath()
    }
    
    @objc open func transformedPositions() -> [CGPoint]
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return [CGPoint]() }
        
        var positions = [CGPoint]()
        positions.reserveCapacity(yAxis.entryCount)
        
        let entries = yAxis.entries
        
        for i in stride(from: 0, to: yAxis.entryCount, by: 1)
        {
            positions.append(CGPoint(x: 0.0, y: entries[i]))
        }
        
        transformer.pointValuesToPixel(&positions)
        
        return positions
    }
    
    /// Draws the zero line at the specified position.
    @objc open func drawZeroLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer,
            let zeroLineColor = yAxis.zeroLineColor
            else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.y -= yAxis.zeroLineWidth / 2.0
        clippingRect.size.height += yAxis.zeroLineWidth
        context.clip(to: clippingRect)
        
        context.setStrokeColor(zeroLineColor.cgColor)
        context.setLineWidth(yAxis.zeroLineWidth)
        
        let pos = transformer.pixelForValues(x: 0.0, y: 0.0)
        
        if yAxis.zeroLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.zeroLineDashPhase, lengths: yAxis.zeroLineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: pos.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: pos.y))
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    open override func renderLimitLines(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return }
        
        var limitLines = yAxis.limitLines
        
        if limitLines.count == 0
        {
            return
        }
        
        context.saveGState()
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for i in 0 ..< limitLines.count
        {
            let l = limitLines[i]
            
            if !l.isEnabled
            {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            var clippingRect = viewPortHandler.contentRect
            clippingRect.origin.y -= l.lineWidth / 2.0
            clippingRect.size.height += l.lineWidth
            context.clip(to: clippingRect)
            
            position.x = 0.0
            position.y = CGFloat(l.limit)
            position = position.applying(trans)
            
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
            
            context.setStrokeColor(l.lineColor.cgColor)
            context.setLineWidth(l.lineWidth)
            if l.lineDashLengths != nil
            {
                context.setLineDash(phase: l.lineDashPhase, lengths: l.lineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            context.strokePath()
            
            let label = l.label
            
            // if drawing the limit-value label is enabled
            if l.drawLabelEnabled && label.count > 0
            {
                let labelLineHeight = l.valueFont.lineHeight
                
                let xOffset: CGFloat = 4.0 + l.xOffset
                let yOffset: CGFloat = l.lineWidth + labelLineHeight + l.yOffset
                
                if l.labelPosition == .rightTop
                {
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentRight - xOffset,
                                            y: position.y - yOffset),
                                        align: .right,
                                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else if l.labelPosition == .rightBottom
                {
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentRight - xOffset,
                                            y: position.y + yOffset - labelLineHeight),
                                        align: .right,
                                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else if l.labelPosition == .leftTop
                {
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentLeft + xOffset,
                                            y: position.y - yOffset),
                                        align: .left,
                                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
                else
                {
                    ChartUtils.drawText(context: context,
                                        text: label,
                                        point: CGPoint(
                                            x: viewPortHandler.contentLeft + xOffset,
                                            y: position.y + yOffset - labelLineHeight),
                                        align: .left,
                                        attributes: [NSAttributedString.Key.font: l.valueFont, NSAttributedString.Key.foregroundColor: l.valueTextColor])
                }
            }
        }
        
        context.restoreGState()
    }
}
extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}

extension String {
    static let numberFormatter = NumberFormatter()
    var doubleValue: Double {
        String.numberFormatter.decimalSeparator = "."
        if let result =  String.numberFormatter.number(from: self) {
            return result.doubleValue
        } else {
            String.numberFormatter.decimalSeparator = ","
            if let result = String.numberFormatter.number(from: self) {
                return result.doubleValue
            }
        }
        return 0
    }
}