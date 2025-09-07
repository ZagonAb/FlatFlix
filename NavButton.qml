// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: navButton
    width: {
        if (isIcon) {
            return height;
        } else if (text !== "") {
            return textItem.contentWidth + (root ? root.width * 0.04 : 30);
        } else {
            return (root ? root.height * 0.05 : 50);
        }
    }
    height: root ? root.height * 0.07 : 60

    property string text: ""
    property bool isIcon: false
    property string iconSource: ""
    property bool isSelected: false
    property bool isFocused: false
    property bool showSelectionIndicator: true
    property var root: null
    signal clicked()

    property color iconColor: getIconColor()

    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: "transparent"
        radius: height / 2
        visible: false
    }

    Image {
        id: icon
        anchors.centerIn: parent
        width: parent.height * 0.7
        height: width
        source: isIcon ? iconSource : ""
        fillMode: Image.PreserveAspectFit
        visible: isIcon
        mipmap: true

        layer.enabled: isIcon
        layer.effect: ColorOverlay {
            color: navButton.iconColor

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: navButton.text
        font.family: global.fonts.sans
        font.pixelSize: parent.height * 0.4
        color: getTextColor()
        visible: !isIcon

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        function getTextColor() {
            if (isSelected && isFocused) {
                return "#000000";
            } else {
                return "#ffffff";
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: navButton.clicked()
    }

    onIsSelectedChanged: {
        updateColors();
    }

    onIsFocusedChanged: {
        updateColors();
    }

    function updateColors() {
        iconColor = getIconColor();
        textItem.color = textItem.getTextColor();
    }

    function getIconColor() {
        if (isSelected && isFocused) {
            return "#000000";
        } else {
            return "#ffffff";
        }
    }
}
