import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Muestra el BottomSheet para seleccionar idioma.
void showLanguagePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => const LanguagePickerSheet(),
  );
}

/// BottomSheet para seleccionar el idioma de la app.
class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static const _languages = [
    _LanguageOption(code: 'en', flag: '🇺🇸', nameKey: 'english'),
    _LanguageOption(code: 'es', flag: '🇪🇸', nameKey: 'spanish'),
    _LanguageOption(code: 'pt', flag: '🇧🇷', nameKey: 'portuguese'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeNotifierProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.selectLanguage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ..._languages.map((lang) {
            final isSelected = currentLocale.languageCode == lang.code;
            return ListTile(
              leading: Text(
                lang.flag,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(_getLanguageName(l10n, lang.nameKey)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              selected: isSelected,
              selectedTileColor: AppColors.primary.withAlpha(20),
              onTap: () {
                ref.read(localeNotifierProvider.notifier).setLocale(lang.code);
                Navigator.of(context).pop();
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getLanguageName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'english':
        return l10n.english;
      case 'spanish':
        return l10n.spanish;
      case 'portuguese':
        return l10n.portuguese;
      default:
        return key;
    }
  }
}

class _LanguageOption {
  final String code;
  final String flag;
  final String nameKey;

  const _LanguageOption({
    required this.code,
    required this.flag,
    required this.nameKey,
  });
}
