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

### Testes End-to-End (E2E) com Docker e PostgreSQL Isolado

A suíte de testes E2E (`npm run test:e2e`) utiliza contêiner descartável do Docker com PostgreSQL isolado (`postgres:16-alpine`) instanciado automaticamente a cada execução na interface de loopback (`127.0.0.1`), garantindo hermeticidade e isolamento de banco por execução.

**Pré-requisitos:**
- Docker daemon instalado e ativo na máquina host.
- Node.js e dependências instaladas (`npm install`).

**Comando de Execução:**
```bash
npm run test:e2e
```

O helper de ciclo de vida (`DockerPostgresHelper`) aloca dinamicamente uma porta efêmera livre no host, cria o banco descartável com credenciais dinâmicas, exporta as variáveis de ambiente necessárias e remove o contêiner ao final da bateria.

## Guia de Integração e Contratos de API (Flutter & Desenvolvedores)

### 1. Usuários e Titularidade (`/user`)
- **`GET /user`**: Retorna uma lista contendo exclusivamente os dados do próprio usuário titular autenticado (projeção `id`, `name`, `email`), garantindo isolamento estrito contra enumeração de terceiros.
- **`GET /user/me`**: Retorna os dados do token de acesso do usuário autenticado no payload JWT (`id`, `email`, `name`).

### 2. Barbearias e Membros (`/barbershops`)
- **`GET /barbershops/:id`**:
  - Para usuários com perfil `OWNER` ou `MANAGER` vinculados à própria barbearia solicitada, o campo `members` retorna a lista de membros da loja.
  - Para outros usuários autenticados (clientes ou membros sem privilégios de gestão na unidade), o campo `members` retorna uma lista vazia (`[]`).
- **Projeção de Membros**: Cada item na listagem de membros é projetado exclusivamente com os campos:
  ```json
  {
    "id": "member_id",
    "role": "OWNER | MANAGER | EMPLOYEE",
    "user": {
      "id": "user_id",
      "name": "Nome do Usuário"
    }
  }
  ```

### 3. Sessão, Refresh e Logout (`/auth`)
- **`POST /auth/refresh`**: Recebe `{ "refreshToken": "<token>" }`. Em caso de sucesso, renova o par de tokens (`accessToken` e `refreshToken`) com rotação atômica. Se um refresh token já revogado for reutilizado, todas as sessões ativas do usuário são automaticamente revogadas por proteção contra comprometimento de sessão.
- **`POST /auth/logout`**: Recebe `{ "refreshToken": "<token>" }` e invalida imediatamente a sessão referenciada.
- **`POST /auth/logout-all`**: Requer `Bearer <accessToken>` e revoga todas as sessões ativas do usuário.
