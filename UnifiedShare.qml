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
  property string route: "browser"
  property string shareUrl: ""
  property string transferId: ""
  property string qrPath: ""
  property double expiresAtUnix: 0

  readonly property string helperPath: {
    var value = String(Qt.resolvedUrl("bin/omarchy-unified-sharectl"))
    if (value.indexOf("file://") === 0) value = value.slice(7)
    return decodeURIComponent(value)
  }
  readonly property color foreground: Color.foreground
  readonly property color urgent: Color.urgent
  readonly property string fontFamily: Style.font.family
  readonly property bool busy: loading || actionProc.running || stopProc.running
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
    actionProc.command = [helperPath, action, route]
    actionProc.running = true
  }

  function clearTransfer() {
    shareUrl = ""
    transferId = ""
    qrPath = ""
    expiresAtUnix = 0
  }

  function stopTransfer() {
    if (transferId === "" || stopProc.running) return
    stopProc.resultText = ""
    stopProc.errorResult = ""
    stopProc.command = [helperPath, "stop-transfer", transferId]
    stopProc.running = true
  }

  function copyLink() {
    if (shareUrl === "") return
    copyProc.command = [helperPath, "copy-link", shareUrl]
    copyProc.running = true
    noticeText = "Link copied"
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
          if (payload.ok) {
            root.noticeText = payload.message || "Share opened"
            if (payload.url && payload.transfer_id) {
              root.shareUrl = String(payload.url)
              root.transferId = String(payload.transfer_id)
              root.expiresAtUnix = Number(payload.expires_at_unix || 0)
              root.qrPath = ""
              qrProc.resultText = ""
              qrProc.command = [root.helperPath, "qr-code", root.shareUrl, root.transferId]
              qrProc.running = true
            }
          }
          else root.errorText = payload.message || "Could not share"
        } catch (error) {
          if (code !== 0) root.errorText = "Invalid response from Unified Share"
        }
      }
      if (code !== 0 && root.errorText === "" && actionProc.errorResult !== "")
        root.errorText = actionProc.errorResult
    }
  }


  Process {
    id: qrProc
    property string resultText: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: qrProc.resultText = text.trim()
    }
    onExited: function(code) {
      if (code === 0) root.qrPath = qrProc.resultText
      else root.errorText = "The link is ready, but its QR code could not be generated"
    }
  }

  Process {
    id: copyProc
  }

  Process {
    id: stopProc
    property string resultText: ""
    property string errorResult: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: stopProc.resultText = text
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: stopProc.errorResult = text.trim()
    }
    onExited: function(code) {
      if (code === 0) {
        root.clearTransfer()
        root.noticeText = "Browser link stopped"
      } else {
        root.errorText = stopProc.errorResult !== ""
          ? stopProc.errorResult : "Could not stop the browser link"
      }
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
          spacing: Style.space(10)

          Text {
            text: "ROUTE"
            color: root.foreground
            opacity: 0.65
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Item { Layout.fillWidth: true }

          ButtonGroup {
            options: [
              { value: "browser", label: "Browser / QR", tooltip: "Works on any device on this LAN" },
              { value: "localsend", label: "LocalSend", tooltip: "Use the installed LocalSend app" }
            ]
            value: root.route
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !root.busy
            onChanged: function(value) { root.route = value }
          }
        }

        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: actionProc.running ? "Preparing…" : "Share files"
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
            enabled: !root.busy && root.readyCount > 0 && root.route !== "browser"
            tooltipText: root.route === "browser"
              ? "Choose LocalSend to share a folder" : "Share a folder"
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
          color: root.foreground
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

        BorderSurface {
          width: parent.width
          visible: root.shareUrl !== ""
          implicitHeight: activeTransfer.implicitHeight + Style.space(24)
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
          borderSpec: Border.controlSpec("normal", root.foreground, root.foreground)
          radius: Style.cornerRadius

          RowLayout {
            id: activeTransfer
            anchors.fill: parent
            anchors.margins: Style.space(12)
            spacing: Style.space(16)

            BorderSurface {
              Layout.preferredWidth: Style.space(172)
              Layout.preferredHeight: Style.space(172)
              color: "white"
              radius: Style.space(6)
              borderSpec: Border.flat(Qt.rgba(0, 0, 0, 0.14), 1)

              Image {
                anchors.fill: parent
                anchors.margins: Style.space(8)
                source: root.qrPath === "" ? "" : "file://" + root.qrPath
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: root.qrPath !== ""
              }

              Text {
                anchors.centerIn: parent
                visible: root.qrPath === ""
                text: qrProc.running ? "Creating QR…" : "QR unavailable"
                color: "#111111"
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(8)

              Text {
                text: "BROWSER LINK ACTIVE"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
              }

              Text {
                Layout.fillWidth: true
                text: root.shareUrl
                color: root.foreground
                opacity: 0.72
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                text: "Scan from a device on this Wi-Fi. The private link expires automatically after 10 minutes."
                color: root.foreground
                opacity: 0.65
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }

              RowLayout {
                spacing: Style.space(8)

                Button {
                  text: "Copy link"
                  iconText: "󰆏"
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  enabled: !copyProc.running
                  onClicked: root.copyLink()
                }

                Button {
                  text: stopProc.running ? "Stopping…" : "Stop sharing"
                  iconText: "󰓛"
                  bordered: true
                  foreground: root.urgent
                  fontFamily: root.fontFamily
                  enabled: !stopProc.running
                  onClicked: root.stopTransfer()
                }
              }
            }
          }
        }

        Text {
          visible: root.shareUrl === ""
          text: "AVAILABLE ROUTES"
          color: root.foreground
          opacity: 0.65
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }

        Column {
          visible: root.shareUrl === ""
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: root.adapters

            BorderSurface {
              required property var modelData
              width: parent.width
              implicitHeight: adapterRow.implicitHeight + Style.space(20)
              color: "transparent"
              borderSpec: Border.controlSpec("normal", root.foreground, root.foreground)
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
                    color: root.foreground
                    opacity: 0.65
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
                  }
                }

                Text {
                  text: Model.stateLabel(modelData.state)
                  color: Model.stateColor(modelData.state, root.foreground, root.foreground, root.urgent)
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
