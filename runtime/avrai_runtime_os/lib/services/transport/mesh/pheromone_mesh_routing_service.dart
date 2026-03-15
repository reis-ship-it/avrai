import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';

/// Service responsible for managing the local inbox and outbox queues for Knowledge Vectors (Pheromones).
/// It handles Epidemic Routing by swapping pending outbox vectors during high-compatibility BLE matches.
class PheromoneMeshRoutingService {
  static const String _logName = 'PheromoneMeshRouting';

  final GovernanceKernelService _governanceKernel;

  // Local inbox queue for vectors received from the mesh
  final List<KnowledgeVector> _inbox = [];

  // Local outbox queue for vectors waiting to be broadcasted to the mesh
  final List<KnowledgeVector> _outbox = [];

  PheromoneMeshRoutingService({
    required GovernanceKernelService governanceKernel,
  }) : _governanceKernel = governanceKernel;

  /// Enqueue a new KnowledgeVector to be sent out to the mesh.
  /// It will be intercepted by the Governance Kernel before entering the outbox.
  void enqueueForBroadcast(KnowledgeVector vector) {
    final clearance = _governanceKernel.interceptOutgoing(vector);
    if (clearance.isApproved && clearance.sanitizedVector != null) {
      _outbox.add(clearance.sanitizedVector!);
      developer.log(
          'Vector enqueued for broadcast (Outbox size: ${_outbox.length})',
          name: _logName);
    } else {
      developer.log(
          'Vector rejected for broadcast: ${clearance.rejectionReason}',
          name: _logName);
    }
  }

  /// Processes an incoming KnowledgeVector received from a nearby device.
  /// It passes through the Governance Kernel before entering the inbox.
  void receiveFromMesh(KnowledgeVector vector) {
    final clearance = _governanceKernel.interceptIncoming(vector);
    if (clearance.isApproved) {
      _inbox.add(vector);
      developer.log(
          'Vector received and stored in inbox (Inbox size: ${_inbox.length})',
          name: _logName);
    } else {
      developer.log('Incoming vector rejected: ${clearance.rejectionReason}',
          name: _logName);
    }
  }

  /// Attempt to securely swap pending outbox vectors with a newly matched device.
  /// For this spike, we simulate the swap by returning the outbox vectors that
  /// are ready to be sent to the remote device, and providing a callback to
  /// ingest the vectors sent by the remote device.
  List<KnowledgeVector> getVectorsForSwapping() {
    if (_outbox.isEmpty) return [];

    // In a real epidemic routing implementation, we might filter which vectors
    // to send based on what the other node already has. For now, we send all
    // pending outbox vectors, up to a limit.
    final vectorsToSend = _outbox.take(10).toList();

    developer.log('Prepared ${vectorsToSend.length} vectors for mesh swapping',
        name: _logName);
    return vectorsToSend;
  }

  /// Clears out the current inbox and returns the vectors for the nightly batch process.
  List<KnowledgeVector> flushInboxForBatchProcessing() {
    final vectors = List<KnowledgeVector>.from(_inbox);
    _inbox.clear();
    return vectors;
  }

  // Getters for testing
  int get inboxSize => _inbox.length;
  int get outboxSize => _outbox.length;
}
