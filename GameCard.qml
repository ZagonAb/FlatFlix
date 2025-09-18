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

    signal gameSelected()

    Rectangle {
        anchors.fill: parent
        color: "#121212"
        radius: 10
        border.width: isCurrentItem && !compactMode && !topBarFocused ? 3 : 0
        border.color: "white"

        Rectangle {
            id: emptyCardRect
            anchors.fill: parent
            anchors.margins: isCurrentItem && !compactMode ? 3 : 0
            color: emptyCardColor
            radius: 10
            visible: showEmptyCard
        }

        Item {
            id: imageContainer
            anchors.fill: parent
            anchors.margins: isCurrentItem && !compactMode ? 3 : 0
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
                fillMode: VideoOutput.Stretch
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
                    if (status === MediaPlayer.Loaded && isCurrentItem && !compactMode) {
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
                radius: 10
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: screenshot
                maskSource: imageMask
                opacity: screenshot.opacity
            }

            Rectangle {
                anchors.fill: parent
                color: "#141414"
                radius: 10
                visible: screenshot.status !== Image.Ready && !videoPlayer.visible

                Text {
                    anchors.centerIn: parent
                    text: gameData ? gameData.title : ""
                    font.family: global.fonts.sans
                    font.pixelSize: 12
                    color: "white"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width - 10
                }
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
                    width: Math.max(2, gameCard.width * 0.008)
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
                    width: Math.max(10, gameCard.width * 0.03)
                    height: width
                    color: "#ff0000"
                    radius: width / 2
                    border.color: "#ff0000"
                    border.width: Math.max(1, gameCard.width * 0.002)

                    Behavior on y {
                        NumberAnimation { duration: 100 }
                    }

                    MouseArea {
                        id: volumeMouseArea
                        anchors.fill: parent
                        anchors.margins: -Math.max(4, gameCard.width * 0.02)

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

                Item {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                    width: Math.max(16, gameCard.width * 0.05)
                    height: width

                    Image {
                        id: volumeUpIcon
                        anchors.centerIn: parent
                        width: Math.max(12, gameCard.width * 0.03)
                        height: width
                        source: "assets/icons/volume.png"
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "ðŸ”Š"
                        font.pixelSize: Math.max(12, gameCard.width * 0.04)
                        color: "#ffffff"
                        visible: volumeUpIcon.status !== Image.Ready
                    }
                }

                Item {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    width: Math.max(14, gameCard.width * 0.045)
                    height: width

                    Image {
                        id: muteIcon
                        anchors.centerIn: parent
                        width: Math.max(10, gameCard.width * 0.03)
                        height: width
                        source: "assets/icons/mute.png"
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                        mipmap: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "ðŸ”‡"
                        font.pixelSize: Math.max(10, gameCard.width * 0.035)
                        color: "#ffffff"
                        opacity: 0.7
                        visible: muteIcon.status !== Image.Ready
                    }
                }
            }

            Item {
                id: gameInfoContainer
                anchors {
                    bottom: imageContainer.bottom
                    right: imageContainer.right
                    bottomMargin: gameCard.height * 0.07
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
                                padding: gameCard.width * 0.012

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
                                    font.pixelSize: Math.max(gameCard.width * 0.018, gameCard.height * 0.025)
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
            anchors.centerIn: parent
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
                leftMargin: isCurrentItem && !compactMode ? 3 : 0
                rightMargin: isCurrentItem && !compactMode ? 3 : 0
                bottomMargin: isCurrentItem && !compactMode ? 3 : 0
            }
            height: showNetflixInfo ? 60 : 0
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
                    leftMargin: 10
                    bottom: parent.verticalCenter
                    bottomMargin: -20
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
                    leftMargin: 10
                    bottom: parent.verticalCenter
                    bottomMargin: 2
                }
                text: gameData ? gameData.title : ""
                font.family: global.fonts.sans
                font.pixelSize: 16
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
    }

    Timer {
        id: videoStartTimer
        interval: 1000
        running: false
        repeat: false

        onTriggered: {
            if (gameData && gameData.assets.video && isCurrentItem && !compactMode && !topBarFocused && !gameInfoActive) {
                //console.log("GameCard: Starting video after timer");
                videoPlayer.source = gameData.assets.video;
            } else {
                //console.log("GameCard: Skipping video start - gameInfoActive:", gameInfoActive);
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
            if (videoPlayer.status === MediaPlayer.Loaded || videoPlayer.status === MediaPlayer.Buffered) {
                videoPlayer.play();
                isPlaying = true;
                wasPlayingBeforeFocusLoss = false;
            } else if (videoPlayer.status === MediaPlayer.Stalled || videoPlayer.status === MediaPlayer.Buffering) {
                resumeTimer.restart();
            }
        }
    }

    onGameDataChanged: {
        handleGameChange();
    }

    onIsCurrentItemChanged: {
        handleGameChange();

        if (isCurrentItem && !compactMode && !showEmptyCard && !topBarFocused) {
            resumeVideo();
        } else {
            pauseVideo();
        }
    }

    onCompactModeChanged: {
        handleGameChange();
    }

    onTopBarFocusedChanged: {
        var cardId = (gameData && gameData.title) ? gameData.title.substring(0, 10) : "Unknown";
        //console.log("GameCard [" + cardId + "]: topBarFocused changed to", topBarFocused, "isCurrentItem:", isCurrentItem);

        if (!isCurrentItem) return;

        if (topBarFocused) {
            pauseVideo();
            videoPlayer.source = "";
            screenshot.opacity = 1.0;
            wasPlayingBeforeFocusLoss = false;
        } else if (!compactMode && !showEmptyCard) {
            var isInSearchSection = false;
            if (typeof root !== 'undefined' && root && root.searchVisible !== undefined) {
                isInSearchSection = root.searchVisible;
            }

            if (!isInSearchSection) {
                handleGameChange();
                resumeVideo();
            }
        }
    }

    onGameInfoActiveChanged: {
        var cardId = (gameData && gameData.title) ? gameData.title.substring(0, 10) : "Unknown";
        //console.log("GameCard [" + cardId + "]: gameInfoActive changed to", gameInfoActive, "isCurrentItem:", isCurrentItem);

        if (gameInfoActive && isCurrentItem) {
            pauseVideo();
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

        videoPlayer.source = "";

        if (isCurrentItem && !compactMode && !showEmptyCard && !topBarFocused && !gameInfoActive) {
            screenshot.opacity = 1.0;
            infoRestoreTimer.start();

            if (gameData && gameData.assets.video) {
                //console.log("GameCard: Starting video timer in handleGameChange");
                videoStartTimer.start();
            }
        } else {
            screenshot.opacity = 1.0;
            if (isCurrentItem && !compactMode && !showEmptyCard) {
                infoRestoreTimer.start();
            }
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
        var cardId = (gameData && gameData.title) ? gameData.title.substring(0, 10) : "Unknown";

        if (pauseRequested) {
            //console.log("GameCard [" + cardId + "]: pauseVideo already requested, skipping");
            return;
        }

        pauseRequested = true;

        /*console.log("GameCard [" + cardId + "]: pauseVideo called", {
            playbackState: videoPlayer.playbackState,
            source: videoPlayer.source !== "",
            gameInfoActive: gameInfoActive,
            isCurrentItem: isCurrentItem,
            compactMode: compactMode,
            topBarFocused: topBarFocused
        });*/

        if (!isCurrentItem && videoPlayer.playbackState !== MediaPlayer.PlayingState) {
            //console.log("GameCard [" + cardId + "]: Not current item and no video playing, skipping");
            pauseRequested = false;
            return;
        }

        videoStartTimer.stop();

        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
            //console.log("GameCard [" + cardId + "]: Pausing active video");
            videoPlayer.pause();
            isPlaying = false;
            wasPlayingBeforeFocusLoss = true;
        } else if (videoPlayer.source !== "" && videoPlayer.status === MediaPlayer.Loaded) {
            //console.log("GameCard [" + cardId + "]: Video loaded but not playing, marking for resume");
            wasPlayingBeforeFocusLoss = true;
        } else if (videoStartTimer.running || (gameData && gameData.assets.video && videoPlayer.source === "")) {
            //console.log("GameCard [" + cardId + "]: Video was about to start, marking as should resume");
            wasPlayingBeforeFocusLoss = true;
        }

        Qt.callLater(function() {
            pauseRequested = false;
        });
    }

    function resumeVideo() {
        /*console.log("GameCard: Attempting to resume video", {
            wasPlayingBeforeFocusLoss: wasPlayingBeforeFocusLoss,
            isCurrentItem: isCurrentItem,
            compactMode: compactMode,
            showEmptyCard: showEmptyCard,
            topBarFocused: topBarFocused,
            hasVideoSource: videoPlayer.source !== "",
            videoStatus: videoPlayer.status
        });*/

        if (!isCurrentItem) {
            //console.log("GameCard: Not current item, skipping resume");
            return;
        }

        if (isCurrentItem && !compactMode && !showEmptyCard && !topBarFocused) {
            var isInSearchSection = false;
            if (typeof root !== 'undefined' && root && root.searchVisible !== undefined) {
                isInSearchSection = root.searchVisible;
            }

            if (!isInSearchSection) {
                if (wasPlayingBeforeFocusLoss) {
                    //console.log("GameCard: Resuming video that was playing before");
                    resumeTimer.start();
                } else if (gameData && gameData.assets.video && videoPlayer.source === "") {
                    //console.log("GameCard: Starting video from beginning");
                    videoPlayer.source = gameData.assets.video;
                    videoStartTimer.start();
                }
            }
        }
    }

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
                width: 20
                height: 20

                Image {
                    width: gameCard.width * 0.04
                    height: gameCard.width * 0.04
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                /*CustomToolTip {
                    id: badgeTooltip
                    text: modelData.name
                    visible: mouseArea.containsMouse && !compactMode
                }*/
            }
        }
    }

    Rectangle {
        id: playTimeIndicator
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 5
        }
        height: gameCard.width * 0.01
        radius: 1.5
        visible: !showEmptyCard && gameData && !compactMode && gameData.playTime > 0
        color: "#40000000"

        Rectangle {
            id: progressBar
            property real hours: gameData ? gameData.playTime / 3600 : 0
            property real k: 100
            property real progress: hours > 0 ? Math.log(1 + hours) / Math.log(1 + hours + k) : 0

            width: parent.width * progress
            height: parent.height
            radius: parent.radius

            color: {
                let t = Math.min(1, hours / 200);
                let r = Math.floor(76 + t * (255 - 76));
                let g = Math.floor(175 - t * 175);
                let b = Math.floor(80 - t * 80);
                return Qt.rgba(r/255, g/255, b/255, 1);
            }
        }

        /*CustomToolTip {
            id: timeTooltip
            text: {
                if (!gameData) return "";
                const hours = Math.floor(gameData.playTime / 3600);
                const minutes = Math.floor((gameData.playTime % 3600) / 60);
                return `Jugado: ${hours}h ${minutes}m • ${gameData.playCount} veces`;
            }
            visible: timeMouseArea.containsMouse && !compactMode
        }*/
    }

}
