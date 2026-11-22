import 'dart:io';

import 'package:cut_map/features/onboarding/services/onboarding_manager.dart';
import 'package:cut_map/features/onboarding/services/onboarding_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileOnboardingStorage & OnboardingManager (#12)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cut_map_onboarding_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('inicia não visto e persiste flag por instalação após conclusão', () async {
      final storage = FileOnboardingStorage(directoryProvider: () async => tempDir);
      final manager = OnboardingManager(storage: storage, autoInitialize: false);

      await manager.initialize();
      expect(manager.isInitialized, isTrue);
      expect(manager.hasSeenOnboarding, isFalse);

      await manager.completeOnboarding();
      expect(manager.hasSeenOnboarding, isTrue);

      // Simula reinicialização / atualização do app lendo o mesmo diretório local
      final reloadedManager = OnboardingManager(
        storage: FileOnboardingStorage(directoryProvider: () async => tempDir),
        autoInitialize: false,
      );
      await reloadedManager.initialize();
      expect(reloadedManager.hasSeenOnboarding, isTrue);
    });

    test('reapresenta onboarding após limpeza de dados / reinstalação', () async {
      final storage = FileOnboardingStorage(directoryProvider: () async => tempDir);
      final manager = OnboardingManager(storage: storage, autoInitialize: false);

      await manager.initialize();
      await manager.completeOnboarding();
      expect(await storage.hasSeenOnboarding(), isTrue);

      // Simula limpeza dos dados locais da instalação
      await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);

      final freshInstallManager = OnboardingManager(
        storage: FileOnboardingStorage(directoryProvider: () async => tempDir),
        autoInitialize: false,
      );
      await freshInstallManager.initialize();
      expect(freshInstallManager.hasSeenOnboarding, isFalse);
    });
  });
}
