import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root

  moduleName: "rajaniraiyn.unified-share"
  ipcTarget: "rajaniraiyn.unified-share"
  manageIpc: false

  property var adapters: []
  property string coreVersion: ""
  property string errorText: ""
  property string noticeText: ""
  property bool loading: false

  readonly property string helperPath: {
    var value = String(Qt.resolvedUrl("bin/omarchy-unified-sharectl"))
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool busy: loading || actionProc.running
  readonly property int readyCount: Model.readyCount(adapters)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (statusProc.running) return
    loading = true
    errorText = ""
    statusProc.resultText = ""
    statusProc.errorResult = ""
    statusProc.command = [helperPath, "status"]
    statusProc.running = true
  }

  function runAction(action) {
    if (busy || readyCount === 0) return
    errorText = ""
    noticeText = ""
    actionProc.resultText = ""
    actionProc.errorResult = ""
    actionProc.command = [helperPath, action]
    actionProc.running = true
  }

  function updateStatus(raw) {
    var status = Model.parseStatus(raw)
    if (!status.ok) {
      adapters = []
      errorText = "Could not read Unified Share status"
      return
    }
    adapters = status.adapters
    coreVersion = status.version
  }

  onOpenedChanged: if (opened) refresh()

  IpcHandler {
    target: "rajaniraiyn.unified-share"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
  }

  Process {
    id: statusProc
    property string resultText: ""
    property string errorResult: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: statusProc.resultText = text
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: statusProc.errorResult = text.trim()
    }
    onExited: function(code) {
      if (statusProc.resultText !== "") root.updateStatus(statusProc.resultText)
      if (code !== 0 && root.adapters.length === 0)
        root.errorText = statusProc.errorResult !== ""
          ? statusProc.errorResult : "Unified Share core is not installed"
      root.loading = false
    }
  }

  Process {
    id: actionProc
    property string resultText: ""
    property string errorResult: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: actionProc.resultText = text
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: actionProc.errorResult = text.trim()
    }
    onExited: function(code) {
      if (actionProc.resultText !== "") {
        try {
          var payload = JSON.parse(actionProc.resultText)
          if (payload.ok) root.noticeText = payload.message || "Share opened"
          else root.errorText = payload.message || "Could not share"
        } catch (error) {
          if (code !== 0) root.errorText = "Invalid response from Unified Share"
        }
      }
      if (code !== 0 && root.errorText === "" && actionProc.errorResult !== "")
        root.errorText = actionProc.errorResult
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "⇄"
    tooltipText: "Unified Share"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton && root.opened) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    centerOnBar: true
    contentWidth: panel.fittedContentWidth(Style.space(620))
    contentHeight: panel.cappedContentHeight(Style.space(540))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "r" || text === "R") root.refresh()
      }

      Column {
        anchors.fill: parent
        spacing: Style.space(14)

        PanelHero {
          id: hero
          width: parent.width
          title: "Unified Share"
          meta: root.loading ? "Checking available routes"
            : root.readyCount + " ready route" + (root.readyCount === 1 ? "" : "s")
          detail: root.coreVersion === "" ? "" : "v" + root.coreVersion
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "⇄"
              color: hero.foreground
              font.family: hero.fontFamily
              font.pixelSize: Style.font.display
              font.bold: true
            }
          }
          trailingControl: Component {
            Button {
              iconText: "󰑐"
              iconSpinning: root.loading
              tooltipText: root.loading ? "Checking routes" : "Refresh (R)"
              foreground: hero.foreground
              fontFamily: hero.fontFamily
              bordered: true
              enabled: !root.busy
              onClicked: root.refresh()
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: "Share files"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !root.busy && root.readyCount > 0
            onClicked: root.runAction("share-file")
          }
          Button {
            Layout.fillWidth: true
            text: "Share folder"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !root.busy && root.readyCount > 0
            onClicked: root.runAction("share-folder")
          }
          Button {
            Layout.fillWidth: true
            text: "Clipboard"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !root.busy && root.readyCount > 0
            onClicked: root.runAction("share-clipboard")
          }
        }

        Text {
          width: parent.width
          visible: root.noticeText !== ""
          text: root.noticeText
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.Wrap
        }

        Text {
          width: parent.width
          visible: root.errorText !== ""
          text: root.errorText
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.Wrap
        }

        Text {
          text: "AVAILABLE ROUTES"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: root.adapters

            BorderSurface {
              required property var modelData
              width: parent.width
              implicitHeight: adapterRow.implicitHeight + Style.space(20)
              color: "transparent"
              borderSpec: Border.controlSpec("normal", root.foreground, root.accent)
              radius: Style.cornerRadius

              RowLayout {
                id: adapterRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(10)
                spacing: Style.space(12)

                Column {
                  Layout.fillWidth: true
                  spacing: Style.space(2)

                  Text {
                    text: String(modelData.name || "Unknown route")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                  Text {
                    width: parent.width
                    text: String(modelData.detail || "")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                  }
                }

                Text {
                  text: Model.stateLabel(modelData.state)
                  color: Model.stateColor(modelData.state, root.foreground, root.accent, root.urgent)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }
              }
            }
          }
        }
      }
    }
  }
}
