import UIKit

let dim = 1024.0
let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))

var image = renderer.image { ctx in
    let cgContext = ctx.cgContext
    let box = ctx.format.bounds
    UIColor.white.setFill()
    cgContext.fill(box)
    
    let colors = [UIColor.red, UIColor.blue, UIColor.yellow, UIColor.white]
    let lineWidth = 8.0 // Width of the black lines
    
    // Function to draw a rectangle with a specified color
    func drawRect(in cgContext: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        cgContext.addRect(rect)
        color.setFill()
        cgContext.fill(rect)
        UIColor.black.setStroke()
        cgContext.setLineWidth(lineWidth)
        cgContext.stroke(rect)
    }
    
    var x: CGFloat = 0.0
    while x < box.width {
        let rectWidth = CGFloat.random(in: 50...200) // Determine column width here
        var y: CGFloat = 0.0
        while y < box.height {
            let rectHeight = CGFloat.random(in: 50...200) // Random height for each rectangle
            let color = colors.randomElement()! // Random color selection
            drawRect(in: cgContext, x: x, y: y, width: rectWidth, height: rectHeight, color: color)
            y += rectHeight
        }
        x += rectWidth // Now 'rectWidth' is in scope for this increment
    }
}

// Convert the image to PNG data and write it to a file
if let data = image.pngData() {
    let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let filePath = folder.appendingPathComponent("MondrianStyle2024.png")
    do {
        try data.write(to: filePath)
        print("Image saved to \(filePath)")
    } catch {
        print("Failed to save image: \(error)")
    }
} else {
    print("Failed to save image")
}
