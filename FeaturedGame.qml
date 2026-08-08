// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: featuredGame

    property var gameData: null
    property var descriptionFunction: null
    property var genreFunction: null
    property bool active: false
    property int buttonIndex: 0
    property int selectionBorderWidth: Style.borderThick

    signal playRequested()
    signal moreInfoRequested()

    visible: gameData !== null

    readonly property int playCount: gameData && gameData.playCount ? gameData.playCount : 0
    readonly property real ratingValue: gameData && gameData.rating ? gameData.rating : 0

    Image {
        id: background
        anchors.fill: parent
        source: {
            if (!gameData || !gameData.assets) return "";
            return gameData.assets.background || gameData.assets.screenshot || "";
        }
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "#141414"
        visible: background.status !== Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: "#050505" }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#D9000000" }
            GradientStop { position: 0.4; color: "#73000000" }
            GradientStop { position: 0.7; color: "transparent" }
        }
    }

    Item {
        id: gameInfoContainer
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: featuredGame.height * 0.078
            rightMargin: featuredGame.width * 0.03
        }
        height: gameInfoRow.height
        width: gameInfoRow.width

        property var infoItems: [
            {
                key: "developer",
                value: gameData ? gameData.developer : "",
                icon: "assets/icons/developer.svg"
            },
            {
                key: "publisher",
                value: gameData ? gameData.publisher : "",
                icon: "assets/icons/publisher.svg"
            }
        ]

        Row {
            id: gameInfoRow
            spacing: featuredGame.width * 0.008

            Repeater {
                model: gameInfoContainer.infoItems
                delegate: Item {
                    height: featuredGame.height * 0.06
                    width: devPubRow.width + featuredGame.width * 0.04
                    visible: modelData.value && modelData.value !== ""

                    Rectangle {
                        anchors.fill: parent
                        color: "#99000000"
                        radius: 0
                    }

                    Row {
                        id: devPubRow
                        anchors.centerIn: parent
                        spacing: featuredGame.width * 0.008

                        Image {
                            source: modelData.icon
                            width: featuredGame.height * 0.04
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.value
                            font.family: global.fonts.sans
                            font.pixelSize: featuredGame.height * 0.035
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Text {
        id: recommendedLabel
        anchors {
            top: parent.top
            left: parent.left
            topMargin: featuredGame.height * 0.06
            leftMargin: featuredGame.width * 0.035
        }
        text: "RECOMMENDED FOR YOU"
        font.family: global.fonts.sans
        font.pixelSize: featuredGame.height * 0.03
        font.bold: true
        font.letterSpacing: 1.5
        color: "#ff0000"
    }

    Column {
        id: infoColumn
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: featuredGame.width * 0.035
            bottomMargin: featuredGame.height * 0.075
            right: parent.right
            rightMargin: featuredGame.width * 0.42
        }
        spacing: featuredGame.height * 0.016

        Image {
            id: titleLogo
            source: gameData && gameData.assets && gameData.assets.logo ? gameData.assets.logo : ""
            fillMode: Image.PreserveAspectFit
            width: Math.min(parent.width, featuredGame.width * 0.3)
            height: featuredGame.height * 0.22
            horizontalAlignment: Image.AlignLeft
            asynchronous: true
            mipmap: true
            visible: source != "" && status === Image.Ready

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 1
                radius: 6
                samples: 12
                color: "#AA000000"
                source: titleLogo
            }
        }

        Text {
            id: titleText
            text: gameData ? gameData.title : ""
            font.family: global.fonts.sans
            font.pixelSize: featuredGame.height * 0.044
            font.bold: true
            color: "white"
            wrapMode: Text.WordWrap
            width: parent.width
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: !titleLogo.visible
        }

        Row {
            spacing: featuredGame.width * 0.01

            Text {
                text: gameData && genreFunction ? genreFunction(gameData) : ""
                font.family: global.fonts.sans
                font.pixelSize: featuredGame.height * 0.03
                font.bold: true
                color: "white"
                opacity: 0.75
                visible: text !== "" && text !== "Unknown"
            }

            Text {
                text: gameData && gameData.releaseYear > 0 ? "\u2022  " + gameData.releaseYear : ""
                font.family: global.fonts.sans
                font.pixelSize: featuredGame.height * 0.03
                font.bold: true
                color: "white"
                opacity: 0.75
                visible: text !== ""
            }

            Text {
                text: ratingValue > 0 ? "\u2022  " + Math.round(ratingValue * 100) + "%" : ""
                font.family: global.fonts.sans
                font.pixelSize: featuredGame.height * 0.03
                font.bold: true
                color: "white"
                opacity: 0.75
                visible: text !== ""
            }
        }

        Item {
            id: expandableActions
            width: parent.width
            clip: true
            visible: opacity > 0.01
            opacity: featuredGame.active ? 1 : 0
            height: featuredGame.active ? actionsInnerColumn.implicitHeight : 0

            Behavior on height {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Column {
                id: actionsInnerColumn
                width: parent.width
                spacing: featuredGame.height * 0.016

                Text {
                    id: descriptionText
                    text: gameData && descriptionFunction ? descriptionFunction(gameData) : ""
                    font.family: global.fonts.sans
                    font.pixelSize: featuredGame.height * 0.035
                    color: "white"
                    opacity: 0.85
                    wrapMode: Text.WordWrap
                    width: parent.width * 0.7
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    lineHeight: 1.2
                    visible: text !== ""
                }

                Row {
                    id: buttonsRow
                    spacing: featuredGame.width * 0.012

                    Rectangle {
                        id: playButton
                        readonly property bool selected: featuredGame.active && featuredGame.buttonIndex === 0
                        width: playRow.width + featuredGame.width * 0.05
                        height: featuredGame.height * 0.09
                        radius: height / 2
                        color: selected ? "#ffffff" : "#4DFFFFFF"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: playRow
                            anchors.centerIn: parent
                            spacing: Style.spacingSmall

                            Text {
                                text: "\u25B6"
                                font.pixelSize: featuredGame.height * 0.04
                                color: playButton.selected ? "black" : "white"
                                anchors.verticalCenter: parent.verticalCenter
                                font.bold: true
                            }

                            Text {
                                text: "Launch"
                                font.family: global.fonts.sans
                                font.pixelSize: featuredGame.height * 0.04
                                font.bold: true
                                color: playButton.selected ? "black" : "white"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                featuredGame.buttonIndex = 0;
                                featuredGame.playRequested();
                            }
                        }
                    }

                    Rectangle {
                        id: infoButton
                        readonly property bool selected: featuredGame.active && featuredGame.buttonIndex === 1
                        width: playRow.width + featuredGame.width * 0.03
                        height: featuredGame.height * 0.09
                        radius: height / 2
                        color: selected ? "#ffffff" : "#4DFFFFFF"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: infoRow
                            anchors.centerIn: parent
                            spacing: Style.spacingSmall

                            Text {
                                text: "More info"
                                font.family: global.fonts.sans
                                font.pixelSize: featuredGame.height * 0.04
                                font.bold: true
                                color: infoButton.selected ? "black" : "white"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                featuredGame.buttonIndex = 1;
                                featuredGame.moreInfoRequested();
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: featuredGame.active ? selectionBorderWidth : 0
        border.color: "white"
    }
}
