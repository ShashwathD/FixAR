//
//  TransitionView.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/5/25.
//

import SwiftUI

struct TransitionView: View {
    var geminiResponse: String
    var problemDesc: String
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View {
        
        ZStack {
            Color(red: 220/255, green: 245/255, blue: 230/255).ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                Text("Troubleshooting Results")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 30/255, green: 100/255, blue: 60/255))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ScrollView {
                    Text(geminiResponse)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .padding(.horizontal, 30)
                }

                Spacer()

                NavigationLink(destination: CameraAppView(viewModel: viewModel, problemDesc: problemDesc)) {
                    Text("Continue to Camera")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 50/255, green: 140/255, blue: 90/255))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                }

                Spacer()
            }
        }
    }
}


//#Preview {
//    TransitionView(geminiResponse: "Preview")
//}
