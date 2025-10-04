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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure webview to show desktop layout
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Version/15.0 Safari/605.1.15"

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

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
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

