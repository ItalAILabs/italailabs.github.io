/* Cookie consent (GDPR, opt-in) — pairs with the GA Consent Mode v2
   bootstrap in _layouts/default.html and #consentBanner markup in
   _includes/consent-banner.html. */
(function () {
  'use strict';

  var KEY = 'italai_consent';
  var TTL_MS = 30 * 24 * 60 * 60 * 1000; // choice re-confirmed every 30 days

  var STATES = {
    accepted: {
      ad_storage: 'granted',
      ad_user_data: 'granted',
      ad_personalization: 'granted',
      analytics_storage: 'granted'
    },
    declined: {
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied'
    }
  };

  function read() {
    try {
      var c = JSON.parse(localStorage.getItem(KEY) || 'null');
      if (c && (c.choice === 'accepted' || c.choice === 'declined') && c.expiry > Date.now()) {
        return c;
      }
      if (c) localStorage.removeItem(KEY); // expired: back to undecided
    } catch (e) { /* storage unavailable: treat as undecided */ }
    return null;
  }

  function write(choice) {
    var now = Date.now();
    try {
      localStorage.setItem(KEY, JSON.stringify({ choice: choice, timestamp: now, expiry: now + TTL_MS }));
    } catch (e) { /* ignore */ }
  }

  function applyGtag(state) {
    if (typeof window.gtag === 'function') {
      window.gtag('consent', 'update', STATES[state]);
    }
  }

  function show(banner) {
    banner.hidden = false;
    requestAnimationFrame(function () {
      banner.classList.add('is-visible');
    });
    // Focus the dialog container, not a button: a programmatic .focus() on
    // the Accept button at page load matches :focus-visible, drawing the
    // focus outline around its gradient border (the "double ring").
    // Focusing the container moves keyboard/SR users into the dialog with
    // no visible ring — first Tab then lands on Accept with the outline.
    banner.tabIndex = -1;
    banner.focus({ preventScroll: true });
  }

  function hide(banner) {
    banner.classList.remove('is-visible');
    setTimeout(function () { banner.hidden = true; }, 250); // matches var(--transition-base)
  }

  document.addEventListener('DOMContentLoaded', function () {
    var banner = document.getElementById('consentBanner');
    var accept = document.getElementById('consentAccept');
    var decline = document.getElementById('consentDecline');
    if (!banner || !accept || !decline) return;

    var state = read();
    if (state) {
      // Safety net: re-apply a stored choice even if the inline bootstrap
      // in <head> did not run before gtag config.
      applyGtag(state.choice);
    } else {
      show(banner);
    }

    accept.addEventListener('click', function () {
      write('accepted');
      applyGtag('accepted');
      hide(banner);
    });

    decline.addEventListener('click', function () {
      write('declined');
      applyGtag('declined');
      hide(banner);
    });

    // Escape declines while the banner is open.
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !banner.hidden) decline.click();
    });
  });
})();
