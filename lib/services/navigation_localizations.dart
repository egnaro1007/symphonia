import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NavigationLocalizations {
  static List<String> getNavigationLabels(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.home,
      localizations.trending,
      localizations.friends,
      localizations.profile,
      localizations.settings,
    ];
  }

  static String getLabel(BuildContext context, int index) {
    final labels = getNavigationLabels(context);
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '';
  }
}
