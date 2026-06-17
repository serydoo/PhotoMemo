//
//  CardPreviewView.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import SwiftUI

struct CardPreviewView: View {

    var body: some View {

        VStack(spacing: 0) {

            Rectangle()
                .fill(.blue)
                .frame(
                    width: 800,
                    height: 500
                )

            Rectangle()
                .fill(
                    Color(
                        red: 244 / 255,
                        green: 243 / 255,
                        blue: 243 / 255
                    )
                )
                .frame(
                    width: 800,
                    height: 130
                )
        }
    }
}

#Preview {

    CardPreviewView()
}