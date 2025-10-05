//
//  StartScreenSceneView.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import SwiftUI

struct StartScreenSceneView: View {
    var body: some View {
        VStack {
            Text("WikiWings")
                .font(.system(size: 200, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
}
