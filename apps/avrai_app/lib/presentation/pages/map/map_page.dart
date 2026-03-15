import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/map/map_view.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppFlowScaffold(
      title: 'Map',
      constrainBody: false,
      useSafeArea: false,
      body: MapView(
        showAppBar: false,
      ),
    );
  }
}
