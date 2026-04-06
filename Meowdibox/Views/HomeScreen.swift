//
//  HomeScreen.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 31/03/26.
//
import SwiftUI

struct HomeScreen: View {
    var body: some View {
        NavigationView {
            ZStack {
                Image("fundo_home")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                VStack {
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 500)
                        .padding()
                    
                    NavigationLink(destination: ContentView()) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 90, height: 90)
                    }
                }
            }
        }
    }
}
#Preview {
    HomeScreen()
}
