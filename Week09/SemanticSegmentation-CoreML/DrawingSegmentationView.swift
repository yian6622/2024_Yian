//
//  DrawingSegmentationView.swift
//  SemanticSegmentation-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit

class DrawingSegmentationView: UIView {
    
    enum ShaderType {
            case standard
            case day41
            case day70
            case ex002
        }
    
    // Current shader type
        var currentShader: ShaderType = .standard {
            didSet {
                self.setNeedsDisplay()  // Redraw view when shader changes
            }
        }
    
    static private var colors: [Int32: UIColor] = [:]
    
    func segmentationColor(with index: Int32) -> UIColor {
        if let color = DrawingSegmentationView.colors[index] {
            return color
        } else {
            let color = UIColor(hue: CGFloat(index) / CGFloat(30), saturation: 1, brightness: 1, alpha: 0.5)
            print(index)
            DrawingSegmentationView.colors[index] = color
            return color
        }
    }
    
    var segmentationmap: SegmentationResultMLMultiArray? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    enum ShaderMode {
        case standard, day70, custom
    }

    var shaderMode: ShaderMode = .standard {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), let segmentationmap = self.segmentationmap else { return }
        ctx.clear(rect)

        let size = self.bounds.size
        let segmentationmapWidthSize = segmentationmap.segmentationmapWidthSize
        let segmentationmapHeightSize = segmentationmap.segmentationmapHeightSize
        let w = size.width / CGFloat(segmentationmapWidthSize)
        let h = size.height / CGFloat(segmentationmapHeightSize)

        for j in 0..<segmentationmapHeightSize {
            for i in 0..<segmentationmapWidthSize {
                let value = segmentationmap[j, i].int32Value
                let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)

                let color: UIColor = {
                    switch currentShader {
                    case .standard:
                        return segmentationColor(with: value)
                    case .day41:
                        // Placeholder for day41 shader effect
                        return UIColor.blue
                    case .day70:
                        // Placeholder for day70 shader effect
                        return UIColor.red
                    case .ex002:
                        // Placeholder for ex002 shader effect
                        return UIColor.green
                    }
                }()
                color.setFill()
                UIRectFill(rect)
            }
        }
    }


}
