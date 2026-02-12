/// v0 ledger operation semantics (append-only modifications via revisions).
enum LedgerOpV0 {
  assert_,
  amend,
  void_,
  restate,
}

extension LedgerOpV0X on LedgerOpV0 {
  String get wireName => switch (this) {
        LedgerOpV0.assert_ => 'assert',
        LedgerOpV0.amend => 'amend',
        LedgerOpV0.void_ => 'void',
        LedgerOpV0.restate => 'restate',
      };

  static LedgerOpV0 fromWireName(String value) => switch (value) {
        'assert' => LedgerOpV0.assert_,
        'amend' => LedgerOpV0.amend,
        'void' => LedgerOpV0.void_,
        'restate' => LedgerOpV0.restate,
        _ => throw ArgumentError.value(value, 'value', 'Unknown ledger op'),
      };
}

