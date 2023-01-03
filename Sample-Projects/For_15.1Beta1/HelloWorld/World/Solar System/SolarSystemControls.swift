/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The control panel to display along with the solar system view.
*/

import SwiftUI

/// The control panel to display along with the solar system view.
struct SolarSystemControls: View {
    @Environment(ViewModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var factCount = 0

    var body: some View {
        VStack {
            Spacer()

            VStack {
                HStack {
                    Button {
                        withAnimation { factCount -= 1 }
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .disabled(factCount == 0)
                    .padding()

                    Spacer()

                    Text("The Solar System")
                        .font(.title)

                    Spacer()

                    Button {
                        withAnimation { factCount += 1 }
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(factCount == Module.funFacts.count - 1)
                    .padding()
                }
                .labelStyle(.iconOnly)

                ZStack {
                    ForEach(Module.funFacts, id: \.self) { fact in
                        Text(fact)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .opacity(fact == Module.funFacts[factCount] ? 1 : 0)
                    }
                }
                .animation(.default, value: factCount)

                Divider()
                    .padding()

                SolarSystemToggle()
                    .buttonStyle(.borderless)
                    .padding(.bottom)

                if reduceMotion {
                    HStack {
                        Spacer()

                        Button {
                            model.solarEarth.isPaused.toggle()
                        } label: {
                            Label(
                                model.solarEarth.isPaused ? "Play" : "Pause",
                                systemImage: model.solarEarth.isPaused ? "play.fill" : "pause.fill")
                        }
                        .overlay {
                            Circle().stroke()
                        }
                        .padding([.trailing, .bottom])
                        .buttonStyle(.borderless)
                        .labelStyle(.iconOnly)
                        .help(model.solarEarth.isPaused ? "Start motion" : "Stop motion")
                    }
                }
            }
            .frame(width: 500)
            .glassBackgroundEffect(in: .rect(cornerRadius: 40))
            .onAppear {
                model.solarEarth.isPaused = reduceMotion
            }
            .onChange(of: reduceMotion) { _, reduceMotion in
                model.solarEarth.isPaused = reduceMotion
            }
        }
    }
}

#Preview {
    SolarSystemControls()
        .environment(ViewModel())
}
