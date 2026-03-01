import 'package:avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_control_plane_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

class _BusinessServiceKernelRegistryService extends UrkKernelRegistryService {
  const _BusinessServiceKernelRegistryService();

  @override
  Future<UrkKernelRegistrySnapshot> loadSnapshot() async {
    return UrkKernelRegistrySnapshot(
      version: 'v1',
      updatedAt: '2026-02-28',
      byProng: const {'runtime_core': 1},
      byMode: const {'federated_cloud': 1},
      byImpactTier: const {'L3': 1},
      kernels: const [
        UrkKernelRecord(
          kernelId: 'k_business_runtime',
          title: 'Business Runtime',
          purpose: 'Business service runtime flow dispatch',
          runtimeScope: ['business_ops_runtime'],
          prongScope: 'runtime_core',
          privacyModes: ['federated_cloud'],
          impactTier: 'L3',
          localityScope: ['cloud'],
          activationTriggers: ['business_runtime_request'],
          authorityMode: 'enforced',
          dependencies: ['M8-P9-2'],
          lifecycleState: 'enforced',
          owner: 'AP',
          approver: 'GOV',
          milestoneId: 'M8-P9-2',
          status: 'done',
        ),
      ],
    );
  }
}

void main() {
  group('BusinessService URK runtime dispatch', () {
    test('verifyBusiness emits activation receipt via runtime validator path',
        () async {
      MockGetStorage.reset();
      final storage = getTestStorage(boxName: 'business_service_urk_dispatch');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      final controlPlane = UrkKernelControlPlaneService(
        prefs: prefs,
        registryService: const _BusinessServiceKernelRegistryService(),
      );
      final dispatcher = UrkRuntimeActivationReceiptDispatcher(
        controlPlaneService: controlPlane,
        registryService: const _BusinessServiceKernelRegistryService(),
      );

      final accountService = BusinessAccountService();
      final service = BusinessService(
        accountService: accountService,
        activationDispatcher: dispatcher,
      );

      final business = await service.createBusinessAccount(
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdBy: 'creator-123',
      );

      await service.verifyBusiness(businessId: business.id);

      final lineage = await controlPlane.getKernelLineage('k_business_runtime');
      expect(
        lineage.where((event) => event.eventType == 'activation_receipt'),
        isNotEmpty,
      );
    });
  });
}
