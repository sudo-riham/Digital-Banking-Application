'use strict';

// ─────────────────────────────────────────────────────────────────────────────
// server/pfmService.js
//
// Personal Financial Management (PFM) Enrichment & Analytics Service.
// 1. Classifies raw Yapily transactions into standard PFM categories:
//    - Income
//    - Housing & Utilities
//    - Groceries
//    - Dining
//    - Subscriptions
//    - Transport
//    - Shopping
//    - Uncategorized
// 2. Aggregates multi-account balances, cash flow, category spend breakdown,
//    recurring bills/subscriptions, and enriched transactions.
// ─────────────────────────────────────────────────────────────────────────────

const fs   = require('fs');
const path = require('path');

const BUDGETS_FILE = path.join(__dirname, 'budgets.json');

const DEFAULT_BUDGETS = {
  'Housing & Utilities': 15000.0,
  'Groceries': 3200.0,
  'Dining': 1500.0,
  'Subscriptions': 250.0,
  'Transport': 1200.0,
  'Shopping': 500.0,
  'Uncategorized': 50000.0,
};

function getBudgets() {
  try {
    if (fs.existsSync(BUDGETS_FILE)) {
      const raw = fs.readFileSync(BUDGETS_FILE, 'utf8');
      const parsed = JSON.parse(raw);
      return { ...DEFAULT_BUDGETS, ...parsed };
    }
  } catch (err) {
    console.warn('[PFM Budgets] Could not read budgets.json:', err.message);
  }
  return { ...DEFAULT_BUDGETS };
}

function saveBudgets(updatedBudgets) {
  const merged = { ...getBudgets() };
  for (const [key, val] of Object.entries(updatedBudgets || {})) {
    const num = Number(val);
    if (!Number.isNaN(num) && num >= 0) {
      merged[key] = Number(num.toFixed(2));
    }
  }
  try {
    fs.writeFileSync(BUDGETS_FILE, JSON.stringify(merged, null, 2), 'utf8');
  } catch (err) {
    console.warn('[PFM Budgets] Could not write budgets.json:', err.message);
  }
  return merged;
}

const PFM_CATEGORIES = [
  'Income',
  'Housing & Utilities',
  'Groceries',
  'Dining',
  'Subscriptions',
  'Transport',
  'Shopping',
  'Uncategorized',
];

/**
 * Extracts a signed numeric amount from a raw Yapily transaction object.
 */
function extractSignedAmount(tx) {
  let raw = 0;
  if (typeof tx.amount === 'number') {
    raw = tx.amount;
  } else if (tx.amount && typeof tx.amount.amount === 'number') {
    raw = tx.amount.amount;
  } else if (tx.transactionAmount && typeof tx.transactionAmount.amount === 'number') {
    raw = tx.transactionAmount.amount;
  }

  const indicator = (tx.creditDebitIndicator || '').toUpperCase();
  const propCode  = (tx.proprietaryBankTransactionCode?.code || '').toUpperCase();

  if (raw > 0 && (indicator === 'DEBIT' || propCode === 'DEBIT')) {
    return -Math.abs(raw);
  }
  return raw;
}

/**
 * Extracts the currency string from a raw Yapily transaction object.
 */
function extractCurrency(tx, fallback = 'GBP') {
  if (typeof tx.currency === 'string' && tx.currency) return tx.currency;
  if (tx.transactionAmount?.currency) return tx.transactionAmount.currency;
  if (tx.amount?.currency) return tx.amount.currency;
  return fallback;
}

/**
 * Extracts a normalized description string from a raw Yapily transaction.
 */
function extractDescription(tx) {
  if (typeof tx.description === 'string' && tx.description.trim()) {
    return tx.description.trim();
  }
  if (Array.isArray(tx.transactionInformation) && tx.transactionInformation.length > 0) {
    return tx.transactionInformation.join(' ').trim();
  }
  if (typeof tx.transactionInformation === 'string' && tx.transactionInformation.trim()) {
    return tx.transactionInformation.trim();
  }
  if (typeof tx.transactionReference === 'string' && tx.transactionReference.trim()) {
    return tx.transactionReference.trim();
  }
  return 'Transaction';
}

/**
 * Extracts merchant name if present, or derives a clean merchant label from description.
 */
function extractMerchantName(tx) {
  const mName = tx.merchant?.merchantName || tx.merchant?.name || '';
  if (typeof mName === 'string' && mName.trim() && mName.toLowerCase() !== 'slacker') {
    return mName.trim();
  }
  return extractDescription(tx);
}

/**
 * Categorizes a raw Yapily transaction into one of the 8 standard PFM categories:
 *   Income, Housing & Utilities, Groceries, Dining, Subscriptions,
 *   Transport, Shopping, Uncategorized
 */
function categorizeTransaction(tx) {
  const signedAmount = extractSignedAmount(tx);
  const description  = extractDescription(tx);
  const merchantName = tx.merchant?.merchantName || tx.merchant?.name || '';
  const mcc          = String(tx.merchant?.merchantCategoryCode || '').toUpperCase();

  const isoDomain    = (tx.isoBankTransactionCode?.domainCode?.code || '').toUpperCase();
  const isoFamily    = (tx.isoBankTransactionCode?.familyCode?.code || '').toUpperCase();
  const isoSubFamily = (tx.isoBankTransactionCode?.subFamilyCode?.code || '').toUpperCase();
  const propCode     = (tx.proprietaryBankTransactionCode?.code || '').toUpperCase();

  // 1. Income: strictly positive inflows / credits
  if (
    signedAmount > 0 ||
    (signedAmount === 0 && (propCode === 'CREDIT' || isoFamily === 'RCHQ' || isoSubFamily === 'SALA'))
  ) {
    return 'Income';
  }

  const searchText = `${description} ${merchantName} ${mcc}`.toUpperCase();

  // 2. Subscriptions: SaaS, streaming, memberships, recurring digital services
  if (
    /\b(NETFLIX|SPOTIFY|APPLE\.COM\/BILL|AMAZON PRIME|PRIME VIDEO|DISNEY|YOUTUBE|XERO|WWW\.XERO\.COM|ELEGANT THEMES|ROCKET LAWYER|ADOBE|MICROSOFT|GITHUB|OPENAI|CHATGPT|SUBSCRIPTION|MEMBERSHIP|AUDIBLE|ICLOUD|GOOGLE ONE|PATREON|GYM|PUREGYM)\b/.test(
      searchText
    )
  ) {
    return 'Subscriptions';
  }

  // 3. Dining: coffee shops, restaurants, bars, wine, food delivery (check Uber Eats before Uber!)
  if (
    /\b(UBER EATS|DELIVEROO|JUST EAT|COSTA COFFEE|COSTA|STARBUCKS|PRET A MANGER|PRET|CAFFE NERO|GREGGS|MCDONALD|KFC|BURGER KING|NANDO|PIZZA|DOMINO|WAGAMAMA|RESTAURANT|CAFE|COFFEE|PAVILION WINE|WINE|PUB\b|BAR\b|BISTRO|DINING|BAKERY)\b/.test(
      searchText
    ) ||
    /^(5811|5812|5813|5814)$/.test(mcc)
  ) {
    return 'Dining';
  }

  // 4. Transport: public transit (TfL), taxis, Uber, flights, rail, fuel, hotels/travel
  if (
    /\b(TFL\.GOV\.UK|TFL TRAVEL|TFL|LONDON TAXI|TAXI|UBER|BOLT|LYFT|TRAINLINE|NATIONAL RAIL|LNER|GWR|EASYJET|RYANAIR|BRITISH AIRWAYS|SHELL|BP\b|ESSO|TEXACO|PETROL|FUEL|PARKING|RINGGO|DELTA HOTEL|HOTEL|AIRBNB|BOOKING\.COM|TRAVEL)\b/.test(
      searchText
    ) ||
    /^(4111|4112|4121|4131|5541|5542|7011)$/.test(mcc)
  ) {
    return 'Transport';
  }

  // 5. Groceries: supermarkets, food stores, coffee capsules/pantry
  if (
    /\b(TESCO|SAINSBURY|ASDA|MORRISONS|WAITROSE|ALDI|LIDL|MARKS & SPENCER|M&S|OCADO|CO-OP|WHOLE FOODS|SUPERMARKET|GROCER|GROCERIES|ICELAND|SPAR|NESPRESSO)\b/.test(
      searchText
    ) ||
    /^(5411|5422|5441|5451|5462|5499)$/.test(mcc)
  ) {
    return 'Groceries';
  }

  // 6. Housing & Utilities: telecom (BT), energy (OVO, Octopus, etc.), water, rent, mortgage, council tax, direct debit bills
  if (
    /\b(OVO ENERGY|OVO\b|BT PLC|BT MOBILE|BRITISH TELECOM|VODAFONE|VIRGIN MEDIA|SKY\b|OCTOPUS ENERGY|BRITISH GAS|EDF|E\.ON|SCOTTISH POWER|THAMES WATER|WATER|ELECTRIC|GAS\b|COUNCIL TAX|RENT|MORTGAGE|UTILITY|UTILITIES|BROADBAND|INSURANCE|HOUSING)\b/.test(
      searchText
    ) ||
    /^(4814|4899|4900|6513)$/.test(mcc) ||
    (isoDomain === 'PMNT' && isoFamily === 'IDDT' && !/\b(PAYROLL)\b/.test(searchText))
  ) {
    return 'Housing & Utilities';
  }

  // 7. Shopping: retail, stationery, clothing, electronics, department stores
  if (
    /\b(JONES STATIONERY|STATIONERY|AMAZON|AMZN|ARGOS|JOHN LEWIS|SELFRIDGES|HARRODS|ZARA|H&M|UNIQLO|ASOS|NIKE|ADIDAS|APPLE STORE|CURRYS|IKEA|BOOTS|SUPERDRUG|WHSMITH|WATERSTONES|EBAY|ETSY|SHOP|RETAIL)\b/.test(
      searchText
    ) ||
    /^(5311|5651|5691|5732|5942|5943|5999)$/.test(mcc)
  ) {
    return 'Shopping';
  }

  // 8. Fallback
  return 'Uncategorized';
}

/**
 * Normalizes a merchant/description key to group recurring bills & subscriptions.
 */
function normalizeMerchantKey(rawLabel) {
  return rawLabel
    .toUpperCase()
    .replace(/\b(0800\d+|SW1X|E1|RH6|USD|GBP|EUR|INET|GATWICK|LONDON|UK|PLC|LTD|LIMITED)\b/g, '')
    .replace(/[^A-Z0-9]+/g, ' ')
    .trim();
}

/**
 * Enriches raw transactions and builds the full PFM summary response.
 *
 * @param {Array<{account: Object, transactions: Array<Object>}>} accountBundles
 * @returns {Object} PfmSummary payload
 */
function buildPfmSummary(accountBundles) {
  let totalNetWorth = 0;
  let primaryCurrency = 'GBP';

  const allEnriched = [];
  const seenTxKeys = new Set();

  for (const bundle of accountBundles) {
    const acc = bundle.account || {};
    const accBalance =
      typeof acc.balance === 'number'
        ? acc.balance
        : acc.accountBalances?.[0]?.balanceAmount?.amount ?? 0;

    totalNetWorth += Number(accBalance) || 0;
    if (acc.currency) {
      primaryCurrency = acc.currency;
    }

    const rawTxList = Array.isArray(bundle.transactions) ? bundle.transactions : [];
    for (const rawTx of rawTxList) {
      const signedAmount = extractSignedAmount(rawTx);
      const currency     = extractCurrency(rawTx, acc.currency || primaryCurrency);
      const description  = extractDescription(rawTx);
      const merchantName = extractMerchantName(rawTx);
      const dateStr      =
        rawTx.bookingDateTime || rawTx.date || rawTx.valueDateTime || new Date().toISOString();

      // Deduplicate identical mock transactions if multiple mock accounts mirror the same feed
      const dedupKey = `${rawTx.id || ''}_${dateStr}_${signedAmount}_${description}`;
      if (seenTxKeys.has(dedupKey)) {
        continue;
      }
      seenTxKeys.add(dedupKey);

      const pfmCategory = categorizeTransaction(rawTx);

      allEnriched.push({
        id: rawTx.id || dedupKey,
        accountId: acc.id || '',
        accountName: acc.nickname || acc.type || 'Account',
        date: dateStr,
        description,
        merchantName,
        amount: Number(signedAmount.toFixed(2)),
        currency,
        isCredit: signedAmount > 0,
        status: rawTx.status || 'BOOKED',
        pfmCategory,
        isoBankTransactionCode: rawTx.isoBankTransactionCode || null,
        proprietaryBankTransactionCode: rawTx.proprietaryBankTransactionCode || null,
      });
    }
  }

  // Sort enriched transactions newest first
  allEnriched.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  // Compute monthly cash flow (inflow, outflow, netSavings)
  let totalInflow = 0;
  let totalOutflow = 0;

  for (const tx of allEnriched) {
    if (tx.amount > 0) {
      totalInflow += tx.amount;
    } else if (tx.amount < 0) {
      totalOutflow += Math.abs(tx.amount);
    }
  }

  totalNetWorth = Number(totalNetWorth.toFixed(2));
  totalInflow   = Number(totalInflow.toFixed(2));
  totalOutflow  = Number(totalOutflow.toFixed(2));
  const netSavings = Number((totalInflow - totalOutflow).toFixed(2));

  // Compute category breakdown across spending categories
  const categoryStats = new Map();
  for (const cat of PFM_CATEGORIES) {
    categoryStats.set(cat, { totalSpent: 0, transactionCount: 0 });
  }

  for (const tx of allEnriched) {
    const entry = categoryStats.get(tx.pfmCategory) || { totalSpent: 0, transactionCount: 0 };
    if (tx.pfmCategory === 'Income') {
      entry.totalSpent += Math.abs(tx.amount);
      entry.transactionCount += 1;
    } else if (tx.amount < 0) {
      entry.totalSpent += Math.abs(tx.amount);
      entry.transactionCount += 1;
    }
    categoryStats.set(tx.pfmCategory, entry);
  }

  const categoryBreakdown = [];
  for (const [category, stats] of categoryStats.entries()) {
    // Spending breakdown tracks expense categories so percentages sum to 100% of totalOutflow
    if (category === 'Income') continue;
    const spent = Number(stats.totalSpent.toFixed(2));
    const percentage =
      totalOutflow > 0 ? Number(((spent / totalOutflow) * 100).toFixed(1)) : 0.0;

    categoryBreakdown.push({
      category,
      totalSpent: spent,
      percentage,
      transactionCount: stats.transactionCount,
    });
  }

  // Sort spending breakdown highest spend first
  categoryBreakdown.sort((a, b) => b.totalSpent - a.totalSpent);

  // Detect recurring transactions (subscriptions, utility bills, or repeated merchants)
  const merchantGroups = new Map();
  for (const tx of allEnriched) {
    if (tx.amount >= 0) continue; // only outgoing bills/subscriptions
    const rawLabel = tx.merchantName || tx.description;
    // Skip generic P2P cash transfers or bank fee lines when detecting recurring bills/subscriptions
    if (/^(CASH TO\b|OTHER$|NON-STERLING|TOTAL CHARGES)/i.test(rawLabel.trim())) {
      continue;
    }

    const key = normalizeMerchantKey(rawLabel);
    if (!key) continue;

    if (!merchantGroups.has(key)) {
      merchantGroups.set(key, []);
    }
    merchantGroups.get(key).push(tx);
  }

  const recurringTransactions = [];
  for (const [, group] of merchantGroups.entries()) {
    const sample = group[0];
    const isDirectDebit =
      sample.isoBankTransactionCode?.familyCode?.code === 'IDDT' ||
      sample.isoBankTransactionCode?.subFamilyCode?.code === 'PMDD';
    const isSubscription = sample.pfmCategory === 'Subscriptions';
    const isHousingUtility = sample.pfmCategory === 'Housing & Utilities';

    if (group.length >= 2 || isSubscription || (isDirectDebit && isHousingUtility)) {
      const sumAbs = group.reduce((acc, item) => acc + Math.abs(item.amount), 0);
      const avgAbs = Number((sumAbs / group.length).toFixed(2));

      recurringTransactions.push({
        merchantName: sample.merchantName || sample.description,
        category: sample.pfmCategory,
        averageAmount: avgAbs,
        lastAmount: Math.abs(sample.amount),
        currency: sample.currency,
        occurrenceCount: group.length,
        frequency: isDirectDebit
          ? 'Monthly Direct Debit'
          : isSubscription
          ? 'Subscription'
          : 'Recurring',
        lastDate: sample.date,
      });
    }
  }

  recurringTransactions.sort((a, b) => b.averageAmount - a.averageAmount);

  return {
    currency: primaryCurrency,
    totalNetWorth,
    accountsCount: accountBundles.length,
    monthlyCashFlow: {
      totalInflow,
      totalOutflow,
      netSavings,
    },
    categoryBreakdown,
    categoryBudgets: getBudgets(),
    recurringTransactions,
    enrichedTransactions: allEnriched,
  };
}

module.exports = {
  PFM_CATEGORIES,
  categorizeTransaction,
  buildPfmSummary,
  getBudgets,
  saveBudgets,
};
