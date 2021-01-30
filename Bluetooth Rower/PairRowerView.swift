//
//  PairRowerView.swift
//  Bluetooth Rower
//
//  Created by Jeff Gugelmann on 30/01/2021.
//

import SwiftUI
import CoreBluetooth

struct PairRowerView: View {
    
    @ObservedObject var bleManager: BLECentralManager
    var activePage: Binding<Page?>
    
    init(bleManager: BLECentralManager, activePage: Binding<Page?>) {
        self.activePage = activePage
        self.bleManager = bleManager
        if self.bleManager.peripherals.filter({ $0.isConnected || $0.isConnecting }).count == 0 && !self.bleManager.isScanning  {
            self.bleManager.startScanning()
        }
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorColor = UIColor.init(Color.init("CardBorderColor"))
    }
    
    var body: some View {
        VStack (alignment: .trailing, spacing: 0) {
            Button("Done", action: {
                if self.bleManager.isScanning {
                    self.bleManager.stopScanning()
                }
                self.activePage.wrappedValue = nil
            }).padding()
            VStack (spacing: 0) {
                Text("Connect to PM5")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 32)
                if bleManager.peripherals.count > 0 {
                    
                    List {
                        ForEach(bleManager.peripherals) { peripheral in
                            Peripheral_ListItem(peripheral: peripheral, onClick: {
                                if peripheral.isConnecting || peripheral.isConnected {
                                    bleManager.disconnectPeripheral(peripheral: peripheral)
                                } else {
                                    bleManager.connectPeripheral(peripheral: peripheral)
                                }
                            })
                            .padding(.trailing, 16)
                        }
                        .listRowBackground(Color.init("BackgroundColor"))
                    }
                    .background(Color.init("BackgroundColor"))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.init("CardBorderColor"), lineWidth: 0.5)
                    )
                } else {
                    ZStack {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.init("BackgroundColor"))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.init("CardBorderColor"), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 32)
        }
    }
}

struct Peripheral_ListItem: View {
    
    let peripheral: Peripheral
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack {
                Text(peripheral.name)
                Spacer()
                if peripheral.isConnected {
                    Image(systemName: "checkmark")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                } else if peripheral.isConnecting {
                    ProgressView()
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
    }
}

struct PairRowerView_Previews: PreviewProvider {
    static var previews: some View {
        PairRowerView(bleManager: BLECentralManager(), activePage: .constant(nil))
    }
}

struct ListItem_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Peripheral_ListItem(peripheral: Peripheral(id: UUID(), name: "Test Peripheral", peripheral: nil, rssi: 8, isConnected: true), onClick: {})
                .padding(.trailing, 16)
        }
    }
}
