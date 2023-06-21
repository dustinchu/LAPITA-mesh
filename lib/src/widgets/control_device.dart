import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../model/device_model.dart';
import '../views/control_module/commands/send_generic_on_off.dart';
import '../views/control_module/module.dart';

class ControlDeviceItem extends StatefulWidget {
  final DiscoveredDevice device;
  final VoidCallback? onTap;

  final MeshManagerApi meshManagerApi;
  final Set<DiscoveredDevice> devices;
  final String uuid;
  ControlDeviceItem({
    Key? key,
    required this.device,
    this.onTap,
    required this.devices,
    required this.meshManagerApi,
    required this.uuid,
  }) : super(key: key);
  @override
  State<ControlDeviceItem> createState() => _ControlDeviceItemState();
}

class _ControlDeviceItemState extends State<ControlDeviceItem> {
  final bleMeshManager = BleMeshManager();

  bool isLoading = false;
  late List<ProvisionedMeshNode> nodes;
  bool connected = false;
  late MeshManagerApi newMeshManagerApi;

  @override
  void initState() {
    super.initState();
    newMeshManagerApi = widget.meshManagerApi;
  }

  Future<void> connect() async {
    setState(() {
      isLoading = true;
    });
    try {
      bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
          newMeshManagerApi, bleMeshManager);
      await bleMeshManager.connect(widget.device);
      // get nodes (ignore first node which is the default provisioner)
      nodes = (await newMeshManagerApi.meshNetwork!.nodes).skip(1).toList();
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

              await newMeshManagerApi.sendConfigModelAppBind(
                unicast,
                element.address,
                model.modelId,
              );
            }
          }
        }
      }
      connected = true;
    } catch (e) {
      connected = false;
    }

    // await subscript(context, newMeshManagerApi, widget.uuid);
    // await Duration(milliseconds: 1000);
    // await publication(context, newMeshManagerApi, widget.uuid);
    setState(() {
      // await subscript(context, newMeshManagerApi, nodes[i].uuid);
      isLoading = false;
    });
  }

  void disConnect() async {
    connected = false;
    await bleMeshManager.disconnect();
    await bleMeshManager.callbacks!.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Card(
            child: InkWell(
              onTap: () {
                connect();
                print(
                    ">>>>${DeviceModel.instance.deviceInfo}   id==${widget.device.id}");
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.device.name}\n${widget.device.id}',
                      ),
                      isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator())
                          : connected
                              ? TextButton(
                                  onPressed: () {
                                    disConnect();
                                    setState(() {});
                                  },
                                  child: Text(
                                      connected ? "Disconnect" : "Connect"))
                              : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          connected
              ? SendGenericOnOff(
                  device: widget.device,
                  meshManagerApi: newMeshManagerApi,
                  deviceUuid: widget.uuid,
                )
              // Module(
              //     uuid: widget.uuid,
              //     meshManagerApi: newMeshManagerApi,
              //     onDisconnect: () {
              //       // deinit();
              //       // _scanProvisionned();
              //     })
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
