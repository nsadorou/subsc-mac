//
//  AnimationHelpers.swift
//  SubscriptionManager
//
//  Created on 2025/01/05.
//

import SwiftUI

// MARK: - Animation Constants
struct AnimationConstants {
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let gentleSpring = Animation.spring(response: 0.7, dampingFraction: 0.9)
    
    static let quickEase = Animation.easeInOut(duration: 0.2)
    static let normalEase = Animation.easeInOut(duration: 0.3)
    static let slowEase = Animation.easeInOut(duration: 0.5)
    
    static let buttonPress = Animation.easeInOut(duration: 0.15)
    static let cardExpand = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Custom View Modifiers
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationConstants.buttonPress, value: configuration.isPressed)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

struct SlideInEffect: ViewModifier {
    let direction: SlideDirection
    @State private var offset: CGFloat = 100
    
    enum SlideDirection {
        case left, right, top, bottom
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: direction == .left ? -offset : (direction == .right ? offset : 0),
                y: direction == .top ? -offset : (direction == .bottom ? offset : 0)
            )
            .opacity(offset == 0 ? 1 : 0)
            .onAppear {
                withAnimation(AnimationConstants.smoothSpring) {
                    offset = 0
                }
            }
    }
}

struct LoadingDots: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationAmount)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}

struct SuccessCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 3, y: 8))
            path.addLine(to: CGPoint(x: 7, y: 12))
            path.addLine(to: CGPoint(x: 13, y: 3))
        }
        .trim(from: 0, to: trimEnd)
        .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 16, height: 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                trimEnd = 1
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func scaleButtonStyle() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
    
    func shake(with amount: CGFloat = 10) -> some View {
        self.modifier(ShakeEffect(animatableData: amount))
    }
    
    func pulseEffect() -> some View {
        self.modifier(PulseEffect())
    }
    
    func glowEffect(color: Color = .blue, radius: CGFloat = 5) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }
    
    func slideIn(from direction: SlideInEffect.SlideDirection) -> some View {
        self.modifier(SlideInEffect(direction: direction))
    }
    
    func cardStyle() -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func hoverable() -> some View {
        self
            .onHover { isHovered in
                withAnimation(AnimationConstants.quickEase) {
                    // ホバー効果はボタンスタイルで処理
                }
            }
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor)
                    .brightness(isHovered ? 0.1 : 0)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .foregroundColor(.white)
            .fontWeight(.medium)
            .animation(AnimationConstants.quickEase, value: isHovered)
            .animation(AnimationConstants.buttonPress, value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .brightness(isHovered ? 0.05 : 0)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.accentColor)
            .fontWeight(.medium)
            .animation(AnimationConstants.quickEase, value: isHovered)
            .animation(AnimationConstants.buttonPress, value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(AnimationConstants.quickSpring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}