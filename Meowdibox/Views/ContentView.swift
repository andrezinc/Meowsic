import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var gameModel = GameModel()
    let botoes = BotoesContent.botoes

    @State private var draggingID: UUID?
    @State private var dragPosition: CGPoint = .zero
    @State private var isPaused: Bool = false
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

                        HStack(alignment: .center, spacing: 52 / 6) {
                            ForEach(Array(botoes.enumerated()), id: \.offset) { index, botao in
                                if index >= 7 {
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
                        }.padding(.trailing, 60)
                    }
                    .padding(.bottom, 10)
                    if isPaused {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: .infinity, height: .infinity)
                            .padding()
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
            .toolbar {
                Button {
                    if !isPaused {
                        gameModel.pauseAllCats()
                        isPaused = true
                    } else {
                        gameModel.startAllCats()
                        isPaused = false
                    }
                } label: {
                    ZStack {
                        Image(systemName: "pause.fill")
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

#Preview {
    ContentView()
}
