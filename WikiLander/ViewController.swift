//
//  ViewController.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    private var webView: WKWebView!
    private var displayLink: CADisplayLink!
    private var startTime: CFTimeInterval = 0

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

        // Start scaling animation at 60Hz
        displayLink = CADisplayLink(target: self, selector: #selector(updateScale))
        displayLink.add(to: .main, forMode: .common)
        startTime = CACurrentMediaTime()
    }

    @objc private func updateScale() {
        let elapsed = CACurrentMediaTime() - startTime

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

