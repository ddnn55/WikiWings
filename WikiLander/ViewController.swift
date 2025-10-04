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
    private var accumulatedOffsetX: Double = 0.0
    private var accumulatedOffsetY: Double = 0.0
    private var horizontalLine: UIView!
    private var verticalLine: UIView!
    private var debugView: UIView!
    private var linkBounds: [CGRect] = []
    private var lastEnumerationTime: CFTimeInterval = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure webview to show desktop layout
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Version/15.0 Safari/605.1.15"

        webView = WKWebView(frame: view.bounds, configuration: configuration)

        // Enable web inspector
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // Set custom user agent for desktop layout
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15"

        // Add red border
        webView.layer.borderColor = UIColor.red.cgColor
        webView.layer.borderWidth = 1.0

        // Enable high quality rendering at scale
        webView.layer.shouldRasterize = false
        webView.contentScaleFactor = UIScreen.main.scale * 4

        view.addSubview(webView)

        // Create debug view for link visualization
        debugView = UIView(frame: view.bounds)
        debugView.backgroundColor = .clear
        debugView.isUserInteractionEnabled = false
        view.addSubview(debugView)

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
        horizontalLine.isHidden = true
        view.addSubview(horizontalLine)

        verticalLine = UIView()
        verticalLine.backgroundColor = .green
        verticalLine.layer.zPosition = 1000
        verticalLine.isHidden = true
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

    private func enumerateLinks() {
        let javascript = """
        (function() {
            const links = document.querySelectorAll('a[href]');
            const results = [];
            let resultIndex = 0;
            links.forEach((link) => {
                const style = window.getComputedStyle(link);
                if (style.visibility === 'hidden') {
                    return;
                }
                const rect = link.getBoundingClientRect();
                results.push({
                    index: resultIndex++,
                    href: link.href,
                    text: link.textContent.trim().substring(0, 50),
                    x: rect.x,
                    y: rect.y,
                    width: rect.width,
                    height: rect.height
                });
            });
            return results;
        })();
        """

        webView.evaluateJavaScript(javascript) { result, error in
            if let error = error {
                print("Error enumerating links: \(error)")
                return
            }

            if let links = result as? [[String: Any]] {
                print("Found \(links.count) links:")
                self.linkBounds.removeAll()

                // Clear existing debug rectangles
                self.debugView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

                for link in links {
                    let index = link["index"] as? Int ?? -1
                    let href = link["href"] as? String ?? ""
                    let text = link["text"] as? String ?? ""
                    let x = link["x"] as? Double ?? 0
                    let y = link["y"] as? Double ?? 0
                    let width = link["width"] as? Double ?? 0
                    let height = link["height"] as? Double ?? 0
                    print("[\(index)] '\(text)' -> \(href)")
                    print("   Bounds: (x: \(x), y: \(y), width: \(width), height: \(height))")

                    // Store bounds and create debug rectangle
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    self.linkBounds.append(rect)

                    let shapeLayer = CAShapeLayer()
                    shapeLayer.path = UIBezierPath(rect: rect).cgPath
                    shapeLayer.strokeColor = UIColor.red.cgColor
                    shapeLayer.fillColor = UIColor.clear.cgColor
                    shapeLayer.lineWidth = 2.0
                    self.debugView.layer.addSublayer(shapeLayer)

                    // Add text layer
                    let textLayer = CATextLayer()
                    textLayer.frame = rect
                    textLayer.string = text
                    textLayer.fontSize = 12
                    textLayer.foregroundColor = UIColor.red.cgColor
                    textLayer.backgroundColor = UIColor.white.withAlphaComponent(0.7).cgColor
                    textLayer.contentsScale = UIScreen.main.scale
                    textLayer.isWrapped = true
                    self.debugView.layer.addSublayer(textLayer)
                }
            }
        }
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
            let clampedRoll = min(Double.pi, max(0.0, roll))
            controlY = 2*(clampedRoll/Double.pi - 0.5)
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

        // Enumerate links once per second after page loads
        if elapsed >= 3.0 && elapsed - lastEnumerationTime >= 1.0 {
            lastEnumerationTime = elapsed
            enumerateLinks()
        }

        // Wait 5 seconds before starting animation
        guard elapsed >= 1.0 else { return }

        let animationTime = elapsed - 1.0

        // Double every 3 seconds (slower animation)
        let scaleFactor = pow(2.0, animationTime / 6.0)

        // Accumulate offsets with inverse scale proportionality
        accumulatedOffsetX -= controlX / scaleFactor
        accumulatedOffsetY += controlY / scaleFactor

        // Use transform instead of bounds to scale everything proportionally
        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor).translatedBy(x: accumulatedOffsetX, y: accumulatedOffsetY)
//        webView.transform = transform
//        debugView.transform = transform
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

