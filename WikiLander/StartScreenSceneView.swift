//
//  StartScreenSceneView.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import SwiftUI

struct StartScreenSceneView: View {
    var isGameOver: Bool = false
    var hopCount: Int = 0
    var linkHistory: [String] = []
    var isExternalDisplay: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RocketAnimationView()

                if isGameOver {
                    VStack(spacing: 20) {
                        Text("WikiWings")
                            .font(.system(size: 200, weight: .bold))
                            .foregroundColor(.white)

                        Text("GAME OVER")
                            .font(.system(size: 200, weight: .bold))
                            .foregroundColor(.red)

                        VStack(spacing: 10) {
                            Text("Survived \(hopCount) hop\(hopCount == 1 ? "" : "s")")
                                .font(.system(size: isExternalDisplay ? 140 : 14))
                                .foregroundColor(.white)

                            Text(linkHistory.joined(separator: " ➡️ "))
                                .font(.system(size: geo.size.width * 0.02))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                    }
                } else {
                    VStack {
                        Text("WikiWings")
                            .font(.system(size: 200, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.black.opacity(0.5))
        }
    }
}
struct Rocket: Identifiable {
    let id = UUID()
    var position: CGPoint
    var fontSize: CGFloat
    var speed: CGFloat
}

struct RocketAnimationView: View {
    @State private var rockets: [Rocket] = []
    let rocketCount = 8
    let rocketEmoji = "🚀"
    let fontSizes: [CGFloat] = [40, 60, 80, 100, 120]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(rockets) { rocket in
                    Text(rocketEmoji)
                        .font(.system(size: rocket.fontSize))
                        .position(rocket.position)
                        .animation(nil, value: rocket.position)
                }
            }
            .onAppear {
                rockets = (0..<rocketCount).map { _ in
                    randomRocket(in: geo.size)
                }
                Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                    withAnimation(.linear(duration: 1/60)) {
                        updateRockets(in: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func randomRocket(in size: CGSize) -> Rocket {
        let fontSize = fontSizes.randomElement()!
        let speed = CGFloat.random(in: 2...5)
        let startFromLeft = Bool.random()
        let x: CGFloat = startFromLeft ? -fontSize : CGFloat.random(in: 0...size.width)
        let y: CGFloat = startFromLeft ? CGFloat.random(in: 0...size.height) : size.height + fontSize
        return Rocket(position: CGPoint(x: x, y: y), fontSize: fontSize, speed: speed)
    }

    private func updateRockets(in size: CGSize) {
        for i in rockets.indices {
            var rocket = rockets[i]
            rocket.position.x += rocket.speed
            rocket.position.y -= rocket.speed
            if rocket.position.x > size.width + rocket.fontSize || rocket.position.y < -rocket.fontSize {
                rockets[i] = randomRocket(in: size)
            } else {
                rockets[i] = rocket
            }
        }
    }
}

#Preview {
    StartScreenSceneView()
        .frame(width: 1920, height: 1080)
}
