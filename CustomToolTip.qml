// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15

Rectangle {
    id: tooltip
    width: tooltipText.contentWidth + 20
    height: tooltipText.contentHeight + 10
    color: "#CC000000"
    radius: 5
    visible: false
    z: 9999

    property string text: ""
    property alias containsMouse: mouseArea.containsMouse

    Text {
        id: tooltipText
        anchors.centerIn: parent
        text: tooltip.text
        color: "white"
        font.family: global.fonts.sans
        font.pixelSize: 12
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    function show(x, y, text) {
        tooltip.text = text;
        tooltip.x = x - tooltip.width / 2;
        tooltip.y = y - tooltip.height - 5;
        tooltip.visible = true;
    }

    function hide() {
        tooltip.visible = false;
    }
}
