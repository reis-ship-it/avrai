/// v0 ledger domains.
///
/// These map to `public.ledger_events_v0.domain` in Supabase.
enum LedgerDomainV0 {
  expertise,
  payments,
  moderation,
  identity,
  security,
  geoExpansion,
  modelLifecycle,
  dataExport,
  deviceCapability,
}

extension LedgerDomainV0X on LedgerDomainV0 {
  /// Database wire name (snake_case).
  String get wireName => switch (this) {
        LedgerDomainV0.expertise => 'expertise',
        LedgerDomainV0.payments => 'payments',
        LedgerDomainV0.moderation => 'moderation',
        LedgerDomainV0.identity => 'identity',
        LedgerDomainV0.security => 'security',
        LedgerDomainV0.geoExpansion => 'geo_expansion',
        LedgerDomainV0.modelLifecycle => 'model_lifecycle',
        LedgerDomainV0.dataExport => 'data_export',
        LedgerDomainV0.deviceCapability => 'device_capability',
      };

  static LedgerDomainV0 fromWireName(String value) => switch (value) {
        'expertise' => LedgerDomainV0.expertise,
        'payments' => LedgerDomainV0.payments,
        'moderation' => LedgerDomainV0.moderation,
        'identity' => LedgerDomainV0.identity,
        'security' => LedgerDomainV0.security,
        'geo_expansion' => LedgerDomainV0.geoExpansion,
        'model_lifecycle' => LedgerDomainV0.modelLifecycle,
        'data_export' => LedgerDomainV0.dataExport,
        'device_capability' => LedgerDomainV0.deviceCapability,
        _ => throw ArgumentError.value(value, 'value', 'Unknown ledger domain'),
      };
}

