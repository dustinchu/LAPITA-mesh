// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

// import '../../app.dart';
// import '../../widgets/device.dart';

// class ScanningAndProvisioning extends StatefulWidget {
//   final NordicNrfMesh nordicNrfMesh;
//   final VoidCallback onGoToControl;

//   const ScanningAndProvisioning({
//     Key? key,
//     required this.nordicNrfMesh,
//     required this.onGoToControl,
//   }) : super(key: key);

//   @override
//   State<ScanningAndProvisioning> createState() =>
//       _ScanningAndProvisioningState();
// }

// class _ScanningAndProvisioningState extends State<ScanningAndProvisioning> {
//   late MeshManagerApi _meshManagerApi;
//   bool isScanning = true;
//   StreamSubscription? _scanSubscription;
//   bool isProvisioning = false;

//   final _serviceData = <String, Uuid>{};
//   final _devices = <DiscoveredDevice>{};

//   @override
//   void initState() {
//     super.initState();
//     _meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
//     _scanUnprovisionned();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _scanSubscription?.cancel();
//   }

//   Future<void> _scanUnprovisionned() async {
//     _serviceData.clear();
//     setState(() {
//       _devices.clear();
//     });
//     await checkAndAskPermissions();
//     _scanSubscription =
//         widget.nordicNrfMesh.scanForUnprovisionedNodes().listen((device) async {
//       if (_devices.every((d) => d.id != device.id)) {
//         final deviceUuid = Uuid.parse(_meshManagerApi
//             .getDeviceUuid(device.serviceData[meshProvisioningUuid]!.toList()));
//         debugPrint('deviceUuid: $deviceUuid');
//         _serviceData[device.id] = deviceUuid;
//         _devices.add(device);
//         setState(() {});
//       }
//     });
//     setState(() {
//       isScanning = true;
//     });
//     return Future.delayed(const Duration(seconds: 10), _stopScan);
//   }

//   Future<void> _stopScan() async {
//     await _scanSubscription?.cancel();
//     isScanning = false;
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   Future<void> provisionDevice(DiscoveredDevice device) async {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     if (isScanning) {
//       await _stopScan();
//     }
//     if (isProvisioning) {
//       return;
//     }
//     isProvisioning = true;

//     try {
//       // Android is sending the mac Adress of the device, but Apple generates
//       // an UUID specific by smartphone.

//       String deviceUUID;

//       if (Platform.isAndroid) {
//         deviceUUID = _serviceData[device.id].toString();
//       } else if (Platform.isIOS) {
//         deviceUUID = device.id.toString();
//       } else {
//         throw UnimplementedError(
//             'device uuid on platform : ${Platform.operatingSystem}');
//       }
//       final provisioningEvent = ProvisioningEvent();
//       final provisionedMeshNodeF = widget.nordicNrfMesh
//           .provisioning(
//             _meshManagerApi,
//             BleMeshManager(),
//             device,
//             deviceUUID,
//             events: provisioningEvent,
//           )
//           .timeout(const Duration(minutes: 1));

//       unawaited(provisionedMeshNodeF.then((node) {
//         Navigator.of(context).pop();
//         scaffoldMessenger.showSnackBar(const SnackBar(
//             content:
//                 Text('Provisionning succeed, redirecting to control tab...')));
//         Future.delayed(const Duration(milliseconds: 500), widget.onGoToControl);
//       }).catchError((_) {
//         Navigator.of(context).pop();
//         scaffoldMessenger.showSnackBar(
//             const SnackBar(content: Text('Provisionning failed')));
//         _scanUnprovisionned();
//       }));
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) =>
//             ProvisioningDialog(provisioningEvent: provisioningEvent),
//       );
//     } catch (e) {
//       debugPrint('$e');
//       scaffoldMessenger
//           .showSnackBar(SnackBar(content: Text('Caught error: $e')));
//     } finally {
//       isProvisioning = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () {
//         if (isScanning) {
//           return Future.value();
//         }
//         return _scanUnprovisionned();
//       },
//       child: Column(
//         children: [
//           if (isScanning) const LinearProgressIndicator(),
//           if (!isScanning && _devices.isEmpty)
//             const Expanded(
//               child: Center(
//                 child: Text('No module found'),
//               ),
//             ),
//           if (_devices.isNotEmpty)
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(8),
//                 children: [
//                   for (var i = 0; i < _devices.length; i++)
//                     Device(
//                       key: ValueKey('device-$i'),
//                       device: _devices.elementAt(i),
//                       onTap: () => provisionDevice(_devices.elementAt(i)),
//                     ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

class ProvisioningDialog extends StatefulWidget {
  final ProvisioningEvent provisioningEvent;
  final MeshManagerApi meshManagerApi;
  final int selectedElementAddress;
  final DiscoveredDevice device;
  final Future<ProvisionedMeshNode> provisionedMeshNode;
  const ProvisioningDialog(
      {Key? key,
      required this.provisioningEvent,
      required this.meshManagerApi,
      required this.selectedElementAddress,
      required this.provisionedMeshNode,
      required this.device})
      : super(key: key);

  @override
  State<ProvisioningDialog> createState() => _ProvisioningDialogState();
}

enum Subscription { add, error, finish, loading, success }

enum Publication { add, error, finish, loading, success }

class _ProvisioningDialogState extends State<ProvisioningDialog> {
  final bleMeshManager = BleMeshManager();
  late List<ProvisionedMeshNode> nodes;

  bool isLoading = true;
  Subscription subscript = Subscription.loading;
  Publication publicat = Publication.loading;
  @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   unawaited(widget.provisionedMeshNode.then((node) {
  //     print("success init");
  //     init();
  //     // Navigator.of(context).pop();
  //     // scaffoldMessenger.showSnackBar(const SnackBar(
  //     //     content:
  //     //         Text('Provisionning succeed, redirecting to control tab...')));
  //     Future.delayed(
  //       const Duration(milliseconds: 500),
  //     );
  //   }).catchError((_) {
  //     print(">>>>>>>>>>>>>>>>>Provisionning error $_");
  //     // Navigator.of(context).pop();
  //     // scaffoldMessenger
  //     //     .showSnackBar(const SnackBar(content: Text('Provisionning failed')));
  //     // _scanUnprovisionned();
  //   }));
  // }

  // publication() async {
  //   // final scaffoldMessenger = ScaffoldMessenger.of(context);
  //   try {
  //     await widget.meshManagerApi
  //         .sendConfigModelPublicationSet(
  //             widget.selectedElementAddress, 4097, DeviceModel.instance.groupId)
  //         .timeout(const Duration(seconds: 40));
  //     print("publocation success");
  //     publicat = Publication.success;
  //   } on TimeoutException catch (_) {
  //     print("publocation error $_");
  //     publicat = Publication.error;
  //     // scaffoldMessenger
  //     //     .showSnackBar(const SnackBar(content: Text('Board didn\'t respond')));
  //   } on PlatformException catch (e) {
  //     print("publocation error ${e.message}");
  //     publicat = Publication.error;
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  //   } catch (e) {
  //     publicat = Publication.error;
  //     print("publocation error $e");
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  // subscription() async {
  //   // final scaffoldMessenger = ScaffoldMessenger.of(context);
  //   try {
  //     await widget.meshManagerApi
  //         .sendConfigModelSubscriptionAdd(
  //             widget.selectedElementAddress, 4096, DeviceModel.instance.groupId)
  //         .timeout(const Duration(seconds: 40));
  //     print("subscript success");
  //     setState(() {
  //       subscript = Subscription.success;
  //     });
  //     // scaffoldMessenger.showSnackBar(const SnackBar(content: Text('OK')));
  //   } on TimeoutException catch (_) {
  //     print("subscript error $_");
  //     subscript = Subscription.error;
  //     // scaffoldMessenger
  //     //     .showSnackBar(const SnackBar(content: Text('Board didn\'t respond')));
  //   } on PlatformException catch (e) {
  //     print("subscript error ${e.message}");
  //     subscript = Subscription.error;
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  //   } catch (e) {
  //     subscript = Subscription.error;
  //     print("subscript error ${e}");
  //     // scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  // Future<void> init() async {
  //   bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
  //       widget.meshManagerApi, bleMeshManager);
  //   await bleMeshManager.connect(widget.device);
  //   // get nodes (ignore first node which is the default provisioner)
  //   nodes = (await widget.meshManagerApi.meshNetwork!.nodes).skip(1).toList();
  //   // will bind app keys (needed to be able to configure node)
  //   for (final node in nodes) {
  //     final elements = await node.elements;
  //     for (final element in elements) {
  //       for (final model in element.models) {
  //         if (model.boundAppKey.isEmpty) {
  //           if (element == elements.first && model == element.models.first) {
  //             continue;
  //           }
  //           final unicast = await node.unicastAddress;
  //           debugPrint('need to bind app key');
  //           await widget.meshManagerApi.sendConfigModelAppBind(
  //             unicast,
  //             element.address,
  //             model.modelId,
  //           );
  //         }
  //       }
  //     }
  //   }

  //   setState(() {
  //     isLoading = false;
  //     subscription();
  //     publication();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('Steps :'),
                  Column(
                    children: [
                      ProvisioningState(
                        text: 'onProvisioningCapabilities',
                        stream: widget
                            .provisioningEvent.onProvisioningCapabilities
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onProvisioning',
                        stream: widget.provisioningEvent.onProvisioning
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onProvisioningReconnect',
                        stream: widget.provisioningEvent.onProvisioningReconnect
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onConfigCompositionDataStatus',
                        stream: widget
                            .provisioningEvent.onConfigCompositionDataStatus
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onConfigAppKeyStatus',
                        stream: widget.provisioningEvent.onConfigAppKeyStatus
                            .map((event) => true),
                      ),
                      // Row(
                      //   children: [
                      //     Text("subscription"),
                      //     const Spacer(),
                      //     subscript == Subscription.error
                      //         ? IconButton(
                      //             onPressed: () => subscription(),
                      //             icon: Icon(Icons.refresh))
                      //         : Checkbox(
                      //             value: subscript == Subscription.success,
                      //             onChanged: null,
                      //           ),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     Text("publication"),
                      //     const Spacer(),
                      //     subscript == Publication.error
                      //         ? IconButton(
                      //             onPressed: () => publication(),
                      //             icon: Icon(Icons.refresh))
                      //         : Checkbox(
                      //             value: publicat == Publication.success,
                      //             onChanged: null,
                      //           ),
                      //   ],
                      // ),
                      // ElevatedButton(
                      //     onPressed: () async {
                      //       await init();
                      //       // Navigator.of(context).pop();
                      //       // final scaffoldMessenger =
                      //       //     ScaffoldMessenger.of(context);
                      //       // try {
                      //       //   await meshManagerApi
                      //       //       .sendConfigModelSubscriptionAdd(
                      //       //           selectedElementAddress,
                      //       //           4096,
                      //       //           selectedModelId)
                      //       //       .timeout(const Duration(seconds: 40));
                      //       //   scaffoldMessenger.showSnackBar(
                      //       //       const SnackBar(content: Text('OK')));
                      //       // } on TimeoutException catch (_) {
                      //       //   scaffoldMessenger.showSnackBar(const SnackBar(
                      //       //       content: Text('Board didn\'t respond')));
                      //       // } on PlatformException catch (e) {
                      //       //   scaffoldMessenger.showSnackBar(
                      //       //       SnackBar(content: Text('${e.message}')));
                      //       // } catch (e) {
                      //       //   scaffoldMessenger.showSnackBar(
                      //       //       SnackBar(content: Text(e.toString())));
                      //       // }
                      //     },
                      //     child: const Text("Finish"))
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProvisioningState extends StatelessWidget {
  final Stream<bool> stream;
  final String text;

  const ProvisioningState({Key? key, required this.stream, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: stream,
      builder: (context, snapshot) {
        return Row(
          children: [
            Container(
                width: 200, child: Text(text, style: TextStyle(fontSize: 12))),
            const Spacer(),
            Checkbox(
              value: snapshot.data,
              onChanged: null,
            ),
          ],
        );
      },
    );
  }
}

class ProvisioningState2 extends StatelessWidget {
  final bool isSuccess;
  final String text;

  const ProvisioningState2(
      {Key? key, required this.isSuccess, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text),
        const Spacer(),
        Checkbox(
          value: isSuccess,
          onChanged: null,
        ),
      ],
    );
  }
}
