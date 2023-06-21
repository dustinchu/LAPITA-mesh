import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mesh/src/views/home/util.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../../../preferences/preferences_repository_impl.dart';
import '../../../model/device_model.dart';

class SendGenericOnOff extends StatefulWidget {
  final MeshManagerApi meshManagerApi;
  String deviceUuid;
  DiscoveredDevice? device;
  SendGenericOnOff(
      {Key? key,
      required this.meshManagerApi,
      required this.deviceUuid,
      required this.device})
      : super(key: key);

  @override
  State<SendGenericOnOff> createState() => _SendGenericOnOffState();
}

class _SendGenericOnOffState extends State<SendGenericOnOff> {
  // int? selectedElementAddress;

  bool onOff = false;
  int? selectedElementAddress;
  final preferences = PreferencesRepositoryImpl();
  @override
  Widget build(BuildContext context) {
    ledOnOf() async {
      Map<String, dynamic> none = await preferences.getJson("node");

      selectedElementAddress = none.containsKey(widget.deviceUuid)
          ? none[widget.deviceUuid]["address"]
          : DeviceModel.instance.maxAddress + 1;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      debugPrint('send level $onOff to $selectedElementAddress');
      final provisionerUuid =
          await widget.meshManagerApi.meshNetwork!.selectedProvisionerUuid();
      final nodes = await widget.meshManagerApi.meshNetwork!.nodes;
      try {
        final provisionedNode =
            nodes.firstWhere((element) => element.uuid == provisionerUuid);
        final sequenceNumber =
            await widget.meshManagerApi.getSequenceNumber(provisionedNode);
        print("seq====$sequenceNumber");
        await widget.meshManagerApi
            .sendGenericOnOffSet(selectedElementAddress!, onOff, sequenceNumber)
            .timeout(const Duration(seconds: 40));

        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('OK')));
      } on TimeoutException catch (_) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('on\off Board didn\'t respond')));
      } on StateError catch (_) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                'No provisioner found with this uuid : $provisionerUuid')));
      } on PlatformException catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Text("LED ON/OFF"),
          Checkbox(
            key: const ValueKey('module-send-generic-on-off-value'),
            value: onOff,
            onChanged: (value) async {
              setState(() {
                onOff = value!;
              });
              ledOnOf();
            },
          ),
          const SizedBox(width: 10),
          TextButton(
              onPressed: () async {
                publication(context, widget.meshManagerApi, widget.deviceUuid);

                // final scaffoldMessenger = ScaffoldMessenger.of(context);
                // try {
                //   await widget.meshManagerApi
                //       .sendConfigModelSubscriptionAdd(
                //           DeviceModel.instance.deviceInfo
                //                   .containsKey(widget.deviceUuid)
                //               ? DeviceModel
                //                   .instance.deviceInfo[widget.deviceUuid]
                //               : DeviceModel.instance.maxAddress + 1,
                //           4096,
                //           DeviceModel.instance.groupId)
                //       .timeout(const Duration(seconds: 40));
                //   scaffoldMessenger
                //       .showSnackBar(const SnackBar(content: Text('OK')));
                // } on TimeoutException catch (_) {
                //   scaffoldMessenger.showSnackBar(
                //       const SnackBar(content: Text('Board didn\'t respond')));
                // } on PlatformException catch (e) {
                //   scaffoldMessenger
                //       .showSnackBar(SnackBar(content: Text('${e.message}')));
                // } catch (e) {
                //   scaffoldMessenger
                //       .showSnackBar(SnackBar(content: Text(e.toString())));
                // }
              },
              child: const Text("Publication")),
          TextButton(
              onPressed: () async {
                // final scaffoldMessenger = ScaffoldMessenger.of(context);
                // try {
                subscript(context, widget.meshManagerApi, widget.deviceUuid);
                //   await widget.meshManagerApi
                //       .sendConfigModelPublicationSet(
                //           DeviceModel.instance.deviceInfo
                //                   .containsKey(widget.deviceUuid)
                //               ? DeviceModel
                //                   .instance.deviceInfo[widget.deviceUuid]
                //               : DeviceModel.instance.maxAddress + 1,
                //           4097,
                //           DeviceModel.instance.groupId)
                //       .timeout(const Duration(seconds: 40));
                //   scaffoldMessenger
                //       .showSnackBar(const SnackBar(content: Text('OK')));
                // } on TimeoutException catch (_) {
                //   scaffoldMessenger.showSnackBar(
                //       const SnackBar(content: Text('Board didn\'t respond')));
                // } on PlatformException catch (e) {
                //   scaffoldMessenger
                //       .showSnackBar(SnackBar(content: Text('${e.message}')));
                // } catch (e) {
                //   scaffoldMessenger
                //       .showSnackBar(SnackBar(content: Text(e.toString())));
                // }
              },
              child: const Text("Subscript"))
        ],
      ),
    );
  }
}
