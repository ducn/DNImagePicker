//
//  WDImagePicker.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit

@objc public protocol WDImagePickerDelegate {
    @objc optional func imagePicker(_ imagePicker: WDImagePicker, pickedImage: UIImage)
    @objc optional func imagePickerDidCancel(_ imagePicker: WDImagePicker)
}

@objc open class WDImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WDImageCropControllerDelegate {
    open var delegate: WDImagePickerDelegate?
    open var cropSize: CGSize!
    open var resizableCropArea = false

    fileprivate var _imagePickerController: UIImagePickerController!

    open var imagePickerController: UIImagePickerController {
        return _imagePickerController
    }
    
    override public init() {
        super.init()

        self.cropSize = CGSize(width: 320, height: 320)
        _imagePickerController = UIImagePickerController()
        _imagePickerController.delegate = self
        _imagePickerController.sourceType = .photoLibrary
    }

    fileprivate func hideController() {
        self._imagePickerController.dismiss(animated: true, completion: nil)
    }

    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if self.delegate?.imagePickerDidCancel != nil {
            self.delegate?.imagePickerDidCancel!(self)
        } else {
            self.hideController()
        }
    }

    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let cropController = WDImageCropViewController()
        cropController.sourceImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        cropController.resizableCropArea = self.resizableCropArea
        cropController.cropSize = self.cropSize
        cropController.delegate = self
        picker.pushViewController(cropController, animated: true)
    }

    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedImage croppedImage: UIImage) {
        self.delegate?.imagePicker?(self, pickedImage: croppedImage)
    }
    
    func imageCropControllerDidCancel(_ imageCropController: WDImageCropViewController) {
        
    }
}
