//
//  DNVideoEditorController.swift
//  QnR
//
//  Created by Duc Ngo on 1/19/17.
//  Copyright © 2017 cinnamon. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import CoreMedia
import Photos
import ICGVideoTrimmer

internal protocol DNVideoEditorControllerDelegate:class {
    func videoEditorController(_ videoEditController: DNVideoEditorController, didSaveEditedVideoToPath editedVideoPath: URL?)
    func videoEditorControllerDidCancel(_ videoEditController: DNVideoEditorController)
}

internal class DNVideoEditorController: UIViewController{
    
    //MARK:- System Events
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layoutIfNeeded()
        loadAsset()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeChecker()
    }

    //MARK:- View Events
    
    //MARK:- Utils
    private func loadAsset(){
        guard let url = videoUrl else { return }
        let asset = AVURLAsset(url: url)
        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        
        // playback
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let videoSize = getResolution(track: videoTrack)
        let playbackSize = scaledSize(in: playbackScrollView, with: videoSize)
        playbackTrailingConstraint.constant = playbackSize.width - playbackScrollView.bounds.width
        playbackBottomConstraint.constant = playbackSize.height - playbackScrollView.bounds.height
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.contentsGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.frame = CGRect(x: 0, y: 0, width: playbackSize.width, height: playbackSize.height)
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        playbackView.layer.insertSublayer(playerLayer, at: 0)                
        _playerLayer = playerLayer
        _asset = asset
        _player = player
        _playedPosition = 0
        // trimmer
        let duration = Float(CMTimeGetSeconds(asset.duration))
        trimmerView.asset = _asset
        trimmerView.themeColor = UIColor.lightGray
        trimmerView.showsRulerView = true
        trimmerView.delegate = self
        trimmerView.trackerColor = UIColor.cyan
        trimmerView.maxLength = duration > maxTrimLength ? CGFloat(maxTrimLength) : CGFloat(floor(duration) + 1)
        trimmerView.maxLength = trimmerView.maxLength > 15 ? trimmerView.maxLength : 15
        trimmerView.minLength = CGFloat(minTrimLength)
        trimmerView.resetSubviews()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(DNVideoEditorController.playbackViewDidTap))
        playbackView.addGestureRecognizer(tapGesture)
        playbackViewDidTap()
    }

    func getResolution(track: AVAssetTrack)->CGSize{
        let videoPreferredSize = track.naturalSize.applying(track.preferredTransform)
        let resolution = CGSize(width:fabs(videoPreferredSize.width), height:fabs(videoPreferredSize.height))
        return resolution
    }
    
    func scaledSize(in container: UIView, with originSize:CGSize)->CGSize{
        var containerSize = CGSize(width: container.bounds.width, height: container.bounds.height)
        if originSize.width > originSize.height{
            let scale = containerSize.height / originSize.height
            containerSize.width = scale * originSize.width
        }else{
            let scale = containerSize.width / originSize.width
            containerSize.height = scale * originSize.height
        }
        return containerSize
    }
    
    //MARK:- Playback Timer
    func playerTimerTick(){
        guard let player = _player else { return}
        _playedPosition = CMTimeGetSeconds(player.currentTime());
        trimmerView.seek(toTime: CGFloat(_playedPosition))
        if _playedPosition >= _stopTime{
            _playedPosition = _startTime
            seekVideo(to: _startTime)
            trimmerView.seek(toTime: CGFloat(_startTime))
        }
    }
    
    func seekVideo(to pos: Float64) {
        guard let player = _player else { return}
        _playedPosition = pos
        let time = CMTimeMakeWithSeconds(_playedPosition, player.currentTime().timescale);
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        _playbackTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(playerTimerTick),
                             userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker(){
        _playbackTimer?.invalidate()
        _playbackTimer = nil
    }
    
    func dlog<T>(_ str: T) {
        //print("DNImagePicker: \(str)")
    }

    //MARK:- Vars
    weak var delegate: DNVideoEditorControllerDelegate?
    var videoUrl:URL?
    var maxTrimLength:Float = 60 // in seconds
    var minTrimLength:Float = 3 // in seconds
    
    fileprivate var _asset:AVAsset?
    fileprivate var _player: AVPlayer?
    fileprivate var _playerLayer: AVPlayerLayer?
    fileprivate var _exporter: AVAssetExportSession!
    fileprivate var _isPlaying = false
    fileprivate var _playbackTimer: Timer?
    fileprivate var _playedPosition:Float64 = 0
    fileprivate var _startTime:Float64 = 0
    fileprivate var _stopTime:Float64 = 0
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView!
    @IBOutlet weak var playbackView: UIView!
    @IBOutlet weak var playbackScrollView: UIScrollView!
    @IBOutlet weak var playbackTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var playbackBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
}


extension DNVideoEditorController:ICGVideoTrimmerDelegate{
    func trimmerView(_ trimmerView: ICGVideoTrimmerView, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        if (startTime != CGFloat(_startTime)) {
            seekVideo(to: Float64(startTime))
        }
        _startTime = Float64(startTime);
        _stopTime = Float64(endTime);
    }
}

extension DNVideoEditorController/*Trim*/{
    
}
extension DNVideoEditorController/*Crop*/{
    func trimAndCrop(){
        guard let asset = _asset else {return}
        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        let outputSize = playbackScrollView.bounds.size
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.renderSize = outputSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let wbound = playbackScrollView.contentSize.width - playbackScrollView.bounds.width
        let hbound = playbackScrollView.contentSize.height - playbackScrollView.bounds.height
        var offset = CGPoint.zero
        if wbound != 0 {
            offset = CGPoint(x: playbackScrollView.contentOffset.x/wbound, y:0)
        }else{
            offset = CGPoint(x: 0, y: playbackScrollView.contentOffset.y/hbound)
        }
        dlog("offset: \(offset)")
        let videoSize = getResolution(track: videoTrack)
        let videoTransform = getResizeAspectFillTransform(videoSize: videoSize,
                                                          outputSize: outputSize,
                                                          offset: offset,
                                                          preferredTransform: videoTrack.preferredTransform)
        videoLayerInstruction.setTransform(videoTransform, at: kCMTimeZero)
        instruction.layerInstructions = [videoLayerInstruction]
        videoComposition.instructions = [instruction]
        
        let start = CMTimeMakeWithSeconds(_startTime, asset.duration.timescale)
        let duration = CMTimeMakeWithSeconds(_stopTime - _startTime, asset.duration.timescale)
        let trimRange = CMTimeRangeMake(start, duration);
        dlog("trimmed at: \(_startTime), duration: \(_stopTime - _startTime)")
        let fileName = "\(UUID().uuidString).mp4"
        let exportUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: exportUrl)
        }
        catch _ {}
        _exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        _exporter.videoComposition = videoComposition
        _exporter.outputURL = exportUrl
        _exporter.outputFileType = AVFileTypeQuickTimeMovie
        _exporter.timeRange = trimRange
        dlog("start export...")
        _exporter.exportAsynchronously(completionHandler: {[weak self]() -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                //self.saveToLibrary(url: self._exporter.outputURL!)
                self?.dlog("finished export: \(self?._exporter.outputURL)")
                self?.videoDidFinishExport(at: self?._exporter.outputURL)
            })
        })

    }
    
    private func saveToLibrary(url:URL){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Saved to Photo Library!", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    private func getResizeAspectFillTransform(videoSize: CGSize,
                                              outputSize: CGSize,
                                              offset:CGPoint,
                                              preferredTransform:CGAffineTransform) -> CGAffineTransform {
        dlog("videoSize = \(videoSize.width)/\(videoSize.height)")
        dlog("outputSize = \(outputSize.width)/\(outputSize.height)")
        dlog("offset = \(offset.x)/\(offset.y)")
        let widthRatio = outputSize.width / videoSize.width
        let heightRatio = outputSize.height / videoSize.height
        dlog("widthRatio = \(widthRatio)")
        dlog("heightRatio = \(heightRatio)")
        let scale = widthRatio >= heightRatio ? widthRatio : heightRatio
        dlog("scale = \(scale)")
        let newWidth = videoSize.width * scale
        let newHeight = videoSize.height * scale
        dlog("newWidth/newHeight = \(newWidth)/\(newHeight)")
        let translateX = (offset.x * (outputSize.width - newWidth))
        let translateY = (offset.y * (outputSize.height - newHeight))
        dlog("translateX/translateY = \(translateX)/\(translateY)")
        var transform = preferredTransform
        transform = preferredTransform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        transform = transform.concatenating(CGAffineTransform(translationX: translateX, y: translateY))
        return transform
    }

}

extension DNVideoEditorController/*IBActions*/{
    func playbackViewDidTap(){
        _isPlaying = !_isPlaying
        if _isPlaying {
            _player?.play()
            startPlaybackTimeChecker()
        } else{
            _player?.pause()
            stopPlaybackTimeChecker()
        }
    }
    
    func videoDidFinishExport(at url:URL?){
        view.isUserInteractionEnabled = true
        loadingIndicator.stopAnimating()
        delegate?.videoEditorController(self, didSaveEditedVideoToPath: url)
    }
    
    @IBAction func cancelButtonDidTouch(){
        //self.parent?.dismiss(animated: true, completion: nil)
        delegate?.videoEditorControllerDidCancel(self)
    }
    
    @IBAction func doneButtonDidTouch(){
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        trimAndCrop()
    }
}
