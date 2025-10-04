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
        guard elapsed >= 5.0 else { return }

        let animationTime = elapsed - 5.0

        // Double every 3 seconds (slower animation)
        let scaleFactor = pow(2.0, animationTime / 3.0)

        let initialWidth = view.bounds.width
        let initialHeight = view.bounds.height

        let newBounds = CGRect(x: 0, y: 0, width: initialWidth * scaleFactor, height: initialHeight * scaleFactor)

        // Calculate center point of visible content before changes
        let scrollView = webView.scrollView
        let centerX = (scrollView.contentOffset.x + scrollView.bounds.width / 2) / scrollView.zoomScale
        let centerY = (scrollView.contentOffset.y + scrollView.bounds.height / 2) / scrollView.zoomScale

        webView.bounds = newBounds
        webView.center = view.center

        // Maintain 1920px logical width
        let newScale = newBounds.width / 1920.0
        webView.scrollView.minimumZoomScale = newScale
        webView.scrollView.maximumZoomScale = newScale
        webView.scrollView.zoomScale = newScale

        // Restore center point after zoom change
        let newOffsetX = centerX * newScale - scrollView.bounds.width / 2
        let newOffsetY = centerY * newScale - scrollView.bounds.height / 2
        scrollView.contentOffset = CGPoint(x: newOffsetX, y: newOffsetY)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

