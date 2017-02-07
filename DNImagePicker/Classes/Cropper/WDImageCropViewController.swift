//
//  WDImageCropViewController.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit
import CoreGraphics

internal protocol WDImageCropControllerDelegate {
    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedImage croppedImage: UIImage)
    func imageCropControllerDidCancel(_ imageCropController: WDImageCropViewController)
}

internal class WDImageCropViewController: UIViewController {
    var sourceImage: UIImage!
    var delegate: WDImageCropControllerDelegate?
    var cropSize: CGSize!
    var resizableCropArea = false

    fileprivate var croppedImage: UIImage!

    fileprivate var imageCropView: WDImageCropView!
    fileprivate var toolbar: UIToolbar!
    fileprivate var useButton: UIButton!
    fileprivate var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false

        self.title = localizedString(for: "Choose Photo")

        self.setupNavigationBar()
        self.setupCropView()
        self.setupToolbar()

        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationController?.isNavigationBarHidden = true
        } else {
            self.navigationController?.isNavigationBarHidden = false
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.imageCropView.frame = self.view.bounds
        self.toolbar?.frame = CGRect(x: 0, y: self.view.frame.height - 54,
            width: self.view.frame.size.width, height: 54)
    }

    func actionCancel(_ sender: AnyObject) {        
        delegate?.imageCropControllerDidCancel(self)
    }

    func actionUse(_ sender: AnyObject) {
        croppedImage = self.imageCropView.croppedImage()
        self.delegate?.imageCropController(self, didFinishWithCroppedImage: croppedImage)
    }

    fileprivate func setupNavigationBar() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self, action: #selector(actionCancel))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Use", style: .plain,
            target: self, action: #selector(actionUse))
    }

    fileprivate func setupCropView() {
        self.imageCropView = WDImageCropView(frame: self.view.bounds)
        self.imageCropView.imageToCrop = sourceImage
        self.imageCropView.resizableCropArea = self.resizableCropArea
        self.imageCropView.cropSize = cropSize
        self.view.addSubview(self.imageCropView)
    }

    fileprivate func setupCancelButton() {
        self.cancelButton = UIButton()
        self.cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        self.cancelButton.titleLabel?.shadowOffset = CGSize(width: 0, height: -1)
        self.cancelButton.frame = CGRect(x: 0, y: 0, width: 58, height: 30)
        self.cancelButton.setTitle(localizedString(for: "Cancel"), for: UIControlState())
        self.cancelButton.setTitleShadowColor(
            UIColor(red: 0.118, green: 0.247, blue: 0.455, alpha: 1), for: UIControlState())
        self.cancelButton.addTarget(self, action: #selector(actionCancel), for: .touchUpInside)
    }

    fileprivate func setupUseButton() {
        self.useButton = UIButton()
        self.useButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        self.useButton.titleLabel?.shadowOffset = CGSize(width: 0, height: -1)
        self.useButton.frame = CGRect(x: 0, y: 0, width: 58, height: 30)
        self.useButton.setTitle(localizedString(for: "Use"), for: UIControlState())
        self.useButton.setTitleShadowColor(
            UIColor(red: 0.118, green: 0.247, blue: 0.455, alpha: 1), for: UIControlState())
        self.useButton.addTarget(self, action: #selector(actionUse), for: .touchUpInside)
    }

    fileprivate func toolbarBackgroundImage() -> UIImage {
        let components: [CGFloat] = [1, 1, 1, 1, 123.0 / 255.0, 125.0 / 255.0, 132.0 / 255.0, 1]

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 320, height: 54), true, 0)

        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: nil, count: 2)

        context?.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 54), options: [])

        let viewImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return viewImage!
    }
    
    fileprivate func localizedString(for string:String)->String{
        if let bundle = libBundle(){
            return NSLocalizedString(string, tableName: nil, bundle: bundle, value: "", comment: "")
        }
        return string
    }
    
    fileprivate func libBundle()->Bundle?{
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: "DNImagePicker", withExtension: "bundle"){
            return Bundle(url: bundleURL)
        }
        return nil
    }

    fileprivate func setupToolbar() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.toolbar = UIToolbar(frame: CGRect.zero)
            self.toolbar.isTranslucent = true
            self.toolbar.barStyle = .black
            self.view.addSubview(self.toolbar)

            self.setupCancelButton()
            self.setupUseButton()

            let info = UILabel(frame: CGRect.zero)
            info.text = ""
            info.textColor = UIColor(red: 0.173, green: 0.173, blue: 0.173, alpha: 1)
            info.backgroundColor = UIColor.clear
            info.shadowColor = UIColor(red: 0.827, green: 0.731, blue: 0.839, alpha: 1)
            info.shadowOffset = CGSize(width: 0, height: 1)
            info.font = UIFont.boldSystemFont(ofSize: 18)
            info.sizeToFit()

            let cancel = UIBarButtonItem(customView: self.cancelButton)
            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let label = UIBarButtonItem(customView: info)
            let use = UIBarButtonItem(customView: self.useButton)

            self.toolbar.setItems([cancel, flex, label, flex, use], animated: false)
        }
    }
}
