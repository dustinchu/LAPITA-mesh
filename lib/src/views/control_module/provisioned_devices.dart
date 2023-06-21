import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../app.dart';
import '../../model/device_model.dart';
import '../../widgets/control_device.dart';
import '../../widgets/title.dart';

class ProvisionedDevices extends StatefulWidget {
  final NordicNrfMesh nordicNrfMesh;

  const ProvisionedDevices({Key? key, required this.nordicNrfMesh})
      : super(key: key);

  @override
  State<ProvisionedDevices> createState() => _ProvisionedDevicesState();
}

class _ProvisionedDevicesState extends State<ProvisionedDevices> {
  late MeshManagerApi _meshManagerApi;
  final _devices = <DiscoveredDevice>{};
  bool isScanning = false;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  DiscoveredDevice? _device;

  @override
  void initState() {
    super.initState();
    _meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
    _scanProvisionned();
  }

  @override
  void dispose() {
    super.dispose();
    _scanSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleWidget2(
          onTap: () => _scanProvisionned(),
          titleText: "Control",
          isScanning: isScanning,
        ),
        if (_device == null) ...[
          if (!isScanning && _devices.isEmpty)
            const Center(
              child: Text('No module found'),
            ),
          if (_devices.isNotEmpty)
            for (var i = 0; i < _devices.length; i++)
              ControlDeviceItem(
                devices: _devices,
                meshManagerApi: _meshManagerApi,
                key: ValueKey('device-$i'),
                device: _devices.elementAt(i),
                uuid: _devices.elementAt(i).id,
                onTap: () {
                  setState(() {
                    DeviceModel.instance.deviceMap[_devices.elementAt(i).id] =
                        _devices.elementAt(i);
                    _device = _devices.elementAt(i);
                  });
                },
              ),
        ]
        // else
        // Module(
        //     devices: _devices,
        //     device: _device!,
        //     meshManagerApi: _meshManagerApi,
        //     onDisconnect: () {
        //       _device = null;
        //       _scanProvisionned();
        //     }),
      ],
    );
  }

  Future<void> _scanProvisionned() async {
    setState(() {
      _devices.clear();
    });
    await checkAndAskPermissions();
    _scanSubscription =
        widget.nordicNrfMesh.scanForProxy().listen((device) async {
      device.serviceUuids.forEach((element) {
        print("scan device===$element");
      });
      if (_devices.every((d) => d.id != device.id)) {
        //掃描的時候 訂閱
        setState(() {
          _devices.add(device);
        });
      }
    });
    setState(() {
      isScanning = true;
    });
    return Future.delayed(const Duration(seconds: 10), _stopScan);
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    isScanning = false;
    if (mounted) {
      setState(() {});
    }
  }
}
