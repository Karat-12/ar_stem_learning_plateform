# Authentication Integration — Implementation Reference

> **Documentation status:** Updated to reflect the actual current implementation.
> Code is the source of truth.

---

## Overview

The Flutter frontend integrates with the Spring Boot backend authentication system using JWT (JSON Web Token). The integration includes secure token storage, automatic session restoration on app startup, login/registration screens, and logout from the navigation shell.

---

## What Is Implemented

### 1. Core Infrastructure (`lib/core/`)

#### `lib/core/config/api_constants.dart` — `ApiConstants`

Static configuration (private constructor — not instantiable):

| Constant | Value | Notes |
|---|---|---|
| `baseUrl` | `http://192.168.1.5:8080` | LAN IP for physical Android device testing. Change per environment. |
| Login endpoint | `/api/v1/auth/login` | |
| Register endpoint | `/api/v1/auth/register` | |
| Users me endpoint | `/api/v1/users/me` | |
| Misconceptions endpoint | `/api/v1/misconceptions` | |
| `authorizationHeader` | `Authorization` | |
| `contentTypeHeader` | `Content-Type` | |
| `connectTimeout` | 30 seconds | |
| `receiveTimeout` | 30 seconds | |
| `sendTimeout` | 30 seconds | |
| `tokenKey` | `jwt_token` | Secure storage key |
| `currentUserKey` | `current_user` | Secure storage key |

> For local desktop development, change `baseUrl` to `http://localhost:8080`.
> For Android emulator, use `http://10.0.2.2:8080`.

---

#### `lib/core/network/api_client.dart` — `ApiClient`

Wraps `Dio`. Constructor accepts a `getToken` async callback (closure over `SecureStorageService`).

**Interceptors (in order):**
1. Auth interceptor — reads token via `getToken()` callback; if non-null, injects `Authorization: Bearer <token>` header
2. Logging interceptor — prints method, URL, and response status to console (debug only)

**Public methods:**
- `get<T>({path, queryParameters, fromJson})` → executes GET, unwraps response via `fromJson`
- `post<T>({path, data, queryParameters, fromJson})` → executes POST
- `put<T>({path, data, queryParameters, fromJson})` → executes PUT
- `delete<T>({path, queryParameters, fromJson})` → executes DELETE

**Error handling:** `_handleDioException(DioException)` maps network and HTTP errors to `ApiException`.

---

#### `lib/core/network/api_exception.dart` — `ApiException`

Custom `Exception`. Fields: `message` (String), `statusCode` (int?), `originalError` (dynamic).

Convenience getters:
- `isAuthenticationError` — status code 401 or 403
- `isInvalidCredentials` — status code 401
- `isNetworkError` — no status code (connection failure, timeout)

---

#### `lib/core/storage/secure_storage_service.dart` — `SecureStorageService`

Wraps `FlutterSecureStorage`. Methods:

| Method | Description |
|---|---|
| `saveToken(String token)` | Writes JWT to `jwt_token` key |
| `getToken()` | Returns stored token or `null` |
| `hasToken()` | Returns `true` if token is stored |
| `deleteToken()` | Removes `jwt_token` key |
| `clearAll()` | Clears all secure storage |

**Platform-native storage backends:**
- Android: EncryptedSharedPreferences
- iOS: Keychain
- Windows: Windows Credential Manager

Tokens are **never** stored in `SharedPreferences` or unencrypted local storage.

---

### 2. Authentication Feature (`lib/features/auth/`)

#### Models

**`CurrentUser`** — represents the authenticated user in memory.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | |
| `email` | `String` | |
| `displayName` | `String?` | From backend `displayName` field |
| `firstName` | `String?` | From backend (if present) |
| `lastName` | `String?` | From backend (if present) |
| `profilePictureUrl` | `String?` | From backend (if present) |
| `roles` | `List<String>` | e.g. `["STUDENT"]` |
| `status` | `String?` | e.g. `"ACTIVE"` |
| `createdAt` | `String?` | |

Computed getter: `fullName` — returns `displayName` → `"$firstName $lastName"` → `firstName` → `lastName` → `email` (fallback chain).

**`LoginRequest`** — `{ email, password }` → `toJson()`

**`LoginResponse`** — `{ token, tokenType, user? }` — parsed from backend response.

**`RegisterRequest`** — `{ displayName, email, password }` → `toJson()`

---

#### `lib/features/auth/services/auth_service.dart` — `AuthService`

Constructor: `apiClient`, `storageService`. Holds `_currentUser` in memory.

| Method | Description |
|---|---|
| `login({email, password})` | POST `/api/v1/auth/login`, saves token, calls `getCurrentUser()`, caches `_currentUser` |
| `register({displayName, email, password})` | POST `/api/v1/auth/register` |
| `getCurrentUser()` | GET `/api/v1/users/me` using the stored token |
| `isLoggedIn()` | Checks `storageService.hasToken()` |
| `restoreSession()` | Checks token existence, calls `getCurrentUser()`, returns `bool` |
| `logout()` | Calls `storageService.deleteToken()`, clears `_currentUser` |
| `clearAuthData()` | Calls `storageService.clearAll()` |

---

#### `lib/features/auth/providers/auth_provider.dart` — `AuthProvider`

`ChangeNotifier`. Central auth state manager.

**`AuthState` enum:** `idle`, `loading`, `authenticated`, `unauthenticated`, `error`

State fields: `_state`, `_currentUser`, `_errorMessage`, `_isRestoring`

Getters: `state`, `currentUser`, `errorMessage`, `isAuthenticated` (state == authenticated), `isLoading` (state == loading), `isRestoring`

| Method | Description |
|---|---|
| `restoreSession()` | Sets `_isRestoring = true`, calls `AuthService.restoreSession()`, sets state to `authenticated` or `unauthenticated`. Always sets `_isRestoring = false` on completion. |
| `login({email, password})` | Sets `loading`, calls service, transitions to `authenticated` or `error` |
| `register({displayName, email, password})` | Calls service, transitions to `unauthenticated` on success (user must then log in) |
| `logout()` | Calls service, transitions to `unauthenticated`, calls `AiCoachProvider.clearAll()` if available |
| `clearAuthData()` | Full wipe via `AuthService.clearAuthData()` |
| `clearError()` | Sets `_errorMessage = null`, notifies listeners |

---

#### `lib/features/auth/screens/login_screen.dart` — `LoginScreen`

`StatefulWidget`. Uses `CyberBackground` + `GlassCard` (max width 500px, centered).

UI:
- Email `TextField` with cyan focus decoration
- Password `TextField` with visibility toggle (`Icons.visibility` / `Icons.visibility_off`)
- Submit on button tap or Enter key
- Shows `CircularProgressIndicator` during `isLoading`
- Shows pink error `SnackBar` from `authProvider.errorMessage`
- "Create an account" `TextButton` → `Navigator.push` to `RegisterScreen`
- Demo credentials note displayed at bottom of card

---

#### `lib/features/auth/screens/register_screen.dart` — `RegisterScreen`

`StatefulWidget`. Fields: Display Name, Email, Password, Confirm Password (all with visibility toggles on password fields).

Client-side validation:
- Email must contain `@`
- Password must be ≥ 8 characters
- Confirm password must match password

On success: shows green `SnackBar` ("Account created! Please log in."), `Navigator.pop()` back to `LoginScreen`.

---

### 3. App Integration

#### `lib/main.dart`

Initialization order:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `SecureStorageService` created
3. `ApiClient` created with token-getter closure over `SecureStorageService`
4. `AuthService`, `SessionService`, `ProgressService`, `AiCoachService` created
5. All providers created: `AuthProvider`, `SessionProvider`, `ProgressProvider`, `AiCoachProvider`
6. `authProvider.restoreSession()` called (async, blocks until complete)
7. `runApp(MultiProvider(..., child: StemArApp()))`

All services and providers are singleton instances (one per app lifecycle).

---

#### `lib/app.dart` — `StemArApp`

Consumes `AuthProvider` to decide what to render:

```
authProvider.isRestoring  →  _LoadingScreen (spinner + "Initializing...")
authProvider.isAuthenticated  →  AppShell (dashboard + labs + AR + progress)
else  →  LoginScreen
```

There is no named route configuration — navigation is state-driven through `Consumer<AuthProvider>`.

---

#### `lib/navigation/app_shell.dart` — logout in AppBar

The `AppBar` contains a `PopupMenuButton` user avatar chip:
- Shows `authProvider.currentUser?.fullName` and email
- "Logout" menu item calls `authProvider.logout()`
- Shows a `SnackBar` "Logged out successfully" after logout
- `Consumer<AuthProvider>` wraps the button so it rebuilds when auth state changes

---

## Startup Session Restoration Flow

```
App Launch
    ↓
main() initializes services
    ↓
authProvider.restoreSession()
    ↓
  SecureStorageService.hasToken()?
    ├── No  →  state = unauthenticated  →  LoginScreen shown
    └── Yes →  AuthService.getCurrentUser() (GET /api/v1/users/me with stored JWT)
                  ├── Success  →  _currentUser cached  →  state = authenticated  →  AppShell shown
                  └── ApiException (401 / network error)  →  storage cleared  →  state = unauthenticated  →  LoginScreen shown
```

---

## API Endpoints Used

| Operation | Method | Endpoint | Auth |
|---|---|---|---|
| Login | POST | `/api/v1/auth/login` | None |
| Register | POST | `/api/v1/auth/register` | None |
| Get own profile | GET | `/api/v1/users/me` | JWT required |

Login response shape:
```json
{
  "token": "eyJhbGci...",
  "tokenType": "Bearer"
}
```

Users/me response shape:
```json
{
  "id": "...",
  "displayName": "Karthik",
  "email": "karthik@example.com",
  "roles": ["STUDENT"],
  "status": "ACTIVE"
}
```

---

## Token Lifecycle

| Event | Action |
|---|---|
| Successful login | `SecureStorageService.saveToken(token)` |
| App restart with stored token | `AuthService.restoreSession()` re-validates via `/users/me` |
| Token invalid / expired (401 from any endpoint) | `ApiException.isAuthenticationError` detected; `authProvider.logout()` called |
| User taps Logout | `SecureStorageService.deleteToken()`, `_currentUser` cleared, state → `unauthenticated` |

> **No refresh token is implemented.** When the 24-hour access token expires, the user must log in again. The app does not automatically handle 401 responses from non-auth endpoints — this is a known limitation.

---

## What Is NOT Implemented

| Feature | Status |
|---|---|
| Token refresh / `POST /auth/refresh` | Not implemented in backend or frontend |
| Server-side logout / token revocation | Not implemented |
| Biometric authentication | Not implemented |
| Password reset flow | Not implemented |
| Remember Me / extended sessions | Not implemented — token expires after 24 hours |
| Automatic 401 interception across all API calls | Not implemented — `isAuthenticationError` check exists on `ApiException` but no global 401 → logout interceptor in `ApiClient` |

---

## Known Limitations

1. **Token expiry handling:** When the JWT expires after 24 hours, subsequent API calls will fail with 401. The app does not automatically redirect to the login screen — the user will see error states in the Progress or AI Coach screens. This requires a token refresh implementation or a Dio interceptor that catches 401 responses and triggers logout.

2. **Base URL is hardcoded to a LAN IP:** `api_constants.dart` has `baseUrl = 'http://192.168.1.5:8080'`. This must be changed manually when switching between physical device, emulator, and desktop targets.

3. **Registration validation inconsistency:** The `RegisterScreen` displays "Password must be at least 6 characters" as the error message, but the actual validation check is `password.length < 8`. The backend also enforces a minimum of 8 characters. This should be corrected to "8 characters" in the UI.

---

## Testing Checklist

- [ ] `flutter pub get` — all dependencies installed
- [ ] Start backend with `MONGODB_URI` and `JWT_SECRET` environment variables set
- [ ] Test login with valid credentials
- [ ] Test invalid credentials show pink error snackbar
- [ ] Test app restart restores session (token still valid)
- [ ] Test logout returns to login screen and clears session
- [ ] Test registration with all required fields
- [ ] Test registration with mismatched passwords shows validation error
- [ ] Test progress screen loads data after login
- [ ] Test AI Coach screen opens from Linked List Assessment result
