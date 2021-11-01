//
//  ViewController.swift
//  BluetoothManager
//
//  Created by haanwave on 2021/11/01.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var bluetoothService = BluetoothManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        /// configure
        bluetoothService.delegate = self
        /// 단일 기기 연결
        /// 연결을 위한 uuid를 할당하고 블루투스 스캔을 시작한다.
        /// 전체 기기를 스캔하려면 uuid를 할당하지 않고(또는 이미 할당된 uuid를 지우고) 스캔을 시작한다
        bluetoothService.uuidForConnect = UUID(uuidString: "UUID")
        bluetoothService.startScan()
    }
}

extension ViewController: BluetoothManagerDelegate {
    func didDiscover(discoveredDevice peripheral: CBPeripheral) {
        /// 검색된 기기 처리
    }
    
    func didConnected(connectedDevice peripheral: CBPeripheral) {
        /// 연결된 기기 처리
    }
}
