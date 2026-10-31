'use strict';

const path    = require('path');
const dotenv  = require('dotenv');

dotenv.config({ path: path.join(__dirname, '.env') });

const express = require('express');
const axios   = require('axios');
const cors    = require('cors');
const {
  categorizeTransaction,
  buildPfmSummary,
  getBudgets,
  saveBudgets,
} = require('./pfmService');

const app  = express();
const PORT = process.env.PORT || 4000;

// ─── Middleware ──────────────────────────────────────────────────────────────
app.use(express.json());
app.use(cors());                 // allow Flutter / emulator to call us

// Holds the most recent deep-link callback URI relayed from the OS / browser
let pendingCallbackUri = null;

// Tracks the most recent active consent tokens seen by this server
const activeConsentTokens = new Set();

// ─── Yapily helpers ───────────────────────────────────────────────────────────
const YAPILY_BASE = 'https://api.yapily.com';

/**
 * Build the Authorization header value from env vars.
 * Credentials NEVER leave this file.
 */
function yapilyAuth() {
  // Reload .env dynamically so edits to server/.env take effect immediately without restarting
  dotenv.config({ path: path.join(__dirname, '.env'), override: true });
  if (
    !process.env.YAPILY_APP_ID ||
    !process.env.YAPILY_APP_SECRET ||
    process.env.YAPILY_APP_ID === 'your_application_id_here'
  ) {
    throw new Error(
      'Please set your real YAPILY_APP_ID and YAPILY_APP_SECRET in server/.env'
    );
  }
  const encoded = Buffer.from(
    `${process.env.YAPILY_APP_ID}:${process.env.YAPILY_APP_SECRET}`
  ).toString('base64');
  return `Basic ${encoded}`;
}

/** Centralised error handler – forwards Yapily error details to the client. */
function handleError(res, err) {
  console.error('[Yapily Proxy Error]', err?.response?.data ?? err.message);
  const status = err?.response?.status ?? 500;
  const body   = err?.response?.data   ?? { error: err.message };
  res.status(status).json(body);
}

/**
 * Resolves one or more valid consent tokens:
 * 1. Explicit header (`x-consent-token` or `consent`) or query param (`consentToken`)
 * 2. Cached active token(s) in memory
 * 3. Latest AUTHORIZED consent from GET /consents on Yapily
 */
async function resolveConsentTokens(req) {
  const headerToken =
    req.headers['x-consent-token'] ||
    req.headers['consent'] ||
    req.query.consentToken;

  if (headerToken && typeof headerToken === 'string' && headerToken.trim()) {
    const tokens = headerToken
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean);
    tokens.forEach((t) => activeConsentTokens.add(t));
    return tokens;
  }

  if (activeConsentTokens.size > 0) {
    return Array.from(activeConsentTokens);
  }

  // Fallback: discover most recent AUTHORIZED consent from Yapily (already returned newest-first)
  const consentsRes = await axios.get(`${YAPILY_BASE}/consents`, {
    headers: { Authorization: yapilyAuth() },
  });
  const consents = (consentsRes.data?.data || []).filter(
    (c) => c.status === 'AUTHORIZED' && c.consentToken
  );

  for (const c of consents.slice(0, 15)) {
    try {
      await axios.get(`${YAPILY_BASE}/accounts`, {
        headers: {
          Authorization: yapilyAuth(),
          consent: c.consentToken,
        },
      });
      activeConsentTokens.add(c.consentToken);
      return [c.consentToken];
    } catch (_) {
      // Skip expired consent and try next
    }
  }

  return [];
}

// ─── Routes ───────────────────────────────────────────────────────────────────

/**
 * GET /proxy/institutions
 * Proxies: GET https://api.yapily.com/institutions
 */
app.get('/proxy/institutions', async (req, res) => {
  try {
    const response = await axios.get(`${YAPILY_BASE}/institutions`, {
      headers: { Authorization: yapilyAuth() },
      params:  req.query,
    });
    res.json(response.data);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * POST /proxy/auth-request
 * Proxies: POST https://api.yapily.com/account-auth-requests
 */
app.post('/proxy/auth-request', async (req, res) => {
  try {
    pendingCallbackUri = null; // clear any stale callback before new auth flow
    const response = await axios.post(
      `${YAPILY_BASE}/account-auth-requests`,
      req.body,
      {
        headers: {
          Authorization:  yapilyAuth(),
          'Content-Type': 'application/json',
        },
      }
    );
    res.status(response.status).json(response.data);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * POST /proxy/exchange-token
 * Proxies: POST https://api.yapily.com/consent-one-time-token
 */
app.post('/proxy/exchange-token', async (req, res) => {
  try {
    const { oneTimeToken } = req.body;
    if (!oneTimeToken) {
      return res.status(400).json({ error: 'oneTimeToken is required' });
    }

    const response = await axios.post(
      `${YAPILY_BASE}/consent-one-time-token`,
      { oneTimeToken },
      {
        headers: {
          Authorization:  yapilyAuth(),
          'Content-Type': 'application/json',
        },
      }
    );
    const token = response.data?.data?.consentToken || response.data?.consentToken;
    if (token) {
      activeConsentTokens.add(token);
    }
    res.status(response.status).json(response.data);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * GET /proxy/accounts
 * Proxies: GET https://api.yapily.com/accounts
 */
app.get('/proxy/accounts', async (req, res) => {
  try {
    const consentToken = req.headers['x-consent-token'];
    if (!consentToken) {
      return res.status(400).json({ error: 'X-Consent-Token header is required' });
    }
    activeConsentTokens.add(consentToken);

    const response = await axios.get(`${YAPILY_BASE}/accounts`, {
      headers: {
        Authorization: yapilyAuth(),
        consent:       consentToken,   // Yapily requires lowercase 'consent'
      },
    });
    res.json(response.data);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * GET /proxy/accounts/:accountId/transactions
 * Proxies: GET https://api.yapily.com/accounts/:accountId/transactions
 * Also attaches `pfmCategory` to each transaction item.
 */
app.get('/proxy/accounts/:accountId/transactions', async (req, res) => {
  try {
    const consentToken = req.headers['x-consent-token'];
    if (!consentToken) {
      return res.status(400).json({ error: 'X-Consent-Token header is required' });
    }
    activeConsentTokens.add(consentToken);

    const response = await axios.get(
      `${YAPILY_BASE}/accounts/${req.params.accountId}/transactions`,
      {
        headers: {
          Authorization: yapilyAuth(),
          consent:       consentToken,
        },
        params: req.query,
      }
    );

    const payload = response.data;
    if (payload && Array.isArray(payload.data)) {
      payload.data = payload.data.map((tx) => ({
        ...tx,
        pfmCategory: categorizeTransaction(tx),
      }));
    }
    res.json(payload);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * GET /proxy/consent/:consentId
 * Proxies: GET https://api.yapily.com/consents/:consentId
 */
app.get('/proxy/consent/:consentId', async (req, res) => {
  try {
    const response = await axios.get(
      `${YAPILY_BASE}/consents/${req.params.consentId}`,
      {
        headers: { Authorization: yapilyAuth() },
      }
    );
    const token = response.data?.data?.consentToken;
    if (token && response.data?.data?.status === 'AUTHORIZED') {
      activeConsentTokens.add(token);
    }
    res.json(response.data);
  } catch (err) {
    handleError(res, err);
  }
});

/**
 * Unified PFM Summary handler
 * Mounted at both GET /api/pfm/summary and GET /proxy/pfm/summary
 */
async function handlePfmSummary(req, res) {
  try {
    const tokens = await resolveConsentTokens(req);
    if (tokens.length === 0) {
      return res.status(400).json({
        error: 'No active consent token found. Please connect a bank account first or pass X-Consent-Token.',
      });
    }

    const accountBundles = [];
    const seenAccountIds = new Set();

    for (const token of tokens) {
      try {
        const accountsRes = await axios.get(`${YAPILY_BASE}/accounts`, {
          headers: {
            Authorization: yapilyAuth(),
            consent:       token,
          },
        });
        const accounts = accountsRes.data?.data || [];

        for (const acc of accounts) {
          if (seenAccountIds.has(acc.id)) continue;
          seenAccountIds.add(acc.id);

          let transactions = [];
          try {
            const txRes = await axios.get(
              `${YAPILY_BASE}/accounts/${acc.id}/transactions`,
              {
                headers: {
                  Authorization: yapilyAuth(),
                  consent:       token,
                },
              }
            );
            transactions = txRes.data?.data || [];
          } catch (txErr) {
            console.warn(
              `[PFM Summary] Could not fetch transactions for account ${acc.id}:`,
              txErr?.response?.status ?? txErr.message
            );
          }

          accountBundles.push({ account: acc, transactions });
        }
      } catch (accErr) {
        activeConsentTokens.delete(token);
        // If explicit token failed and no other tokens worked, propagate error
        if (tokens.length === 1) {
          throw accErr;
        }
      }
    }

    const summary = buildPfmSummary(accountBundles);
    res.json(summary);
  } catch (err) {
    handleError(res, err);
  }
}

app.get('/api/pfm/summary', handlePfmSummary);
app.get('/proxy/pfm/summary', handlePfmSummary);

/**
 * GET /api/pfm/budgets (and /proxy/pfm/budgets)
 * Returns the persisted monthly category spending limits.
 */
app.get(['/api/pfm/budgets', '/proxy/pfm/budgets'], (_req, res) => {
  res.json({ budgets: getBudgets() });
});

/**
 * PUT /api/pfm/budgets (and /proxy/pfm/budgets)
 * Updates one or more category spending limits and persists to server/budgets.json.
 */
app.put(['/api/pfm/budgets', '/proxy/pfm/budgets'], (req, res) => {
  const payload = req.body?.budgets || req.body || {};
  const updated = saveBudgets(payload);
  res.json({ budgets: updated });
});

/**
 * POST /proxy/deep-link-relay
 * Receives the dabi-lab3://callback?... URI from the OS protocol handler
 * when testing on desktop so the running Flutter instance can pick it up.
 */
app.post('/proxy/deep-link-relay', (req, res) => {
  if (req.body && req.body.uri) {
    console.log('[Deep-Link Relay] Captured:', req.body.uri);
    pendingCallbackUri = req.body.uri;
  }
  res.json({ ok: true });
});

/**
 * GET /proxy/pending-callback
 * Polled by AuthScreen while waiting for browser SCA completion.
 */
app.get('/proxy/pending-callback', (_req, res) => {
  const uri = pendingCallbackUri;
  pendingCallbackUri = null;
  res.json({ uri });
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ status: 'ok', port: PORT }));

// ─── Serve Flutter Web Build at http://localhost:4000 ─────────────────────────
const flutterWebDir = path.join(__dirname, '..', 'dabi_lab3', 'build', 'web');
app.use(express.static(flutterWebDir));

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🏦  Yapily proxy & PFM server running on http://localhost:${PORT}`);
  console.log(`   GET  http://localhost:${PORT}/api/pfm/summary`);
  console.log(`   GET  http://localhost:${PORT}/proxy/institutions`);
  console.log(`   POST http://localhost:${PORT}/proxy/auth-request`);
  console.log(`   POST http://localhost:${PORT}/proxy/exchange-token`);
  console.log(`   GET  http://localhost:${PORT}/proxy/accounts`);
  console.log(`   GET  http://localhost:${PORT}/proxy/accounts/:id/transactions`);
  console.log(`   GET  http://localhost:${PORT}/proxy/consent/:consentId\n`);
});
