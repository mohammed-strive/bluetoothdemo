//
//  CentralController.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 16/11/22.
//

import Foundation
import CoreBluetooth
import os

class CentralController: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    @Published var peripherals: [CBPeripheral] = []
    @Published var transferCharacteristic: CBCharacteristic?
    @Published var connectedToPeripheral = false
    @Published var connectToPeripheralError: Error?
    @Published var publishedMessages: [Message] = []
    @Published var centralUser: User?
    
    var data = Data()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals() {
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        centralManager.connect(peripheral)
    }
    
    func writeData(message: String) {
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = transferCharacteristic
        else { return }
        
        while connectedPeripheral.canSendWriteWithoutResponse {
            let mtu = connectedPeripheral.maximumWriteValueLength(for: .withoutResponse)
            var rawPacket = [UInt8]()
            
            let bytesToCopy: size_t = min(mtu, message.count)
            data.copyBytes(to: &rawPacket, count: bytesToCopy)
            
            let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
            let stringFromData = String(data: packetData, encoding: .utf8)
            let messageData = Data(bytes: Array(message.utf8), count: mtu)
            
            os_log("Writing %d bytes: %s", bytesToCopy, String(describing: stringFromData))
            connectedPeripheral.writeValue(messageData, for: transferCharacteristic, type: .withoutResponse)
        }
    }
    
    func cleanup() {
        
        guard let connectedPeripheral = connectedPeripheral, case .connected = connectedPeripheral.state else { return }
        
        for service in (connectedPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID {
                    self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}


extension CentralController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central Manager state is powered ON")
            scanForPeripherals()
        default:
            print("Central Manager is in \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Trying to connect to the periperhal: \(String(describing: peripheral.name))")
        peripherals.append(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedToPeripheral = true
        self.connectedPeripheral = peripheral
        centralUser = User(name: peripheral.name ?? "Central User", isCurrentUser: true)
        central.stopScan()
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("Peripheral disconnected")
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Failed to connect to peripheral: \(String(describing: error.debugDescription))")
        connectToPeripheralError = error
        connectedToPeripheral = false
    }
}

extension CentralController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error while discovering services: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        os_log("Discovering services for \(String(describing: peripheral.name))")
        
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            os_log("Error discovering Characteristics: %s", error.localizedDescription)
            return
        }
        
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            self.transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Unable to recieve updates from device: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
        publishedMessages.append(Message(content: stringFromData, user: User(name: "peripheral", isCurrentUser: false)))
    }
}
