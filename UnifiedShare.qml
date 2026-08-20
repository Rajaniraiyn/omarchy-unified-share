import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property string deviceName: ""
  property string coreVersion: ""
  property var historyEntries: []
  property string errorText: ""
  property bool loading: false

  readonly property string helperPath: {
    var value = String(Qt.resolvedUrl("bin/omarchy-unified-sharectl"))
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }
  readonly property string providerPath: {
    var value = String(Qt.resolvedUrl("bin/omarchy-unified-share"))
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }
  readonly property color foreground: Color.popups.text
  readonly property color urgent: Color.urgent
  readonly property string fontFamily: Style.font.family
  readonly property bool busy: statusProc.running || historyProc.running

  function open(payloadJson) {
    opened = true
    refresh()
    Qt.callLater(function() { if (root.opened) keyCatcher.forceActiveFocus() })
  }

  function close() { opened = false }

  function dismiss() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "rajaniraiyn.unified-share")
    else close()
  }

  function refresh() {
    if (busy) return
    loading = true
    errorText = ""
    statusProc.resultText = ""
    statusProc.command = [helperPath, "status"]
    statusProc.running = true
    historyProc.resultText = ""
    historyProc.command = [helperPath, "history"]
    historyProc.running = true
  }

  function launch(action) {
    dismiss()
    launchProc.command = [providerPath, "share", action]
    launchProc.running = true
  }

  Process {
    id: statusProc
    property string resultText: ""
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: statusProc.resultText = text }
    onExited: function(code) {
      if (code !== 0) root.errorText = "Unified Share core is not installed"
      else {
        try {
          var payload = JSON.parse(statusProc.resultText)
          root.deviceName = String(payload.device_name || "Omarchy")
          root.coreVersion = String(payload.version || "")
        } catch (error) { root.errorText = "Could not read Unified Share settings" }
      }
      root.loading = statusProc.running || historyProc.running
    }
  }

  Process {
    id: historyProc
    property string resultText: ""
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: historyProc.resultText = text }
    onExited: function(code) {
      if (code === 0) {
        try { root.historyEntries = JSON.parse(historyProc.resultText).entries || [] }
        catch (error) { root.historyEntries = [] }
      }
      root.loading = statusProc.running || historyProc.running
    }
  }

  Process { id: launchProc }
  Process { id: settingsProc; onExited: function(code) { if (code === 0 && root.opened) root.refresh() } }

  FloatingWindow {
    id: window
    title: "Omarchy Unified Share"
    visible: root.opened
    color: Color.popups.background
    implicitWidth: 760
    implicitHeight: 540
    minimumSize: Qt.size(640, 460)

    onVisibleChanged: if (!visible && root.opened) root.dismiss()

    FocusScope {
      anchors.fill: parent
      focus: true

      PanelKeyCatcher {
        id: keyCatcher
        anchors.fill: parent
        anchors.margins: Style.spacing.popupPadding
        onCloseRequested: root.dismiss()
        onTextKey: function(text) { if (text === "r" || text === "R") root.refresh() }

        Column {
          anchors.fill: parent
          spacing: Style.space(14)

          PanelHero {
            id: hero
            width: parent.width
            title: "Unified Share"
            meta: "Share through the best available route"
            detail: root.coreVersion === "" ? "" : "v" + root.coreVersion
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text { text: "⇄"; color: hero.foreground; font.family: hero.fontFamily; font.pixelSize: Style.font.display; font.bold: true }
            }
            trailingControl: Component {
              Button {
                iconText: "󰑐"
                iconSpinning: root.loading
                tooltipText: root.loading ? "Reading sharing state" : "Refresh (R)"
                foreground: hero.foreground
                fontFamily: hero.fontFamily
                bordered: true
                enabled: !root.busy
                onClicked: root.refresh()
              }
            }
          }

          BorderSurface {
            width: parent.width
            implicitHeight: identityRow.implicitHeight + Style.space(20)
            color: Util.alpha(root.foreground, 0.04)
            borderSpec: Border.controlSpec("normal", root.foreground, root.foreground)
            radius: Style.cornerRadius

            RowLayout {
              id: identityRow
              anchors.fill: parent
              anchors.margins: Style.space(10)
              spacing: Style.space(12)
              Column {
                Layout.fillWidth: true
                spacing: Style.space(2)
                Text { text: "THIS COMPUTER"; color: root.foreground; opacity: 0.62; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1.1 }
                Text { text: root.deviceName || "Omarchy"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
              }
              Button {
                text: "Rename"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: { settingsProc.command = [root.providerPath, "device-name"]; settingsProc.running = true }
              }
            }
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(8)
            Button { Layout.fillWidth: true; text: "Share files"; iconText: ""; bordered: true; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.launch("file") }
            Button { Layout.fillWidth: true; text: "Share folder"; iconText: ""; bordered: true; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.launch("folder") }
            Button { Layout.fillWidth: true; text: "Clipboard"; iconText: ""; bordered: true; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.launch("clipboard") }
          }

          RowLayout {
            width: parent.width
            Text { Layout.fillWidth: true; text: "RECENT TRANSFERS"; color: root.foreground; opacity: 0.62; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 1.1 }
            Button {
              text: "View all"
              bordered: false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: { launchProc.command = [root.providerPath, "history"]; launchProc.running = true }
            }
          }

          Text {
            width: parent.width
            visible: !root.loading && root.historyEntries.length === 0
            text: "No transfers yet. History stays on this computer and never stores file paths."
            color: root.foreground
            opacity: 0.62
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            Repeater {
              model: root.historyEntries.slice(0, 4)
              BorderSurface {
                required property var modelData
                width: parent.width
                implicitHeight: recentRow.implicitHeight + Style.space(14)
                color: "transparent"
                borderSpec: Border.controlSpec("normal", root.foreground, root.foreground)
                radius: Style.cornerRadius
                RowLayout {
                  id: recentRow
                  anchors.fill: parent
                  anchors.margins: Style.space(7)
                  spacing: Style.space(10)
                  Text { text: String(modelData.outcome) === "completed" ? "󰄬" : "󰅙"; color: String(modelData.outcome) === "completed" ? root.foreground : root.urgent; font.family: root.fontFamily; font.pixelSize: Style.font.body }
                  Text { Layout.fillWidth: true; text: String(modelData.target) + "  ·  " + Number(modelData.item_count) + " item(s)"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight }
                  Text { text: String(modelData.route).replace(/_/g, " ").toUpperCase(); color: root.foreground; opacity: 0.55; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
                }
              }
            }
          }

          Text { width: parent.width; visible: root.errorText !== ""; text: root.errorText; color: root.urgent; font.family: root.fontFamily; font.pixelSize: Style.font.body; wrapMode: Text.WordWrap }
        }
      }
    }
  }
}
