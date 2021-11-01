//
//  TransferService.swift
//  BluetoothManager
//
//  Created by haanwave on 2021/11/01.
//

import Foundation

struct TransferService {
    static let serviceUUID = CBUUID(string: "serviceUUID")
    static let characteristicUUID = CBUUID(string: "characteristicUUID")
    static var transferCharacteristic: CBCharacteristic?
}
