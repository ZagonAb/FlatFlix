// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtMultimedia 5.12
import "utils.js" as Utils

Item {
    id: gameCard
    property var gameData
    property bool isCurrentItem: false
    property bool showNetflixInfo: false
    property bool compactMode: false
    property bool showEmptyCard: false
    property bool topBarFocused: false
    property string emptyCardColor: "#141414"
    property bool isPlaying: false
    property bool wasPlayingBeforeFocusLoss: false
    property bool gameInfoActive: false
    property bool pauseRequested: false
    property string collectionShortName: ""
    property int selectionBorderWidth: Style.borderThick
    property string _dbgTag: "gc-" + Math.floor(Math.random() * 100000)

    signal gameSelected()

    Rectangle {
        anchors.fill: parent
        color: "#121212"
        radius: 0
        border.width: isCurrentItem && !compactMode && !topBarFocused ? selectionBorderWidth : 0
        border.color: "white"

        Rectangle {
            id: emptyCardRect
            anchors.fill: parent
            anchors.margins: isCurrentItem && !compactMode ? selectionBorderWidth : 0
            color: emptyCardColor
            radius: 0
            visible: showEmptyCard
        }

        Item {
            id: imageContainer
            anchors.fill: parent
            anchors.margins: isCurrentItem && !compactMode ? selectionBorderWidth : 0
            visible: !showEmptyCard

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
                opacity: 1.0

                Behavior on opacity {
                    enabled: isCurrentItem
                    NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
                }

                onSourceChanged: {
                    if (isCurrentItem) {
                        screenshot.opacity = 0
                        fadeInScreenshot.restart()
                    } else {
                        screenshot.opacity = 1
                    }
                }
            }

            NumberAnimation {
                id: fadeInScreenshot
                target: screenshot
                property: "opacity"
                from: 0
                to: 1
                duration: 500
                easing.type: Easing.InOutQuad
            }

            Video {
                id: videoPlayer
                anchors.fill: parent
                source: gameData && gameData.assets.video ? gameData.assets.video : ""
                fillMode: VideoOutput.PreserveAspectCrop
                autoPlay: false
                loops: 1
                muted: false
                volume: getStoredVolume()
                opacity: 0.0
                visible: false

                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }

                onStatusChanged: {
                    if (status === MediaPlayer.Loaded && pendingSeekPosition >= 0) {
                        videoPlayer.seek(pendingSeekPosition);
                        pendingSeekPosition = -1;
                    }
                    if (status === MediaPlayer.Loaded && isCurrentItem && !compactMode) {
                        videoPlayer.visible = true;
                        videoPlayer.opacity = 1.0;
                        screenshot.opacity = 0.0;
                        volumeControlContainer.opacity = 1.0;
                        volumeControlContainer.visible = true;
                        playVideo();
                    }
                }

                onStopped: {
                    videoPlayer.opacity = 0.0;
                    screenshot.opacity = 1.0;
                    volumeControlContainer.opacity = 0.0;
                    volumeControlContainer.visible = false;
                }

                onErrorChanged: {
                    if (error !== MediaPlayer.NoError) {
                        videoPlayer.opacity = 0.0;
                        screenshot.opacity = 1.0;
                        volumeControlContainer.opacity = 0.0;
                        volumeControlContainer.visible = false;
                    }
                }
            }

            OpacityMask {
                id: videoMask
                anchors.fill: parent
                source: videoPlayer
                maskSource: imageMask
                opacity: videoPlayer.opacity
                visible: videoPlayer.opacity > 0
            }

            Rectangle {
                id: imageMask
                anchors.fill: parent
                radius: 0
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: screenshot
                maskSource: imageMask
                opacity: screenshot.opacity
            }

            Rectangle {
                id: gradientOverlay
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.7; color: "transparent" }
                    GradientStop { position: 1.0; color: "#030303" }
                }
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: gradientOverlay
                maskSource: imageMask
                opacity: showNetflixInfo ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }

            Item {
                id: volumeControlContainer
                anchors {
                    right: parent.right
                    rightMargin: gameCard.width * 0.04
                    verticalCenter: parent.verticalCenter
                }
                width: gameCard.width * 0.08
                height: parent.height * 0.6
                opacity: 0.0
                visible: false

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                Rectangle {
                    id: volumeBarBackground
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: gameCard.height * 0.08
                        bottom: parent.bottom
                        bottomMargin: gameCard.height * 0.08
                    }
                    width: Math.max(Math.round(2 * Style.scale), gameCard.width * 0.008)
                    color: "#80ffffff"
                    radius: width / 2

                    MouseArea {
                        id: barMouseArea
                        anchors.fill: parent
                        anchors.leftMargin: -gameCard.width * 0.025
                        anchors.rightMargin: -gameCard.width * 0.025

                        onClicked: {
                            updateVolumeFromBarClick(mouse.y);
                        }
                    }
                }

                Rectangle {
                    id: volumeLevel
                    anchors {
                        horizontalCenter: volumeBarBackground.horizontalCenter
                        bottom: volumeBarBackground.bottom
                    }
                    width: volumeBarBackground.width
                    height: volumeBarBackground.height * (videoPlayer.volume || 0)
                    color: "#ff0000"
                    radius: width / 2

                    Behavior on height {
                        NumberAnimation { duration: 100 }
                    }
                }

                Rectangle {
                    id: volumeHandle
                    anchors {
                        horizontalCenter: volumeBarBackground.horizontalCenter
                    }
                    y: volumeBarBackground.y + volumeBarBackground.height * (1 - (videoPlayer.volume || 0)) - height/2
                    width: Math.max(Math.round(10 * Style.scale), gameCard.width * 0.03)
                    height: width
                    color: "#ff0000"
                    radius: width / 2
                    border.color: "#ff0000"
                    border.width: Math.max(Style.borderThin, gameCard.width * 0.002)

                    Behavior on y {
                        NumberAnimation { duration: 100 }
                    }

                    MouseArea {
                        id: volumeMouseArea
                        anchors.fill: parent
                        anchors.margins: -Math.max(Math.round(4 * Style.scale), gameCard.width * 0.02)

                        property bool isDragging: false
                        property real startY: 0
                        property real startVolume: 0

                        onPressed: {
                            volumeHandle.color = "#ff0000";
                            isDragging = true;
                            startY = mouse.y;
                            startVolume = videoPlayer.volume;
                        }

                        onReleased: {
                            volumeHandle.color = "#ff0000";
                            isDragging = false;
                        }

                        onMouseYChanged: {
                            if (isDragging) {
                                var deltaY = mouse.y - startY;
                                var volumeChange = -(deltaY / volumeBarBackground.height);
                                var newVolume = Math.max(0, Math.min(1, startVolume + volumeChange));

                                videoPlayer.volume = newVolume;
                                saveVolume(newVolume);
                            }
                        }
                    }
                }
            }

            Item {
                id: gameInfoContainer
                anchors {
                    bottom: imageContainer.bottom
                    right: imageContainer.right
                    bottomMargin: gameCard.height * 0.05
                    rightMargin: gameCard.width * 0.02
                }
                height: Math.max(gameCard.height * 0.06, gameCard.height * 0.08)
                width: gameInfoRow.width
                visible: isCurrentItem && !compactMode && !showEmptyCard

                property var elementTimers: []

                opacity: 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

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
                    anchors.centerIn: parent
                    spacing: gameCard.width * 0.02

                    Repeater {
                        model: gameInfoContainer.infoItems
                        delegate: Item {
                            height: gameInfoContainer.height
                            width: infoRow.width + gameCard.width * 0.03
                            visible: modelData.value && modelData.value !== ""

                            Rectangle {
                                anchors.fill: parent
                                color: "#99000000"
                                radius: gameCard.width * 0.008
                            }

                            Row {
                                id: infoRow
                                anchors.centerIn: parent
                                spacing: gameCard.width * 0.012
                                padding: gameCard.width * 0.008

                                Image {
                                    source: modelData.icon
                                    width: Math.max(gameCard.width * 0.03, gameCard.height * 0.05)
                                    height: width
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.value
                                    font.family: global.fonts.sans
                                    font.pixelSize: Math.max(gameCard.width * 0.025, gameCard.height * 0.032)
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
        }

        Image {
            id: compactLogo
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: parent.height * 0.25
            width: Math.min(parent.width * 0.8, parent.height * 0.5)
            height: width * 0.6
            source: gameData && gameData.assets.logo ? gameData.assets.logo : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            mipmap: true
            visible: compactMode && source != "" && !showEmptyCard
        }

        Item {
            id: netflixInfo
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: isCurrentItem && !compactMode ? selectionBorderWidth : 0
                rightMargin: isCurrentItem && !compactMode ? selectionBorderWidth : 0
                bottomMargin: isCurrentItem && !compactMode ? selectionBorderWidth : 0
            }
            height: showNetflixInfo ? Math.round(60 * Style.scale) : 0
            visible: showNetflixInfo && !showEmptyCard
            opacity: showNetflixInfo ? 1.0 : 0.0

            Behavior on height {
                NumberAnimation { duration: 300 }
            }
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Image {
                id: selectedGameLogo
                anchors {
                    left: parent.left
                    leftMargin: Style.spacingMedium
                    bottom: parent.verticalCenter
                    bottomMargin: -Math.round(20 * Style.scale)
                }
                width: gameCard.width * 0.3
                height: gameCard.height * 0.3
                source: gameData && gameData.assets.logo ? gameData.assets.logo : ""
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                asynchronous: true
                mipmap: true
                visible: source != ""

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: -1
                    verticalOffset: - 1
                    radius: 4
                    samples: 8
                    color: "white"
                    source: selectedGameLogo
                }
            }

            Text {
                id: gameTitle
                anchors {
                    left: parent.left
                    leftMargin: Style.spacingMedium
                    bottom: parent.verticalCenter
                    bottomMargin: Math.round(2 * Style.scale)
                }
                text: gameData ? gameData.title : ""
                font.family: global.fonts.sans
                font.pixelSize: Style.fontSizeMedium
                font.bold: true
                color: "white"
                width: parent.width - 20
                elide: Text.ElideRight
                visible: selectedGameLogo.source == "" || selectedGameLogo.status !== Image.Ready
            }
        }

        MouseArea {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
            enabled: !showEmptyCard
        }

        Rectangle {
            id: playTimeIndicator
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: isCurrentItem && !compactMode && !topBarFocused ? selectionBorderWidth : 0
                leftMargin: isCurrentItem && !compactMode && !topBarFocused ? selectionBorderWidth : 0
                rightMargin: isCurrentItem && !compactMode && !topBarFocused ? selectionBorderWidth : 0
            }
            height: Math.round(gameCard.height * 0.030)
            radius: 0
            visible: !showEmptyCard && gameData && gameData.playTime > 0
            && collectionShortName === "history"
            color: "#80ffffff"

            Rectangle {
                id: progressBar
                property real hours: gameData ? gameData.playTime / 3600 : 0
                property real k: 100
                property real progress: hours > 0 ? Math.log(1 + hours) / Math.log(1 + hours + k) : 0

                width: parent.width * progress
                height: parent.height
                radius: 0

                color: {
                    let t = Math.min(1, hours / 200);
                    let r = Math.floor(76 + t * (255 - 76));
                    let g = Math.floor(175 - t * 175);
                    let b = Math.floor(80 - t * 80);
                    return Qt.rgba(r/255, g/255, b/255, 1);
                }
            }
        }
    }

    Timer {
        id: videoStartTimer
        interval: 1000
        running: false
        repeat: false

        onTriggered: {
            if (gameData && gameData.assets.video && isCurrentItem && !compactMode && !topBarFocused && !gameInfoActive) {
                videoPlayer.source = gameData.assets.video;
            }
        }
    }

    Timer {
        id: infoRestoreTimer
        interval: 300
        running: false
        repeat: false

        onTriggered: {
            if (isCurrentItem && !compactMode && !showEmptyCard) {
                gameInfoContainer.opacity = 1.0;
                selectedGameLogo.opacity = 1.0;
            }
        }
    }

    Timer {
        id: resumeTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            if (!gameData || !gameData.assets || !gameData.assets.video) return;

            var targetVolume = getStoredVolume();

            videoPlayer.visible = true;
            videoPlayer.volume = 0.0;
            videoPlayer.play();
            isPlaying = true;
            wasPlayingBeforeFocusLoss = false;

            if (pendingHandoffPosition >= 0) {
                videoPlayer.seek(pendingHandoffPosition);
                pendingHandoffPosition = -1;
            }

            videoPlayer.opacity = 1.0;
            screenshot.opacity = 0.0;

            volumeControlContainer.visible = true;
            volumeControlContainer.opacity = 1.0;
            volumeRestoreAnimation.to = targetVolume;
            volumeRestoreAnimation.restart();
        }
    }

    NumberAnimation {
        id: volumeRestoreAnimation
        target: videoPlayer
        property: "volume"
        from: 0.0
        to: 0.25
        duration: 500
        easing.type: Easing.InOutQuad
    }

    readonly property bool shouldPlay: isCurrentItem && !compactMode && !showEmptyCard && !topBarFocused && !gameInfoActive

    function isPlaybackAllowedByContext() {
        if (typeof root !== 'undefined' && root && root.searchVisible !== undefined) {
            return !root.searchVisible;
        }
        return true;
    }

    function applyPlaybackIntent() {
        if (shouldPlay && isPlaybackAllowedByContext()) {
            resumeVideo();
        } else {
            pauseVideo();
        }
    }

    onShouldPlayChanged: {
        applyPlaybackIntent();
    }

    onGameDataChanged: {
        handleGameChange();
    }

    onCompactModeChanged: {
        handleGameChange();
    }

    onTopBarFocusedChanged: {
        if (!isCurrentItem) return;

        if (topBarFocused) {
            Qt.callLater(function() {
                videoPlayer.source = "";
                screenshot.opacity = 1.0;
                wasPlayingBeforeFocusLoss = false;
            });
        }
    }

    function handleGameChange() {
        videoStartTimer.stop();
        videoPlayer.stop();
        videoPlayer.opacity = 0.0;
        videoPlayer.visible = false;
        screenshot.opacity = 1.0;
        volumeControlContainer.opacity = 0.0;
        volumeControlContainer.visible = false;
        gameInfoContainer.opacity = 0.0;
        selectedGameLogo.opacity = 0.0;
        wasPlayingBeforeFocusLoss = false;
        pendingSeekPosition = -1;

        videoPlayer.source = "";

        if (isCurrentItem && !compactMode && !showEmptyCard) {
            infoRestoreTimer.start();
        }

        if (shouldPlay && isPlaybackAllowedByContext() && gameData && gameData.assets.video) {
            videoStartTimer.start();
        }
    }

    function saveVolume(volume) {
        if (typeof api !== 'undefined' && api.memory) {
            api.memory.set("videoVolume", volume);
        }
    }

    function getStoredVolume() {
        if (typeof api !== 'undefined' && api.memory && api.memory.has("videoVolume")) {
            return api.memory.get("videoVolume");
        }
        return 0.25;
    }

    function updateVolumeFromBarClick(mouseY) {
        if (!gameData) return;

        var relativeY = mouseY;
        var normalizedPosition = relativeY / volumeBarBackground.height;
        var newVolume = Math.max(0, Math.min(1, 1 - normalizedPosition));

        videoPlayer.volume = newVolume;
        saveVolume(newVolume);
    }

    function playVideo() {
        if (gameData && gameData.assets && gameData.assets.video && isCurrentItem && !compactMode && !topBarFocused) {
            videoPlayer.play();
            isPlaying = true;
        }
    }

    function pauseVideo() {
        if (pauseRequested) {
            return;
        }

        pauseRequested = true;

        if (!isCurrentItem && videoPlayer.playbackState !== MediaPlayer.PlayingState) {
            pauseRequested = false;
            return;
        }

        videoStartTimer.stop();

        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.pause();
            isPlaying = false;
            wasPlayingBeforeFocusLoss = true;
            if (gameInfoActive) {
                videoPlayer.opacity = 0.0;
                screenshot.opacity = 1.0;
                volumeControlContainer.opacity = 0.0;
            }
        } else if (videoPlayer.source.toString() !== "" && videoPlayer.status === MediaPlayer.Loaded) {
            wasPlayingBeforeFocusLoss = true;
        } else if (videoStartTimer.running || (gameData && gameData.assets.video && videoPlayer.source.toString() === "")) {
            wasPlayingBeforeFocusLoss = true;
        }

        Qt.callLater(function() {
            pauseRequested = false;
        });
    }

    function resumeVideo() {
        if (!isCurrentItem) {
            return;
        }

        if (isCurrentItem && !compactMode && !showEmptyCard && !topBarFocused) {
            var isInSearchSection = false;
            if (typeof root !== 'undefined' && root && root.searchVisible !== undefined) {
                isInSearchSection = root.searchVisible;
            }

            if (!isInSearchSection) {
                if (wasPlayingBeforeFocusLoss) {
                    resumeTimer.start();
                } else if (gameData && gameData.assets.video && videoPlayer.source.toString() === "") {
                    videoPlayer.source = gameData.assets.video;
                    videoStartTimer.start();
                }
            }
        }
    }

    function increaseVolume() {
        if (!gameData || !gameData.assets || !gameData.assets.video) return false;
        if (videoPlayer.playbackState !== MediaPlayer.PlayingState) return false;

        var currentVolume = videoPlayer.volume;
        var newVolume = Math.min(1.0, currentVolume + 0.1);
        videoPlayer.volume = newVolume;
        saveVolume(newVolume);
        return true;
    }

    function decreaseVolume() {
        if (!gameData || !gameData.assets || !gameData.assets.video) return false;
        if (videoPlayer.playbackState !== MediaPlayer.PlayingState) return false;

        var currentVolume = videoPlayer.volume;
        var newVolume = Math.max(0.0, currentVolume - 0.1);
        videoPlayer.volume = newVolume;
        saveVolume(newVolume);
        return true;
    }

    function getCurrentVolume() {
        return videoPlayer.volume;
    }

    function isVideoPlaying() {
        return videoPlayer.playbackState === MediaPlayer.PlayingState &&
        gameData && gameData.assets && gameData.assets.video;
    }

    function getVideoPosition() {
        return videoPlayer.position || 0;
    }

    function seekVideo(positionMs) {
        if (videoPlayer.source.toString() === "" || positionMs === undefined || positionMs === null) return;
        if (videoPlayer.status === MediaPlayer.Loaded || videoPlayer.status === MediaPlayer.Buffered) {
            videoPlayer.seek(positionMs);
        } else {
            pendingSeekPosition = positionMs;
        }
    }

    property real pendingSeekPosition: -1
    property real pendingHandoffPosition: -1

    Component.onDestruction: {
        videoStartTimer.stop();
        videoPlayer.stop();
    }

    Row {
        id: progressBadges
        anchors {
            top: parent.top
            right: parent.right
            topMargin: gameCard.width * 0.02
            rightMargin: gameCard.width * 0.03
        }
        spacing: gameCard.width * 0.025

        visible: !showEmptyCard && gameData && !compactMode && gameData && gameData.playTime !== undefined

        Repeater {
            model: {
                if (gameData) {
                    try {
                        return Utils.getGameBadges(gameData).slice(0, 3);
                    } catch (e) {
                        return [];
                    }
                }
                return [];
            }

            delegate: Item {
                width: Math.round(20 * Style.scale)
                height: Math.round(20 * Style.scale)

                Image {
                    width: gameCard.width * 0.04
                    height: gameCard.width * 0.04
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }
        }
    }
}
