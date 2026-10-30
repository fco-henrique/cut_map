# API Cut Map

API NestJS com autenticação, usuários, barbearias, avaliações e envio de códigos por e-mail. O [guia principal](../../README.md) explica a configuração completa do projeto.

## Desenvolvimento local

Crie um banco PostgreSQL, copie [`.env.example`](.env.example) para `.env` e configure banco, segredos JWT e SMTP. Em seguida:

```bash
npm ci
npm run start:dev
```

A API usa a porta `3000` por padrão. A sincronização automática do TypeORM no exemplo é destinada apenas ao ambiente local. Com sincronização desativada em um banco existente, veja o SQL em [`sql/`](sql/).

## Verificação

```bash
npm run build
npm test -- --runInBand
```
