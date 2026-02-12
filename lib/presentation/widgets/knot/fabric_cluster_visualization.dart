// Fabric Cluster Visualization Widget
// 
// Widget for displaying fabric clusters (communities)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:flutter/material.dart';
import 'package:avrai_knot/models/knot/fabric_cluster.dart';

/// Widget for visualizing fabric clusters
class FabricClusterVisualization extends StatelessWidget {
  final List<FabricCluster> clusters;
  final Function(FabricCluster)? onClusterTap;
  
  const FabricClusterVisualization({
    super.key,
    required this.clusters,
    this.onClusterTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return const Center(
        child: Text('No clusters found'),
      );
    }
    
    return ListView.builder(
      itemCount: clusters.length,
      itemBuilder: (context, index) {
        final cluster = clusters[index];
        return ClusterCard(
          cluster: cluster,
          onTap: onClusterTap != null ? () => onClusterTap!(cluster) : null,
        );
      },
    );
  }
}

/// Card widget for displaying a single cluster
class ClusterCard extends StatelessWidget {
  final FabricCluster cluster;
  final VoidCallback? onTap;
  
  const ClusterCard({
    super.key,
    required this.cluster,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cluster ${cluster.clusterId}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (cluster.isKnotTribe)
                    Chip(
                      label: const Text('Knot Tribe'),
                      backgroundColor: Colors.blue.shade100,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${cluster.userCount} users',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Density: ${(cluster.density * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Diversity: ${cluster.knotTypeDistribution.describe()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: cluster.density,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cluster.density > 0.7 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
