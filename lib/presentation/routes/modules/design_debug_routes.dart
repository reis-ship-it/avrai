import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/pages/debug/geo_area_evolution_debug_page.dart';
import 'package:avrai/presentation/pages/debug/proof_run_page.dart';
import 'package:avrai/presentation/pages/design/design_playground_page.dart';

List<RouteBase> buildDesignDebugRoutes({required bool enableProofRun}) {
  return [
    GoRoute(
      path: 'proof-run',
      redirect: (context, state) {
        if (kDebugMode || enableProofRun) return null;
        return '/home';
      },
      builder: (c, s) => const ProofRunPage(),
    ),
    GoRoute(
      path: 'design/playground',
      builder: (c, s) => const DesignPlaygroundPage(),
    ),
    GoRoute(
      path: 'geo-area-debug',
      redirect: (context, state) {
        if (kDebugMode) return null;
        return '/home';
      },
      builder: (c, s) => const GeoAreaEvolutionDebugPage(),
    ),
  ];
}
