import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceItem extends StatelessWidget {
  final DiscoveredDevice device;
  final VoidCallback? onTap;

  const DeviceItem({Key? key, required this.device, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${device.name} : ${device.id}',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
