//
//  HomeScreen.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 31/03/26.
//
import SwiftUI

struct HomeScreen: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    var body: some View {
        NavigationView {
            ZStack {
                Image("fundo_home")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 500)
                        .padding()
                    
                    Spacer()
                    NavigationLink(destination: ContentView()) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 45, height: 45)
                    }
                    .padding(.bottom,40)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
#Preview {
    HomeScreen()
}
