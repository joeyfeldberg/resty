import SwiftUI

struct BreakBackdropView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.08, blue: 0.15),
                            Color(red: 0.10, green: 0.16, blue: 0.28),
                            Color(red: 0.22, green: 0.30, blue: 0.26)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Circle()
                        .fill(Color(red: 0.34, green: 0.64, blue: 0.78).opacity(0.16))
                        .frame(width: size.width * 0.56)
                        .blur(radius: 50)
                        .offset(x: -size.width * 0.30, y: -size.height * 0.22)

                    Circle()
                        .fill(Color(red: 0.98, green: 0.63, blue: 0.33).opacity(0.96))
                        .frame(width: size.width * 0.18)
                        .blur(radius: 1.5)
                        .offset(x: size.width * 0.20, y: -size.height * 0.10)
                        .shadow(color: Color(red: 0.98, green: 0.64, blue: 0.35).opacity(0.30), radius: 70)

                    Circle()
                        .fill(Color(red: 0.98, green: 0.63, blue: 0.33).opacity(0.12))
                        .frame(width: size.width * 0.28)
                        .blur(radius: 10)
                        .offset(x: size.width * 0.20, y: -size.height * 0.10)

                    AtmosphereRibbon(amplitude: 0.16, phase: CGFloat(time * 0.12))
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.88, blue: 0.77).opacity(0.38),
                                    Color(red: 0.76, green: 0.95, blue: 0.86).opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: size.height * 0.24)
                        .blur(radius: 22)
                        .blendMode(.screen)
                        .offset(x: -size.width * 0.05, y: size.height * 0.10)

                    AtmosphereRibbon(amplitude: 0.10, phase: CGFloat(time * 0.08) + 1.4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: size.height * 0.16)
                        .blur(radius: 28)
                        .offset(x: size.width * 0.08, y: size.height * 0.18)

                    MistBand(amplitude: 0.06, phase: CGFloat(time * 0.10), bias: 0.58)
                        .fill(Color.white.opacity(0.09))
                        .frame(height: size.height * 0.12)
                        .blur(radius: 14)
                        .offset(x: sin(time * 0.12) * 28, y: size.height * 0.10)

                    MistBand(amplitude: 0.04, phase: CGFloat(time * 0.08) + 2.0, bias: 0.70)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: size.height * 0.10)
                        .blur(radius: 18)
                        .offset(x: cos(time * 0.10) * 32, y: size.height * 0.16)

                    BreakHillShape(horizon: 0.54, amplitude: 0.22, shift: -0.18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.07, green: 0.11, blue: 0.17),
                                    Color(red: 0.05, green: 0.08, blue: 0.13)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: size.height * 0.56)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    BreakHillShape(horizon: 0.60, amplitude: 0.18, shift: 0.14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.11, green: 0.21, blue: 0.20),
                                    Color(red: 0.07, green: 0.14, blue: 0.14)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: size.height * 0.46)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    BreakHillShape(horizon: 0.69, amplitude: 0.14, shift: -0.10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.34, blue: 0.26),
                                    Color(red: 0.11, green: 0.22, blue: 0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            BreakHillShape(horizon: 0.69, amplitude: 0.14, shift: -0.10)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .frame(height: size.height * 0.34)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    BreakHillShape(horizon: 0.77, amplitude: 0.10, shift: 0.06)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.30, green: 0.50, blue: 0.31),
                                    Color(red: 0.18, green: 0.31, blue: 0.21)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: size.height * 0.24)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    ValleyGlow()
                        .fill(Color(red: 0.72, green: 0.89, blue: 0.76).opacity(0.12))
                        .frame(width: size.width * 0.42, height: size.height * 0.12)
                        .blur(radius: 16)
                        .offset(x: -size.width * 0.04, y: size.height * 0.28)
                }
                .compositingGroup()
                .ignoresSafeArea()
            }
        }
    }
}

private struct AtmosphereRibbon: Shape {
    let amplitude: CGFloat
    let phase: CGFloat

    func path(in rect: CGRect) -> Path {
        let midY = rect.height * 0.58
        let offset = sin(phase) * rect.width * 0.05

        return Path { path in
            path.move(to: CGPoint(x: 0, y: midY))
            path.addCurve(
                to: CGPoint(x: rect.width, y: midY - rect.height * 0.10),
                control1: CGPoint(x: rect.width * 0.20 + offset, y: rect.height * (0.08 - amplitude)),
                control2: CGPoint(x: rect.width * 0.72 + offset, y: rect.height * (1.02 - amplitude))
            )
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.closeSubpath()
        }
    }
}

private struct MistBand: Shape {
    let amplitude: CGFloat
    let phase: CGFloat
    let bias: CGFloat

    func path(in rect: CGRect) -> Path {
        let baseY = rect.height * bias
        let wave = sin(phase) * rect.width * 0.03

        return Path { path in
            path.move(to: CGPoint(x: 0, y: baseY))
            path.addCurve(
                to: CGPoint(x: rect.width, y: baseY - rect.height * 0.10),
                control1: CGPoint(x: rect.width * 0.22 + wave, y: rect.height * (bias - amplitude)),
                control2: CGPoint(x: rect.width * 0.72 + wave, y: rect.height * (bias + amplitude))
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
    }
}

private struct BreakHillShape: Shape {
    let horizon: CGFloat
    let amplitude: CGFloat
    let shift: CGFloat

    func path(in rect: CGRect) -> Path {
        let baseline = rect.height * horizon
        let horizontalShift = rect.width * shift

        return Path { path in
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: baseline))
            path.addCurve(
                to: CGPoint(x: rect.width, y: baseline + rect.height * 0.02),
                control1: CGPoint(x: rect.width * 0.20 + horizontalShift, y: baseline - rect.height * amplitude),
                control2: CGPoint(x: rect.width * 0.74 + horizontalShift, y: baseline + rect.height * amplitude * 0.60)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.closeSubpath()
        }
    }
}

private struct ValleyGlow: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}
