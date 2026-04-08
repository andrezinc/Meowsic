//
//  HomeScreen.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 31/03/26.
//
import SwiftUI

struct SelectionHomeScreen: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("fundo_home")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                NavigationLink {
                    ContentView()
                } label: {
                    RoundedRectangle(cornerRadius: CGFloat(5))
                        .fill(.cinza)
                        .frame(width: 50, height: 50)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    SelectionHomeScreen()
}
