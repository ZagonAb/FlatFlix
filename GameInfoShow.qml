// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.12
import "utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: gameInfoShow

    anchors.fill: parent

    property bool crtEffectEnabled: api.memory.get("crtEffectEnabled") !== false
    property bool isFavorite: gameData ? gameData.favorite : false
    property var getFirstGenreFunction: null
    property bool showing: false
    property var gameData: null
    property string sourceContext: "main"
    property bool isTogglingFavorite: false
    property int currentButtonIndex: 0
    property bool isLaunching: false

    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0

    signal launchGame()
    signal toggleFavorite()
    signal gameInfoClosed()
    signal toggleShader()
    signal closed()

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function restoreFocus() {
        if (gameInfoShow.parent && gameInfoShow.parent.gameInfoFocusState) {
            currentButtonIndex = gameInfoShow.parent.gameInfoFocusState.currentButtonIndex;
            navigateButtons(currentButtonIndex === 0 ? "stay" : (currentButtonIndex === 1 ? "down" : "down"));
        }
        forceActiveFocus();
    }

    onVisibleChanged: {
        if (visible) {
            showing = true;
            forceActiveFocus();
        }
    }

    function close() {
        //console.log("GameInfoShow: Closing, isLaunching:", isLaunching, "sourceContext:", sourceContext);

        showing = false;

        if (parent && sourceContext === "main") {
            parent.gameInfoVisible = false;
            parent.themeOpacity = 1.0;
            if (parent.hasOwnProperty("topBarVisible")) {
                parent.topBarVisible = true;
            }
        }

        closeTimer.start();

        if (typeof parent !== 'undefined' && parent && typeof parent.gameInfoClosed === 'function' && !isLaunching) {
            //console.log("GameInfoShow: Calling parent.gameInfoClosed for context:", sourceContext);
            parent.gameInfoClosed();
        }
    }

    function navigateButtons(direction) {
        if (direction === "down") {
            currentButtonIndex = (currentButtonIndex + 1) % 3;
        } else if (direction === "up") {
            currentButtonIndex = (currentButtonIndex - 1 + 3) % 3;
        }

        if (currentButtonIndex === 0) {
            launchButton.forceActiveFocus();
        } else if (currentButtonIndex === 1) {
            favoriteButton.forceActiveFocus();
        } else {
            shaderButton.forceActiveFocus();
        }
    }

    function toggleFavoriteWithLoading() {
        if (isTogglingFavorite) return;

        isTogglingFavorite = true;
        favoriteToggleTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: {
            //console.log("GameInfoShow: Close timer triggered");

            if (typeof parent !== 'undefined' && parent && typeof parent.gameInfoClosed === 'function' && !isLaunching) {
                parent.gameInfoClosed();
            }

            gameInfoShow.closed();
            isLaunching = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#030303"
    }

    Item {
        id: screenshotContainer
        width: parent.width * 0.62
        height: parent.height * 0.70
        anchors {
            top: parent.top
            right: parent.right
        }

        Item {
            id: imageScreen
            opacity: 0
            anchors.fill: parent

            Image {
                id: screenshot
                anchors.fill: parent
                source: {
                    if (gameData && gameData.assets) {

                        return gameData.assets.background || gameData.assets.screenshot || "";
                    }
                    return "";
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            ShaderEffect {
                id: crtEffect
                anchors.fill: parent
                property variant source: screenshot
                property real time: 0.0

                visible: crtEffectEnabled

                NumberAnimation on time {
                    loops: Animation.Infinite
                    from: 0
                    to: 100
                    duration: 100000
                }

                fragmentShader: "
                uniform sampler2D source;
                uniform lowp float qt_Opacity;
                uniform lowp float time;
                varying highp vec2 qt_TexCoord0;

                void main() {
                vec2 uv = qt_TexCoord0;

                vec2 centered = uv - 0.5;
                float dist = length(centered);
                uv = centered * (1.0 + 0.08 * dist * dist) + 0.5;

                vec4 color = texture2D(source, uv);

                float scanline = sin(uv.y * 600.0) * 0.04;
                color.rgb -= scanline;

                float vignette = 1.0 - 0.2 * dist;
                color.rgb *= vignette;
                color.rgb *= 1.1;
                gl_FragColor = color * qt_Opacity;
            }"
            }

            Image {
                id: screenshotFallback
                anchors.fill: parent
                source: screenshot.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: !crtEffectEnabled
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }

            Timer {
                id: screenshotTimer
                interval: 250
                onTriggered: {
                    imageScreen.opacity = 1.0
                }
            }

            Component.onCompleted: {
                if (gameInfoShow.showing) {
                    screenshotTimer.start()
                }
            }

            Connections {
                target: gameInfoShow
                function onShowingChanged() {
                    if (gameInfoShow.showing) {
                        imageScreen.opacity = 0
                        screenshotTimer.restart()
                    } else {
                        screenshotTimer.stop()
                        imageScreen.opacity = 0
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * 0.8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#030303" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.height * 0.8
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.3; color: "#40030303" }
                GradientStop { position: 1.0; color: "#030303" }
            }
        }
    }

    Item {
        id: infoContainer
        width: parent.width * 0.55
        height: parent.height
        anchors.left: parent.left

        ColumnLayout {
            anchors {
                fill: parent
                margins: 40
                topMargin: 60
            }
            spacing: 5

            Image {
                id: gameLogo
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width * 0.7
                Layout.preferredHeight: width * 0.3
                source: gameData && gameData.assets.logo ? gameData.assets.logo : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source !== ""

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 2
                    verticalOffset: 2
                    radius: 8
                    samples: 16
                    color: "#80000000"
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: gameInfoShow.height * 0.01

                Repeater {
                    model: getMetadataItems()

                    delegate: Row {
                        spacing: gameInfoShow.height * 0.01

                        Text {
                            text: modelData.text
                            font.family: global.fonts.sans
                            font.pixelSize: gameInfoShow.height * 0.022
                            color: "#ffffff"
                            opacity: 0.8
                        }

                        Rectangle {
                            width: gameInfoShow.height * 0.01
                            height: gameInfoShow.height * 0.01
                            radius: width / 2
                            color: "#161616"
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index < getMetadataItems().length - 1
                        }
                    }
                }
            }

            Rectangle {
                id: descriptionContainer
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.2
                color: "transparent"
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: descriptionContainer.width
                        height: descriptionContainer.height
                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: parent.height * 0.15
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#00FFFFFF" }
                                GradientStop { position: 1.0; color: "#FFFFFFFF" }
                            }
                        }
                        Rectangle {
                            y: parent.height * 0.15
                            width: parent.width
                            height: parent.height * 0.7
                            color: "#FFFFFFFF"
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * 0.15
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                                GradientStop { position: 1.0; color: "#00FFFFFF" }
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        if (gameData && gameData.description && gameData.description.length > 15) {
                            return autoScrollComponent;
                        } else {
                            return staticTextComponent;
                        }
                    }
                }

                Component {
                    id: autoScrollComponent
                    PegasusUtils.AutoScroll {
                        anchors.fill: parent
                        pixelsPerSecond: 20
                        scrollWaitDuration: 2000

                        Text {
                            width: parent.width
                            anchors.top: parent.top
                            text: gameData && gameData.description ? gameData.description : "No description available..."
                            color: "#c1c1c1"
                            font {
                                pixelSize: gameInfoShow.height * 0.025
                                family: global.fonts.sans
                            }
                            wrapMode: Text.WordWrap
                            lineHeight: 1.4
                        }
                    }
                }

                Component {
                    id: staticTextComponent
                    Text {
                        width: parent.width
                        anchors.top: parent.top
                        anchors.topMargin: parent.height * 0.02
                        text: gameData && gameData.description ? gameData.description : "No description available..."
                        color: "#c1c1c1"
                        font {
                            pixelSize: gameInfoShow.height * 0.025
                            family: global.fonts.sans
                        }
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                text: {
                    if (gameData && gameData.collections && gameData.collections.count > 0) {
                        return "From: " + gameData.collections.get(0).name;
                    }
                    return "";
                }
                font.family: global.fonts.sans
                font.pixelSize: gameInfoShow.height * 0.022
                color: "#ffffff"
                opacity: 0.8
                visible: text !== ""
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 30
                visible: (gameData && gameData.developer) || (gameData && gameData.publisher)

                Column {
                    visible: gameData && gameData.developer
                    spacing: 5

                    Text {
                        text: "Developer"
                        font.family: global.fonts.sans
                        font.pixelSize: gameInfoShow.height * 0.022
                        color: "#aaaaaa"
                    }

                    Text {
                        text: gameData ? gameData.developer : ""
                        font.family: global.fonts.sans
                        font.pixelSize: gameInfoShow.height * 0.020
                        color: "#666666"
                    }
                }

                Column {
                    visible: gameData && gameData.publisher
                    spacing: 5

                    Text {
                        text: "Publisher"
                        font.family: global.fonts.sans
                        font.pixelSize: gameInfoShow.height * 0.022
                        color: "#aaaaaa"
                    }

                    Text {
                        text: gameData ? gameData.publisher : ""
                        font.family: global.fonts.sans
                        font.pixelSize: gameInfoShow.height * 0.020
                        color: "#666666"
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    spacing: 10
                    visible: gameData

                    Repeater {
                        model: {
                            if (gameData) {
                                try {
                                    return Utils.getGameBadges(gameData);
                                } catch (e) {
                                    console.log("Error getting badges:", e);
                                    return [];
                                }
                            }
                            return [];
                        }

                        delegate: Rectangle {
                            width: badgeRow.width + 30
                            height: gameInfoShow.height * 0.05
                            radius: 25
                            color: {
                                switch(modelData.level) {
                                    case "platinum": return "#CCE5E4E2";
                                    case "gold": return "#CCFFD700";
                                    case "silver": return "#CCC0C0C0";
                                    case "bronze": return "#CCCD7F32";
                                    default: return "#CCFF0000";
                                }
                            }

                            Row {
                                id: badgeRow
                                anchors.centerIn: parent
                                spacing: 5

                                Image {
                                    source: modelData.icon
                                    width: gameInfoShow.width * 0.015
                                    height: gameInfoShow.width * 0.015
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                    mipmap: true
                                }

                                Text {
                                    text: modelData.name
                                    font.family: global.fonts.sans
                                    font.pixelSize: gameInfoShow.height * 0.022
                                    font.bold: true
                                    color: modelData.level === "platinum" ? "#000000" : ""
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: false
            }

            ColumnLayout {
                id: buttonsColumn
                Layout.alignment: Qt.AlignLeft
                spacing: 15
                focus: true

                Rectangle {
                    id: launchButton
                    Layout.preferredWidth: gameInfoShow.width * 0.35
                    Layout.preferredHeight: gameInfoShow.height * 0.065
                    color: launchButton.activeFocus ? "#ffffff" : "transparent"
                    radius: 25

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: parent.height * 0.5
                        }
                        spacing: parent.height * 0.3

                        Image {
                            source: "assets/icons/launch.svg"
                            width: favoriteButton.height * 0.6
                            height: favoriteButton.height * 0.6
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: launchButton.activeFocus ? "#000000" : "#ffffff"
                            }
                        }

                        Text {
                            text: "Launch"
                            font.family: global.fonts.sans
                            font.pixelSize: favoriteButton.height * 0.4
                            font.bold: launchButton.activeFocus
                            color: launchButton.activeFocus ? "#000000" : "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        id: launchProgressIndicator
                        anchors {
                            right: parent.right
                            rightMargin: parent.height * 0.4
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width * 0.15
                        height: parent.height * 0.1
                        radius: height / 2
                        visible: launchButton.activeFocus && gameData && gameData.playTime > 0
                        color: launchButton.activeFocus ? "#40000000" : "transparent"

                        Rectangle {
                            id: launchProgressBar
                            property real hours: gameData ? gameData.playTime / 3600 : 0
                            property real k: 100
                            property real progress: hours > 0 ? Math.log(1 + hours) / Math.log(1 + hours + k) : 0

                            width: parent.width * progress
                            height: parent.height
                            radius: parent.radius

                            color: {
                                if (launchButton.activeFocus) {
                                    let t = Math.min(1, hours / 200);
                                    let r = Math.floor(76 + t * (255 - 76));
                                    let g = Math.floor(175 - t * 175);
                                    let b = Math.floor(80 - t * 80);
                                    return Qt.rgba(r/255, g/255, b/255, 1);
                                }
                                return "transparent";
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: gameInfoShow.launchGame()
                    }
                }

                Rectangle {
                    id: favoriteButton
                    Layout.preferredWidth: gameInfoShow.width * 0.35
                    Layout.preferredHeight: gameInfoShow.height * 0.065
                    color: favoriteButton.activeFocus ? "#ffffff" : "transparent"
                    radius: 25

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: parent.height * 0.5
                        }
                        spacing: parent.height * 0.3

                        Image {
                            source: {
                                if (isTogglingFavorite) {
                                    return isFavorite ? "assets/icons/remove-favorite.svg" : "assets/icons/add-favorite.svg";
                                } else {
                                    return isFavorite ? "assets/icons/remove-favorite.svg" : "assets/icons/add-favorite.svg";
                                }
                            }
                            width: favoriteButton.height * 0.6
                            height: favoriteButton.height * 0.6
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: favoriteButton.activeFocus ? "#000000" : "#ffffff"
                            }
                        }

                        Text {
                            text: {
                                if (isTogglingFavorite) {
                                    return isFavorite ? "Removing..." : "Adding...";
                                } else {
                                    return isFavorite ? "Remove from Mi FlatFlix" : "Add to Mi FlatFlix";
                                }
                            }
                            font.family: global.fonts.sans
                            font.pixelSize: favoriteButton.height * 0.4
                            font.bold: favoriteButton.activeFocus
                            color: favoriteButton.activeFocus ? "#000000" : "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isTogglingFavorite
                        onClicked: toggleFavoriteWithLoading()
                    }
                }

                Rectangle {
                    id: shaderButton
                    Layout.preferredWidth: gameInfoShow.width * 0.35
                    Layout.preferredHeight: gameInfoShow.height * 0.065
                    color: shaderButton.activeFocus ? "#ffffff" : "transparent"
                    radius: 25

                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: parent.height * 0.5
                        }
                        spacing: parent.height * 0.3

                        Image {
                            source: "assets/icons/shader.svg"
                            width: shaderButton.height * 0.6
                            height: shaderButton.height * 0.6
                            mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                            layer.enabled: true
                            layer.effect: ColorOverlay {
                                color: shaderButton.activeFocus ? "#000000" : "#ffffff"
                            }
                        }

                        Text {
                            text: crtEffectEnabled ? "Disable CRT Effect" : "Enable CRT Effect"
                            font.family: global.fonts.sans
                            font.pixelSize: shaderButton.height * 0.4
                            font.bold: shaderButton.activeFocus
                            color: shaderButton.activeFocus ? "#000000" : "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleCrtEffect()
                    }
                }
            }
        }
    }

    Timer {
        id: favoriteToggleTimer
        interval: 1000
        onTriggered: {
            gameInfoShow.toggleFavorite();
            isTogglingFavorite = false;
        }
    }

    function getMetadataItems() {
        var items = [];

        if (gameData) {

            if (gameData.playTime > 0) {
                try {
                    var gameXP = Utils.calculateGameXP(gameData);
                    items.push({
                        text: Math.round(gameXP) + " XP",
                               showSeparator: gameData.releaseYear > 0 || gameData.players > 1 || gameData.rating > 0
                    });
                } catch (e) {
                    console.log("Error calculating XP:", e);
                }
            }

            if (gameData.releaseYear > 0) {
                items.push({ text: gameData.releaseYear.toString() });
            }

            if (gameData.genre && gameData.genre !== "") {
                var firstGenre = getFirstGenreFunction ? getFirstGenreFunction(gameData) : gameData.genre;
                items.push({ text: firstGenre });
            }

            if (gameData.playTime > 0) {
                var hours = Math.floor(gameData.playTime / 3600);
                var minutes = Math.floor((gameData.playTime % 3600) / 60);
                items.push({ text: hours + "h " + minutes + "m" });
            }

            if (gameData.rating > 0) {
                items.push({ text: Math.round(gameData.rating * 100) + "%" });
            }

            if (gameData.players > 1) {
                items.push({ text: gameData.players + " Players" });
            }

            if (gameData.playCount > 0) {
                items.push({ text: gameData.playCount + " Plays" });
            }
        }

        return items;
    }

    function toggleCrtEffect() {
        crtEffectEnabled = !crtEffectEnabled;
        api.memory.set("crtEffectEnabled", crtEffectEnabled);
    }

    Component.onCompleted: {
        forceActiveFocus();
        launchButton.forceActiveFocus();
        currentButtonIndex = 0;
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
            gameInfoShow.close();
            event.accepted = true;
        } else if (!event.isAutoRepeat && api.keys.isFilters(event)) {
            if (gameInfoShow.parent && typeof gameInfoShow.parent.showStatsScreen === "function") {
                gameInfoShow.parent.showStatsScreen();
            }
            event.accepted = true;
        } else if (!event.isAutoRepeat && api.keys.isAccept(event)) {
            if (launchButton.activeFocus) {
                gameInfoShow.launchGame();
            } else if (favoriteButton.activeFocus && !isTogglingFavorite) {
                toggleFavoriteWithLoading();
            } else if (shaderButton.activeFocus) {
                toggleCrtEffect();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_F && !isTogglingFavorite) {
            toggleFavoriteWithLoading();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            navigateButtons("down");
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            navigateButtons("up");
            event.accepted = true;
        }
    }
}
