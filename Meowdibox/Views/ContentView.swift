import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var gameModel = GameModel()
    let botoes = BotoesContent.botoes

    @State var draggingID: UUID?
    @State var dragPosition: CGPoint = .zero
    @State var isPaused: Bool = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Image("fundo")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    SpriteView(scene: gameModel.scene, transition: nil, isPaused: false, preferredFramesPerSecond: 180, options: [.allowsTransparency], shouldRender: { _ in true })

                    VStack(alignment: .center) {
                        ShowBotoesContent(geo: geo, goTo: 7, draggingID: $draggingID, dragPosition: $dragPosition, gameModel: gameModel)

                        ShowBotoesContent(geo: geo, goTo: 8, draggingID: $draggingID, dragPosition: $dragPosition, gameModel: gameModel)
                            .padding(.trailing, 60)
                    }

                    .padding(.bottom, 10)
                    if isPaused {
                        ZStack(alignment: .center) {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()
                            PauseHomeScreen(pause: $isPaused, isDarkMode: $isDarkMode, onDismiss: {
                                dismiss()
                            }, gameModel: gameModel)
                        }
                    }
                    if let id = draggingID,
                       let botao = botoes.first(where: { $0.id == id })
                    {
                        BotaoView(botao: botao, isDragging: true, mutado: false, existSound: false)
                            .position(dragPosition)
                            .allowsHitTesting(false)
                    }
                }
                .onAppear {
                    gameModel.start(viewSize: geo.size)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .toolbar {
                Button {
                    if !isPaused {
                        gameModel.pauseAllCats()
                        isPaused = true
                    }
                } label: {
                    ZStack {
                        Image(systemName: !isPaused ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.cinza.opacity(0.5))
                                    .frame(width: 40, height: 40)
                            ).padding(.top, 30)
                    }
                }
            }
        }.navigationBarBackButtonHidden()
    }
}

struct PauseHomeScreen: View {
    @Binding var pause: Bool
    @Binding var isDarkMode: Bool
    let onDismiss: () -> Void
    @ObservedObject var gameModel: GameModel
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.cinzaFundo)
            .stroke(.strokeCinza, lineWidth: 10)
            .frame(width: 485, height: 257)
            .overlay {
                VStack(spacing:10) {
                    
                    Image("Pause")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 181)
                    HStack(alignment: .center,spacing: 23){
                        
                        Button{
                            onDismiss()
                        } label: {
                            Image("Menu")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 81)
                        }
                        
                        Button{
                            gameModel.startAllCats()
                            pause.toggle()
                        }label: {
                            Image("Continue")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 106)
                        }
                        
                        Button{
                            isDarkMode.toggle()
                        }
                        label: {
                            Image("Mode")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 81)
                        }
                        
                    }
                }
            }
    }
}

struct ShowBotoesContent: View {
    let botoes = BotoesContent.botoes
    var geo: GeometryProxy
    let goTo: Int
    @Binding var draggingID: UUID?
    @Binding var dragPosition: CGPoint
    @ObservedObject var gameModel: GameModel
    var body: some View {
        if goTo <= 7 {
            HStack(alignment: .center, spacing: 52 / 6) {
                ForEach(Array(botoes.enumerated()), id: \.offset) { index, botao in
                    if index >= goTo {
                        let isDragging = draggingID == botao.id
                        let isPlaying = (gameModel.pausedSounds.first(where: { $0 == botao.som }) != nil)
                        let existSound = (gameModel.sounds.first(where: { $0 == botao.som }) == nil)

                        BotaoView(botao: botao, isDragging: isDragging, mutado: isPlaying, existSound: existSound)
                            .opacity(isDragging ? 0.35 : 1.0)
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        if existSound {
                                            let resultado = CGPoint(x: value.location.x - 60, y: value.location.y) // tamanho do botao pela metade
                                            draggingID = botao.id
                                            dragPosition = resultado
                                        }
                                    }
                                    .onEnded { value in
                                        if existSound {
                                            let dropPointSwiftUI = value.location

                                            let skPoint = CGPoint(
                                                x: dropPointSwiftUI.x - 50,
                                                y: geo.size.height - dropPointSwiftUI.y - 11
                                            )

                                            if gameModel.changeTexture(
                                                textureName: botao.textura,
                                                soundName: botao.som,
                                                posicao: skPoint
                                            ) {
                                                gameModel.sounds.append(botao.som)
                                            }
                                        }
                                        withAnimation(.spring(response: 1, dampingFraction: 0.7)) {
                                            draggingID = nil
                                            dragPosition = .zero
                                        }
                                    }
                            )
                    }
                }
            }
        } else {
            HStack(alignment: .center, spacing: 52 / 6) {
                ForEach(Array(botoes.enumerated()), id: \.offset) { index, botao in
                    if index < 7 {
                        let isDragging = draggingID == botao.id
                        let isPlaying = (gameModel.pausedSounds.first(where: { $0 == botao.som }) != nil)
                        let existSound = (gameModel.sounds.first(where: { $0 == botao.som }) == nil)

                        BotaoView(botao: botao, isDragging: isDragging, mutado: isPlaying, existSound: existSound)
                            .opacity(isDragging ? 0.35 : 1.0)
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        if existSound {
                                            let resultado = CGPoint(x: value.location.x - 60, y: value.location.y) // tamanho do botao pela metade
                                            draggingID = botao.id
                                            dragPosition = resultado
                                        }
                                    }
                                    .onEnded { value in
                                        if existSound {
                                            let dropPointSwiftUI = value.location

                                            let skPoint = CGPoint(
                                                x: dropPointSwiftUI.x - 50,
                                                y: geo.size.height - dropPointSwiftUI.y - 11 // tamanho do gato
                                            )

                                            if gameModel.changeTexture(
                                                textureName: botao.textura,
                                                soundName: botao.som,
                                                posicao: skPoint
                                            ) {
                                                gameModel.sounds.append(botao.som)
                                            }
                                        }
                                        draggingID = nil
                                        dragPosition = .zero
                                    }
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
