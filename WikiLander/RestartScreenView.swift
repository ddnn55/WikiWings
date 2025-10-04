//
//  RestartScreenView.swift
//  WikiLander
//
//  Created by David Stolarsky on 10/4/25.
//

import SwiftUI

struct RestartScreenView: View {
    let onRestart: () -> Void

    var body: some View {
        Button(action: onRestart) {
            Text("TRY AGAIN")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 200, height: 50)
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}
