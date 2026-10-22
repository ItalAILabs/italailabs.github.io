/* UTM campaign capture for the contact form.
   Bounded retention: tags are kept for 30 days, then discarded — long
   enough for realistic campaign attribution, short enough to satisfy
   storage limitation (GDPR). Records are stored as {v, ts} so expiry is
   enforced on every read.
   Consent: capture only runs when the visitor has an active "accept"
   choice (italai_consent, 30-day TTL) — consistent with the site's
   opt-in model. Expiry purging below runs regardless of consent. */
const UTM_KEYS = ["utm_source", "utm_medium", "utm_campaign"];
const TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days
const params = new URLSearchParams(window.location.search);

function read(key) {
  let raw = null;
  try {
    raw = localStorage.getItem(key);
  } catch (e) {
    return null; // storage unavailable
  }
  if (!raw) return null;
  let rec;
  try {
    rec = JSON.parse(raw);
  } catch (e) {
    rec = null;
  }
  if (!rec || typeof rec.v !== "string" || typeof rec.ts !== "number") {
    // Legacy raw value written by an older version (no expiry):
    // do not inherit its indefinite retention.
    try {
      localStorage.removeItem(key);
    } catch (e) {}
    return null;
  }
  if (Date.now() - rec.ts > TTL_MS) {
    try {
      localStorage.removeItem(key);
    } catch (e) {}
    return null;
  }
  return rec.v;
}

// Enforce the 30-day expiry on every visit (purges expired/legacy entries),
// regardless of consent state — minimization applies to everyone.
UTM_KEYS.forEach((key) => read(key));

function consentActive() {
  try {
    const c = JSON.parse(localStorage.getItem("italai_consent") || "null");
    return !!(c && c.choice === "accept" && c.expiry > Date.now());
  } catch (e) {
    return false;
  }
}

const captured = {};
UTM_KEYS.forEach((key) => {
  const value = params.get(key);
  if (value) captured[key] = value;
});

if (Object.keys(captured).length && consentActive()) {
  const now = Date.now();
  UTM_KEYS.forEach((key) => {
    if (captured[key]) {
      try {
        localStorage.setItem(key, JSON.stringify({ v: captured[key], ts: now }));
      } catch (e) {}
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  UTM_KEYS.forEach((key) => {
    const field = document.querySelector(`input[name="${key}"]`);
    if (field) field.value = read(key) || "";
  });
});
