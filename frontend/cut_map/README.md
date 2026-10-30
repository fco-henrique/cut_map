# Aplicativo Cut Map

Aplicativo Flutter para encontrar barbearias próximas e cadastrar estabelecimentos. Veja o [guia principal](../../README.md) para preparar também a API.

## Desenvolvimento local

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:3000
```

Em um celular físico, use o IP local do computador que executa a API; `localhost` apontaria para o celular. Computador e celular precisam estar na mesma rede.

## Verificação

```bash
flutter analyze
flutter test
```
