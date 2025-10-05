//
//  ViewController.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import UIKit
import WebKit
import CoreMotion
import AVFoundation
import SwiftUI

struct LinkInfo {
    let bounds: CGRect
    let href: String
    let text: String
}

class ExternalDisplayViewController: UIViewController {
    weak var gameWebView: WKWebView?
    weak var gameDebugView: UIView?
    weak var gameHorizontalLine: UIView?
    weak var gameVerticalLine: UIView?
    weak var gameHorizontalLabel: UILabel?
    weak var gameVerticalLabel: UILabel?
    weak var gameOverHostingView: UIView?
    weak var restartHostingView: UIView?
    weak var startSceneHostingView: UIView?

    private var hasLaidOut = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Only do initial layout once to avoid interfering with transforms
        guard !hasLaidOut else { return }
        hasLaidOut = true

        // Layout all game views to fill the external display
        gameWebView?.frame = view.bounds
        gameDebugView?.frame = view.bounds
        gameOverHostingView?.frame = view.bounds
        restartHostingView?.frame = view.bounds
        startSceneHostingView?.frame = view.bounds
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

class ViewController: UIViewController, WKNavigationDelegate {

    private let showDebugRectangles = false
    private let showControlLines = false

    private var webView: WKWebView!
    private var displayLink: CADisplayLink!
    private var startTime: CFTimeInterval = 0
    private var motionManager: CMMotionManager!
    private var controlX: Double = 0.0
    private var controlY: Double = 0.0
    private var accumulatedOffsetX: Double = 0.0
    private var accumulatedOffsetY: Double = 0.0
    private let controlPower: Double = 8.0
    private var diveSpeed: Double = 1.0
    private var accumulatedScale: Double = 1.0
    private var lastUpdateTime: CFTimeInterval = 0
    private let scalePower: Double = 1.2
    private var turboPower: Double = 1.0
    private var touchOverlay: UIView!
    private var horizontalLine: UIView!
    private var verticalLine: UIView!
    private var horizontalLabel: UILabel!
    private var verticalLabel: UILabel!
    private var debugView: UIView!
    private var links: [LinkInfo] = []
    private var linksEnumerated = false
    private var isGameOver = false
    private var gameOverHostingController: UIHostingController<GameOverScreenView>!
    private var restartHostingController: UIHostingController<RestartScreenView>!
    private var startHostingController: UIHostingController<StartScreenControllerView>!
    private var startSceneHostingController: UIHostingController<StartScreenSceneView>!
    private var gameStarted = false
    private let originalURL = "https://en.wikipedia.org/wiki/Main_Page"
//     private let originalURL = "https://en.wikipedia.org/wiki/History_of_philosophy"
    private var hopCount = 0
    private var linkHistory: [String] = []
    private var visitedURLs: Set<String> = []

    // External display properties
    private var externalWindow: UIWindow?
    private var yolkImageView: UIImageView?
    private var externalViewController: ExternalDisplayViewController?
    private var philosophyImageView: UIImageView?

    // Audio
    private var crashAudioPlayer: AVAudioPlayer?
    private var rocketEngineAudioPlayer: AVAudioPlayer?
    private var linkHitAudioPlayer: AVAudioPlayer?
    private var philosophyAudioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set background color
        view.backgroundColor = .black

        // Configure webview to show desktop layout
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Version/15.0 Safari/605.1.15"

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self

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

        // Disable user interaction to prevent text selection, etc.
        webView.isUserInteractionEnabled = false

        view.addSubview(webView)

        // Create touch overlay for turbo boost
        touchOverlay = UIView(frame: view.bounds)
        touchOverlay.backgroundColor = .clear
        view.addSubview(touchOverlay)

        // Add touch gesture recognizers
        let touchDownGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTouch(_:)))
        touchDownGesture.minimumPressDuration = 0
        touchOverlay.addGestureRecognizer(touchDownGesture)

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

        // Disable scrolling to prevent offset issues
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentOffset = .zero

        // Load Wikipedia
        if let url = URL(string: originalURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        // Create control indicator lines
        horizontalLine = UIView()
        horizontalLine.backgroundColor = .red
        horizontalLine.layer.zPosition = 1000
        horizontalLine.isHidden = !showControlLines
        view.addSubview(horizontalLine)

        horizontalLabel = UILabel()
        horizontalLabel.font = UIFont.boldSystemFont(ofSize: 36)
        horizontalLabel.textColor = .red
        horizontalLabel.layer.zPosition = 1000
        horizontalLabel.isHidden = !showControlLines
        view.addSubview(horizontalLabel)

        verticalLine = UIView()
        verticalLine.backgroundColor = .blue
        verticalLine.layer.zPosition = 1000
        verticalLine.isHidden = !showControlLines
        view.addSubview(verticalLine)

        verticalLabel = UILabel()
        verticalLabel.font = UIFont.boldSystemFont(ofSize: 36)
        verticalLabel.textColor = .blue
        verticalLabel.layer.zPosition = 1000
        verticalLabel.isHidden = !showControlLines
        view.addSubview(verticalLabel)

        // Create game over UI
        let gameOverView = GameOverScreenView(hopCount: hopCount, linkHistory: linkHistory, isExternalDisplay: false)
        gameOverHostingController = UIHostingController(rootView: gameOverView)
        gameOverHostingController.view.backgroundColor = .clear
        gameOverHostingController.view.isHidden = true
        addChild(gameOverHostingController)
        view.addSubview(gameOverHostingController.view)
        gameOverHostingController.didMove(toParent: self)

        // Create restart UI
        let restartView = RestartScreenView(onRestart: { [weak self] in
            self?.restartGame()
        })
        restartHostingController = UIHostingController(rootView: restartView)
        restartHostingController.view.backgroundColor = .clear
        restartHostingController.view.isHidden = true
        addChild(restartHostingController)
        view.addSubview(restartHostingController.view)
        restartHostingController.didMove(toParent: self)

        // Create welcome screen (add after touchOverlay)
        let startView = StartScreenControllerView(onStart: { [weak self] in
            self?.startGame()
        })
        startHostingController = UIHostingController(rootView: startView)
        startHostingController.view.backgroundColor = .clear
        addChild(startHostingController)
        view.addSubview(startHostingController.view)
        startHostingController.didMove(toParent: self)

        // Bring welcome screen to front so it's above touchOverlay
        view.bringSubviewToFront(startHostingController.view)

        // Create start screen scene view for external display
        let startSceneView = StartScreenSceneView()
        startSceneHostingController = UIHostingController(rootView: startSceneView)
        startSceneHostingController.view.backgroundColor = .clear
        addChild(startSceneHostingController)
        view.addSubview(startSceneHostingController.view)
        startSceneHostingController.didMove(toParent: self)
        startSceneHostingController.view.isHidden = true // Initially hidden, will show on external display

        // Create philosophy image view (initially hidden)
        philosophyImageView = UIImageView(frame: view.bounds)
        philosophyImageView?.image = UIImage(named: "philosophy")
        philosophyImageView?.contentMode = .scaleAspectFill
        philosophyImageView?.backgroundColor = .clear
        philosophyImageView?.isUserInteractionEnabled = false
        philosophyImageView?.isHidden = true
        philosophyImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(philosophyImageView!)

        // Start motion manager
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates()
        }

        // Set up external display observers
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillConnect), name: UIScene.willConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDidDisconnect), name: UIScene.didDisconnectNotification, object: nil)

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Load crash sound
        if let soundURL = Bundle.main.url(forResource: "Crash", withExtension: "wav") {
            do {
                crashAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                crashAudioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load crash sound: \(error)")
            }
        }
        else {
            print("failed to create soundURL")
        }

        // Load rocket engine sound
        if let soundURL = Bundle.main.url(forResource: "Rocket_Engine", withExtension: "wav") {
            do {
                rocketEngineAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                rocketEngineAudioPlayer?.numberOfLoops = -1 // Loop indefinitely
                rocketEngineAudioPlayer?.prepareToPlay()
                rocketEngineAudioPlayer?.play()
            } catch {
                print("Failed to load rocket engine sound: \(error)")
            }
        }
        else {
            print("failed to create rocket engine soundURL")
        }

        // Load link hit sound
        if let soundURL = Bundle.main.url(forResource: "Link_Hit", withExtension: "wav") {
            do {
                linkHitAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                linkHitAudioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load link hit sound: \(error)")
            }
        }
        else {
            print("failed to create link hit soundURL")
        }

        // Load philosophy sound
        if let soundURL = Bundle.main.url(forResource: "Philosophy", withExtension: "wav") {
            do {
                philosophyAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                philosophyAudioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load philosophy sound: \(error)")
            }
        }
        else {
            print("failed to create philosophy soundURL")
        }

        // Start scaling animation at 60Hz
        displayLink = CADisplayLink(target: self, selector: #selector(updateScale))
        displayLink.add(to: .main, forMode: .common)
        displayLink.isPaused = true // Don't start until user taps START
        startTime = CACurrentMediaTime()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update Yolk image view frame if it exists
        yolkImageView?.frame = view.bounds

        // Update philosophy image view frame based on where it's displayed
        if let philosophyView = philosophyImageView {
            if philosophyView.superview == view {
                // On main screen
                philosophyView.frame = view.bounds
            } else if let externalVC = externalViewController, philosophyView.superview == externalVC.view {
                // On external display
                philosophyView.frame = externalVC.view.bounds
            }
        }

        // Layout restart and start screen (always on phone)
        restartHostingController.view.frame = view.bounds
        startHostingController.view.frame = view.bounds

        // Only layout game over UI and start scene UI if it's on the main screen
        guard externalWindow == nil else { return }
        gameOverHostingController.view.frame = view.bounds
        startSceneHostingController.view.frame = view.bounds
    }

    private func enumerateLinks() {
        // Ensure scroll position is at origin
        webView.scrollView.contentOffset = .zero

        let zoomScale = webView.scrollView.zoomScale
        let containerView = externalViewController?.view ?? view!
        // Only apply safe area offset on phone screen, not external display
        let leftSafeArea = externalViewController == nil ? view.safeAreaInsets.left : 0.0
        let topSafeArea = externalViewController == nil ? view.safeAreaInsets.top : 0.0

        let javascript = """
        (function() {
            const links = document.querySelectorAll('a[href]');
            const results = [];
            let resultIndex = 0;
            const scrollX = window.pageXOffset || window.scrollX;
            const scrollY = window.pageYOffset || window.scrollY;
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
                    x: (rect.x + scrollX) * \(zoomScale),
                    y: (rect.y + scrollY) * \(zoomScale),
                    width: rect.width * \(zoomScale),
                    height: rect.height * \(zoomScale)
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
                // print("Found \(links.count) links:")
                self.links.removeAll()

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
                    // print("[\(index)] '\(text)' -> \(href)")
                    // print("   Bounds: (x: \(x), y: \(y), width: \(width), height: \(height))")

                    // Store bounds and create debug rectangle
                    let rect = CGRect(x: x + leftSafeArea, y: y + topSafeArea, width: width, height: height)
                    let linkInfo = LinkInfo(bounds: rect, href: href, text: text)
                    self.links.append(linkInfo)

                    if self.showDebugRectangles {
                        let shapeLayer = CAShapeLayer()
                        shapeLayer.path = UIBezierPath(rect: rect).cgPath
                        shapeLayer.strokeColor = UIColor.red.cgColor
                        shapeLayer.fillColor = UIColor.clear.cgColor
                        shapeLayer.lineWidth = 2.0
                        self.debugView.layer.addSublayer(shapeLayer)

                        // Add text label
                        let textLayer = CATextLayer()
                        textLayer.string = text
                        textLayer.fontSize = 72
                        textLayer.foregroundColor = UIColor.red.cgColor
                        textLayer.backgroundColor = UIColor.white.withAlphaComponent(0.5).cgColor
                        textLayer.contentsScale = UIScreen.main.scale
                        textLayer.frame = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 72)
                        textLayer.alignmentMode = .left
                        textLayer.truncationMode = .end
                        self.debugView.layer.addSublayer(textLayer)
                    }

                    // Draw X over visited links (always show, regardless of showDebugRectangles)
                    if self.visitedURLs.contains(href) {
                        let xPath = UIBezierPath()
                        // Draw X from corner to corner
                        xPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
                        xPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                        xPath.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                        xPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

                        let xLayer = CAShapeLayer()
                        xLayer.path = xPath.cgPath
                        xLayer.strokeColor = UIColor.red.cgColor
                        xLayer.lineWidth = 4.0
                        self.debugView.layer.addSublayer(xLayer)
                    }
                }

                // Print maximum x+width value
                let maxXPlusWidth = self.links.map { $0.bounds.maxX }.max() ?? 0
                // print("Maximum (x+width) value: \(maxXPlusWidth)")

                // Mark links as enumerated
                self.linksEnumerated = true
            }
        }
    }

    @objc private func handleTouch(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            turboPower = 2.0
            view.backgroundColor = .red
            yolkImageView?.backgroundColor = .red
        case .ended, .cancelled, .failed:
            turboPower = 1.0
            view.backgroundColor = .black
            yolkImageView?.backgroundColor = .black
        default:
            break
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Reset scroll position
        webView.scrollView.contentOffset = .zero

        // Activate OS theme radio button
        let themeScript = """
        (function() {
            const radioButton = document.querySelector('#skin-client-pref-skin-theme-value-os');
            if (radioButton) {
                radioButton.checked = true;
                radioButton.click();
            }
        })();
        """
        webView.evaluateJavaScript(themeScript, completionHandler: nil)

        // Only enumerate links if game has started
        guard gameStarted else { return }

        // Track visited URL
        if let currentURL = webView.url?.absoluteString {
            visitedURLs.insert(currentURL)
        }

        // Speak page title after link hit sound finishes (but not for original URL)
        if webView.url?.absoluteString != originalURL && hopCount > 0 {
            webView.evaluateJavaScript("document.title") { [weak self] result, error in
                guard let self = self, let title = result as? String else { return }

                // Remove " - Wikipedia" suffix if present
                let cleanTitle = title.hasSuffix(" - Wikipedia") ?
                    String(title.dropLast(" - Wikipedia".count)) : title

                // Show philosophy image if we've reached the Philosophy page
                if cleanTitle == "Philosophy" {
                    DispatchQueue.main.async {
                        // Play philosophy sound
                        self.philosophyAudioPlayer?.play()

                        // Show philosophy image on external display if connected, otherwise main screen
                        if let externalVC = self.externalViewController {
                            self.philosophyImageView?.removeFromSuperview()
                            self.philosophyImageView?.frame = externalVC.view.bounds
                            self.philosophyImageView?.alpha = 1.0
                            externalVC.view.addSubview(self.philosophyImageView!)
                            self.philosophyImageView?.isHidden = false
                            externalVC.view.bringSubviewToFront(self.philosophyImageView!)
                            externalVC.view.setNeedsLayout()
                            externalVC.view.layoutIfNeeded()
                        } else {
                            self.philosophyImageView?.frame = self.view.bounds
                            self.philosophyImageView?.alpha = 1.0
                            self.philosophyImageView?.isHidden = false
                            self.view.bringSubviewToFront(self.philosophyImageView!)
                            self.view.setNeedsLayout()
                            self.view.layoutIfNeeded()
                        }

                        // Fade out after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            UIView.animate(withDuration: 1.0, animations: {
                                self.philosophyImageView?.alpha = 0.0
                            })
                        }

                        // Delay link enumeration until after philosophy image fades out completely
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.enumerateLinks()
                        }
                    }
                } else {
                    // Wait for link hit sound to finish before speaking
                    let soundDuration = self.linkHitAudioPlayer?.duration ?? 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + soundDuration) {
                        let utterance = AVSpeechUtterance(string: cleanTitle)
                        utterance.rate = 0.5
                        self.speechSynthesizer.speak(utterance)
                    }

                    // Enumerate links with normal delay for non-Philosophy pages
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.enumerateLinks()
                    }
                }
            }
        } else {
            // Enumerate links once when page finishes loading (for original URL or first load)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.enumerateLinks()
            }
        }
    }

    @objc private func updateScale() {
        // Stop updates if game is over
        if isGameOver {
            return
        }

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
        let displayView = externalViewController?.view ?? view!

        if showControlLines {
            let centerX = displayView.bounds.width / 2
            let centerY = displayView.bounds.height / 2
            let lineThickness: CGFloat = 3

            // Horizontal line showing X control
            let horizontalLineLength = CGFloat(controlX) * (displayView.bounds.width / 2)
            if controlX >= 0 {
                horizontalLine.frame = CGRect(x: centerX, y: centerY - lineThickness/2,
                                             width: horizontalLineLength, height: lineThickness)
                horizontalLabel.text = String(format: "%.2f", controlX)
                horizontalLabel.sizeToFit()
                horizontalLabel.frame.origin = CGPoint(x: centerX + horizontalLineLength + 5, y: centerY - horizontalLabel.frame.height/2)
            } else {
                horizontalLine.frame = CGRect(x: centerX + horizontalLineLength, y: centerY - lineThickness/2,
                                             width: -horizontalLineLength, height: lineThickness)
                horizontalLabel.text = String(format: "%.2f", controlX)
                horizontalLabel.sizeToFit()
                horizontalLabel.frame.origin = CGPoint(x: centerX + horizontalLineLength - horizontalLabel.frame.width - 5, y: centerY - horizontalLabel.frame.height/2)
            }

            // Vertical line showing Y control
            let verticalLineLength = CGFloat(controlY) * (displayView.bounds.height / 2)
            if controlY >= 0 {
                verticalLine.frame = CGRect(x: centerX - lineThickness/2, y: centerY,
                                           width: lineThickness, height: verticalLineLength)
                verticalLabel.text = String(format: "%.2f", controlY)
                verticalLabel.sizeToFit()
                verticalLabel.frame.origin = CGPoint(x: centerX - verticalLabel.frame.width/2, y: centerY + verticalLineLength + 5)
            } else {
                verticalLine.frame = CGRect(x: centerX - lineThickness/2, y: centerY + verticalLineLength,
                                           width: lineThickness, height: -verticalLineLength)
                verticalLabel.text = String(format: "%.2f", controlY)
                verticalLabel.sizeToFit()
                verticalLabel.frame.origin = CGPoint(x: centerX - verticalLabel.frame.width/2, y: centerY + verticalLineLength - verticalLabel.frame.height - 5)
            }
        }

        // Wait 5 seconds before starting animation
        guard elapsed >= 1.0 else {
            rocketEngineAudioPlayer?.stop()
            return
        }

        // Wait for links to be enumerated before starting dive
        guard linksEnumerated else {
            // Update lastUpdateTime even when paused
            lastUpdateTime = elapsed
            rocketEngineAudioPlayer?.stop()
            return
        }

        // Start rocket engine sound if not already playing
        if rocketEngineAudioPlayer?.isPlaying == false {
            rocketEngineAudioPlayer?.play()
        }

        // Calculate delta time
        let deltaTime = lastUpdateTime > 0 ? elapsed - lastUpdateTime : 0
        lastUpdateTime = elapsed

        // Update accumulated scale exponentially (with turbo boost when touching)
        accumulatedScale *= pow(scalePower, deltaTime * diveSpeed * turboPower)

        // Accumulate offsets with inverse scale proportionality
        // Scale control power based on screen width for consistent feel across displays
        let effectiveControlPower = controlPower * (displayView.bounds.width / 390.0) // normalized to iPhone width
        accumulatedOffsetX -= (controlX * effectiveControlPower) / accumulatedScale
        accumulatedOffsetY += (controlY * effectiveControlPower) / accumulatedScale

        // Use transform instead of bounds to scale everything proportionally
        let transform = CGAffineTransform(scaleX: accumulatedScale, y: accumulatedScale).translatedBy(x: accumulatedOffsetX, y: accumulatedOffsetY)
       webView.transform = transform
       debugView.transform = transform

        // Check if any link bounds (with transform applied) completely contain the screen bounds
        // Use external display bounds if active, otherwise main view bounds
        let screenBounds = displayView.bounds

        // Convert screen bounds to debugView's coordinate space (which has the same transform as webView)
        let screenBoundsInDebugView = displayView.convert(screenBounds, to: debugView)

        // Check for intersections
        var hasIntersection = false
        var foundContainingLink = false

        for (index, link) in links.enumerated() {
            // Print debug info for 64th link
//            if index == 64 {
//                 print("link:   \(link.bounds)")
//                 print("screen (debugView space): \(screenBoundsInDebugView)")
//            }

            // Check if link intersects screen (skip visited links for intersection check)
            if link.bounds.intersects(screenBoundsInDebugView) && !visitedURLs.contains(link.href) {
                hasIntersection = true
            }

            if link.bounds.contains(screenBoundsInDebugView) {
                // Skip visited links
                if visitedURLs.contains(link.href) {
                    print("⏭️ Skipping visited link: '\(link.text)' -> \(link.href)")
                    continue
                }

                foundContainingLink = true
                print("🎯 Link \(index) contains screen: '\(link.text)' -> \(link.href)")

                // Play link hit sound (skip for Philosophy page)
                let isPhilosophyLink = link.href.contains("wiki/Philosophy")
                if !isPhilosophyLink {
                    linkHitAudioPlayer?.play()
                }

                // Track progress
                hopCount += 1
                linkHistory.append(link.text)

                // Clear old links and rectangles immediately
                links.removeAll()
                debugView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                linksEnumerated = false

                // Reset accumulated offsets and restart animation
                accumulatedOffsetX = 0.0
                accumulatedOffsetY = 0.0
                accumulatedScale = 1.0
                lastUpdateTime = 0.0
                startTime = CACurrentMediaTime()
                diveSpeed += 1.0 // Double the dive speed for next page

                // Reset transforms
                webView.transform = .identity
                debugView.transform = .identity

                // Navigate to the link
                if let url = URL(string: link.href) {
                    // Check if this is an anchor link on the current page
                    let currentURL = webView.url
                    let isSamePageAnchor = currentURL?.scheme == url.scheme &&
                                          currentURL?.host == url.host &&
                                          currentURL?.path == url.path &&
                                          url.fragment != nil

                    if isSamePageAnchor {
                        print("📍 Same-page anchor link detected, re-enumerating without reload")
                        // Track this anchor URL as visited
                        visitedURLs.insert(link.href)

                        // Speak link text after sound finishes (since title won't change, skip for Philosophy)
                        if !isPhilosophyLink {
                            let soundDuration = linkHitAudioPlayer?.duration ?? 0
                            let linkText = link.text
                            DispatchQueue.main.asyncAfter(deadline: .now() + soundDuration) { [weak self] in
                                let utterance = AVSpeechUtterance(string: linkText)
                                utterance.rate = 0.5
                                self?.speechSynthesizer.speak(utterance)
                            }
                        }

                        // Don't navigate, just re-enumerate links after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.enumerateLinks()
                        }
                    } else {
                        // Normal navigation to a different page
                        webView.load(URLRequest(url: url))
                    }
                }

                break // Only navigate to first matching link
            }
        }

        // Check for game over condition: no links intersecting screen and we have links enumerated
        if !hasIntersection && !links.isEmpty && !isGameOver && !foundContainingLink {
            isGameOver = true

            // Stop rocket engine and play crash sound
            rocketEngineAudioPlayer?.stop()
            crashAudioPlayer?.play()

            // Update game over view with current state
            let isExternal = externalWindow != nil
            let gameOverView = GameOverScreenView(hopCount: hopCount, linkHistory: linkHistory, isExternalDisplay: isExternal)
            gameOverHostingController.rootView = gameOverView
            gameOverHostingController.view.isHidden = false
            restartHostingController.view.isHidden = false
            touchOverlay.isUserInteractionEnabled = false

            displayLink.isPaused = true
        }
    }

    @objc private func startGame() {
        // Hide welcome screen
        startHostingController.view.isHidden = true
        startSceneHostingController.view.isHidden = true

        // Hide philosophy image if visible
        philosophyImageView?.isHidden = true

        // Mark game as started
        gameStarted = true

        // Start the animation
        displayLink.isPaused = false
        startTime = CACurrentMediaTime()

        // Enumerate links
        enumerateLinks()
    }

    @objc private func restartGame() {
        // Reset all state
        isGameOver = false
        gameOverHostingController.view.isHidden = true
        restartHostingController.view.isHidden = true
        touchOverlay.isUserInteractionEnabled = true
        turboPower = 1.0

        // Hide philosophy image if visible
        philosophyImageView?.isHidden = true

        // Reset game variables
        accumulatedOffsetX = 0.0
        accumulatedOffsetY = 0.0
        accumulatedScale = 1.0
        lastUpdateTime = 0.0
        diveSpeed = 1.0
        startTime = CACurrentMediaTime()
        links.removeAll()
        linksEnumerated = false
        hopCount = 0
        linkHistory.removeAll()
        visitedURLs.removeAll()

        // Clear debug view
        debugView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // Reset transforms
        webView.transform = .identity
        debugView.transform = .identity

        // Load original URL
        if let url = URL(string: originalURL) {
            webView.load(URLRequest(url: url))
        }

        // Resume animation
        displayLink.isPaused = false
    }

    // MARK: - External Display

    @objc private func sceneWillConnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }

        // Check if this is an external display scene
        guard scene.screen != UIScreen.main else { return }

        setupExternalDisplay(scene)
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }

        // Check if this was an external display scene
        guard scene.screen != UIScreen.main else { return }

        teardownExternalDisplay()
    }

    private func setupExternalDisplay(_ scene: UIWindowScene) {
        // Create external window for the scene
        externalWindow = UIWindow(windowScene: scene)

        // Create a custom view controller for the external display
        let externalVC = ExternalDisplayViewController()
        externalViewController = externalVC
        externalWindow?.rootViewController = externalVC
        externalWindow?.isHidden = false

        // Store references to views for layout
        externalVC.gameWebView = webView
        externalVC.gameDebugView = debugView
        externalVC.gameHorizontalLine = horizontalLine
        externalVC.gameVerticalLine = verticalLine
        externalVC.gameHorizontalLabel = horizontalLabel
        externalVC.gameVerticalLabel = verticalLabel
        externalVC.gameOverHostingView = gameOverHostingController.view
        externalVC.restartHostingView = nil // Restart button stays on phone
        externalVC.startSceneHostingView = startSceneHostingController.view

        // Move visual game UI to external display (keep touchOverlay, restart button, and start screen on phone)
        webView.removeFromSuperview()
        debugView.removeFromSuperview()
        horizontalLine.removeFromSuperview()
        verticalLine.removeFromSuperview()
        horizontalLabel.removeFromSuperview()
        verticalLabel.removeFromSuperview()

        // Properly transfer game over controller to external display (restart stays on phone)
        gameOverHostingController.willMove(toParent: nil)
        gameOverHostingController.view.removeFromSuperview()
        gameOverHostingController.removeFromParent()

        // Properly transfer start scene controller to external display
        startSceneHostingController.willMove(toParent: nil)
        startSceneHostingController.view.removeFromSuperview()
        startSceneHostingController.removeFromParent()

        externalVC.view.addSubview(webView)
        externalVC.view.addSubview(debugView)
        externalVC.view.addSubview(horizontalLine)
        externalVC.view.addSubview(verticalLine)
        externalVC.view.addSubview(horizontalLabel)
        externalVC.view.addSubview(verticalLabel)

        externalVC.addChild(gameOverHostingController)
        externalVC.view.addSubview(gameOverHostingController.view)
        gameOverHostingController.didMove(toParent: externalVC)

        externalVC.addChild(startSceneHostingController)
        externalVC.view.addSubview(startSceneHostingController.view)
        startSceneHostingController.didMove(toParent: externalVC)
        startSceneHostingController.view.isHidden = startHostingController.view.isHidden // Match visibility of controller start screen

        // Trigger layout
        externalVC.view.setNeedsLayout()
        externalVC.view.layoutIfNeeded()

        // Recalculate webView zoom scale for external display
        let externalScreenWidth = scene.screen.bounds.width
        let externalScale = externalScreenWidth / 1920.0
        webView.scrollView.minimumZoomScale = externalScale
        webView.scrollView.maximumZoomScale = externalScale
        webView.scrollView.zoomScale = externalScale

        // Update contentScaleFactor for external screen
        webView.contentScaleFactor = scene.screen.scale * 4

        // Reset transforms and animation state when moving to external display
        webView.transform = .identity
        debugView.transform = .identity
        accumulatedOffsetX = 0.0
        accumulatedOffsetY = 0.0
        accumulatedScale = 1.0
        lastUpdateTime = 0.0
        startTime = CACurrentMediaTime()

        // Clear old links and rectangles immediately
        links.removeAll()
        debugView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        linksEnumerated = false

        // Stop rocket engine sound
        // rocketEngineAudioPlayer?.stop()

        // Re-enumerate links with new scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.enumerateLinks()
        }

        // Re-add restart button to main view (it stays on phone for interaction)
        addChild(restartHostingController)
        view.addSubview(restartHostingController.view)
        restartHostingController.didMove(toParent: self)
        restartHostingController.view.frame = view.bounds

        // Create Yolk image view for main screen
        yolkImageView = UIImageView(frame: view.bounds)
        yolkImageView?.image = UIImage(named: "Gemini_Generated_Image_ox03eqox03eqox03")
        yolkImageView?.contentMode = .scaleAspectFit
        yolkImageView?.backgroundColor = .black
        yolkImageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        yolkImageView?.isUserInteractionEnabled = false
        view.addSubview(yolkImageView!)

        // Keep touchOverlay, restart button, and start screen on top
        view.bringSubviewToFront(touchOverlay)
        view.bringSubviewToFront(restartHostingController.view)
        view.bringSubviewToFront(startHostingController.view)
    }

    private func teardownExternalDisplay() {
        guard let externalVC = externalWindow?.rootViewController else { return }

        // Move visual game UI back to main view (touchOverlay, restart button, and start screen stayed on phone)
        webView.removeFromSuperview()
        debugView.removeFromSuperview()
        horizontalLine.removeFromSuperview()
        verticalLine.removeFromSuperview()
        horizontalLabel.removeFromSuperview()
        verticalLabel.removeFromSuperview()

        // Properly transfer game over controller back to main view controller
        gameOverHostingController.willMove(toParent: nil)
        gameOverHostingController.view.removeFromSuperview()
        gameOverHostingController.removeFromParent()

        // Properly transfer start scene controller back to main view controller
        startSceneHostingController.willMove(toParent: nil)
        startSceneHostingController.view.removeFromSuperview()
        startSceneHostingController.removeFromParent()

        view.addSubview(webView)
        view.addSubview(touchOverlay)
        view.addSubview(debugView)
        view.addSubview(horizontalLine)
        view.addSubview(verticalLine)
        view.addSubview(horizontalLabel)
        view.addSubview(verticalLabel)

        addChild(gameOverHostingController)
        view.addSubview(gameOverHostingController.view)
        gameOverHostingController.didMove(toParent: self)

        addChild(startSceneHostingController)
        view.addSubview(startSceneHostingController.view)
        startSceneHostingController.didMove(toParent: self)

        // Update frames for main display
        webView.frame = view.bounds
        touchOverlay.frame = view.bounds
        debugView.frame = view.bounds

        // Restore webView zoom scale for main display
        let mainScreenWidth = UIScreen.main.bounds.width
        let mainScale = mainScreenWidth / 1920.0
        webView.scrollView.minimumZoomScale = mainScale
        webView.scrollView.maximumZoomScale = mainScale
        webView.scrollView.zoomScale = mainScale

        // Update contentScaleFactor for main screen
        webView.contentScaleFactor = UIScreen.main.scale * 4

        // Reset transforms and animation state when moving back to main display
        webView.transform = .identity
        debugView.transform = .identity
        accumulatedOffsetX = 0.0
        accumulatedOffsetY = 0.0
        accumulatedScale = 1.0
        lastUpdateTime = 0.0
        startTime = CACurrentMediaTime()

        // Clear old links and rectangles immediately
        links.removeAll()
        debugView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        linksEnumerated = false

        // Stop rocket engine sound
        // rocketEngineAudioPlayer?.stop()

        // Re-enumerate links with restored scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.enumerateLinks()
        }

        // Remove Yolk image view
        yolkImageView?.removeFromSuperview()
        yolkImageView = nil

        // Ensure restart button stays on top
        view.bringSubviewToFront(restartHostingController.view)

        // Clean up external window and view controller
        externalWindow?.isHidden = true
        externalWindow = nil
        externalViewController = nil
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

