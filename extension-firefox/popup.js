const status = document.getElementById("status");

function send(message) {
  status.textContent = "Working…";
  chrome.runtime.sendMessage(message, response => {
    if (chrome.runtime.lastError || !response?.ok) {
      status.textContent = `Not connected: ${response?.error || chrome.runtime.lastError?.message || "unknown error"}`;
      return;
    }
    status.textContent = `Connected: ${response.port || "COM2"} at ${response.baud || "2400"} baud`;
  });
}

document.getElementById("test").addEventListener("click", () => send({ type: "display", value: "25000.00" }));
document.getElementById("clear").addEventListener("click", () => send({ type: "clear" }));
send({ type: "health" });
