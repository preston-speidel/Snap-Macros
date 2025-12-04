# SnapMacros Camera Capture Tutorial  
## Camera Capture → Image → OpenAI 

## Overview

This tutorial explains how SnapMacros handles camera images, step by step:

1. Tap **“Snap Meal”**
2. Open the **camera**
3. Capture an image and store it
4. Send the image to the **OpenAI API** for macro estimation
5. Show a **confirmation sheet** with the image and editable macros
6. Save the meal so it appears in the **Today** list with a thumbnail

We’ll focus only on the parts of the code that matter for:

- Camera capture (`CameraCaptureView`)
- Holding the image (`CameraViewModel`)
- Sending the image to OpenAI (`OpenAIClient` + `AnalysisViewModel`)
- Showing the image in the confirm sheet and in the meal list

---

## Getting Started

### Requirements

- Xcode installed
- iOS target that supports SwiftUI and `UIImagePickerController`
- A valid **OpenAI API key** (needed for the actual macro estimation) 

### Info.plist – Camera Permission

Because we use the device camera, we need a camera usage description (edit the info.plist):

![Screenshot](infoplistCamera.png)

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take meal photos for macro estimation.</string>
```

<iframe width="560" height="315"
src="https://www.youtube.com/embed/GAHWt2HPEIM"
title="YouTube video player" frameborder="0"
allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen>
</iframe>

### OpenAI API Key

Snapmacros sends the image of your food to OpenAI to get the estimated macros, in order for it to work correctly a API key is needed for the calculation.
```swift
struct OpenAIClient {
    var model: String = "gpt-4o-mini"
    // Put your key here
    private let apiKey: String = "apikey"
}
```

---

## Step-by-Step: Camera → Image → AI

### 1. CameraCaptureView – Wrapping UIImagePickerController in SwiftUI

CameraCaptureView is a SwiftUI view that shows either the camera or photo library and returns the picked image through a binding.

File: CameraCaptureView.swift
```swift
struct CameraCaptureView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var useCamera = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        UIKitImagePicker(source: useCamera ? .camera : .photoLibrary,
                         image: $image) {
            dismiss()
        }
        .ignoresSafeArea()
    }
}
```
The real work is done in the UIKitImagePicker bridge:
```swift
private struct UIKitImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, photoLibrary }

    let source: Source
    @Binding var image: UIImage?
    var onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = (source == .camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    ...

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: UIKitImagePicker

        ...

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                parent.image = img
            }
            parent.onFinish()
        }
    }
}
```
- CameraCaptureView decides camera vs photo library with useCamera.
- UIKitImagePicker uses UIImagePickerController under the hood.
- When the user picks/cancels, image (the binding) is updated and onFinish() closes the sheet.

### 2. CameraViewModel – Where the Captured Image Lives

You keep the last captured image in a simple view model.

File: ViewModels.swift
```swift
final class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage? = nil
}
```
This lets you:
- Bind CameraCaptureView directly to cameraVM.capturedImage.
- React to that image in HomeView once the picker dismisses. 
