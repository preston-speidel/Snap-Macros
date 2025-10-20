//
//  CameraCaptureView.swift
//  Snap Macros
//

import SwiftUI
import PhotosUI

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            Text("Capture a meal")
                .font(.title2).bold()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            } else {
                Text("No image yet").foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button("Open Camera") { presentCamera() }
                    .buttonStyle(.borderedProminent)
                Button("Photo Library") { presentLibrary() }
                    .buttonStyle(.bordered)
            }

            if image != nil {
                Button("Use Photo") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }

    private func presentCamera() {
        #if targetEnvironment(simulator)
        // Simulator lacks camera — fall back to library
        presentLibrary()
        #else
        ImagePicker.present(source: .camera) { picked in
            self.image = picked
        }
        #endif
    }

    private func presentLibrary() {
        ImagePicker.present(source: .photoLibrary) { picked in
            self.image = picked
        }
    }
}

// Minimal UIImagePickerController wrapper for SwiftUI
final class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let picker = UIImagePickerController()
    var completion: (UIImage?) -> Void

    init(source: UIImagePickerController.SourceType, completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        super.init()
        picker.sourceType = source
        picker.allowsEditing = false
        picker.delegate = self
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let img = (info[.originalImage] as? UIImage)
        completion(img)
        picker.presentingViewController?.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        completion(nil)
        picker.presentingViewController?.dismiss(animated: true)
    }
}

enum ImagePicker {
    static func present(source: UIImagePickerController.SourceType, completion: @escaping (UIImage?) -> Void) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else { return }
        let coord = ImagePickerCoordinator(source: source, completion: completion)
        root.present(coord.picker, animated: true)
    }
}

extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: { $0.isKeyWindow }) }
}
