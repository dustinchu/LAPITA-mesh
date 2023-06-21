import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../../preferences/preferences_repository_impl.dart';
import '../../model/device_model.dart';

createGroup(BuildContext context, IMeshNetwork _meshNetwork,
    MeshManagerApi _meshManagerApi) async {
  if (_meshNetwork != null) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final groupName = await showDialog<String>(
        context: context,
        builder: (c) {
          String? groupName;
          return Dialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Group name'),
                      onChanged: (text) => groupName = text,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, groupName),
                      child: const Text('OK'),
                    )
                  ],
                ),
              ),
            ),
          );
        });
    if (groupName != null && groupName.isNotEmpty) {
      try {
        await _meshManagerApi.meshNetwork!.addGroupWithName(groupName);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('OK')));
      } on PlatformException catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } else {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No name given, aborting')));
    }
  }
  // _meshNetwork != null
  //     ? ()
  //     : null;
}

deleteGroup(BuildContext context, IMeshNetwork meshNetwork,
    MeshManagerApi meshManagerApi) async {
  if (meshNetwork != null) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final groupAdr = await showDialog<String>(
        context: context,
        builder: (c) {
          String? groupAdr;
          return Dialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            elevation: 0.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Group address'),
                      keyboardType: TextInputType.number,
                      onChanged: (text) => groupAdr = text,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, groupAdr),
                      child: const Text('OK'),
                    )
                  ],
                ),
              ),
            ),
          );
        });
    if (groupAdr != null && groupAdr.isNotEmpty) {
      try {
        await meshManagerApi.meshNetwork!.removeGroup(int.parse(groupAdr));
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('OK')));
      } on PlatformException catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } else {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No address given, aborting')));
    }
  }
}

subscript(BuildContext context, MeshManagerApi meshManagerApi,
    String deviceUuid) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final preferences = PreferencesRepositoryImpl();
  Map<String, dynamic> none = await preferences.getJson("node");
  print(">>>>>>>${none}   uuid==$deviceUuid");
  print(
      "sub====${none.containsKey(deviceUuid) ? none[deviceUuid]["address"] : DeviceModel.instance.maxAddress + 1}   gid ==${DeviceModel.instance.groupId}   4096");
  try {
    meshManagerApi
        .sendConfigModelSubscriptionAdd(
          none.containsKey(deviceUuid)
              ? none[deviceUuid]["address"]
              : DeviceModel.instance.maxAddress + 1,
          DeviceModel.instance.groupId,
          4096,
        )
        .timeout(const Duration(seconds: 40));
    scaffoldMessenger
        .showSnackBar(const SnackBar(content: Text('Subscript OK')));
  } on TimeoutException catch (_) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Subscript Board didn\'t respond')));
  } on PlatformException catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  } catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

publication(BuildContext context, MeshManagerApi meshManagerApi,
    String deviceUuid) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final preferences = PreferencesRepositoryImpl();
  Map<String, dynamic> none = await preferences.getJson("node");
  print(">>>>>>>${none}   uuid==$deviceUuid");
  print(
      "pub====${none.containsKey(deviceUuid) ? none[deviceUuid]["address"] : DeviceModel.instance.maxAddress + 1}   gid ==${DeviceModel.instance.groupId}   4096");
  try {
    await meshManagerApi
        .sendConfigModelPublicationSet(
          none.containsKey(deviceUuid)
              ? none[deviceUuid]["address"]
              : DeviceModel.instance.maxAddress + 1,
          DeviceModel.instance.groupId,
          4097,
        )
        .timeout(const Duration(seconds: 40));
    scaffoldMessenger
        .showSnackBar(const SnackBar(content: Text('Publication OK')));
  } on TimeoutException catch (_) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Publication Board didn\'t respond')));
  } on PlatformException catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text('${e.message}')));
  } catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
