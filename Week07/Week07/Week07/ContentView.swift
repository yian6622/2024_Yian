import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var uiImages: [UIImage?] = [nil, nil, nil]
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?

    var body: some View {
        VStack {
            HStack {
                ForEach(0..<uiImages.count, id: \.self) { index in
                    if let uiImage = uiImages[index] {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }

            HStack {
                Button("Sepia Tone") {
                    applyFilter(filter: "CISepiaTone")
                }
                Button("Noir") {
                    applyFilter(filter: "CIPhotoEffectNoir")
                }
                Button("Mono") {
                    applyFilter(filter: "CIPhotoEffectMono")
                }
            }
            .padding()

            Button("Select Image") {
                showingImagePicker = true
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImages) {
            ImagePicker(image: $inputImage)
        }
    }

    func loadImages() {
        guard let inputImage = self.inputImage else { return }
        uiImages = [inputImage, inputImage, inputImage]  // Assign the same image to all for demonstration
    }

    func applyFilter(filter: String) {
        let context = CIContext()

        for index in uiImages.indices {
            guard let inputImage = uiImages[index] else { continue }
            let beginImage = CIImage(image: inputImage)

            if let currentFilter = CIFilter(name: filter) {
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

                if let output = currentFilter.outputImage, let cgimg = context.createCGImage(output, from: output.extent) {
                    uiImages[index] = UIImage(cgImage: cgimg)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
