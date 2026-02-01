const channel = new BroadcastChannel("my_app_channel");

// Unique-ish tab id (for debugging / ignoring your own messages)
const TAB_ID = crypto.randomUUID?.() ?? String(Date.now()) + Math.random();

function onMessage(handler) {
  channel.addEventListener("message", (e) => {
    const msg = e.data;
    if (!msg || msg.sender === TAB_ID) return;
    handler(msg);
  });
}

function send(type, payload) {
  channel.postMessage({
    sender: TAB_ID,
    type,
    payload,
    ts: Date.now(),
  });
}

// optional: cleanup
function close() {
  channel.close();
}