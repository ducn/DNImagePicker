//
//  PhotoLibraryPickerViewController.swift
//  QnR
//
//  Created by Duc Ngo on 1/19/17.
//  Copyright © 2017 cinnamon. All rights reserved.
//

import Foundation
import UIKit
import Photos
import MobileCoreServices

public protocol DNImagePickerControllerDelegate:class{
    func imagePickerControllerDidCancel(_ picker: DNImagePickerController)
    func imagePickerController(_ picker: DNImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
}

public class DNImagePickerController: UIViewController{
    public weak var delegate: DNImagePickerControllerDelegate?
    public var mediaTypes:[String] = [kUTTypeMovie as String, kUTTypeImage as String]
    public var maxTrimLength:Float = 60.0 // in seconds
    public var minTrimLength:Float = 3.0 // in seconds
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        useDefaultPickerUI()
    }
    
    private func useDefaultPickerUI(){
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.mediaTypes = self.mediaTypes
        picker.delegate = self
        addChild(controller: picker)
        _internalPicker = picker
    }
    
    fileprivate func openVideoEditor(with videoUrl:URL){
        _internalPicker?.view.removeFromSuperview()
        _internalPicker?.removeFromParentViewController()
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: "DNImagePicker", withExtension: "bundle"),
            let bundle = Bundle(url: bundleURL){
            let videoEditor = DNVideoEditorController(nibName: "DNVideoEditorController", bundle: bundle)
            videoEditor.videoUrl = videoUrl
            videoEditor.delegate = self
            videoEditor.maxTrimLength = maxTrimLength
            videoEditor.minTrimLength = minTrimLength
            addChild(controller: videoEditor)
        }
    }
    
    fileprivate func openImageEditor(image: UIImage){
        let screenSize = UIScreen.main.bounds
        let imageEditor = WDImageCropViewController()
        imageEditor.sourceImage = image
        imageEditor.cropSize = CGSize(width: screenSize.width, height: screenSize.width)
        imageEditor.delegate = self
        addChild(controller: imageEditor)
    }
    
    fileprivate func addChild(controller: UIViewController){
        let constrains = [NSLayoutAttribute.top, NSLayoutAttribute.left,
                          NSLayoutAttribute.right, NSLayoutAttribute.bottom]
        self.addChildViewController(controller)
        let subview = controller.view!
        self.view.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        for constrain in constrains {
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: constrain, relatedBy: NSLayoutRelation.equal, toItem: subview, attribute: constrain, multiplier: 1.0, constant: 0))
        }
        controller.didMove(toParentViewController: self)
    }
    
    fileprivate func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate weak var _internalPicker: UIImagePickerController?
}

extension DNImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.imagePickerControllerDidCancel(self)
        dismiss()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let mediaUrl = info[UIImagePickerControllerMediaURL] as? URL {
            openVideoEditor(with: mediaUrl)
        }else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            openImageEditor(image: image)
        }else{
            dismiss()
        }
    }
}

extension DNImagePickerController: DNVideoEditorControllerDelegate{
    func videoEditorControllerDidCancel(_ videoEditController: DNVideoEditorController) {
        delegate?.imagePickerControllerDidCancel(self)
        dismiss()
    }
    
    func videoEditorController(_ videoEditController: DNVideoEditorController, didSaveEditedVideoToPath editedVideoPath: URL?) {
        let info = [UIImagePickerControllerMediaURL:editedVideoPath]
        delegate?.imagePickerController(self, didFinishPickingMediaWithInfo: info)
        dismiss()
    }
}

extension DNImagePickerController: WDImageCropControllerDelegate{
    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedImage croppedImage: UIImage) {
        let info = [UIImagePickerControllerOriginalImage:croppedImage]
        delegate?.imagePickerController(self, didFinishPickingMediaWithInfo: info)
        dismiss()
    }
    
    func imageCropControllerDidCancel(_ imageCropController: WDImageCropViewController) {
        delegate?.imagePickerControllerDidCancel(self)
        dismiss()
    }
}
