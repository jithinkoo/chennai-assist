// Browser alerts for the admin: a short sound, a desktop notification and a
// flashing tab title whenever the server pushes an "admin-alert" event
// (new chat, new visitor message, new question).

let audioCtx = null
let unread = 0
let baseTitle = document.title
let flashTimer = null

function beep() {
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)()
    if (audioCtx.state === "suspended") audioCtx.resume()
    // Two short rising tones.
    ;[[880, 0], [1320, 0.18]].forEach(([freq, at]) => {
      const osc = audioCtx.createOscillator()
      const gain = audioCtx.createGain()
      osc.type = "sine"
      osc.frequency.value = freq
      gain.gain.setValueAtTime(0.0001, audioCtx.currentTime + at)
      gain.gain.exponentialRampToValueAtTime(0.25, audioCtx.currentTime + at + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + at + 0.16)
      osc.connect(gain).connect(audioCtx.destination)
      osc.start(audioCtx.currentTime + at)
      osc.stop(audioCtx.currentTime + at + 0.17)
    })
  } catch (_e) { /* sound is best-effort */ }
}

function flashTitle(text) {
  unread += 1
  if (flashTimer) return
  let on = false
  flashTimer = setInterval(() => {
    on = !on
    document.title = on ? `🔔 (${unread}) ${text}` : baseTitle
  }, 1000)
}

function stopFlash() {
  unread = 0
  if (flashTimer) clearInterval(flashTimer)
  flashTimer = null
  document.title = baseTitle
}

function permission() {
  return "Notification" in window ? Notification.permission : "unsupported"
}

function updateStatus() {
  const el = document.getElementById("browser-alert-status")
  if (!el) return
  const p = permission()
  el.textContent =
    p === "granted" ? "on (sound + notifications)" :
    p === "denied" ? "notifications blocked in this browser: allow them in the site settings (sound still works)" :
    p === "unsupported" ? "this browser has no notifications (sound still works)" :
    "not enabled yet: click Enable browser alerts"
}

export function setupAdminAlerts() {
  window.addEventListener("phx:admin-alert", ({detail}) => {
    beep()
    if (document.hidden || !document.hasFocus()) flashTitle(detail.title)
    if (permission() === "granted") {
      const n = new Notification(detail.title, {body: detail.body, tag: detail.url, renotify: true})
      n.onclick = () => { window.focus(); window.location.href = detail.url; n.close() }
    }
  })

  window.addEventListener("focus", stopFlash)
  document.addEventListener("visibilitychange", () => { if (!document.hidden) stopFlash() })

  // Permission must be requested from a click; this also unlocks sound.
  document.addEventListener("click", e => {
    if (!e.target.closest("[data-enable-alerts]")) return
    beep()
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission().then(updateStatus)
    } else {
      updateStatus()
    }
  })

  window.addEventListener("phx:page-loading-stop", () => { baseTitle = document.title; updateStatus() })
  updateStatus()
}
