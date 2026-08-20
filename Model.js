.pragma library

function parseStatus(raw) {
  try {
    var payload = JSON.parse(String(raw || "{}"))
    if (Number(payload.schema_version) !== 1 || !(payload.adapters instanceof Array))
      throw new Error("Unsupported status contract")
    return {
      ok: true,
      version: String(payload.version || ""),
      adapters: payload.adapters
    }
  } catch (error) {
    return { ok: false, version: "", adapters: [], error: String(error) }
  }
}

function stateLabel(state) {
  return String(state || "unknown").replace(/_/g, " ").toUpperCase()
}

function stateColor(state, foreground, accent, urgent) {
  if (state === "ready") return accent
  if (state === "experimental") return foreground
  if (state === "unsupported") return urgent
  return Qt.darker(foreground, 1.45)
}

function readyCount(adapters) {
  return (adapters || []).filter(function(adapter) { return adapter.state === "ready" }).length
}

