//
//  Helpers.swift
//  Bluetooth Rower
//
//  Created by Jeff Gugelmann on 30/01/2021.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        PrimaryButtonStyleView(configuration: configuration, color: color)
    }
}

private extension PrimaryButtonStyle {
    struct PrimaryButtonStyleView: View {
        @Environment(\.isEnabled) var isEnabled
        let configuration: PrimaryButtonStyle.Configuration
        let color: Color
        
        var body: some View {
            configuration
                .label
                .font(Font.body.bold())
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(isEnabled ? color : Color.init("CardColor"))
                .cornerRadius(8)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }
}

struct CardButtonStyle: ButtonStyle {
        
    func makeBody(configuration: Self.Configuration) -> some View {
        CardButtonStyleView(configuration: configuration)
    }
}

private extension CardButtonStyle {
    struct CardButtonStyleView: View {
        @Environment(\.isEnabled) var isEnabled
        let configuration: PrimaryButtonStyle.Configuration
        
        var body: some View {
            configuration
                .label
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(Color.init("CardColor"))
                .cornerRadius(8)
                .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1) : 0.5)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.init("CardBorderColor"), lineWidth: 0.5)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
        }
    }
}

enum Page: Identifiable {
    case pairRower
    
    var id: Int {
        hashValue
    }
}

struct CardButton_Previews: PreviewProvider {
    static var previews: some View {
        Button("Test", action: {})
            .buttonStyle(CardButtonStyle())
            .disabled(false)
            .frame(maxWidth: .infinity)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        Button("Test", action: {})
            .buttonStyle(PrimaryButtonStyle())
            .disabled(false)
            .frame(maxWidth: .infinity)
    }
}
