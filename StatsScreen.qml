// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

FocusScope {
    id: statsScreen
    anchors.fill: parent
    focus: true

    property bool showing: false
    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0
    property int totalGames: api.allGames.count
    property int totalFavorites: 0
    property int totalPlayTime: 0
    property int totalPlayCount: 0
    property int currentStreak: 0
    property int bestStreak: 0
    property int distinctGames: 0
    property int totalXP: 0
    property var currentLevel: ({})
    property real levelProgress: 0
    property var achievementState: ({})
    property real headerHeight: parent.height * 0.12
    property real sectionSpacing: parent.height * 0.03
    property real boxSpacing: parent.width * 0.01
    property real boxHeight: parent.height * 0.15
    property real sectionTitleSize: parent.height * 0.03
    property real dividerHeight: 1
    property var mostPlayedGames: []
    property var favoriteGames: []
    property var forgottenGames: []
    property var weeklyMostPlayed: []
    property var allCollections: []

    signal closed()
    property var returnFocusFunction: null

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    onVisibleChanged: {
        if (visible) {
            calculateStats();
            loadAchievementData();
            forceActiveFocus();
        }
    }

    function closeScreen() {
        showing = false;

        if (returnFocusFunction && typeof returnFocusFunction === "function") {
            returnFocusFunction();
        }

        closed();
    }

    function calculateStats() {
        totalFavorites = 0;
        totalPlayTime = 0;
        totalPlayCount = 0;

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i);
            if (game) {
                if (game.favorite) totalFavorites++;
                if (game.playTime) totalPlayTime += game.playTime;
                if (game.playCount) totalPlayCount += game.playCount;
            }
        }

        mostPlayedGames = Utils.getMostPlayedGames(5);
        favoriteGames = Utils.getFavoriteGamesWithAssets(10);
        forgottenGames = Utils.getForgottenGames(5);
        weeklyMostPlayed = Utils.getWeeklyMostPlayed(5);
        allCollections = Utils.getLargestCollections();
    }

    function formatPlayTime(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        return hours + "h " + minutes + "m";
    }

    function loadAchievementData() {
        try {
            achievementState = api.memory.get("achievementState") || {};
            currentStreak = achievementState.streak ? achievementState.streak.current : 0;
            bestStreak = achievementState.streak ? achievementState.streak.best : 0;
            distinctGames = achievementState.totals ? achievementState.totals.distinctGames30m : 0;
            totalXP = achievementState.xp || 0;
            currentLevel = Utils.getLevelFromXP(totalXP);
            levelProgress = Utils.getProgressToNextLevel(totalXP, currentLevel);
        } catch (e) {
            console.log("Error loading achievement data:", e);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#030303"
        opacity: 0.98
    }

    Rectangle {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: headerHeight
        color: "#1a1a1a"

        Text {
            anchors.centerIn: parent
            text: "GAME STATISTICS"
            font.family: global.fonts.sans
            font.pixelSize: headerHeight * 0.4
            font.bold: true
            font.letterSpacing: 2
            color: "white"
        }

        Rectangle {
            id: backButton
            anchors {
                left: parent.left
                leftMargin: parent.width * 0.02
                verticalCenter: parent.verticalCenter
            }
            width: headerHeight * 0.6
            height: headerHeight * 0.6
            radius: width / 2
            color: mouseArea.containsPress ? "#333333" : mouseArea.containsMouse ? "#444444" : "#555555"

            Image {
                anchors.centerIn: parent
                source: "assets/statsScreen/back.svg"
                width: parent.width * 0.5
                height: parent.height * 0.5
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: statsScreen.closed()
                hoverEnabled: true
            }
        }
    }

    Flickable {
        id: flickableContent
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: statsScreen.height * 0.03
        }
        contentHeight: contentLayout.height + sectionSpacing * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: true
        flickableDirection: Flickable.VerticalFlick

        Behavior on contentY {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: contentLayout
            width: parent.width - 40
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: sectionSpacing

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5


                Text {
                    text: "General Progress"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }

                GridLayout {
                    width: parent.width
                    columns: 3
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Total XP"
                        value: totalXP
                        iconSource: "assets/statsScreen/star.svg"
                        useImage: true
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Current Level"
                        value: currentLevel.name || "Rookie"
                        iconSource: currentLevel.icon || "assets/levels/level-1.svg"
                        useImage: true
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Progress"
                        value: Math.round(levelProgress * 100) + "%"
                        iconSource: "assets/statsScreen/progress.svg"
                        useImage: true
                    }
                }

                Item {
                    width: parent.width
                    height: boxHeight * 0.8
                    visible: currentLevel && typeof currentLevel.level !== 'undefined' && currentLevel.level > 0


                    Text {
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: {
                            if (currentLevel.level >= 10) {
                                return "Maximum level reached!";
                            } else {
                                var nextLevel = Utils.Achievements.xpToReachLevel(currentLevel.level + 1);
                                var xpNeeded = Math.max(0, nextLevel - totalXP);
                                return xpNeeded + " XP needed for level " + (currentLevel.level + 1);
                            }
                        }
                        font.family: global.fonts.sans
                        font.pixelSize: sectionTitleSize * 0.7
                        color: "white"
                        opacity: 0.8
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            topMargin: parent.height * 0.4
                            left: parent.left
                            right: parent.right
                        }
                        height: parent.height * 0.15
                        radius: height / 2
                        color: "#333333"

                        Rectangle {
                            height: parent.height
                            width: parent.width * levelProgress
                            radius: parent.radius
                            color: "#ff0000"
                            Behavior on width {
                                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Row {
                        anchors {
                            top: parent.top
                            topMargin: parent.height * 0.6
                            leftMargin: statsScreen.width * 0.02
                            left: parent.left
                            right: parent.right
                        }
                        spacing: statsScreen.width * 0.90

                        Text {
                            text: Utils.Achievements.xpToReachLevel(currentLevel.level)
                            font.family: global.fonts.sans
                            font.pixelSize: sectionTitleSize * 0.5
                            color: "white"
                            opacity: 0.6
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: Utils.Achievements.xpToReachLevel(currentLevel.level + 1)
                            font.family: global.fonts.sans
                            font.pixelSize: sectionTitleSize * 0.5
                            color: "white"
                            opacity: 0.6
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5

                Text {
                    text: "Game Statistics"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Total Games"
                        value: totalGames
                        iconSource: "assets/statsScreen/gamepad.svg"
                        useImage: true
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Favorites"
                        value: totalFavorites
                        iconSource: "assets/statsScreen/heart.svg"
                        useImage: true
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Play Time"
                        value: {
                            var hours = Math.floor(totalPlayTime / 3600);
                            var minutes = Math.floor((totalPlayTime % 3600) / 60);
                            return hours + "h " + minutes + "m";
                        }
                        iconSource: "assets/statsScreen/clock.svg"
                        useImage: true
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Games Played"
                        value: totalPlayCount
                        iconSource: "assets/statsScreen/numbers.svg"
                        useImage: true
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5
                visible: currentStreak > 0 || distinctGames > 0

                Text {
                    text: "Gaming Habits"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }

                GridLayout {
                    width: parent.width
                    columns: 2
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Current Streak"
                        value: currentStreak + " days"
                        iconSource: "assets/statsScreen/fire.svg"
                        useImage: true
                        visible: currentStreak > 0
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Best Streak"
                        value: bestStreak + " days"
                        iconSource: "assets/statsScreen/trophy.svg"
                        useImage: true
                        visible: bestStreak > 0
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "Different Games"
                        value: distinctGames
                        iconSource: "assets/statsScreen/target.svg"
                        useImage: true
                        visible: distinctGames > 0
                    }

                    StatBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight
                        title: "XP per hour"
                        value: Utils.Achievements.CFG.XP_PER_HOUR
                        iconSource: "assets/statsScreen/bolt.svg"
                        useImage: true
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5

                Text {
                    text: "Achievements Unlocked"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }

                GridLayout {
                    width: parent.width
                    columns: 4
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    Repeater {
                        model: {
                            var earned = achievementState.badges ? achievementState.badges.earned : [];
                            var badges = [];

                            for (var i = 0; i < earned.length; i++) {
                                var badgeId = earned[i];
                                var badgeName = Utils.Achievements.getBadgeName(badgeId);
                                var badgeIcon = Utils.Achievements.getBadgeIcon(badgeId);

                                if (badgeName && badgeIcon) {
                                    badges.push({ id: badgeId, name: badgeName, icon: badgeIcon });
                                }
                            }

                            return badges;
                        }

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 0.6
                            radius: 10
                            color: "#1a1a1a"
                            border.color: "#333333"
                            border.width: 1

                            Column {
                                anchors {
                                    fill: parent
                                    margins: parent.height * 0.1
                                }
                                spacing: parent.height * 0.05

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: modelData.icon
                                    width: parent.height * 0.4
                                    height: width
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.14
                                    font.bold: true
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Utils.Achievements.getBadgeDescription(modelData.id)
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.10
                                    color: "#aaaaaa"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.columnSpan: 4
                        Layout.fillWidth: true
                        Layout.preferredHeight: boxHeight * 0.6
                        color: "transparent"
                        visible: {
                            var earned = achievementState.badges ? achievementState.badges.earned : [];
                            return earned.length === 0;
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "You haven't unlocked any achievements yet. Keep playing!"
                            font.family: global.fonts.sans
                            font.pixelSize: sectionTitleSize * 0.8
                            color: "#666666"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5

                Text {
                    text: "Upcoming Achievements"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }

                GridLayout {
                    width: parent.width
                    columns: 4
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    Repeater {
                        model: {
                            var nextBadges = [];
                            var totals = achievementState.totals || {};
                            var hoursTotal = (totals.seconds || 0) / 3600.0;
                            var launchesTotal = totals.launches || 0;
                            var distinctTotal = totals.distinctGames30m || 0;
                            var streakDays = achievementState.streak ? achievementState.streak.current : 0;

                            var categories = ["time", "playcount", "streak", "variety"];
                            for (var c = 0; c < categories.length; c++) {
                                var category = categories[c];
                                for (var i = 0; i < Utils.BADGES[category].length; i++) {
                                    var badge = Utils.BADGES[category][i];
                                    var earned = achievementState.badges && achievementState.badges.earned ?
                                    achievementState.badges.earned.indexOf(badge.id) >= 0 : false;

                                    if (!earned) {
                                        var progress = 0;
                                        var target = 0;
                                        var formattedProgress = "";

                                        if (category === "time") {
                                            progress = hoursTotal;
                                            target = badge.hours;
                                            formattedProgress = Math.floor(progress) + "/" + target;
                                        } else if (category === "playcount") {
                                            progress = launchesTotal;
                                            target = badge.count;
                                            formattedProgress = Math.floor(progress) + "/" + target;
                                        } else if (category === "streak") {
                                            progress = streakDays;
                                            target = badge.days;
                                            formattedProgress = Math.floor(progress) + "/" + target;
                                        } else if (category === "variety") {
                                            progress = distinctTotal;
                                            target = badge.distinct;
                                            formattedProgress = Math.floor(progress) + "/" + target;
                                        }

                                        if (progress < target) {
                                            nextBadges.push({
                                                badge: badge,
                                                progress: progress,
                                                formattedProgress: formattedProgress,
                                                    target: target,
                                                    percent: Math.min(100, Math.round((progress / target) * 100))
                                            });
                                            break;
                                        }
                                    }
                                }
                            }

                            return nextBadges;
                        }

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 0.6
                            radius: 10
                            color: "#1a1a1a"
                            border.color: "#333333"
                            border.width: 1

                            Column {
                                anchors {
                                    fill: parent
                                    margins: parent.height * 0.1
                                }
                                spacing: parent.height * 0.05

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.badge.name
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.14
                                    font.bold: true
                                    color: "white"
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.formattedProgress
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.12
                                    color: "#aaaaaa"
                                }

                                Rectangle {
                                    width: parent.width
                                    height: parent.height * 0.09
                                    radius: height / 2
                                    color: "#333333"

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (modelData.percent / 100)
                                        radius: parent.radius
                                        color: "#ff0000"
                                        Behavior on width {
                                            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.percent + "%"
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.11
                                    color: "white"
                                    opacity: 0.8
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Utils.Achievements.getUpcomingDescription(modelData.badge, "")
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.09
                                    color: "#aaaaaa"
                                    opacity: 0.7
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5

                Text {
                    text: "FlatFlix information"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize + 8
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: parent.width
                    height: dividerHeight
                    color: "#333333"
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: sectionSpacing * 0.5

                Text {
                    text: "All Collections"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize
                    font.bold: true
                    color: "white"
                }

                GridLayout {
                    width: parent.width
                    columns: 4
                    rowSpacing: boxSpacing
                    columnSpacing: boxSpacing

                    Repeater {
                        model: allCollections

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: boxHeight * 0.6
                            radius: 10
                            color: "#1a1a1a"
                            border.color: "#333333"
                            border.width: 1

                            Column {
                                anchors {
                                    fill: parent
                                    margins: parent.height * 0.1
                                }
                                spacing: parent.height * 0.05

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "assets/statsScreen/collection.svg"
                                    width: parent.height * 0.25
                                    height: width
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.gameCount
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.3
                                    font.bold: true
                                    color: "white"
                                    elide: Text.ElideRight
                                    minimumPixelSize: 8
                                    fontSizeMode: Text.Fit
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name.toUpperCase()
                                    font.family: global.fonts.sans
                                    font.pixelSize: parent.height * 0.16
                                    font.letterSpacing: 1
                                    color: "#aaaaaa"
                                    elide: Text.ElideRight
                                    minimumPixelSize: 6
                                    fontSizeMode: Text.Fit
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: boxSpacing * 0.5
                visible: mostPlayedGames.length > 0

                Text {
                    text: "Most Played Games"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize * 0.8
                    font.bold: true
                    color: "white"
                    opacity: 0.9
                }

                Repeater {
                    model: mostPlayedGames.slice(0, 3)

                    delegate: Rectangle {
                        width: parent.width
                        height: boxHeight * 0.6
                        radius: 5
                        color: "#1a1a1a"
                        border.color: "#333333"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: (index + 1) + "."
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.3
                                font.bold: true
                                color: getPositionColor(index + 1)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width * 0.5
                                text: modelData.game.title
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.25
                                color: "white"
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: formatPlayTime(modelData.playTime)
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.2
                                color: "#aaaaaa"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: boxSpacing * 0.5
                visible: weeklyMostPlayed.length > 0

                Text {
                    text: "This Week's Most Played"
                    font.family: global.fonts.sans
                    font.pixelSize: sectionTitleSize * 0.8
                    font.bold: true
                    color: "white"
                    opacity: 0.9
                }

                Repeater {
                    model: weeklyMostPlayed.slice(0, 3)

                    delegate: Rectangle {
                        width: parent.width
                        height: boxHeight * 0.6
                        radius: 5
                        color: "#1a1a1a"
                        border.color: "#333333"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: (index + 1) + "."
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.3
                                font.bold: true
                                color: getPositionColor(index + 1)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width * 0.5
                                text: modelData.game.title
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.25
                                color: "white"
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.playCount + " times"
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.2
                                color: "#aaaaaa"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    function getPositionColor(position) {
        switch(position) {
            case 1: return "#FFD700";
            case 2: return "#C0C0C0";
            case 3: return "#CD7F32";
            default: return "white";
        }
    }

    Keys.onPressed: {
        if (api.keys.isFilters(event) || api.keys.isCancel(event)) {
            closeScreen();
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Up) {
            var newY = Math.max(0, flickableContent.contentY - flickableContent.height * 0.2);
            flickableContent.contentY = newY;
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Down) {
            var maxY = Math.max(0, flickableContent.contentHeight - flickableContent.height);
            var newY = Math.min(maxY, flickableContent.contentY + flickableContent.height * 0.2);
            flickableContent.contentY = newY;
            event.accepted = true;
        }
        else if (event.key === Qt.Key_Home) {
            flickableContent.contentY = 0;
            event.accepted = true;
        }
        else if (event.key === Qt.Key_End) {
            var maxY = Math.max(0, flickableContent.contentHeight - flickableContent.height);
            flickableContent.contentY = maxY;
            event.accepted = true;
        }
    }

    Rectangle {
        id: scrollIndicator
        anchors {
            right: parent.right
            top: flickableContent.top
            bottom: flickableContent.bottom
            rightMargin: 5
        }
        width: 4
        color: "#333333"
        radius: 2
        visible: flickableContent.contentHeight > flickableContent.height

        Rectangle {
            id: scrollThumb
            width: parent.width
            height: Math.max(20, (flickableContent.height / flickableContent.contentHeight) * parent.height)
            y: (flickableContent.contentY / flickableContent.contentHeight) * parent.height
            color: "#666666"
            radius: parent.radius

            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
