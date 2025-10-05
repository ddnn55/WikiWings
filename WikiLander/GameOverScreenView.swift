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
        StartScreenSceneView(
            isGameOver: true,
            hopCount: hopCount,
            linkHistory: linkHistory,
            isExternalDisplay: isExternalDisplay
        )
    }
}

#Preview(traits: .fixedLayout(width: 1920, height: 1080)) {
    GameOverScreenView(hopCount: 30, linkHistory: ["History", "Philosophy", "Science", "Nature", "Universe", "Biology", "Chemistry", "Physics", "Mathematics", "Geometry", "Algebra", "Calculus", "Statistics", "Logic", "Epistemology", "Metaphysics", "Ethics", "Politics", "Sociology", "Psychology", "Cognition", "Perception", "Reality", "Truth", "Knowledge", "Wisdom", "Understanding", "Reason", "Rationality", "Thought"], isExternalDisplay: true)
        .background(Color.black)
}
