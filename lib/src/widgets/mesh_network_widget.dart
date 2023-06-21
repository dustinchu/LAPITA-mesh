import 'package:flutter/material.dart';
import 'package:mesh/src/widgets/title.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import 'group.dart';
import 'node.dart';

class MeshNetworkDataWidget extends StatefulWidget {
  final IMeshNetwork meshNetwork;

  const MeshNetworkDataWidget({Key? key, required this.meshNetwork})
      : super(key: key);

  @override
  State<MeshNetworkDataWidget> createState() => _MeshNetworkDataWidgetState();
}

class _MeshNetworkDataWidgetState extends State<MeshNetworkDataWidget> {
  List<ProvisionedMeshNode> _nodes = [];
  List<GroupData> _groups = [];

  @override
  void initState() {
    super.initState();
    widget.meshNetwork.nodes.then((value) => setState(() => _nodes = value));
    widget.meshNetwork.groups.then((value) => setState(() => _groups = value));
  }

  @override
  void didUpdateWidget(covariant MeshNetworkDataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // nodes, provisioners and groups may have changed
    widget.meshNetwork.nodes.then((value) => setState(() => _nodes = value));
    widget.meshNetwork.groups.then((value) => setState(() => _groups = value));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // DeviceModel.instance.addInfo(_nodes);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: const Text('MeshNetwork ID:'),
            subtitle: Text(widget.meshNetwork.id),
          ),
          if (_nodes.isNotEmpty) ...[
            TitleWidget(titleText: 'Nodes (${_nodes.length}): '),
            ..._nodes.map((e) =>
                Node(e, widget.meshNetwork, 'node-${_nodes.indexOf(e)}')),
          ],
          if (_groups.isNotEmpty) ...[
            TitleWidget(titleText: 'Groups (${_groups.length}): '),
            ..._groups.map((e) => Group(e, widget.meshNetwork)),
          ]
        ],
      ),
    );
  }
}
