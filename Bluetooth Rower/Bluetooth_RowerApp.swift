//
//  Bluetooth_RowerApp.swift
//  Bluetooth Rower
//
//  Created by Jeff Gugelmann on 30/01/2021.
//

import SwiftUI

@main
struct Bluetooth_RowerApp: App {
    @State var activePage: Page?
    
    @ObservedObject var bleCentralManager: BLECentralManager = BLECentralManager()
    @ObservedObject var blePeripheralManager: BLEPeripheralManager = BLEPeripheralManager()
    
    init() {
        bleCentralManager.peripheralManager = blePeripheralManager
    }
    
    var body: some Scene {
        WindowGroup {
            ConnectedView(bleCentralManager: bleCentralManager, blePeripheralManager: blePeripheralManager, activePage: $activePage)
                .sheet(item: $activePage, onDismiss: {
                    if bleCentralManager.isScanning {
                        bleCentralManager.stopScanning()
                    }
                }) { item in
                    switch item {
                    case .pairRower:
                        PairRowerView(bleManager: bleCentralManager, activePage: $activePage)
                    }
                }
        }
    }
}
