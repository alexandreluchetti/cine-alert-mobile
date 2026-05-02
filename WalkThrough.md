# CineAlert Mobile — WalkThrough

> Arquivo de contexto para onboarding de novos chats com o Claude.
> Leia este arquivo antes de qualquer interação sobre o projeto.

---

## O que é o CineAlert

Aplicativo Flutter para **agendamento de lembretes de filmes e séries**. O usuário descobre conteúdo, agenda um lembrete com data/hora e recebe uma notificação local ou push quando chegar a hora. Idioma: **português (pt_BR)**. Tema: **escuro exclusivo**.

- **App:** `cine_alert` · versão atual `1.0.2+3`
- **SDK Flutter:** `>=3.2.0 <4.0.0`
- **Backend:** API REST hospedada na AWS → `https://api.cinealert.link`
- **Repositório:** `alexandreluchetti/cine-alert-mobile`

---

## Stack técnica

| Camada | Tecnologia |
|---|---|
| State management | Riverpod 2.x (`StateNotifier`) |
| Navegação | GoRouter 17 com shell autenticado |
| HTTP | Dio 5 + `AuthInterceptor` (Bearer + refresh automático em 401) |
| Notificações | `flutter_local_notifications` + Firebase Messaging (FCM) |
| Persistência local | SharedPreferences (tokens) · Hive (cache de conteúdo) |
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
| `error` | `#FF4444` | Erros |
| `success` | `#4CAF50` | Sucesso |

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
/reminders   → RemindersScreen     (lista, swipe-to-cancel, filtro status)
/profile     → ProfileScreen       (stats, editar avatar, logout)
```

---

## API Backend

| Domínio | Endpoint | Método |
|---|---|---|
| Auth | `/api/auth/login` `/register` `/logout` `/forgot-password` | POST |
| Token | `/api/auth/refresh` | POST |
| Perfil | `/api/users/me/fcm-token` | PUT |
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

### v1.0.1+2
- Correção de bug geral (incremento de patch)
- Substituído `ic_notification.png` (corrompido/perfil ICC inválido) por `ic_notification.xml` (Vector Drawable) — resolve falha de build AAPT2

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
