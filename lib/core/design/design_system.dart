import 'package:flutter/material.dart';
import 'package:avrai/core/design/component_tokens.dart';
import 'package:avrai/core/navigation/app_page_transitions.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Single entrypoint to AVRAI design primitives.
///
/// This file is the quickest way for humans and AI to discover where design
/// behavior is defined: colors, tokens, typography, spacing, and motion.
class AvraiDesignSystem {
  const AvraiDesignSystem._();

  static const Type colors = AppColors;
  static PageTransitionsTheme get transitions =>
      AppPageTransitions.pageTransitionsTheme;
}

/// Friendly context accessors for design primitives.
extension AvraiDesignContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get text => theme.textTheme;

  AppSpacing get spacing => theme.extension<AppSpacing>() ?? const AppSpacing();

  AppTypography get typography =>
      theme.extension<AppTypography>() ?? const AppTypography();

  AppRadius get radii => theme.extension<AppRadius>() ?? const AppRadius();

  AppMotion get motionTokens =>
      theme.extension<AppMotion>() ?? const AppMotion();

  PortalTokens get portalTokens =>
      theme.extension<PortalTokens>() ?? const PortalTokens();

  ButtonTokens get buttonTokens =>
      theme.extension<ButtonTokens>() ?? const ButtonTokens();

  InputTokens get inputTokens =>
      theme.extension<InputTokens>() ?? const InputTokens();

  CardTokens get cardTokens =>
      theme.extension<CardTokens>() ?? const CardTokens();

  ChipTokens get chipTokens =>
      theme.extension<ChipTokens>() ?? const ChipTokens();

  OverlayTokens get overlayTokens =>
      theme.extension<OverlayTokens>() ?? const OverlayTokens();

  IconTokens get iconTokens =>
      theme.extension<IconTokens>() ?? const IconTokens();

  FeedbackTokens get feedbackTokens =>
      theme.extension<FeedbackTokens>() ?? const FeedbackTokens();

  EdgeInsets get pagePadding => EdgeInsets.all(spacing.md);

  EdgeInsets get sectionPadding => EdgeInsets.all(spacing.lg);
}
