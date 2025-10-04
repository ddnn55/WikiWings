//
//  ViewController.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import UIKit
import WebKit
import CoreMotion

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var displayLink: CADisplayLink!
    private var startTime: CFTimeInterval = 0
    private var motionManager: CMMotionManager!
    private var controlX: Double = 0.0
    private var controlY: Double = 0.0
    private var horizontalLine: UIView!
    private var verticalLine: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure webview to show desktop layout
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Version/15.0 Safari/605.1.15"

        webView = WKWebView(frame: view.bounds, configuration: configuration)

        // Set custom user agent for desktop layout
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"

        // Add red border
        webView.layer.borderColor = UIColor.red.cgColor
        webView.layer.borderWidth = 1.0

        // Enable high quality rendering at scale
        webView.layer.shouldRasterize = false
        webView.contentScaleFactor = UIScreen.main.scale * 4

        view.addSubview(webView)

        // Calculate scale to fit 1920px logical width
        let screenWidth = UIScreen.main.bounds.width
        let scale = screenWidth / 1920.0
        webView.scrollView.minimumZoomScale = scale
        webView.scrollView.maximumZoomScale = scale
        webView.scrollView.zoomScale = scale

        // Load Wikipedia
        if let url = URL(string: "https://en.wikipedia.org/wiki/Main_Page") {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        // Create control indicator lines
        horizontalLine = UIView()
        horizontalLine.backgroundColor = .green
        horizontalLine.layer.zPosition = 1000
        view.addSubview(horizontalLine)

        verticalLine = UIView()
        verticalLine.backgroundColor = .green
        verticalLine.layer.zPosition = 1000
        view.addSubview(verticalLine)

        // Start motion manager
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates()
        }

        // Start scaling animation at 60Hz
        displayLink = CADisplayLink(target: self, selector: #selector(updateScale))
        displayLink.add(to: .main, forMode: .common)
        startTime = CACurrentMediaTime()
    }

    @objc private func updateScale() {
        let elapsed = CACurrentMediaTime() - startTime

        // Read accelerometer and update control values
        if let motion = motionManager.deviceMotion {
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch

            // In Landscape Left orientation:
            // Pitch = banking left/right (X control)
            // Roll = pitching forward/back (Y control)
            // Pitch: -π/2 (left edge down) = -1.0, π/2 (right edge down) = 1.0
            // Roll: -π/2 (top edge away) = -1.0, π/2 (top edge toward) = 1.0
            controlX = 0.0 - max(-1.0, min(1.0, pitch / (Double.pi / 2)))
            controlY = max(-1.0, min(1.0, roll / (Double.pi / 2)))
        }

        // Update control indicator lines
        let centerX = view.bounds.width / 2
        let centerY = view.bounds.height / 2
        let lineThickness: CGFloat = 3

        // Horizontal line showing X control
        let horizontalLineLength = CGFloat(controlX) * (view.bounds.width / 2)
        if controlX >= 0 {
            horizontalLine.frame = CGRect(x: centerX, y: centerY - lineThickness/2,
                                         width: horizontalLineLength, height: lineThickness)
        } else {
            horizontalLine.frame = CGRect(x: centerX + horizontalLineLength, y: centerY - lineThickness/2,
                                         width: -horizontalLineLength, height: lineThickness)
        }

        // Vertical line showing Y control
        let verticalLineLength = CGFloat(controlY) * (view.bounds.height / 2)
        if controlY >= 0 {
            verticalLine.frame = CGRect(x: centerX - lineThickness/2, y: centerY,
                                       width: lineThickness, height: verticalLineLength)
        } else {
            verticalLine.frame = CGRect(x: centerX - lineThickness/2, y: centerY + verticalLineLength,
                                       width: lineThickness, height: -verticalLineLength)
        }

        // Wait 5 seconds before starting animation
        guard elapsed >= 1.0 else { return }

        let animationTime = elapsed - 1.0

        // Double every 3 seconds (slower animation)
        let scaleFactor = pow(2.0, animationTime / 6.0)

        // Use transform instead of bounds to scale everything proportionally
        webView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

