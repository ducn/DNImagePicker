# DNImagePicker
A replacement of UIImagePickerController with additional trim/crop square video supported!. 
Thanks for WDImagePicker & ICGVideoTrimmer

## Install

```ruby
use_frameworks!

pod 'DNImagePicker'
```
## Usage

```swift
let imagePicker = DNImagePicker()
// Setup media types
imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
// Setup trim length for video
imagePicker.maxTrimLength = 30 //seconds
imagePicker.minTrimLength = 15 //seconds
imagePicker.delegate = self

self.presentViewController(imagePicker, animated: true, completion: nil)
```

And received image/video via delegates exactly the same as UIImagePickerController protocol

```swift
func imagePickerControllerDidCancel(_ picker: DNImagePickerController) {
    
}

func imagePickerController(_ picker: DNImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
        // Receive video url here
    }
    else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
        // Receive image here
    }
}
```swift

## Screenshot

Trim/crop video screen:
https://raw.githubusercontent.com/ducn/DNImagePicker/master/crop-video.png

Crop photo screen
https://raw.githubusercontent.com/ducn/DNImagePicker/master/crop-photo.png

### License
MIT
