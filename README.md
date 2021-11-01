# BluetoothManager
BluetoothManager for use with multiple ViewControllers

## Required
### info.plist
```swift
<key>NSBluetoothAlwaysUsageDescription</key>
<string>장치 검색을 위한 블루투스 권한이 필요합니다.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>주변 장치와 통신하기 위한 권한이 필요합니다.</string>
```

## Delegate
```swift
func didDiscover(discoveredDevice peripheral: CBPeripheral) {
    /// 검색된 기기 처리
}

func didConnected(connectedDevice peripheral: CBPeripheral) {
    /// 연결된 기기 처리
}
```

## Usage
```swift
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
```
