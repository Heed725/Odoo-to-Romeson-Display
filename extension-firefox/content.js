(() => {
  let lastValue = null;
  let timer = null;

  // The extension is injected only on /pos/ui routes, but keep this guard in
  // case a browser restores the script after an Odoo single-page navigation.
  if (!/^\/pos\/ui(?:\/|$)/.test(window.location.pathname)) return;

  const moneyPattern = /[-+]?\d[\d\s.,'\u00a0]*/g;
  const totalLabel = /^(total|jumla|amount due|remaining|to pay|balance|grand total)$/i;

  function parseNumber(text) {
    if (!text) return null;
    const matches = String(text).match(moneyPattern) || [];

    for (let i = matches.length - 1; i >= 0; i -= 1) {
      let raw = matches[i].replace(/[\s'\u00a0]/g, "");
      if (!raw || !/\d/.test(raw)) continue;

      const comma = raw.lastIndexOf(",");
      const dot = raw.lastIndexOf(".");
      const separator = Math.max(comma, dot);

      if (comma >= 0 && dot >= 0) {
        const decimal = separator === comma ? "," : ".";
        const thousands = decimal === "," ? /\./g : /,/g;
        raw = raw.replace(thousands, "").replace(decimal, ".");
      } else if (separator >= 0) {
        const mark = raw[separator];
        const decimals = raw.length - separator - 1;
        const occurrences = raw.split(mark).length - 1;

        if (decimals === 1 || decimals === 2) {
          raw = raw.slice(0, separator).replace(/[.,]/g, "") + "." + raw.slice(separator + 1);
        } else {
          // A single group of three digits, or repeated groups, is a
          // thousands separator in the Odoo currencies that omit decimals.
          raw = raw.replace(/[.,]/g, "");
        }

        if (occurrences > 1 && decimals <= 2) {
          const last = raw.lastIndexOf(".");
          raw = last >= 0
            ? raw.slice(0, last).replace(/\./g, "") + raw.slice(last)
            : raw;
        }
      }

      const value = Number(raw);
      if (Number.isFinite(value) && value >= 0) return value;
    }
    return null;
  }

  function isVisible(element) {
    return Boolean(element && (element.offsetWidth || element.offsetHeight || element.getClientRects().length));
  }

  function valueFromElement(element) {
    for (const attribute of ["amount", "data-amount", "data-value"]) {
      const value = parseNumber(element.getAttribute?.(attribute));
      if (value !== null) return value;
    }
    return parseNumber(element.innerText || element.textContent);
  }

  function amountFromSelectors() {
    // Ordered from the most specific standard Odoo selectors to older
    // selectors retained for Odoo 14-18 and common custom POS themes.
    const selectors = [
      ".product-screen .order-summary .total",
      ".order-summary .total",
      ".payment-screen .payment-status-amount .amount",
      ".payment-status-amount .amount",
      ".payment-status-total-due",
      ".payment-status-remaining",
      ".pos-receipt .pos-receipt-amount",
      ".pos-receipt-amount"
    ];

    for (const selector of selectors) {
      for (const element of document.querySelectorAll(selector)) {
        if (!isVisible(element)) continue;
        const value = valueFromElement(element);
        if (value !== null) return value;
      }
    }
    return null;
  }

  function amountFromLabel() {
    const elements = document.querySelectorAll("span,div,label");
    for (const element of elements) {
      const label = (element.textContent || "").trim();
      if (!isVisible(element) || !totalLabel.test(label)) continue;

      const candidates = [
        element.nextElementSibling,
        element.parentElement,
        element.parentElement?.parentElement
      ].filter(Boolean);

      for (const candidate of candidates) {
        const value = valueFromElement(candidate);
        if (value !== null) return value;
      }
    }
    return null;
  }

  function normalizeForLED8(value) {
    if (value >= 1000000) return String(Math.round(value));
    return value.toFixed(2);
  }

  function scan() {
    timer = null;
    const amount = amountFromSelectors() ?? amountFromLabel();
    if (amount === null) return;

    const value = normalizeForLED8(amount);
    if (value === lastValue) return;

    chrome.runtime.sendMessage({ type: "display", value }, response => {
      if (chrome.runtime.lastError || !response?.ok) return;
      lastValue = value;
    });
  }

  function scheduleScan() {
    if (timer) clearTimeout(timer);
    timer = setTimeout(scan, 180);
  }

  const observer = new MutationObserver(scheduleScan);
  observer.observe(document.documentElement, {
    subtree: true,
    childList: true,
    characterData: true
  });

  setInterval(scan, 1500);
  scheduleScan();
})();
