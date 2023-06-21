import 'package:flutter/material.dart';
import 'package:mesh/src/model/device_model.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../views/control_module/mesh_element.dart';

class Group extends StatefulWidget {
  final GroupData groupData;
  final IMeshNetwork meshNetwork;
  const Group(this.groupData, this.meshNetwork, {Key? key}) : super(key: key);

  @override
  State<Group> createState() => _GroupState();
}

class _GroupState extends State<Group> {
  List<ElementData> elements = [];

  @override
  Widget build(BuildContext context) {
    DeviceModel.instance.groupId = widget.groupData.address;
    return ExpansionTile(
      title: Text(widget.groupData.name),
      subtitle: Text(widget.groupData.address.toString()),
      onExpansionChanged: (isOpen) {
        if (isOpen) {
          debugPrint('load elements');
          widget.meshNetwork
              .elementsForGroup(widget.groupData.address)
              .then((value) => setState(() => elements = value));
        }
      },
      children: <Widget>[
        const Text('Elements :'),
        Column(
          children: <Widget>[
            ...elements.map((e) => MeshElement(e)).toList(),
          ],
        ),
      ],
    );
  }
}
