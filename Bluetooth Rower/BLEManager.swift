//
//  BLEManager.swift
//  Bluetooth Rower
//
//  Created by Jeff Gugelmann on 30/01/2021.
//

import SwiftUI
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: UUID
    let name: String
    var peripheral: CBPeripheral?
    var rssi: Int
    var isConnecting: Bool = false
    var isConnected: Bool = false
}

struct RowerData {
    var powerLow: UInt8 = 0
    var powerHigh: UInt8 = 0
    var strokeRate: UInt8 = 0
    var heartRate: UInt8 = 255
    var isRowing: Bool = false
}

class BLECentralManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        
    var centralManager: CBCentralManager!
    var peripheralManager: BLEPeripheralManager?
        
    @Published var isSwitchedOn = false
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var peripherals = [Peripheral]()
    
    @Published var rowerData = RowerData()
    
    let RowerServiceUUID = "CE060030-43E5-11E4-916C-0800200C9A66"
    let RowerStrokeDataCharacteristicUUID = "CE060036-43E5-11E4-916C-0800200C9A66"
    let RowerGeneralStatusCharacteristicUUID = "CE060031-43E5-11E4-916C-0800200C9A66"
    let RowerAdditionalStatusCharacteristicUUID = "CE060032-43E5-11E4-916C-0800200C9A66"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Bluetooth state changed
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
        } else {
            isSwitchedOn = false
        }
    }
    
    // Peripheral discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            let index = peripherals.firstIndex(where: {$0.name == name})
            if index == nil {
                let newPeripheral = Peripheral(id: peripheral.identifier, name: name, peripheral: peripheral, rssi: RSSI.intValue)
                peripherals.append(newPeripheral)
            } else {
                if (RSSI.intValue >= -75) {
                    peripherals[index!].rssi = RSSI.intValue
                } else {
                    peripherals.remove(at: index!)
                }
            }
        }
    }
    
    // Peripheral connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        let index = peripherals.firstIndex(where: {$0.name == peripheral.name})
        if index != nil {
            peripherals[index!].isConnecting = false
            peripherals[index!].isConnected = true
            peripherals[index!].peripheral = peripheral
        }
        isConnected = true
        peripheral.discoverServices([CBUUID(string: RowerServiceUUID)])
    }
    
    // Peripheral failed to connect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let index = peripherals.firstIndex(where: {$0.name == peripheral.name})
        if index != nil {
            peripherals[index!].isConnecting = false
            peripherals[index!].isConnected = false
            peripherals[index!].peripheral = peripheral
        }
        isConnected = false
    }
    
    // Peripheral disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let index = peripherals.firstIndex(where: {$0.name == peripheral.name})
        if index != nil {
            peripherals.remove(at: index!)
        }
        isConnected = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            if service.uuid.uuidString == RowerServiceUUID {
                peripheral.discoverCharacteristics([CBUUID(string: RowerStrokeDataCharacteristicUUID), CBUUID(string: RowerGeneralStatusCharacteristicUUID), CBUUID(string: RowerAdditionalStatusCharacteristicUUID)], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let uuid = characteristic.uuid.uuidString
            if [RowerGeneralStatusCharacteristicUUID, RowerAdditionalStatusCharacteristicUUID, RowerStrokeDataCharacteristicUUID].contains(uuid) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let uuid = characteristic.uuid.uuidString
        let data = characteristic.value!
        
        if uuid == RowerGeneralStatusCharacteristicUUID {
            let rowingState = data[9]
            rowerData.isRowing = rowingState == 1
        } else if uuid == RowerAdditionalStatusCharacteristicUUID {
            let heartRate = data[6]
            let strokeRate = data[5]
            rowerData.heartRate = heartRate
            rowerData.strokeRate = strokeRate
            
        } else if uuid == RowerStrokeDataCharacteristicUUID {
            let strokePowerLow = data[3]
            let strokePowerHigh = data[4]
            rowerData.powerLow = strokePowerLow
            rowerData.powerHigh = strokePowerHigh
        }
        
        peripheralManager?.updateData(rowerData)
    }
    
    
    func startScanning() {
        peripherals.removeAll()
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "CE060000-43E5-11E4-916C-0800200C9A66")], options: nil)
        isScanning = true
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connectPeripheral(peripheral: Peripheral) {
        if centralManager.isScanning {
            stopScanning()
        }
        let index = peripherals.firstIndex(where: {$0.name == peripheral.name})
        if index != nil {
            peripherals[index!].isConnecting = true
        }
        centralManager.connect(peripheral.peripheral!, options: nil)
    }
    
    func disconnectPeripheral(peripheral: Peripheral) {
        centralManager.cancelPeripheralConnection(peripheral.peripheral!)
    }
    
}

class BLEPeripheralManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    var powerPeripheralManager: CBPeripheralManager!
    @Published var isSwitchedOn = false
    @Published var isAdvertising = false
    @Published var isSubscribed = false
    @Published var powerConversionEnabled = true
    
    var valueToUpdate = 0
        
    let CylingPowerServiceUUID = "1818"
    let HeartRateServiceUUID = "180D"
    
    var CyclingPowerService: CBMutableService?
    var CyclingPowerFeature: CBMutableCharacteristic?
    var CyclingPowerMeasurement: CBMutableCharacteristic?
    var SensorLocation: CBMutableCharacteristic?
    
    var HeartRateService: CBMutableService?
    var HeartRateMeasurement: CBMutableCharacteristic?
        
    override init() {
        super.init()
        powerPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        powerPeripheralManager.delegate = self
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            isSwitchedOn = true
            CyclingPowerService = CBMutableService.init(type: CBUUID(string: CylingPowerServiceUUID), primary: true)
            HeartRateService = CBMutableService.init(type: CBUUID(string: HeartRateServiceUUID), primary: true)
            
            
            CyclingPowerFeature = CBMutableCharacteristic.init(
                type: CBUUID(string: "2A65"),
                properties: [.read],
                value: Data(bytes: [0x00,0x00,0x00,0x00], count: 4),
                permissions: [CBAttributePermissions.readable]
            )
            CyclingPowerMeasurement = CBMutableCharacteristic.init(
                type: CBUUID(string: "2A63"),
                properties: [.notify],
                value: nil,
                permissions: [CBAttributePermissions.readable]
            )
            SensorLocation = CBMutableCharacteristic.init(
                type: CBUUID(string: "2A5D"),
                properties: [.read],
                value: Data(bytes: [0x0D], count: 1),
                permissions: [CBAttributePermissions.readable]
            )
            HeartRateMeasurement = CBMutableCharacteristic.init(
                type: CBUUID(string: "2A37"),
                properties: [.notify],
                value: nil,
                permissions: [CBAttributePermissions.readable]
            )
            
            CyclingPowerService!.characteristics = [CyclingPowerFeature!, CyclingPowerMeasurement!, SensorLocation!]
            HeartRateService!.characteristics = [HeartRateMeasurement!]
            
            powerPeripheralManager.add(CyclingPowerService!)
            powerPeripheralManager.add(HeartRateService!)
        } else {
            isSwitchedOn = false
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid.isEqual(CyclingPowerMeasurement!.uuid) {
            request.value = CyclingPowerMeasurement!.value
            peripheral.respond(to: request, withResult: .success)
        } else if request.characteristic.uuid.isEqual(CyclingPowerFeature!.uuid) {
            request.value = CyclingPowerFeature!.value
            peripheral.respond(to: request, withResult: .success)
        } else if request.characteristic.uuid.isEqual(SensorLocation!.uuid) {
            request.value = SensorLocation!.value
            peripheral.respond(to: request, withResult: .success)
        } else if request.characteristic.uuid.isEqual(HeartRateMeasurement!.uuid) {
            request.value = HeartRateMeasurement!.value
            peripheral.respond(to: request, withResult: .success)
        }
        peripheral.respond(to: request, withResult: CBATTError.success)
    }
        
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        isSubscribed = true
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        isSubscribed = false
    }
    
    func startAdvertising() {
        isAdvertising = true
        powerPeripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey: "PM5 To Zwift", CBAdvertisementDataServiceUUIDsKey: [self.CyclingPowerService!.uuid, self.HeartRateService!.uuid]])
    }
    
    func stopAdvertising() {
        isAdvertising = false
        powerPeripheralManager.stopAdvertising();
    }
    
    func togglePowerConversion() {
        powerConversionEnabled.toggle()
    }
    
    func updateData(_ data: RowerData) {
        var success = true
        if valueToUpdate == 0 {
            success = updatePower(low: data.isRowing ? data.powerLow : 0, high: data.isRowing ? data.powerHigh : 0)
        } else if valueToUpdate == 1 {
            if data.heartRate != 255 {
                success = updateHeartRate(heartRate: data.heartRate)
            }
        }
        if success {
            valueToUpdate = (valueToUpdate + 1) % 2
        }
    }
    
    func updatePower(low: UInt8, high: UInt8) -> Bool {
        
        let flags: UInt8 = 0x00
        let revolutions: UInt8 = 0
        let timestamp: UInt8 = 0
        
        var powerLow: UInt8 = low
        var powerHigh: UInt8 = high
        
        if powerConversionEnabled {
            let power: UInt16 = UInt16((high & 0xff) << 8) | UInt16(low & 0xff)
            let convertedPower = UInt16(Double(power) * 1.3)
            
            powerLow = UInt8(convertedPower & 0x00ff)
            powerHigh = UInt8(convertedPower >> 8)
        }
        
        
        let bleBuffer: [UInt8] = [
            flags & 0xff,
            (flags >> 8) & 0xff,
            powerLow & 0xff,
            powerHigh & 0xff,
            revolutions & 0xff,
            (revolutions >> 8) & 0xff,
            timestamp & 0xff,
            (timestamp >> 8) & 0xff,
        ]
        let bleBufferData = Data(bleBuffer)
        
        let success = powerPeripheralManager.updateValue(bleBufferData, for: CyclingPowerMeasurement!, onSubscribedCentrals: nil)
        return success
    }
    
    func updateHeartRate(heartRate: UInt8) -> Bool {
        let flags: UInt8 = 0x00
        
        let buffer: [UInt8] = [
            flags & 0xff,
            heartRate & 0xff
        ]
        let bufferData = Data(buffer)
        
        let success = powerPeripheralManager.updateValue(bufferData, for: HeartRateMeasurement!, onSubscribedCentrals: nil)
        return success
    }
    
}
