//
//  CameraCaptureView.swift
//  Snap Macros
//

import SwiftUI
import UIKit

// SwiftUI wrapper that shows either the Camera (on device) or Photo Library (on simulator / if camera unavailable)
// It returns the picked image via the binding and dismisses itself via the environment dismiss
struct CameraCaptureView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var useCamera = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        //UIKitImagePicker(source: .photoLibrary,
        UIKitImagePicker(source: useCamera ? .camera : .photoLibrary, image: $image) {
            //called on cancel or after picking image — close the sheet
            dismiss()
        }
        .ignoresSafeArea()
    }
}

private struct UIKitImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, photoLibrary }

    let source: Source
    @Binding var image: UIImage?
    var onFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = (source == .camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: UIKitImagePicker
        init(_ parent: UIKitImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onFinish()
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                parent.image = img
            }
            parent.onFinish()
        }
    }
}

