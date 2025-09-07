import QtQuick 2.15

Rectangle {
    id: statBox
    width: parent.width
    height: parent.height
    radius: 10
    color: "#1a1a1a"
    border.color: "#333333"
    border.width: 1

    property string title: ""
    property variant value: ""
    property string icon: ""
    property string iconSource: ""
    property bool useImage: false
    property real iconSize: height * 0.25
    property real valueFontSize: height * 0.3
    property real titleFontSize: height * 0.15

    Column {
        anchors {
            fill: parent
            margins: parent.height * 0.1
        }
        spacing: parent.height * 0.05

        Item {
            width: parent.width
            height: statBox.iconSize
            anchors.horizontalCenter: parent.horizontalCenter

            Loader {
                anchors.centerIn: parent
                sourceComponent: useImage ? imageComponent : textComponent
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: statBox.value
            font.family: global.fonts.sans
            font.pixelSize: statBox.valueFontSize
            font.bold: true
            color: "white"
            elide: Text.ElideRight
            minimumPixelSize: 8
            fontSizeMode: Text.Fit
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: statBox.title.toUpperCase()
            font.family: global.fonts.sans
            font.pixelSize: statBox.titleFontSize
            font.letterSpacing: 1
            color: "#aaaaaa"
            elide: Text.ElideRight
            minimumPixelSize: 6
            fontSizeMode: Text.Fit
        }
    }

    Component {
        id: imageComponent
        Image {
            source: statBox.iconSource
            width: statBox.iconSize
            height: statBox.iconSize
            fillMode: Image.PreserveAspectFit
            mipmap: true
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    Component {
        id: textComponent
        Text {
            text: statBox.icon
            font.pixelSize: statBox.iconSize
            color: "white"
            font.bold: true
        }
    }
}


