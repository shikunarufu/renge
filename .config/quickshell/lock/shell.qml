import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
  id: root
  property bool failed: false
  
  PamContext {
    id: pam
    configDirectory: Quickshell.shellDir + "/pam"
    config: "password.conf"
    property string password: ""
    
    onResponseRequiredChanged: if (responseRequired) respond(password)
    
    onCompleted: result => {
      password = ""
      if (result === PamResult.Success) {
        lock.locked = false
        Qt.quit()
      } else {
        root.failed = true
      }
    }
  }
  
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
  
  WlSessionLock {
    id: lock
    locked: true
    
    WlSessionLockSurface {
      Rectangle {
        anchors.fill: parent
        color: "#11111b"
        
        Column {
          anchors.centerIn: parent
          spacing: 16
          
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            color: "#cdd6f4"
            font.pixelSize: 72
          }
          
          Rectangle {
            width: 280
            height: 40
            radius: 8
            color: "#1e1e2e"
            border.width: 2
            border.color: root.failed ? "#f38ba8" : "#45475a"
            
            TextInput {
              id: input
              anchors.fill: parent
              anchors.margins: 8
              color: "#cdd6f4"
              font.pixelSize: 18
              echoMode: TextInput.Password
              enabled: !pam.active
              focus: true
              verticalAlignment: TextInput.AlignVCenter
              onTextChanged: root.failed = false
              onAccepted: {
                pam.password = text
                text = ""
                pam.start()
              }
            }
          }
          
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.failed ? "Wrong password" : ""
            color: "#f38ba8"
            font.pixelSize: 14
          }
        }
      }
    }
  }
}
