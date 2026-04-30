# CineAlert

Aplicativo mobile para descoberta e gerenciamento de lembretes de filmes e séries. Desenvolvido em Flutter com arquitetura limpa, Riverpod para gerenciamento de estado e integração com notificações push via Firebase.

---

## Funcionalidades

- **Autenticação** — Cadastro e login com JWT; refresh automático de token
- **Descoberta de conteúdo** — Trending de filmes e séries com filtros por gênero
- **Busca avançada** — Filtros por tipo (filme/série), ano e gênero
- **Detalhes** — Sinopse, avaliação, trailer e informações completas do título
- **Lembretes** — Agendamento com recorrência (única, diária, semanal) e mensagem personalizada
- **Notificações** — Push via Firebase Cloud Messaging + notificações locais com suporte a fuso horário
- **Perfil** — Estatísticas de lembretes e gerenciamento de conta
- **Tema escuro** — Interface escura com acento dourado (`#F5C518`)

---

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3 / Dart ≥ 3.2 |
| Estado | Riverpod 2 (StateNotifier, FutureProvider) |
| Navegação | GoRouter 17 |
| HTTP | Dio 5 com interceptor de autenticação |
| Notificações | Firebase Messaging + flutter_local_notifications |
| Armazenamento local | Hive + SharedPreferences |
| Animações | flutter_animate |
| Imagens | cached_network_image |
| Geração de código | build_runner, riverpod_generator, json_serializable |

---

## Arquitetura

O projeto segue os princípios de **Clean Architecture** com separação em camadas:

```
lib/
├── core/
│   ├── constants/       # Cores, tema, constantes de API
│   ├── network/         # Dio client com interceptor de auth
│   ├── notifications/   # Firebase + notificações locais
│   └── routes/          # GoRouter (AppRouter)
├── data/
│   └── repositories/    # Acesso à API (auth, conteúdo, lembretes)
├── domain/
│   └── entities/        # Modelos de domínio (Auth, Content, Reminder)
└── presentation/
    ├── providers/        # Estado Riverpod (auth, conteúdo, lembretes)
    ├── screens/          # Telas (splash, auth, home, busca, detalhe, lembretes, perfil)
    └── widgets/          # Componentes reutilizáveis
```

---

## Pré-requisitos

- Flutter SDK ≥ 3.2.0
- Dart SDK ≥ 3.2.0
- Conta e projeto no Firebase (Android/iOS)
- JDK 17+ (para build Android)

---

## Configuração

**1. Clone o repositório e instale as dependências:**

```bash
git clone <repo-url>
cd cine-alert-mobile
flutter pub get
```

**2. Configure o Firebase:**

Adicione os arquivos de configuração do seu projeto Firebase:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

**3. Configure a URL base da API (opcional):**

Por padrão aponta para `https://api.cinealert.link`. Para alterar, defina a variável de ambiente `BASE_URL` antes do build:

```bash
flutter run --dart-define=BASE_URL=https://sua-api.com
```

**4. Gere os arquivos de código (Riverpod, Hive, JSON):**

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Executando

```bash
# Desenvolvimento
flutter run

# Build Android
flutter build apk --release

# Build iOS
flutter build ipa --release
```

---

## Fluxo de navegação

```
/splash
  └── /login ──────────────── /register
  └── /home (ShellRoute)
        ├── /home
        ├── /search?q={query}
        ├── /reminders
        └── /profile
              └── /detail/:imdbId
```

---

## API

A aplicação consome a API REST `https://api.cinealert.link/api`. Endpoints principais:

| Domínio | Endpoints |
|---|---|
| Auth | `POST /auth/login`, `POST /auth/register`, `POST /auth/refresh` |
| Conteúdo | `GET /content/trending`, `GET /content/search`, `GET /content/:imdbId` |
| Lembretes | `GET /reminders`, `POST /reminders`, `DELETE /reminders/:id` |

Todas as requisições autenticadas enviam `Authorization: Bearer <token>`. Em caso de 401, o cliente tenta refresh automático e, em falha, limpa a sessão.

---

## Licença

Projeto privado — todos os direitos reservados.
