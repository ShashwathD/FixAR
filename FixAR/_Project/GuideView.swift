//
//  GuideView.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/6/25.
//

import SwiftUI

struct GuideView: View {
    var guide: Guide

    var body: some View {
        ZStack {
            Color(red: 220/255, green: 245/255, blue: 230/255).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text(guide.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 30/255, green: 100/255, blue: 60/255))

                ScrollView {
                    Text(guide.content)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Guide Detail")
        }
    }
}


//#Preview {
//    GuideView()
//}
