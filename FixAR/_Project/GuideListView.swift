//
//  GuideListView.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/6/25.
//

import SwiftUI

struct GuideListView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            Color(red: 220/255, green: 245/255, blue: 230/255)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Saved Guides")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 30/255, green: 100/255, blue: 60/255))
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.savedGuides.indices, id: \.self) { index in
                            NavigationLink(destination: GuideView(guide: viewModel.savedGuides[index])) {
                                HStack {
                                    Text(viewModel.savedGuides[index].title)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding()
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}



//#Preview {
//    GuideListView()
//}
