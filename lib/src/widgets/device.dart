import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../app.dart';
import '../model/device_model.dart';
import '../views/control_module/module.dart';
import '../views/home/util.dart';
import '../views/scan_and_provisionning/scan_and_provisioning.dart';
import 'device_item.dart';
import 'title.dart';

class Device extends StatefulWidget {
  IMeshNetwork meshNetwork;
  MeshManagerApi meshManagerApi;
  NordicNrfMesh nordicNrfMesh;
  Device(
      {Key? key,
      required this.nordicNrfMesh,
      required this.meshNetwork,
      required this.meshManagerApi})
      : super(key: key);
  @override
  State<Device> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  final _serviceData = <String, Uuid>{};
  final _devices = <DiscoveredDevice>{};
  bool isScanning = true;
  StreamSubscription? _scanSubscription;
  bool isProvisioning = false;
  final bleMeshManager = BleMeshManager();

  late List<ProvisionedMeshNode> nodes;
  @override
  void initState() {
    _scanUnprovisionned();
    super.initState();
  }

  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    isScanning = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> init(DiscoveredDevice device, String deviceUUid) async {
    bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
        widget.meshManagerApi, bleMeshManager);
    await bleMeshManager.connect(device);
    // get nodes (ignore first node which is the default provisioner)
    nodes = (await widget.meshManagerApi.meshNetwork!.nodes).skip(1).toList();
    // will bind app keys (needed to be able to configure node)
    for (final node in nodes) {
      final elements = await node.elements;
      for (final element in elements) {
        for (final model in element.models) {
          if (model.boundAppKey.isEmpty) {
            if (element == elements.first && model == element.models.first) {
              continue;
            }
            final unicast = await node.unicastAddress;
            debugPrint('need to bind app key');
            await widget.meshManagerApi.sendConfigModelAppBind(
              unicast,
              element.address,
              model.modelId,
            );
          }
        }
      }
    }
    print("deviceUUid===${device.id} ");
    await Duration(milliseconds: 500);
    await subscript(context, widget.meshManagerApi, device.id);
    await Duration(milliseconds: 500);
    await publication(context, widget.meshManagerApi, device.id);
  }

  Future<void> _scanUnprovisionned() async {
    _serviceData.clear();
    setState(() {
      _devices.clear();
    });
    await checkAndAskPermissions();
    _scanSubscription =
        widget.nordicNrfMesh.scanForUnprovisionedNodes().listen((device) async {
      print("scan device===$device");
      if (_devices.every((d) => d.id != device.id)) {
        if (device.serviceData[meshProvisioningUuid] != null) {
          final deviceUuid = Uuid.parse(widget.meshManagerApi.getDeviceUuid(
              device.serviceData[meshProvisioningUuid]!.toList()));
          debugPrint('deviceUuid: $deviceUuid');
          _serviceData[device.id] = deviceUuid;
          _devices.add(device);
          setState(() {});
        }
      }
    });
    setState(() {
      isScanning = true;
    });
    return Future.delayed(const Duration(seconds: 10), _stopScan);
  }

  Future<void> provisionDevice(DiscoveredDevice device) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isScanning) {
      await _stopScan();
    }
    if (isProvisioning) {
      return;
    }
    isProvisioning = true;

    try {
      String deviceUUID;

      if (Platform.isAndroid) {
        deviceUUID = _serviceData[device.id].toString();
      } else if (Platform.isIOS) {
        deviceUUID = device.id.toString();
      } else {
        throw UnimplementedError(
            'device uuid on platform : ${Platform.operatingSystem}');
      }
      DeviceModel.instance.saveUUID(device.id, deviceUUID);
      final provisioningEvent = ProvisioningEvent();
      final provisionedMeshNodeF = widget.nordicNrfMesh
          .provisioning(
            widget.meshManagerApi,
            BleMeshManager(),
            device,
            deviceUUID,
            events: provisioningEvent,
          )
          .timeout(const Duration(minutes: 1));

      unawaited(provisionedMeshNodeF.then((node) {
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          DeviceModel.instance.addInfo(node, device.id);
          init(device, deviceUUID);
          // _scanUnprovisionned();
          // init(device, deviceUUID);
        });

        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(const SnackBar(
            content:
                Text('Provisionning succeed, redirecting to control tab...')));
        Future.delayed(
          const Duration(milliseconds: 500),
        );
      }).catchError((_) {
        print(">>>>>>>>>>>>>>>>>Provisionning");
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Provisionning failed')));
        _scanUnprovisionned();
      }));
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProvisioningDialog(
          provisionedMeshNode: provisionedMeshNodeF,
          provisioningEvent: provisioningEvent,
          meshManagerApi: widget.meshManagerApi,
          selectedElementAddress: DeviceModel.instance.maxAddress + 1,
          device: device,
        ),
      );
    } catch (e) {
      debugPrint('fail >>>>>>>>>>>>>$e');
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Caught error: $e')));
    } finally {
      isProvisioning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleWidget2(
          onTap: () => _scanUnprovisionned(),
          titleText: "Device",
          isScanning: isScanning,
        ),
        if (!isScanning && _devices.isEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('No Device'),
            ],
          ),
        if (_devices.isNotEmpty)
          for (var i = 0; i < _devices.length; i++)
            DeviceItem(
              key: ValueKey('device-$i'),
              device: _devices.elementAt(i),
              onTap: () => provisionDevice(_devices.elementAt(i)),
            ),
      ],
    );
  }
}
