# Cut Map

Aplicativo para descobrir barbearias próximas e cadastrar estabelecimentos. O repositório reúne uma API NestJS e um aplicativo Flutter. O projeto está em desenvolvimento; as abas Explorar e Perfil ainda têm conteúdo provisório.

## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `backend/cut-map` | API NestJS, autenticação, usuários, barbearias, avaliações e envio de e-mails |
| `frontend/cut_map` | Aplicativo Flutter com autenticação, Home, mapa e cadastro de barbearias |

## Requisitos

- Node.js 22 e npm.
- PostgreSQL.
- Flutter no canal estável com Dart compatível com `sdk: ^3.9.0` do `pubspec.yaml`.
- Uma conta SMTP para testar confirmação de e-mail e recuperação de senha.
- Para testar em celular físico, computador e celular na mesma rede local.

## Executar localmente

### API

1. Crie um banco PostgreSQL chamado `cut_map`.
2. Copie `backend/cut-map/.env.example` para `backend/cut-map/.env` e substitua as credenciais e os segredos. O arquivo `.env` não deve ser versionado.
3. Em `backend/cut-map`, execute:

```bash
npm ci
npm run start:dev
```

A API usa a porta `3000` por padrão. O exemplo habilita a sincronização do TypeORM **somente para desenvolvimento local**. Se o banco existente usa `DATABASE_SYNCHRONIZE=false`, aplique também o SQL de `backend/cut-map/sql/20261022_barbershop_contact_hours.sql` para adicionar contato e horários. O projeto ainda não possui um conjunto completo de migrações para criar o banco do zero com a sincronização desativada.

### Aplicativo

Em `frontend/cut_map`, execute:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://IP_DO_COMPUTADOR:3000
```

Substitua `IP_DO_COMPUTADOR` pelo IP local da máquina que executa a API. No celular físico, `localhost` aponta para o próprio celular; confirme que a rede e o firewall permitem acessar a porta `3000`. O endereço padrão no código é apenas uma configuração local e pode não funcionar em outra rede.

## Verificações

```bash
cd backend/cut-map
npm run build
npm test -- --runInBand
```

```bash
cd frontend/cut_map
flutter analyze
flutter test
```

O [workflow de CI](.github/workflows/ci.yml) executa essas verificações em pull requests e em envios para `main` e `develop`. O teste Flutter atual cobre a regra de funcionamento e distância; os demais fluxos críticos ainda precisam de cobertura.

## Contribuição

Abra uma issue para descrever um bug ou uma melhoria. Inclua o comportamento esperado, o resultado atual e passos para reproduzir quando aplicável. Trabalhe em uma branch e abra um pull request com as verificações passando. Os commits seguem o padrão `feat(front): descrição em português`, usando `fix`, `refac` ou `chore` e `back` quando apropriado.
