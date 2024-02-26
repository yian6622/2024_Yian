import SwiftUI
import UIKit

struct ContentView: View {
    @State private var mondrianImage: Image? = nil

    var body: some View {
        VStack {
            if let mondrianImage = mondrianImage {
                mondrianImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()
            } else {
                Text("Generating art...")
                    .padding()
            }
            Button("Refresh") {
                let uiImage = generateMondrianStyleImage()
                mondrianImage = Image(uiImage: uiImage)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .onAppear {
            // Generate the image when the view appears
            let uiImage = generateMondrianStyleImage()
            mondrianImage = Image(uiImage: uiImage)
        }
    }
    
    func generateMondrianStyleImage() -> UIImage {
        let dim = 312.0 // Smaller size for demonstration
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        
        let image = renderer.image { ctx in
            let cgContext = ctx.cgContext
            let box = ctx.format.bounds
            UIColor.white.setFill()
            cgContext.fill(box)
            
            let colors = [UIColor.red, UIColor.blue, UIColor.yellow, UIColor.white]
            let lineWidth = 8.0
            
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
                let rectWidth = CGFloat.random(in: 50...200)
                var y: CGFloat = 0.0
                while y < box.height {
                    let rectHeight = CGFloat.random(in: 50...200)
                    let color = colors.randomElement()!
                    drawRect(in: cgContext, x: x, y: y, width: rectWidth, height: rectHeight, color: color)
                    y += rectHeight
                }
                x += rectWidth
            }
        }
        
        return image
    }
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
