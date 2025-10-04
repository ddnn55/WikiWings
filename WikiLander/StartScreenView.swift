//
//  StartScreenView.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import SwiftUI

struct StartScreenView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("WikiLander")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.white)

            Button(action: onStart) {
                Text("START")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(width: 200, height: 60)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
    }
}
