class SocialOAuthFallback {
  static bool shouldUsePlaceholderInTests({required bool isWidgetTestBinding}) {
    return isWidgetTestBinding;
  }
}
