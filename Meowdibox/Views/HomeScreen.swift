//
//  HomeScreen.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 31/03/26.
//
import SwiftUI

struct HomeScreen: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isActive = false
    @State private var opacity: Double = 1.0

    var body: some View {
        if isActive {
            SelectionHomeScreen()
        } else {
            ZStack {
                Image("fundo_home")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 500)
                    .padding()
            }
            .opacity(opacity)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}
