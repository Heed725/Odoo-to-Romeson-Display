const BRIDGE = "http://127.0.0.1:8765";

async function bridgeRequest(path) {
  const response = await fetch(`${BRIDGE}${path}`, { cache: "no-store" });
  if (!response.ok) throw new Error(`Bridge returned HTTP ${response.status}`);
  return response.json();
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  let request;
  if (message?.type === "display" && /^\d+(\.\d+)?$/.test(String(message.value))) {
    request = bridgeRequest(`/display?value=${encodeURIComponent(message.value)}`);
  } else if (message?.type === "clear") {
    request = bridgeRequest("/clear");
  } else if (message?.type === "health") {
    request = bridgeRequest("/health");
  } else {
    sendResponse({ ok: false, error: "Invalid request" });
    return false;
  }

  request.then(sendResponse).catch(error => sendResponse({ ok: false, error: error.message }));
  return true;
});
