import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../preferences/preferences_repository_impl.dart';

class DeviceModel {
  static final DeviceModel _singleton = DeviceModel._internal();
  DeviceModel._internal();
  static DeviceModel get instance => _singleton;
  Map<String, dynamic> deviceInfo = {};

  final preferences = PreferencesRepositoryImpl();
  int groupId = 0;
  int maxAddress = 0;
  Map<String, DiscoveredDevice> deviceMap = {};
  addInfo(ProvisionedMeshNode node, String deviceID) async {
    print(">>>>>>>>>>>>>>>>>>>>>>$node    d  $deviceID");
    Map<String, dynamic> none = await preferences.getJson("node");
    if (!none.containsKey(deviceID)) {
      int address = await node.unicastAddress;
      none[deviceID] = {"UUID": node.uuid, "address": address};

      if (address > maxAddress) {
        maxAddress = address;
      }
    }
    preferences.setJsonStr("node", json.encode(none));

    print(">>>>>>>>>>>>>>>>>>>>>>$deviceInfo");
  }

  saveUUID(String deviceID, String uid) async {
    print(">>>>>>>save>>>>>>>>>>>>>>>$uid    d  $deviceID");
    Map<String, dynamic> uuid = await preferences.getJson("uuid");
    if (!uuid.containsKey(deviceID)) {
      uuid[deviceID] = uid;
    }
    preferences.setJsonStr("uuid", json.encode(uuid));

    print(">>>>>>>>>>>>>>>>>>>>>>$deviceInfo");
  }
}
