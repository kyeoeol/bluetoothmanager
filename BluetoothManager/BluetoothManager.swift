//
//  BluetoothManager.swift
//  BluetoothManager
//
//  Created by haanwave on 2021/11/01.
//

import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func didDiscover(discoveredDevice peripheral: CBPeripheral)
    func didConnected(connectedDevice peripheral: CBPeripheral)
}

class BluetoothManager: NSObject {
    static let shared = BluetoothManager()
    
    weak var delegate: BluetoothManagerDelegate?
    
    var centralManager: CBCentralManager!
    /// 연결된 기기가 제거되지 않게 하기 위해 복사한다.
    var connectedPeripherals: CBPeripheral?
    var uuidForConnect: UUID?
    
    /// 블루투스 서비스를 위한 CBCentralManager 초기화
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
    }
    
    /// UUID를 이용한 단일 기기 검색을 위한 초기화
    convenience init(with uuid: UUID? = nil) {
        self.init()
        uuidForConnect = uuid
    }
    
    /// 블루투스 스캔 시작
    func startScan() {
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: nil,
                                              options: nil)
        }
    }
    
    /// 블루투스 스캔 정지
    func stopScan() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    /// 연결된 기기와 블루투스 연결 해제
    func cancelConnect() {
        if let connectedPeripherals = connectedPeripherals {
            centralManager.cancelPeripheralConnection(connectedPeripherals)
            uuidForConnect = nil
            self.connectedPeripherals = nil
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        /// centralManagerDidUpdateState는 필수 프로토콜 메서드이다.
        /// 일반적으로 현재 장치가 BLE(Bluetooth Low Energy)를 지원하는지, 전원이 켜져 있는지 등을 확인한다.
        /// 이 예시에서는 CBCentralManagerState 'PoweredOn'을 기다리는 데 사용한다.
        switch central.state {
        case .poweredOn:
            /// 주변 기기 스캔 작업을 시작
            print("--->[centralManager:DidUpdateState] poweredOn")
            centralManager.scanForPeripherals(withServices: nil,
                                              options: nil)
        case .poweredOff:
            print("--->[centralManager:DidUpdateState] poweredOff")
        case .unauthorized:
            print("--->[centralManager:DidUpdateState] unauthorized")
        case .unsupported:
            print("--->[centralManager:DidUpdateState] unsupported")
        case .resetting:
            print("--->[centralManager:DidUpdateState] resetting")
        case .unknown:
            print("--->[centralManager:DidUpdateState] unknown")
        default:
            print("--->[centralManager:DidUpdateState] a previously unknown central manager state occurred")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        /// 이 콜백은 전송 서비스 UUID를 알리는 주변 장치가 발견될 때마다 발생한다.
        /// RSSI를 확인하여 기기가 가까이 있는지 확인한다.
        /// 신호 강도가 너무 낮아 데이터 전송을 시도 할 수 없는 경우 거부한다.
        /// 앱의 사용 사례에 따라 최소 RSSI 값을 변경할 수 있다.
        guard RSSI.intValue >= -66 else { return }
        if let uuid = uuidForConnect {
            /// 단일 기기 연결을 위한 UUID 있다면 해당 UUID를 가진 peripheral 찾아 연결한다.
            guard peripheral.identifier == uuid else { return }
            connectedPeripherals = peripheral
            centralManager.connect(peripheral, options: nil)
            print("--->[centralManager:didDiscover] discoverd perhiperals:", peripheral)
        }
        else {
            delegate?.didDiscover(discoveredDevice: peripheral)
            print("--->[centralManager:didDiscover] discoverd perhiperals:", peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        /// 어떤 이유로 든 연결이 실패하면 관련된 처리를 한다.
        if let error = error {
            print("--->[centralManager:didFailToConnect] failed to connect to \(peripheral), Error: \(error)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        /// 주변 장치에 연결 했으므로 이제 'transferCharacteristic(전송 특성)'를 찾기 위해 서비스와 특성을 찾는다.
        print("--->[centralManager:didConnect] peripheral connected")
        /// 스캔 중지
        if centralManager.isScanning {
            centralManager.stopScan()
            print("--->[centralManager:didConnect] scanning stopped")
        }
        /// delegate를 통해  콜백을 받았는지 확인할 수 있다.
        peripheral.delegate = self
        /// serviceUUID와 일치하는 서비스만 검색
        /// 서비스 정보를 받게되면 peripheral didDiscoverServices가 호출된다.
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        /// 연결이 끊어지면 주변 장치의 로컬 복사본을 정리한다.
        connectedPeripherals = nil
        print("--->[centralManager:didDisconnectPeripheral] perhiperal disconnected")
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            /// 서비스가 무효화되었을 때  서비스를 재검색한다.
            peripheral.discoverServices([TransferService.serviceUUID])
            print("--->[peripheral:didModifyServices] invalidation of transport service, re-discovering service")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("--->[peripheral:didDiscoverServices] error discovering services: ", error)
            return
        }
        /// Transfer Service가 발견됨, 특성이 발견되면 didDiscoverCharacteristicsForService메소드가 호출된다.
        /// 둘 이상의 경우를 대비하여 새로 채워진 peripheral.services 배열을 반복한다.
        guard let peripheralServices = peripheral.services else {
            print("--->[peripheral:didDiscoverServices] no peripheral services")
            return
        }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
            print("--->[peripheral:didDiscoverServices] transfer service found", service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("--->[peripheral:didDiscoverCharacteristicsFor] error discovering characteristics: ", error)
            return
        }
        /// Transfer characteristic(전송 특성)이 발견됨
        /// 전송 특성이 발견되면, 구독을 시작하고,  우리가 포함하고 있는 데이터를 원한다는 것을 주변기기에 알린다.
        /// 다시 말하지만, 만약의 경우에 대비하여 배열을 반복하고 올바른지 확인한다.
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            /// 올바르다면 구독을 시작한다.
            TransferService.transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            print("--->[didDiscoverCharacteristicsFor] transfer characteristic found", characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("--->[peripheral:didUpdateNotificationStateFor] error changing notification state: ", error)
            return
        }
        /// 구독 / 구독 취소 여부를 알린다.
        /// 전송 특성이 아닌 경우 종료
        guard characteristic.uuid == TransferService.characteristicUUID else { return }
        if characteristic.isNotifying {
            /// 알림(구독) 시작
            print("--->[peripheral:didUpdateNotificationStateFor] start notification", characteristic)
        } else {
            /// 알림(구독) 중지
            print("--->[peripheral:didUpdateNotificationStateFor] cancel notification", characteristic)
        }
    }
}
