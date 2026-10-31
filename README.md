# DABI504 Lab 3 — Yapily Open Banking (AISP) Mobile App

A two-part application built from scratch for Lab 3:
1. **`server/`** — Local Node.js/Express backend proxy that reads your Yapily `YAPILY_APP_ID` and `YAPILY_APP_SECRET` from `server/.env` (never exposed in the Flutter mobile binary).
2. **`dabi_lab3/`** — Flutter mobile application (Android & iOS) implementing the complete Open Banking AISP journey with `dabi-lab3://callback` deep linking.

---

## 1. Setup & Start the Local Proxy Server

1. Copy `server/.env.example` to `server/.env`:
   ```powershell
   cd "c:\Users\Admin\Desktop\Digital Banking Application DABI504\server"
   Copy-Item .env.example .env
   ```
2. Open `server/.env` in your editor and paste your Yapily Sandbox **Application ID** and **Application Secret**:
   ```env
   YAPILY_APP_ID=your_application_id_here
   YAPILY_APP_SECRET=your_application_secret_here
   PORT=4000
   ```
3. In the **Yapily Console**, register the callback URL on your application:
   ```text
   dabi-lab3://callback
   ```
4. Start the proxy server:
   ```powershell
   npm start
   ```
   Verify it is listening on `http://localhost:4000/health`.

---

## 2. Run the Flutter Mobile App

> **Why `flutter` didn't work in `cmd` earlier:** Windows terminals only load `PATH` changes when a **new** terminal window is opened, or if `C:\flutter\bin` was added as a single combined string. We have now ensured `C:\flutter\bin` is registered in your Windows User `PATH`. You can also always run `C:\flutter\bin\flutter.bat` directly.

Open a **new** terminal window:
```powershell
cd "c:\Users\Admin\Desktop\Digital Banking Application DABI504\dabi_lab3"
flutter run
```

---

## 3. User Journey (Step-by-Step)

1. **Screen 1 — Select Your Bank (`GET /institutions`)**:
   - Lists real Yapily institutions fetched through the proxy (`Modelo Sandbox` sorted to the top).
   - Tap **Modelo Sandbox**.
2. **Screen 2 — Start AIS Consent (`POST /account-auth-requests`)**:
   - Sends `applicationUserId: 64bc476b-74cd-4ecd-b341-50d32279d8db`, `institutionId`, `callback: dabi-lab3://callback`, and `oneTimeToken: true`.
   - Automatically opens `authorisationUrl` in the browser so you can complete SCA (`mits` / `mits`).
3. **Deep-Link Redirect (`dabi-lab3://callback`)**:
   - Catches the redirect back into the app via `app_links`.
   - Reads `one-time-token` (or `consent` / `consentToken` if returned directly) and exchanges the one-time token via `POST /consent-one-time-token` on the proxy server.
4. **Screen 3 — Accounts, Consent Lease & Transactions**:
   - Calls `GET /consents/{consentId}` and displays `authorizedAt`, `expiresAt`, and `reconfirmBy` (showing that AIS consent is a time-bounded lease, not forever).
   - Calls `GET /accounts` with `consent: <consentToken>` and displays account balances and IBANs.
   - Calls `GET /accounts/{accountId}/transactions` for the selected account.
   - Strictly AISP read-only (no payment endpoints or Pay buttons).
