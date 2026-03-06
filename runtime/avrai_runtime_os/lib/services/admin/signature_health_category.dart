enum SignatureHealthCategory {
  strong,
  weakData,
  stale,
  fallback,
  reviewNeeded,
  bundle,
}

extension SignatureHealthCategoryX on SignatureHealthCategory {
  String get label {
    switch (this) {
      case SignatureHealthCategory.strong:
        return 'Strong';
      case SignatureHealthCategory.weakData:
        return 'Weak Data';
      case SignatureHealthCategory.stale:
        return 'Stale';
      case SignatureHealthCategory.fallback:
        return 'Fallback';
      case SignatureHealthCategory.reviewNeeded:
        return 'Review Needed';
      case SignatureHealthCategory.bundle:
        return 'Bundle';
    }
  }
}
