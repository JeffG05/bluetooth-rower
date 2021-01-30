//
//  ConnectedView.swift
//  Bluetooth Rower
//
//  Created by Jeff Gugelmann on 30/01/2021.
//

import SwiftUI

struct ConnectedView: View {
    
    @ObservedObject var bleCentralManager: BLECentralManager
    @ObservedObject var blePeripheralManager: BLEPeripheralManager
    var activePage: Binding<Page?>
    
    init(bleCentralManager: BLECentralManager, blePeripheralManager: BLEPeripheralManager, activePage: Binding<Page?>) {
        self.bleCentralManager = bleCentralManager
        self.blePeripheralManager = blePeripheralManager
        self.activePage = activePage
        
        if bleCentralManager.isConnected && !blePeripheralManager.isAdvertising {
            blePeripheralManager.startAdvertising()
        } else if !bleCentralManager.isConnected && blePeripheralManager.isAdvertising {
            blePeripheralManager.stopAdvertising()
        }
        
    }
    
    var body: some View {
        let rowerConnected = bleCentralManager.peripherals.filter({$0.isConnected}).count != 0
        let zwiftConnected = blePeripheralManager.isSubscribed
        let statusOk = rowerConnected && zwiftConnected
        
        GeometryReader { proxy in
            VStack {
                ScrollView {
                    Text("Bluetooth Rower")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 24)
                        .padding(.bottom, 4)
                    Text("Status")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: Alignment.leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 2)
                    CardView {
                        Image(systemName: statusOk ? "checkmark.circle" : (rowerConnected ? "exclamationmark.circle" : "xmark.circle"))
                            .font(.system(size: 80, weight: .thin))
                            .foregroundColor(statusOk ? .green : (rowerConnected ? .orange : .red))
                        Text(statusOk ? "Connected" : (rowerConnected ? "Broadcasting" : "Not Connected"))
                            .font(.title2)
                            .foregroundColor(statusOk ? .green : (rowerConnected ? .orange : .red))
                            .padding(2)
                    }
                    Text("Connections")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: Alignment.leading)
                        .padding(.top, 32)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 2)
                    ClickableCardView(onClick: { activePage.wrappedValue = .pairRower }) {
                        HStack {
                            VStack {
                                Text("Rower")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.headline)
                                    .padding(.leading, 24)
                                    .padding(.bottom, 1)
                                Text(rowerConnected ? "Connected" : "Not Connected")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.subheadline)
                                    .padding(.leading, 24)
                                    .foregroundColor(rowerConnected ? .green : .red)
                            }
                            Image(systemName: "chevron.right")
                                .padding(.trailing)
                                .foregroundColor(.gray)
                        }
                    }
                    .disabled(!bleCentralManager.isSwitchedOn)
                    CardView() {
                        HStack {
                            VStack {
                                Text("Fitness App")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.headline)
                                    .padding(.leading, 24)
                                    .padding(.bottom, 1)
                                Text(zwiftConnected ? "Connected" : "Not Connected")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.subheadline)
                                    .padding(.leading, 24)
                                    .foregroundColor(zwiftConnected ? .green : .red)
                            }
                        }
                    }
                    .disabled(!bleCentralManager.isSwitchedOn || !bleCentralManager.isConnected)
                    Text("Settings")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: Alignment.leading)
                        .padding(.top, 32)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 2)
                    ClickableCardView(onClick: {
                        blePeripheralManager.togglePowerConversion()
                    }) {
                        Text("Power Conversion")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 1)
                        Text(blePeripheralManager.powerConversionEnabled ? "Enabled" : "Disabled")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline)
                            .foregroundColor(blePeripheralManager.powerConversionEnabled ? .green : .red)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .padding(proxy.safeAreaInsets)
            .background(Color.init("BackgroundColor"))
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        }
        
    }
}

struct CardView<Content: View> : View {
    
    @Environment(\.isEnabled) var isEnabled
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            VStack {
                content
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(Color.init("CardColor"))
            .cornerRadius(8)
            .opacity(isEnabled ? 1 : 0.5)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.init("CardBorderColor"), lineWidth: 0.5)
            )
        }
        .padding(.horizontal)
    }
    
}

struct ClickableCardView<Content: View> : View {
    
    let content: Content
    let onClick: () -> Void
    
    init(onClick: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onClick = onClick
    }
    
    var body: some View {
        VStack {
            Button(action: { self.onClick() }) {
                VStack {
                    content
                }.foregroundColor(Color.init("TextColor"))
            }
            .buttonStyle(CardButtonStyle())
        }
        .padding(.horizontal)
    }
    
}

struct ConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedView(bleCentralManager: BLECentralManager(), blePeripheralManager: BLEPeripheralManager(), activePage: .constant(nil))
    }
}
