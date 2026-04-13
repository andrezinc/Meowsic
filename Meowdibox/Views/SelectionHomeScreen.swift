//
//  HomeScreen.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 31/03/26.
//
import SwiftUI

struct SelectionHomeScreen: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var bueiro: String = "bueiroClick"
    @State private var goToNextPage: Bool = false
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.fundoSelectionHomeScreen.ignoresSafeArea()

               
                VStack(alignment: .center){
                    HStack {
                        Image(bueiro)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 225)
                            .onTapGesture {
                                if bueiro == "bueiro" {
                                    goToNextPage = true
                                } else {
                                    bueiro = "bueiro"
                                }
                            }
                            .background(
                                Image("titulo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 123)
                                    .offset(x: -30, y: -80)
                                    .opacity(bueiro == "bueiro" ? 1: 0)
                            ).offset(y:-40)
                            
                        
                        VStack {
                            
                            
                            Image("bueiroDefault")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 225)
                                .background(
                                    Image("bloqueado")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 110)
                                        .offset(y:-100)
                                )
                        }.offset(y:-40)
                        
                        VStack {
                          
                            
                            Image("bueiroDefault")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 225)
                                .background(
                                    Image("bloqueado")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 110)
                                        .offset(y:-100)
                                )
                        }.offset(y:-40)
                        
                    }.background(
                        Image("rua")
                            .scaledToFill()
                    )
                    
                    Text("Choose a drain and discover a secret alley-cat band.")
                        .font(.system(size:20, design: .rounded))
                        .padding(.bottom,49)
                        
                }
                // .offset(x:-10,y:-40)
            }
            .onAppear(){
                bueiro = "bueiroClick"
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .navigationDestination(isPresented: $goToNextPage) {
                ContentView()
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    SelectionHomeScreen()
}
