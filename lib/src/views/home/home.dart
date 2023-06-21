import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mesh/src/model/device_model.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../app.dart';
import '../../widgets/device.dart';
import '../../widgets/mesh_network_widget.dart';
import '../control_module/module.dart';
import '../control_module/provisioned_devices.dart';
import 'util.dart';

class Home extends StatefulWidget {
  final NordicNrfMesh nordicNrfMesh;

  const Home({Key? key, required this.nordicNrfMesh}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late IMeshNetwork? _meshNetwork;
  late final MeshManagerApi _meshManagerApi;
  late final StreamSubscription<IMeshNetwork?> onNetworkUpdateSubscription;
  late final StreamSubscription<IMeshNetwork?> onNetworkImportSubscription;
  late final StreamSubscription<IMeshNetwork?> onNetworkLoadingSubscription;
  StreamSubscription? _scanSubscription;
  final bleMeshManager = BleMeshManager();
  late List<ProvisionedMeshNode> nodes;
  final _serviceData = <String, Uuid>{};
  final _devices = <DiscoveredDevice>{};
  bool isScanning = true;
  bool isProvisioning = false;
  bool isPermissions = false;
  @override
  void initState() {
    super.initState();
    _meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
    _meshNetwork = _meshManagerApi.meshNetwork;
    onNetworkUpdateSubscription =
        _meshManagerApi.onNetworkUpdated.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });
    onNetworkImportSubscription =
        _meshManagerApi.onNetworkImported.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });
    onNetworkLoadingSubscription =
        _meshManagerApi.onNetworkLoaded.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((mag) async {
      isPermissions = await checkAndAskPermissions();
      print("permission===>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>$isPermissions");
      if (isPermissions) {
        await _scanUnprovisionned();
      }
      await widget.nordicNrfMesh.meshManagerApi.loadMeshNetwork();
      if (_meshNetwork != null) {
        List<GroupData> groups = [];
        groups = await _meshNetwork!.groups;
        print("groups >>>>>>>>>>>>>>>>>>>.size  =====${groups.length}");
        if (groups.isEmpty || groups.length == 0) {
          await _meshManagerApi.meshNetwork!.addGroupWithName("My Group");
          setState(() {});
        }
        if (groups.isNotEmpty) {
          DeviceModel.instance.groupId = groups[0].address;
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    onNetworkUpdateSubscription.cancel();
    onNetworkLoadingSubscription.cancel();
    onNetworkImportSubscription.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scanUnprovisionned() async {
    _serviceData.clear();
    setState(() {
      _devices.clear();
    });

    _scanSubscription =
        widget.nordicNrfMesh.scanForUnprovisionedNodes().listen((device) async {
      print("scan device===$device");
      if (_devices.every((d) => d.id != device.id)) {
        if (device.serviceData[meshProvisioningUuid] != null) {
          final deviceUuid = Uuid.parse(_meshManagerApi.getDeviceUuid(
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

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    isScanning = false;
    if (mounted) {
      setState(() {});
    }
  }

  // publication(String deviceUUid) async {
  //   // final scaffoldMessenger = ScaffoldMessenger.of(context);
  //   try {
  //     print(
  //         "subscript data===${DeviceModel.instance.maxAddress + 1}    4097  ${DeviceModel.instance.groupId} ");
  //     await _meshManagerApi
  //         .sendConfigModelPublicationSet(
  //             DeviceModel.instance.deviceInfo.containsKey(deviceUUid)
  //                 ? DeviceModel.instance.deviceInfo[deviceUUid]
  //                 : DeviceModel.instance.maxAddress + 1,
  //             4097,
  //             DeviceModel.instance.groupId)
  //         .timeout(const Duration(seconds: 40));
  //     print("publocation success");
  //     // publicat = Publication.success;
  //   } on TimeoutException catch (_) {
  //     print("publocation error $_");
  //     // publicat = Publication.error;
  //     // scaffoldMessenger
  //     //     .showSnackBar(const SnackBar(content: Text('Board didn\'t respond')));
  //   } on PlatformException catch (e) {
  //     print("publocation error ${e.message}");
  //     // publicat = Publication.error;
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  //   } catch (e) {
  //     // publicat = Publication.error;
  //     print("publocation error $e");
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  // subscription(String deviceUUid) async {
  //   try {
  //     print(
  //         "subscript data===${DeviceModel.instance.maxAddress + 1}    4096  ${DeviceModel.instance.groupId}   device info =${DeviceModel.instance.deviceInfo}  device UUid ==$deviceUUid");
  //     await _meshManagerApi
  //         .sendConfigModelSubscriptionAdd(
  //             DeviceModel.instance.deviceInfo.containsKey(deviceUUid)
  //                 ? DeviceModel.instance.deviceInfo[deviceUUid]
  //                 : DeviceModel.instance.maxAddress + 1,
  //             4096,
  //             DeviceModel.instance.groupId)
  //         .timeout(const Duration(seconds: 40));
  //     print("subscript success");
  //     setState(() {
  //       // subscript = Subscription.success;
  //     });
  //     // scaffoldMessenger.showSnackBar(const SnackBar(content: Text('OK')));
  //   } on TimeoutException catch (_) {
  //     print("subscript error $_");
  //     // subscript = Subscription.error;
  //     // scaffoldMessenger
  //     //     .showSnackBar(const SnackBar(content: Text('Board didn\'t respond')));
  //   } on PlatformException catch (e) {
  //     print("subscript error ${e.message}");
  //     // subscript = Subscription.error;
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  //   } catch (e) {
  //     // subscript = Subscription.error;
  //     print("subscript error ${e}");
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  Future<void> init(DiscoveredDevice device, String deviceUUid) async {
    bleMeshManager.callbacks =
        DoozProvisionedBleMeshManagerCallbacks(_meshManagerApi, bleMeshManager);
    await bleMeshManager.connect(device);
    // get nodes (ignore first node which is the default provisioner)
    nodes = (await _meshManagerApi.meshNetwork!.nodes).skip(1).toList();
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
            await _meshManagerApi.sendConfigModelAppBind(
              unicast,
              element.address,
              model.modelId,
            );
          }
        }
      }
    }

    await subscript(context, _meshManagerApi, deviceUUid);
    await Duration(milliseconds: 500);
    await publication(context, _meshManagerApi, deviceUUid);
  }

  // Future<void> provisionDevice(DiscoveredDevice device) async {
  //   final scaffoldMessenger = ScaffoldMessenger.of(context);
  //   if (isScanning) {
  //     await _stopScan();
  //   }
  //   if (isProvisioning) {
  //     return;
  //   }
  //   isProvisioning = true;

  //   try {
  //     String deviceUUID;

  //     if (Platform.isAndroid) {
  //       deviceUUID = _serviceData[device.id].toString();
  //     } else if (Platform.isIOS) {
  //       deviceUUID = device.id.toString();
  //     } else {
  //       throw UnimplementedError(
  //           'device uuid on platform : ${Platform.operatingSystem}');
  //     }
  //     DeviceModel.instance.saveUUID(device.id, deviceUUID);

  //     final provisioningEvent = ProvisioningEvent();
  //     final provisionedMeshNodeF = widget.nordicNrfMesh
  //         .provisioning(
  //           _meshManagerApi,
  //           BleMeshManager(),
  //           device,
  //           deviceUUID,
  //           events: provisioningEvent,
  //         )
  //         .timeout(const Duration(minutes: 1));

  //     unawaited(provisionedMeshNodeF.then((node) {
  //       Future.delayed(const Duration(milliseconds: 500)).then((value) {
  //         init(device, deviceUUID);
  //       });

  //       Navigator.of(context).pop();
  //       scaffoldMessenger.showSnackBar(const SnackBar(
  //           content:
  //               Text('Provisionning succeed, redirecting to control tab...')));
  //       Future.delayed(
  //         const Duration(milliseconds: 500),
  //       );
  //     }).catchError((_) {
  //       print(">>>>>>>>>>>>>>>>>Provisionning");
  //       Navigator.of(context).pop();
  //       scaffoldMessenger.showSnackBar(
  //           const SnackBar(content: Text('Provisionning failed')));
  //       _scanUnprovisionned();
  //     }));
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => ProvisioningDialog(
  //         provisionedMeshNode: provisionedMeshNodeF,
  //         provisioningEvent: provisioningEvent,
  //         meshManagerApi: _meshManagerApi,
  //         selectedElementAddress: DeviceModel.instance.maxAddress + 1,
  //         device: device,
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint('fail >>>>>>>>>>>>>$e');
  //     scaffoldMessenger
  //         .showSnackBar(SnackBar(content: Text('Caught error: $e')));
  //   } finally {
  //     isProvisioning = false;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAPITA - Mesh 版本'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            // onPressed: widget.nordicNrfMesh.meshManagerApi.loadMeshNetwork
            onPressed: () async {
              isPermissions = await checkAndAskPermissions();
              print(
                  "permission===>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>$isPermissions");
              setState(() {});
              if (isPermissions) {
                _scanUnprovisionned();
              } else {
                scaffoldMessenger
                    .showSnackBar(SnackBar(content: Text('Permissions fail')));
              }
            },
          ),
        ],
      ),
      body: _meshNetwork == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : !isPermissions
              ? Center(
                  child: TextButton(
                      onPressed: () {}, child: Text("Permissions fail")),
                )
              : ListView(
                  children: [
                    if (_meshNetwork != null)
                      MeshNetworkDataWidget(meshNetwork: _meshNetwork!)
                    else
                      const SizedBox.shrink(),
                    if (_meshNetwork != null)
                      //建立device的時候要把node id存到本機才行
                      Device(
                        meshManagerApi: _meshManagerApi,
                        meshNetwork: _meshNetwork!,
                        nordicNrfMesh: widget.nordicNrfMesh,
                      )
                    else
                      const SizedBox.shrink(),
                    if (_meshNetwork != null)
                      ProvisionedDevices(
                        nordicNrfMesh: widget.nordicNrfMesh,
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
    );
  }
}
