# CineAlert Mobile — WalkThrough

> Arquivo de contexto para onboarding de novos chats com o Claude.
> Leia este arquivo antes de qualquer interação sobre o projeto.

---

## O que é o CineAlert

Aplicativo Flutter para **agendamento de lembretes de filmes e séries**. O usuário descobre conteúdo, agenda um lembrete com data/hora e recebe uma notificação local ou push quando chegar a hora. Idioma: **português (pt_BR)**. Tema: **escuro exclusivo**.

- **App:** `cine_alert` · versão atual `1.0.9+10`
- **SDK Flutter:** `>=3.2.0 <4.0.0`
- **Backend:** API REST hospedada na AWS → `https://api.cinealert.link`
- **Repositório:** `alexandreluchetti/cine-alert-mobile`

---

## Stack técnica

| Camada | Tecnologia |
|---|---|
| State management | Riverpod 2.x (`StateNotifier`) |
| Navegação | GoRouter 17 com shell autenticado |
| HTTP | Dio 5 + `AuthInterceptor` (Bearer + refresh automático em 401/403 com fila de requisições concorrentes via `Completer`) |
| Notificações | `flutter_local_notifications` + Firebase Messaging (FCM) |
| Persistência local | SharedPreferences (tokens + dados do usuário) · Hive (cache de conteúdo) |
| Imagens | `cached_network_image` |
| Animações | `flutter_animate` |

---

## Arquitetura

```
presentation/   → Screens, Widgets, Riverpod Providers
domain/         → Entities puras (imutáveis)
data/           → Repositories + Dio Client → AWS API
core/           → constants, network, notifications, routes
```

---

## Paleta de cores (`app_colors.dart`)

| Token | Hex | Uso |
|---|---|---|
| `background` | `#1A1A1A` | Scaffold |
| `surface` | `#2C2C2C` | Cards, inputs |
| `accent` | `#F5C518` | Primária (dourado) |
| `accentDark` | `#D4A800` | Variante escura |
| `textPrimary` | `#FFFFFF` | Textos principais |
| `textSecondary` | `#AAAAAA` | Textos secundários |
| `textDisabled` | `#666666` | Textos/ícones desabilitados |
| `error` | `#FF4444` | Erros |
| `success` | `#4CAF50` | Sucesso |
| `warning` | `#FFA726` | Avisos |
| `info` | `#29B6F6` | Informação |
| `divider` | `#3A3A3A` | Separadores |
| `cardBorder` | `#404040` | Borda de cards |

---

## Telas e navegação

```
/splash      → SplashScreen        (verifica auth, redireciona)
/login       → LoginScreen         (e-mail + senha, forgot password)
/register    → RegisterScreen      (nome, e-mail, senha, confirmação)
── shell autenticado (BottomNavigationBar: Home / Busca / Lembretes / Perfil) ──
/home        → HomeScreen          (trending carousel, chips de gênero, grid)
/search      → SearchResultsScreen (busca inline, filtros tipo/ano)
/detail/:id  → TitleDetailScreen   (sinopse, trailer, FAB → agendar)
/reminders   → RemindersScreen     (lista, swipe-to-cancel, filtro status — padrão: Pendentes)
/profile     → ProfileScreen       (stats, editar nome, logout)
```

---

## API Backend

| Domínio | Endpoint | Método |
|---|---|---|
| Auth | `/api/auth/login` `/register` `/logout` `/forgot-password` | POST |
| Token | `/api/auth/refresh` | POST |
| Perfil (FCM) | `/api/users/me/fcm-token` | PUT |
| Perfil (update) | `/api/users/me` | PUT |
| Conteúdo | `/api/content/search` `/content/{imdbId}` `/content/trending/movies` `/content/genres` | GET |
| Lembretes | `/api/reminders` | GET / POST |
| Lembretes | `/api/reminders/{id}` | DELETE |
| Stats | `/api/reminders/stats` | GET |

---

## Widgets customizados

| Widget | Descrição |
|---|---|
| `CineAlertLogo` | Logo animável: gradiente dourado, ícone de filme, badge de sino. Props: `size`, `showText` |
| `CineAlertButton` | Botão filled/outlined com estado de loading e ícone opcional |
| `CineAlertTextField` | Campo com toggle de senha e suporte a ícones |
| `MovieCard` | Card de poster com badge de tipo (FILME / SÉRIE / DOC) |
| `StatusBadge` | Badge colorido de status do lembrete (Pendente / Enviado / Cancelado) |

---

## Notificações

- **Canal Android:** `cine_alert_channel` / "Lembretes"
- **Ícone de notificação:** `android/app/src/main/res/drawable/ic_notification.xml` (Vector Drawable)
- FCM token é sincronizado automaticamente com o backend após login/registro e em toda renovação de token (`onTokenRefresh`)
- Agendamento local usa `timezone` + `flutter_local_notifications` com `tz.setLocalLocation` (fuso do dispositivo)
- Recorrência: única / diária / semanal

### Comportamento por estado do app (FCM)

| Estado do app | Mensagem com `notification` | Mensagem data-only |
|---|---|---|
| **Foreground** | Exibida via `_showNotification` | Exibida via `_showNotification` com fallback em `message.data` |
| **Background / fechado** | Exibida automaticamente pelo OS | Background handler inicializa Firebase + exibe via `FlutterLocalNotificationsPlugin` |

> **Atenção:** `android.permission.INTERNET` deve estar no `AndroidManifest.xml` principal (não só no debug). Sem ela, o FCM não conecta no APK release.

---

## Assets

| Asset | Caminho | Observação |
|---|---|---|
| Logo PNG (app icon) | `assets/images/cinealert_logo.png` | Usado como ícone do launcher |
| Logo SVG (vetor) | `assets/images/cinealert_logo.svg` | Vetor puro, exportável para novo icon PNG |
| App icon (Android) | `assets/icon.png` | Gerado via `flutter_launcher_icons` |

> Para atualizar o ícone do launcher: exportar `cinealert_logo.svg` → PNG 1024×1024 → `assets/icon.png` → `dart run flutter_launcher_icons`

---

## Autenticação — arquitetura de bridges (GoRouter ↔ Riverpod)

O GoRouter não consegue observar providers Riverpod diretamente. Para evitar dependência circular entre `dioProvider` e `authProvider`, foram criados dois singletons `ChangeNotifier` em `lib/core/network/session_notifier.dart`:

| Classe | Responsabilidade |
|---|---|
| `SessionNotifier` | Sinaliza expiração de sessão (token inválido / refresh falhou no `AuthInterceptor`) |
| `AuthStateNotifier` | Sinaliza mudanças de autenticação (login, registro, logout) via `AuthNotifier` |

O GoRouter usa `refreshListenable: Listenable.merge([SessionNotifier.instance, AuthStateNotifier.instance])` e um `redirect` que envia o usuário para `/login` sempre que `!isAuthenticated || isExpired` em rotas protegidas.

> **Regra:** nunca usar `context.goNamed('login')` após um gap `async` em `ConsumerWidget` (não tem `mounted`). Toda navegação pós-logout/expiração é feita via `AuthStateNotifier.setAuthenticated(false)` → GoRouter redireciona automaticamente.

---

## Interceptor de autenticação — padrão Completer

`AuthInterceptor` em `lib/core/network/dio_client.dart` usa um `Completer<String?>?` para lidar com múltiplas requisições `401`/`403` concorrentes:

- **Erros tratados como auth error:** status **401** (não autenticado) e **403** (backend retorna Forbidden para token expirado — comportamento do Spring Security padrão sem `AuthenticationEntryPoint` customizado).
- **Primeira requisição 401/403:** cria o `Completer`, executa `POST /auth/refresh`, salva o novo token e chama `complete(newToken)` — desbloqueando todas as demais.
- **Requisições 401/403 subsequentes (durante o refresh):** aguardam `_refreshCompleter!.future` e retentam com o token recebido.
- **Flag `_authRetry`** no `extra` da requisição evita que retries re-entrem no interceptor.
- **Falha no refresh:** `prefs.clear()` + `SessionNotifier.instance.expire()` → GoRouter redireciona para `/login`.

> **Nunca** voltar ao padrão `_isRefreshing: bool` — ele descarta silenciosamente todas as requisições concorrentes ao retornar `handler.next(err)` para elas.
>
> **Nota backend:** o ideal é configurar um `AuthenticationEntryPoint` no Spring Security para retornar 401 (não 403) em falhas de autenticação. Enquanto isso não for feito, o interceptor trata ambos.

---

## Persistência do usuário (SharedPreferences)

`AuthRepository._saveTokens()` persiste três chaves:

| Chave (`AppConstants`) | Conteúdo |
|---|---|
| `accessTokenKey` | JWT de acesso |
| `refreshTokenKey` | JWT de refresh |
| `userKey` | JSON com `id`, `name`, `email`, `avatarUrl` |

`getStoredAuth()` reconstrói o `AuthEntity` completo a partir dessas chaves. `checkAuthentication()` chama esse método e define `state = AuthAuthenticated(storedAuth)` — garantindo que `ProfileScreen` e demais telas recebam os dados do usuário corretos ao reabrir o app sem um novo login.

`logout()` remove as três chaves. `prefs.clear()` (usado pelo interceptor em falha de refresh) também as remove.

---

## Session refresh ao voltar ao foreground

`MainShell` (`lib/presentation/screens/main/main_shell.dart`) implementa `WidgetsBindingObserver` para detectar quando o app volta ao foreground após um período em background.

### Fluxo

```
App → background → paused  → _pausedAt = DateTime.now()
App → foreground → resumed → Δt ≥ 5 min? → _onSessionRefresh()
```

### `_onSessionRefresh()`

```dart
void _onSessionRefresh() {
  ref.invalidate(trendingProvider);       // HomeScreen reconstrói
  ref.invalidate(genresProvider);          // HomeScreen reconstrói
  ref.invalidate(reminderStatsProvider);   // ProfileScreen reconstrói
  ref.read(sessionRefreshProvider.notifier).state++;  // sinal para telas com estado
}
```

### `sessionRefreshProvider`

`StateProvider<int>` definido em `auth_provider.dart`. Atua como sinal de "precisa recarregar". Telas que gerenciam estado próprio (ex.: `RemindersScreen`) escutam via `ref.listen`:

```dart
ref.listen<int>(sessionRefreshProvider, (_, __) {
  ref.read(reminderProvider.notifier).loadReminders(status: _filterStatus);
});
```

### Regras importantes

- `_pausedAt` é atualizado **somente** em `AppLifecycleState.paused`. **Nunca** em `inactive` — o evento `inactive` dispara tanto ao ir para background quanto ao voltar ao foreground (iOS), o que zeraria `_pausedAt` imediatamente antes do `resumed`, impedindo o refresh.
- `FutureProvider` sem `autoDispose` (`trendingProvider`, `genresProvider`, `reminderStatsProvider`) **não re-executam automaticamente** ao serem observados de novo — precisam ser explicitamente invalidados via `ref.invalidate`.
- `reminderProvider` é `StateNotifierProvider` — `loadReminders()` precisa ser chamado explicitamente; por isso usa o sinal em vez de `ref.invalidate`.

---

## Cancelamento de requisições HTTP (CancelToken)

Todos os métodos de repositório que fazem chamadas lentas (ex.: buscam no IMDB via backend) aceitam um parâmetro opcional `CancelToken? cancelToken` do Dio. Isso permite cancelar o request quando a tela é destruída, evitando erros desnecessários no backend (`ClientAbortException`) e na UI.

### Repositórios com suporte a cancelamento

| Método | Arquivo |
|---|---|
| `ContentRepository.search(...)` | `content_repository.dart` |
| `ContentRepository.getDetail(...)` | `content_repository.dart` |
| `ContentRepository.getTrending()` | `content_repository.dart` |
| `ReminderRepository.getReminders(...)` | `reminder_repository.dart` |
| `ReminderRepository.createReminder(...)` | `reminder_repository.dart` |

### Padrão nos providers / notifiers

**`FutureProvider`** — usar `ref.onDispose` para cancelar ao descartar:
```dart
final myProvider = FutureProvider.autoDispose((ref) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.watch(myRepositoryProvider).myMethod(cancelToken: cancelToken);
});
```

**`StateNotifier`** — substituir o token a cada nova carga e cancelar no `dispose()`:
```dart
CancelToken _cancelToken = CancelToken();

Future<void> load() async {
  _cancelToken.cancel();        // cancela carga anterior
  _cancelToken = CancelToken(); // novo token para esta carga
  try {
    final data = await _repository.getData(cancelToken: _cancelToken);
    state = AsyncValue.data(data);
  } catch (e, st) {
    if (e is AppException && e.isCancelled) return; // saída silenciosa
    state = AsyncValue.error(e, st);
  }
}

@override
void dispose() {
  _cancelToken.cancel();
  super.dispose();
}
```

### `AppException.isCancelled`

`AppException.fromDioError` detecta `DioExceptionType.cancel` e retorna `AppException('cancelled')`. O getter `isCancelled` permite identificar o cancelamento sem comparar strings:

```dart
if (e is AppException && e.isCancelled) return; // não exibir erro na UI
```

> **`contentDetailProvider`** é `FutureProvider.autoDispose.family` — descartado automaticamente quando `TitleDetailScreen` sai da árvore, cancelando a requisição em andamento.

> **Nunca** converter providers de detalhe de volta para não-`autoDispose` — isso manteria todas as telas de detalhe em memória indefinidamente.

---

## `ContentEntity.id` — identificador interno vs. `imdbId`

`ContentEntity.id` é `String?` (nullable). O campo `id` representa o UUID interno do banco de dados do backend, que **nem sempre é retornado** — especialmente em endpoints de busca/detalhe que atuam como proxy para o IMDB API sem persistir o conteúdo localmente.

O `imdbId` é o identificador universal garantido em toda resposta (`String` não-nullable).

**Regra ao passar `contentId` para `POST /api/reminders`:**
```dart
final contentId = content.id ?? content.imdbId; // nunca usar content.id! diretamente
```

> **Nunca** usar `content.id!` sem verificação — resultará em erro se o backend não retornar o UUID interno.

---

## Diálogos — regras de contexto

Padrão obrigatório em todos os `AlertDialog` do projeto:

```dart
showDialog(
  context: context,           // context estável do widget (build method)
  builder: (dialogCtx) => AlertDialog(
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogCtx, false), // ← dialogCtx, não context
      ),
    ],
  ),
);
```

> **Nunca** usar o `context` externo (do widget pai) dentro de `Navigator.pop` no diálogo. Isso popa a rota do widget pai em vez do diálogo → tela preta.
>
> **Nunca** chamar `context.goNamed(...)` ou `context.go(...)` após um `await` em `ConsumerWidget`. Use os notifiers (`AuthStateNotifier`, `SessionNotifier`) para disparar redirects via GoRouter.

---

## Versionamento

Arquivo: `pubspec.yaml` → campo `version: MAJOR.MINOR.PATCH+buildNumber`

- `PATCH` → correção de bug
- `MINOR` → nova funcionalidade
- `MAJOR` → mudança breaking
- `buildNumber` → sempre crescente (usado pela Play Store)

---

## Fuso horário — contrato App ↔ Backend

### Envio (App → Backend)
`scheduledAt` é serializado com offset local do dispositivo via helper `_toIso8601WithOffset`:
```
Usuário BRT (UTC-3) agenda 17:00 → envia "2026-05-10T17:00:00-03:00"
```
O backend recebe o `ZonedDateTime`, persiste o `zone_id` (`-03:00`) e converte internamente para UTC.

### Recebimento (Backend → App)
O backend devolve `scheduledAt` com offset (ex: `"2026-05-10T17:00:00-03:00"`).
`DateTime.parse(...).toLocal()` converte corretamente para o fuso local antes de exibir.

> **Nunca usar** `.toUtc().toIso8601String()` ao enviar (perde o timezone real).
> **Nunca exibir** `DateTime` vindo da API sem `.toLocal()`.

---

## Histórico de alterações recentes

### v1.0.9+10

**Auth — backend retorna 403 em vez de 401 para token expirado (`dio_client.dart`)**
- `AuthInterceptor.onError`: condição de intercepção alterada de `status != 401` para `status != 401 && status != 403` — o Spring Security sem `AuthenticationEntryPoint` customizado retorna 403 (Forbidden) para JWTs expirados, impedindo o refresh automático
- `AppException.fromDioError`: mensagens localizadas em pt_BR por tipo de erro (`connectionTimeout` → "Tempo de conexão esgotado", `connectionError` → "Sem conexão com o servidor", `badCertificate` → "Erro de certificado SSL", etc.); erros sem resposta (`e.response == null`) distinguidos de erros com resposta HTTP

**Session refresh ao voltar ao foreground (`main_shell.dart`, `auth_provider.dart`, `reminders_screen.dart`, `content_provider.dart`)**
- `MainShell` convertido para `ConsumerStatefulWidget` com `WidgetsBindingObserver`
- Ao resumir após ≥5 min em background: `ref.invalidate` em `trendingProvider`, `genresProvider`, `reminderStatsProvider` + incremento de `sessionRefreshProvider`
- `_pausedAt` atualizado **somente** em `paused` (nunca em `inactive` — evita bug em iOS onde `inactive` dispara antes de `resumed`)
- `sessionRefreshProvider = StateProvider<int>` adicionado em `auth_provider.dart`; `RemindersScreen` escuta via `ref.listen` e recarrega com o filtro ativo
- `RefreshIndicator` centralizado no `body` do `Scaffold` da `RemindersScreen` (cobre estados de dados, vazio e erro); `AlwaysScrollableScrollPhysics` nos filhos não-scrolláveis

**FCM token — sincronização e notificações (`auth_provider.dart`, `main.dart`, `pubspec.yaml`)**
- `_syncFcmToken()` agora é `await`ado em `login()` e `register()` (garante token sincronizado antes da primeira criação de lembrete); mantido fire-and-forget em `checkAuthentication()` (não bloqueia o cold start)
- `debugPrint` nos handlers de erro do `main.dart` substituído por `print` (visível em release via logcat/stdout)
- Removida dependência `firebase_auth: ^6.2.0` (nunca utilizada no código Dart)
- **Prompt enviado ao backend:** `updateFcmToken()` em `UserUseCaseImpl` deve também atualizar o campo `user_fcm_token` de todos os lembretes `PENDING` do usuário — sem isso, lembretes criados antes de uma reinstalação do app continuam com o token antigo (inválido) e as notificações falham com "Requested entity was not found"

---

### v1.0.4+5

**Cancelamento de requisições HTTP ao sair da tela (`dio_client.dart`, `content_repository.dart`, `reminder_repository.dart`, `content_provider.dart`, `reminder_provider.dart`)**
- `AppException.fromDioError`: detecta `DioExceptionType.cancel` antes de qualquer outro tratamento → retorna `AppException('cancelled')`; novo getter `isCancelled` para identificação limpa nos callers
- `ContentRepository`: adicionado `CancelToken? cancelToken` em `search`, `getDetail` e `getTrending`
- `ReminderRepository`: adicionado `CancelToken? cancelToken` em `getReminders` e `createReminder`
- `contentDetailProvider`: convertido para `FutureProvider.autoDispose.family` + `ref.onDispose(cancelToken.cancel)` — descartado automaticamente quando `TitleDetailScreen` sai da árvore
- `trendingProvider` e `genresProvider`: adicionados `CancelToken` + `ref.onDispose`
- `SearchNotifier`: `_cancelToken` substituído a cada `search()` (cancela busca anterior); `dispose()` cancela token ativo; erros `isCancelled` saem silenciosamente
- `ReminderNotifier`: `_cancelToken` substituído a cada `loadReminders()` (evita race condition ao trocar filtro); `dispose()` cancela token ativo; erros `isCancelled` saem silenciosamente

**Criação de lembrete via busca — erro "Conteúdo sem ID" (`schedule_reminder_sheet.dart`)**
- Removido o guard `if (widget.content.id == null)` que bloqueava a criação com mensagem de erro
- `contentId` agora usa `content.id ?? content.imdbId` — garante que sempre há um identificador válido independente do endpoint retornar o UUID interno ou não

---

### v1.0.3+4

**Autenticação — expiração de sessão após idle (`dio_client.dart`, `app_router.dart`, `session_notifier.dart`)**
- Criado `lib/core/network/session_notifier.dart` com dois singletons `ChangeNotifier`: `SessionNotifier` (expiração) e `AuthStateNotifier` (login/logout)
- `AuthInterceptor.onError`: substituído flag `_isRefreshing: bool` por `Completer<String?>` — todas as requisições `401` concorrentes aguardam o mesmo refresh e retentam juntas com o novo token
- Adicionada flag `_authRetry` no `extra` das requisições para evitar loops no interceptor
- Falha no refresh agora chama `SessionNotifier.instance.expire()` → GoRouter redireciona para `/login`
- `appRouterProvider`: adicionados `refreshListenable: Listenable.merge([...])` e `redirect` que guarda rotas protegidas

**Autenticação — estado do usuário ao reabrir o app (`auth_repository.dart`, `auth_provider.dart`)**
- `_saveTokens()` agora persiste dados do usuário (`id`, `name`, `email`, `avatarUrl`) como JSON em `AppConstants.userKey`
- Novo método `getStoredAuth()`: reconstrói `AuthEntity` completo a partir do SharedPreferences
- `checkAuthentication()` substituiu `isAuthenticated()` por `getStoredAuth()` e define `state = AuthAuthenticated(storedAuth)` — corrige nome/email ausentes na `ProfileScreen` ao reabrir o app
- `logout()` agora remove `AppConstants.userKey` além dos tokens

**Autenticação — logout com tela preta (`auth_provider.dart`, `profile_screen.dart`)**
- `AuthNotifier.logout()` chama `AuthStateNotifier.instance.setAuthenticated(false)` → GoRouter redireciona automaticamente para `/login` sem depender do `BuildContext` da tela
- Removido `context.goNamed('login')` do `ProfileScreen` (chamado após `await` em `ConsumerWidget` — context obsoleto → tela preta)
- Todos os `Navigator.pop` nos diálogos do `ProfileScreen` corrigidos para usar `dialogCtx`

**Lembretes — swipe-to-delete com tela preta (`reminders_screen.dart`)**
- `_ReminderCard`: `onDelete: VoidCallback` substituído por `onConfirmDelete: Future<bool> Function()`
- Diálogo de confirmação movido para dentro do `confirmDismiss` do `Dismissible` — usa `context` estável do `_ReminderCard.build` para `showDialog` e `dialogCtx` para `Navigator.pop`
- `confirmDismiss` agora awaita a deleção e retorna `true` → `Dismissible` remove o item com animação nativa
- Removido método `_confirmDelete()` do State (lógica consolidada no widget)
- Filtro padrão da tela alterado de "Todos" para "Pendentes" (`_filterStatus = ReminderStatus.pending`)

**Perfil — editar nome com tela preta + sem API (`auth_repository.dart`, `auth_provider.dart`, `profile_screen.dart`)**
- Novo método `AuthRepository.updateProfile({required String name})`: chama `PUT /api/users/me` e atualiza o JSON do usuário no SharedPreferences
- Novo método `AuthNotifier.updateName(String name)`: chama o repositório e emite novo `AuthAuthenticated` com o nome atualizado — `ProfileScreen` reconstrói automaticamente
- `_showEditProfile`: corrigido `builder: (dialogCtx)` + `Navigator.pop(dialogCtx)`, "Salvar" agora awaita `updateName()` e exibe SnackBar de sucesso ou erro

---

### v1.0.2+3

**Fuso horário — serialização com offset (`reminder_repository.dart`)**
- `scheduledAt` agora é enviado com offset local via `_toIso8601WithOffset(dt)` → formato `"2026-05-10T17:00:00-03:00"`
- Antes usava `.toUtc().toIso8601String()` → backend recebia `"Z"` e perdia o timezone real do usuário
- Respostas da API parseadas com `.toLocal()` em `scheduledAt` e `createdAt` → exibição correta no fuso do usuário

**Notificações FCM — correções em `notification_service.dart`**
- **Background handler:** adicionado `await Firebase.initializeApp()` (obrigatório em release/AOT — o isolate começa sem contexto do app); mensagens data-only agora exibem notificação local via `FlutterLocalNotificationsPlugin`
- **Foreground listener:** removida a guarda `if (message.notification != null)`; agora trata qualquer mensagem com fallback em `message.data['title']` / `message.data['body']`
- Adicionado import `firebase_core/firebase_core.dart` em `notification_service.dart`

**AndroidManifest — permissão INTERNET (`android/app/src/main/AndroidManifest.xml`)**
- Adicionada `android.permission.INTERNET` no manifest principal
- Antes existia **apenas** em `src/debug/AndroidManifest.xml` → APK release não recebia notificações FCM

---

### v1.0.1+2
- Correção de bug geral (incremento de patch)
- Substituído `ic_notification.png` (corrompido/perfil ICC inválido) por `ic_notification.xml` (Vector Drawable) — resolve falha de build AAPT2

---

### v1.0.0+1 — Mudanças no logo (`CineAlertLogo` widget)
- **Removido** efeito glossy (camada branca skeuomórfica no canto superior)
- **Gradiente atualizado:** `#F5C518→#D4920A` (2 stops) → `#FFD740→#F5C518→#C48A00` (3 stops)
- **Badge do sino:** `BoxShape.circle` → `BorderRadius` (retângulo arredondado — padrão moderno iOS/Android)
- **Ícone principal:** `local_movies_rounded` → `movie_filter_rounded`
- **Wordmark:** tagline "Seus filmes. Seus horários." removida; `letterSpacing` 0.5 → 1.5
- **Novo asset:** `assets/images/cinealert_logo.svg` (vetor puro com mesma geometria do widget)

---

## Como gerar o APK

```bash
# Instalar dependências
flutter pub get

# Build release (recomendado para instalar no dispositivo)
flutter build apk --release

# APK gerado em:
# build/app/outputs/flutter-apk/app-release.apk

# Instalar via USB (com ADB/depuração USB ativa)
flutter install
```
