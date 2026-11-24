import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class OnboardingStorage {
  Future<bool> hasSeenOnboarding();
  Future<void> markOnboardingAsSeen();
}

/// Armazena a flag de onboarding por instalação em diretório local excluído de backup
/// (Android via backup_rules/data_extraction_rules; iOS via AppDelegate isExcludedFromBackup).
class FileOnboardingStorage implements OnboardingStorage {
  static const _directoryName = 'onboarding';
  static const _fileName = 'seen.flag';

  final Future<Directory> Function() _directoryProvider;

  FileOnboardingStorage({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  Future<File> _flagFile() async {
    final baseDir = await _directoryProvider();
    final onboardingDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}$_directoryName',
    );
    if (!await onboardingDir.exists()) {
      await onboardingDir.create(recursive: true);
    }
    return File('${onboardingDir.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    try {
      final file = await _flagFile();
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      return content.trim() == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markOnboardingAsSeen() async {
    final file = await _flagFile();
    await file.writeAsString('1', flush: true);
  }
}
