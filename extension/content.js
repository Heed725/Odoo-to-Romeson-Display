(() => {
  let lastValue = null;
  let timer = null;
  let failures = 0;

  const moneyPattern = /(?:TZS|TSh|TSH)?\s*([0-9][0-9,.\s]*)\s*(?:TZS|TSh|TSH)?/gi;
  const totalLabel = /^(total|jumla|amount due|remaining|to pay)$/i;

  function parseNumber(text) {
    if (!text) return null;
    const matches = [...text.matchAll(moneyPattern)];
    for (let i = matches.length - 1; i >= 0; i -= 1) {
      let raw = matches[i][1].replace(/\s/g, "");
      if (!raw) continue;

      if (raw.includes(",") && raw.includes(".")) {
        raw = raw.lastIndexOf(".") > raw.lastIndexOf(",")
          ? raw.replace(/,/g, "")
          : raw.replace(/\./g, "").replace(",", ".");
      } else if (raw.includes(",")) {
        const parts = raw.split(",");
        raw = parts.length === 2 && parts[1].length === 2
          ? `${parts[0]}.${parts[1]}`
          : raw.replace(/,/g, "");
      }

      const value = Number(raw);
      if (Number.isFinite(value) && value >= 0) return value;
    }
    return null;
  }

  function amountFromSelectors() {
    const selectors = [
      ".payment-status-total-due",
      ".payment-status-remaining",
      ".order-summary .total",
      ".order-summary",
      ".pos-receipt-amount",
      ".total"
    ];
    for (const selector of selectors) {
      for (const element of document.querySelectorAll(selector)) {
        if (!element.offsetParent) continue;
        const value = parseNumber(element.innerText);
        if (value !== null) return value;
      }
    }
    return null;
  }

  function amountFromLabel() {
    const elements = document.querySelectorAll("span,div,label");
    for (const element of elements) {
      if (!element.offsetParent || !totalLabel.test(element.textContent.trim())) continue;
      const candidates = [
        element.nextElementSibling,
        element.parentElement,
        element.parentElement?.parentElement
      ].filter(Boolean);
      for (const candidate of candidates) {
        const value = parseNumber(candidate.innerText);
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
    if (amount === null) {
      failures += 1;
      return;
    }
    failures = 0;
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
