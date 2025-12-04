# SnapMacros Camera Capture Tutorial  
## Camera Capture → Image → OpenAI 

## Overview

This tutorial explains **exactly how SnapMacros handles camera images**, step by step:

1. Tap **“Snap Meal”**
2. Open the **camera or photo library**
3. Capture/select an image and store it
4. Send the image to the **OpenAI API** for macro estimation
5. Show a **confirmation sheet** with the image and editable macros
6. Save the meal so it appears in the **Today** list with a thumbnail

We’ll focus only on the parts of the code that matter for:

- Camera capture (`CameraCaptureView`)
- Holding the image (`CameraViewModel`)
- Sending the image to OpenAI (`OpenAIClient` + `AnalysisViewModel`)
- Showing the image in the confirm sheet and in the meal list

All snippets below are directly from your project, with `...` where the rest of the file continues.

---

## Getting Started

### Requirements

- Xcode installed (same setup you used for this project)
- iOS target that supports SwiftUI and `UIImagePickerController`
- A valid **OpenAI API key**

### Info.plist – Camera Permission

Because we use the device camera, we need a camera usage description:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take meal photos for macro estimation.</string>
```
