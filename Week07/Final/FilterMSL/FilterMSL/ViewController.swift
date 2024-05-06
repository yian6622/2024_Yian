//
//  ViewController.swift
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var videoCapture: VideoCaptureService!
    var videoView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        videoCapture = VideoCaptureService()
        setupVideoDisplayView()
        videoCapture.startSession()
    }

    private func setupVideoDisplayView() {
        videoView = MTKView(frame: view.bounds)
        videoView.device = MTLCreateSystemDefaultDevice()
        view.addSubview(videoView)

        if let processor = videoCapture.videoProcessor {
            processor.setupTargetView(videoView)
        }
    }
}

