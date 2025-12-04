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
```xml
struct OpenAIClient {
    var model: String = "gpt-4o-mini"
    // Put your key here
    private let apiKey: String = "apikey"
}
```

---

## Step-by-Step: Camera → Image → AI

### 1. CameraCaptureView – Wrapping UIImagePickerController in SwiftUI

