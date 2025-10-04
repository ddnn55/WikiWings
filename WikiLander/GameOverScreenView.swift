//
//  GameOverScreenView.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import SwiftUI

struct GameOverScreenView: View {
    let hopCount: Int
    let linkHistory: [String]
    let isExternalDisplay: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.system(size: 200, weight: .bold))
                .foregroundColor(.red)

            VStack(spacing: 10) {
                Text("Survived \(hopCount) hop\(hopCount == 1 ? "" : "s")")
                    .font(.system(size: isExternalDisplay ? 140 : 14))
                    .foregroundColor(.white)

                Text(linkHistory.joined(separator: " ➡️ "))
                    .font(.system(size: isExternalDisplay ? 140 : 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(Color.black.opacity(0.7))
        }
    }
}
