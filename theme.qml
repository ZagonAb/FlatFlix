// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12
import "utils.js" as Utils

FocusScope {
    id: root

    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property var allCollections: []
    property bool showAllCollections: topBar.currentSection === 1
    property bool showFavoritesOnly: topBar.currentSection === 2
    property int savedCollectionIndex: 0
    property int savedGameIndex: 0
    property bool gameInfoVisible: false
    property bool topBarVisible: true
    property var savedFocusState: null
    property bool showSearch: topBar.currentSection === 0
    property bool searchVisible: topBar.currentSection === 0
    property real themeOpacity: 1.0

    property int totalXP: 0
    property var currentLevel: ({})
    property real levelProgress: 0


    property var currentScreen: "main"
    property var previousScreen: "main"
    property var previousFocusState: null

    property bool statsScreenActive: false

    Behavior on themeOpacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function handleSectionChangeFromTopBar(newSection) {
        var wasFocused = topBar.isFocused;
        if (selectedGame && typeof selectedGame.pauseVideo === "function" && selectedGame.isPlaying && newSection !== 0) {
            selectedGame.pauseVideo();
        }

        topBar.isFocused = true;
        topBar.currentSection = newSection;

        if (newSection === 0) {
            searchVisible = true;
            topBarVisible = true;
            if (selectedGame && typeof selectedGame.pauseVideo === "function" && selectedGame.isPlaying) {
                selectedGame.pauseVideo();
                selectedGame.wasPlayingBeforeFocusLoss = false;
            }
            if (searchComponent) {
                searchComponent.keyboardFocused = false;
                searchComponent.genreListFocused = false;
                searchComponent.resultsGridFocused = false;
            }
        } else {
            searchVisible = false;
            topBarVisible = true;
        }

        updateCollectionsList();
    }

    function showGameInfo() {
        if (gameInfoVisible) return;

        if (selectedGame && typeof selectedGame.pauseVideo === "function") {
            selectedGame.pauseVideo();
        }

        savedFocusState = {
            collectionIndex: currentCollectionIndex,
            gameIndex: currentGameIndex,
            topBarFocused: topBar.isFocused,
            topBarVisible: topBarVisible
        };

        topBarVisible = false;
        themeOpacity = 0.3;
        gameInfoVisible = true;
    }

    function hideGameInfo() {
        if (!gameInfoVisible) return;

        gameInfoVisible = false;
        themeOpacity = 1.0;

        if (selectedGame && typeof selectedGame.resumeVideo === "function") {
            selectedGame.resumeVideo();
        }

        if (savedFocusState) {
            currentCollectionIndex = savedFocusState.collectionIndex;
            currentGameIndex = savedFocusState.gameIndex;
            topBar.isFocused = savedFocusState.topBarFocused;
            topBarVisible = savedFocusState.topBarVisible;
        }

        forceActiveFocus();
    }

    function setTopBarVisible(visible) {
        topBarVisible = visible;
    }

    function restoreTopBarFocus() {
        topBar.isFocused = true;
        if (selectedGame && typeof selectedGame.pauseVideo === "function") {
            selectedGame.pauseVideo();
        }
    }

    function launchCurrentGame() {
        var game = getCurrentGame();
        if (game) {
            game.launch();
        }
    }

    function resetFocusAfterGameLaunch() {
        currentCollectionIndex = 0;
        currentGameIndex = 0;

        updateCollectionsList();

        topBar.isFocused = true;
        topBarVisible = true;
        gameInfoVisible = false;
        themeOpacity = 1.0;
        savedFocusState = null;
        previousFocusState = null;

        forceActiveFocus();

    }

    function toggleCurrentGameFavorite() {
        var game = getCurrentGame();
        if (game) {
            game.favorite = !game.favorite;
        }
    }

    function createContinuePlayingCollection() {
        var recentGames = [];

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i);
            if (game && game.lastPlayed && game.lastPlayed.getTime() > 0) {
                recentGames.push({
                    game: game,
                    lastPlayedTime: game.lastPlayed.getTime()
                });
            }
        }

        recentGames.sort(function(a, b) {
            return b.lastPlayedTime - a.lastPlayedTime;
        });

        if (recentGames.length === 0) {
            return null;
        }

        var continueCollection = {
            name: "Continue playing",
            shortName: "history",
            games: {
                count: recentGames.length,
                get: function(index) {
                    return index >= 0 && index < recentGames.length ? recentGames[index].game : null;
                }
            },
            assets: {},
            extra: {}
        };

        return continueCollection;
    }

    function createFavoritesCollection() {
        var favoriteGames = [];

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i);
            if (game && game.favorite) {
                favoriteGames.push(game);
            }
        }

        if (favoriteGames.length === 0) {
            return null;
        }

        var favoritesCollection = {
            name: "Mi FlatFlix",
            shortName: "favorite",
            games: {
                count: favoriteGames.length,
                get: function(index) {
                    return index >= 0 && index < favoriteGames.length ? favoriteGames[index] : null;
                }
            },
            assets: {},
            extra: {}
        };

        return favoritesCollection;
    }

    function updateCollectionsList() {
        var newCollections = [];

        if (topBar.currentSection === 2) {
            var favoritesCollection = createFavoritesCollection();
            if (favoritesCollection) {
                newCollections.push(favoritesCollection);
            }
        }

        var continueCollection = createContinuePlayingCollection();
        if (continueCollection) {
            newCollections.push(continueCollection);
        }

        for (var i = 0; i < api.collections.count; i++) {
            newCollections.push(api.collections.get(i));
        }

        allCollections = newCollections;

        if (topBar.currentSection === 2) {
            if (api.memory.get("lastSection") !== 2) {
                api.memory.set("savedCollectionIndex", currentCollectionIndex);
                api.memory.set("savedGameIndex", currentGameIndex);
            }
            currentCollectionIndex = 0;
            currentGameIndex = 0;
        } else if (topBar.currentSection === 1) {
            if (api.memory.get("lastSection") === 2) {
                var savedCollectionIdx = api.memory.get("savedCollectionIndex");
                var savedGameIdx = api.memory.get("savedGameIndex");

                if (savedCollectionIdx !== undefined) {
                    currentCollectionIndex = savedCollectionIdx;
                    if (savedGameIdx !== undefined) {
                        var restoredCollection = getCurrentCollection();
                        if (restoredCollection && savedGameIdx < restoredCollection.games.count) {
                            currentGameIndex = savedGameIdx;
                        } else {
                            currentGameIndex = 0;
                        }
                    } else {
                        currentGameIndex = 0;
                    }
                }
            }
        }

        api.memory.set("lastSection", topBar.currentSection);
    }

    function getCurrentCollection() {
        return currentCollectionIndex < allCollections.length ? allCollections[currentCollectionIndex] : null;
    }

    function getCurrentGame() {
        var collection = getCurrentCollection();
        return collection && currentGameIndex < collection.games.count ? collection.games.get(currentGameIndex) : null;
    }

    function getShortDescription(gameData) {
        if (!gameData || !gameData.description)
            return "No description available...";

        var text = gameData.description;
        var firstDot = text.indexOf(".");
        var secondDot = firstDot > -1 ? text.indexOf(".", firstDot + 1) : -1;

        if (secondDot > -1 && secondDot < 150) {
            return text.substring(0, secondDot + 1);
        } else if (firstDot > -1 && firstDot < 150) {
            return text.substring(0, firstDot + 1);
        }

        return text.substring(0, 150) + (text.length > 150 ? "..." : "");
    }

    function getFirstGenre(gameData) {
        if (!gameData || !gameData.genre)
            return "Unknown";

        var genreText = gameData.genre;
        var separators = [",", "/", "-"];
        var allParts = [genreText];

        for (var i = 0; i < separators.length; i++) {
            var separator = separators[i];
            var newParts = [];
            for (var j = 0; j < allParts.length; j++) {
                var part = allParts[j];
                var splitParts = part.split(separator);
                for (var k = 0; k < splitParts.length; k++) {
                    newParts.push(splitParts[k]);
                }
            }
            allParts = newParts;
        }

        var cleanedParts = [];
        for (var l = 0; l < allParts.length; l++) {
            var cleaned = allParts[l].trim();
            if (cleaned.length > 0) {
                cleanedParts.push(cleaned);
            }
        }

        if (cleanedParts.length > 0) {
            return cleanedParts[0];
        }

        return "Unknown";
    }

    component MetadataText: Text {
        property bool showSeparator: false

        font.family: global.fonts.sans
        font.pixelSize: root.height * 0.02
        color: "#ffffff"
        opacity: 0.8
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        visible: text !== ""
    }

    component SeparatorCircle: Rectangle {
        property bool shouldShow: false

        width: root.height * 0.008
        height: root.height * 0.008
        radius: root.height * 0.004
        color: "#666666"
        anchors.verticalCenter: parent.verticalCenter
        visible: shouldShow
    }

    Rectangle {
        anchors.fill: parent
        color: "#030303"
        opacity: themeOpacity
    }

    TopBar {
        id: topBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: root.height * 0.03
        }
        currentSection: 1
        isFocused: false
        visible: topBarVisible
        opacity: topBarVisible ? 1.0 : 0.0
        enabled: topBarVisible

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }


        onSectionSelected: function(index) {
            if (root && typeof root.handleSectionChangeFromTopBar === "function") {
                root.handleSectionChangeFromTopBar(index);
            } else {
                currentSection = index;
                if (root && typeof root.updateCollectionsList === "function") {
                    root.updateCollectionsList();
                }
            }
        }

        onFocusChanged: {
            if (hasFocus) {
                if (selectedGame && typeof selectedGame.pauseVideo === "function") {
                    selectedGame.pauseVideo();
                }
            } else {
                if (selectedGame && typeof selectedGame.resumeVideo === "function") {
                    selectedGame.resumeVideo();
                }
            }
        }
    }

    Item {
        id: userProgress

        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.height * 0.04
            rightMargin: root.width * 0.02
        }
        width: progressRow.width + root.width * 0.03
        height: root.height * 0.06
        z: 1001

        Rectangle {
            id: backgroundShadow
            anchors.fill: parent
            anchors.margins: -root.height * 0.015
            color: "transparent"
            radius: root.height * 0.025

            Rectangle {
                id: shadowRect
                anchors.fill: parent
                color: "#80000000"
                radius: parent.radius
                visible: false
            }

            DropShadow {
                anchors.fill: shadowRect
                source: shadowRect
                radius: root.height * 0.02
                samples: 41
                color: "#CC000000"
                spread: 0.2
                transparentBorder: true
            }
        }

        Row {
            id: progressRow
            spacing: root.width * 0.008
            z: 1
            anchors.centerIn: parent

            Rectangle {
                width: root.height * 0.06
                height: root.height * 0.06
                radius: width / 2
                color: "#80FF0000"

                Image {
                    id: levelIcon
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: parent.width * 0.6
                    source: currentLevel.icon || "assets/levels/level-1.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: showLevelDetails()
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Column {
                spacing: root.height * 0.005
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: `Level ${currentLevel.level || 1} - ${currentLevel.name || "Rookie"}`
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.016
                    font.bold: true
                    color: "white"
                }

                Rectangle {
                    width: root.width * 0.12
                    height: root.height * 0.006
                    radius: height / 2
                    color: "#CCFFFFFF"

                    Rectangle {
                        width: parent.width * levelProgress
                        height: parent.height
                        radius: parent.radius
                        color: "#CCFF0000"
                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Text {
                    text: {
                        if (currentLevel.level >= 10) {
                            return "Maximum level reached!";
                        } else {
                            var progressPercent = Math.round(levelProgress * 100);
                            return `${progressPercent}% progress toward level ${currentLevel.level + 1}`;
                        }
                    }
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.012
                    color: "white"
                    opacity: 0.8
                }
            }
        }

        Item {
            id: tooltipContainer
            visible: levelTooltip.visible
            z: 1002

            Rectangle {
                id: tooltipShadowRect
                width: levelTooltip.width
                height: levelTooltip.height
                color: "#CC000000"
                radius: root.height * 0.01
                visible: false
            }

            DropShadow {
                anchors.fill: tooltipShadowRect
                source: tooltipShadowRect
                radius: root.height * 0.015
                samples: 31
                color: "#AA000000"
                spread: 0.3
                transparentBorder: true
            }

            Rectangle {
                id: levelTooltip
                width: levelTooltipContent.width + root.width * 0.02
                height: levelTooltipContent.height + root.height * 0.01
                color: "#CC000000"
                radius: root.height * 0.01
                visible: false
                border.color: "#33FFFFFF"
                border.width: 1

                Column {
                    id: levelTooltipContent
                    anchors.centerIn: parent
                    spacing: root.height * 0.008

                    Row {
                        spacing: root.width * 0.01
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: tooltipLevelIcon
                            width: root.height * 0.03
                            height: root.height * 0.03
                            source: currentLevel.icon || "assets/levels/level-1.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        Text {
                            text: `Level ${currentLevel.level || 1} - ${currentLevel.name || "Rookie"}`
                            color: "white"
                            font.family: global.fonts.sans
                            font.pixelSize: root.height * 0.018
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: levelTooltipText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (currentLevel.level >= 10) {
                                return `Total XP: ${totalXP}\nMaximum level reached! 🎉`;
                            } else {
                                var nextLevel = Utils.getLevelFromXP(currentLevel.xpRequired + 1);
                                var xpNeeded = Math.max(0, nextLevel.xpRequired - totalXP);
                                return `Total XP: ${totalXP}\n${xpNeeded} XP needed to reach level ${currentLevel.level + 1}`;
                            }
                        }
                        color: "white"
                        font.family: global.fonts.sans
                        font.pixelSize: root.height * 0.015
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    function showLevelDetails() {
        if (typeof showStatsScreen === "function") {
            showStatsScreen();
        }
        else if (levelTooltip.visible) {
            levelTooltip.visible = false;
        } else {
            levelTooltip.x = userProgress.x + userProgress.width / 2 - levelTooltip.width / 2;
            levelTooltip.y = userProgress.y + userProgress.height + 5;
            levelTooltip.visible = true;

            var nextLevel = Utils.getLevelFromXP(currentLevel.xpRequired + 1);
            var xpNeeded = nextLevel.xpRequired - totalXP;
            levelTooltipText.text = `Total XP: ${totalXP}\nNext level: ${xpNeeded} XP needed`;
        }
    }

    function showStatsScreen() {
        previousScreen = currentScreen
        currentScreen = "stats"
        statsScreenActive = true

        previousFocusState = {
            collectionIndex: currentCollectionIndex,
            gameIndex: currentGameIndex,
            topBarFocused: topBar.isFocused,
            topBarVisible: topBarVisible,
            searchState: searchComponent ? {
                keyboardFocused: searchComponent.keyboardFocused,
                genreListFocused: searchComponent.genreListFocused,
                resultsGridFocused: searchComponent.resultsGridFocused,
                selectedKeyRow: searchComponent.selectedKeyRow,
                selectedKeyCol: searchComponent.selectedKeyCol,
                selectedGenreIndex: searchComponent.selectedGenreIndex,
                selectedResultIndex: searchComponent.selectedResultIndex,
                searchText: searchComponent.searchText
            } : null,
            gameInfoState: gameInfoVisible ? {
                currentButtonIndex: gameInfoComponent.currentButtonIndex
            } : null
        }

        statsScreenLoader.active = true
        themeOpacity = 0.3
        topBarVisible = false
    }


    function returnFromStatsScreen() {
        currentScreen = previousScreen
        statsScreenActive = false
        themeOpacity = 1.0
        topBarVisible = true

        if (previousFocusState) {
            currentCollectionIndex = previousFocusState.collectionIndex
            currentGameIndex = previousFocusState.gameIndex
            topBar.isFocused = previousFocusState.topBarFocused
            topBarVisible = previousFocusState.topBarVisible

            if (previousFocusState.searchState && searchComponent) {
                searchComponent.keyboardFocused = previousFocusState.searchState.keyboardFocused
                searchComponent.genreListFocused = previousFocusState.searchState.genreListFocused
                searchComponent.resultsGridFocused = previousFocusState.searchState.resultsGridFocused
                searchComponent.selectedKeyRow = previousFocusState.searchState.selectedKeyRow
                searchComponent.selectedKeyCol = previousFocusState.searchState.selectedKeyCol
                searchComponent.selectedGenreIndex = previousFocusState.searchState.selectedGenreIndex
                searchComponent.selectedResultIndex = previousFocusState.searchState.selectedResultIndex
                searchComponent.searchText = previousFocusState.searchState.searchText

                searchComponent.forceActiveFocus();
            }

            if (previousFocusState.gameInfoState && gameInfoComponent.visible) {
                gameInfoComponent.currentButtonIndex = previousFocusState.gameInfoState.currentButtonIndex
                gameInfoComponent.forceActiveFocus();
            }
        }

        if (!previousFocusState || (!previousFocusState.searchState && !previousFocusState.gameInfoState)) {
            forceActiveFocus();
        }
    }

    Timer {
        id: progressUpdateTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            try {
                var achievementState = api.memory.get("achievementState") || {};
                var result = Utils.Achievements.updateProgress(achievementState, api.allGames);

                api.memory.set("achievementState", result.state);

                totalXP = result.state.xp;
                currentLevel = Utils.getLevelFromXP(totalXP);
                levelProgress = Utils.getProgressToNextLevel(totalXP, currentLevel);

                if (result.newBadges && result.newBadges.length > 0) {
                    showBadgeNotifications(result.newBadges);
                }
            } catch (e) {
                console.log("Error updating achievement system:", e);
            }
        }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 40

        anchors.topMargin: searchVisible ? 0 : 60
        visible: !searchVisible

        Text {
            id: continueHeader
            anchors {
                top: parent.top
                left: parent.left
            }
            text: "top bar in the future, no remove"
            font.family: global.fonts.sans
            font.pixelSize: 28
            font.bold: true
            color: "white"
            visible: false
        }

        Item {
            id: mainContent
            anchors {
                top: continueHeader.bottom
                topMargin: 30
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Item {
                id: firstCollectionContainer
                width: parent.width
                height: parent.height * 0.7
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Text {
                    id: collectionTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: {
                        var collection = getCurrentCollection();
                        return collection ? collection.name : "";
                    }
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.04
                    font.bold: true
                    color: "white"
                }

                Row {
                    id: contentRow
                    anchors {
                        top: collectionTitle.bottom
                        topMargin: 15
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: 20

                    GameCard {
                        id: selectedGame
                        width: contentRow.width * 0.45
                        height: contentRow.height * 0.9
                        gameData: getCurrentGame()
                        isCurrentItem: true
                        showNetflixInfo: true
                        topBarFocused: topBar.isFocused
                        onGameSelected: {
                            if (gameData) {
                                gameData.launch()
                            }
                        }
                    }

                    Row {
                        id: nextGamesContainer
                        width: contentRow.width * 0.55
                        height: selectedGame.height
                        spacing: 10

                        Repeater {
                            id: gameRepeater
                            model: 3
                            delegate: GameCard {
                                width: (nextGamesContainer.width - 20) / 3
                                height: nextGamesContainer.height
                                topBarFocused: topBar.isFocused
                                gameData: {
                                    var collection = getCurrentCollection();
                                    if (!collection) return null;

                                    var nextIndex = currentGameIndex + index + 1;
                                    return nextIndex < collection.games.count ? collection.games.get(nextIndex) : null;
                                }
                                isCurrentItem: false
                                showNetflixInfo: false
                                compactMode: true
                                showEmptyCard: {
                                    var collection = getCurrentCollection();
                                    if (!collection) return false;

                                    var nextIndex = currentGameIndex + index + 1;
                                    return nextIndex >= collection.games.count;
                                }
                                emptyCardColor: {
                                    var collection = getCurrentCollection();
                                    if (!collection) return "#141414";

                                    var nextIndex = currentGameIndex + index + 1;
                                    var gamesLeft = collection.games.count - currentGameIndex - 1;
                                    var emptyPosition = index - gamesLeft + 1;

                                    if (emptyPosition === 1) return "#141414";
                                    else if (emptyPosition === 2) return "#0f0f0f";
                                    else if (emptyPosition === 3) return "#0a0a0a";
                                    return "#141414";
                                }
                                onGameSelected: {
                                    if (gameData) {
                                        currentGameIndex = currentGameIndex + index + 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: gameInfoContainer
                width: parent.width
                height: parent.height * 0.15
                anchors {
                    top: firstCollectionContainer.bottom
                    topMargin: -30
                    left: parent.left
                    right: parent.right
                }

                property var currentGame: getCurrentGame()

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    spacing: root.height * 0.014

                    Row {
                        id: gameMetadataRow
                        spacing: root.width * 0.008
                        height: root.height * 0.023

                        property bool isHistoryCollection: {
                            var collection = getCurrentCollection();
                            return collection && collection.shortName === "history";
                        }

                        property var metadataItems: [
                            {
                                text: !isHistoryCollection && gameInfoContainer.currentGame ? root.getFirstGenre(gameInfoContainer.currentGame) : "",
                                showSeparator: !isHistoryCollection && gameInfoContainer.currentGame &&
                                (gameInfoContainer.currentGame.releaseYear > 0 ||
                                gameInfoContainer.currentGame.players > 1 ||
                                gameInfoContainer.currentGame.rating > 0)
                            },
                            {
                                text: !isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.releaseYear > 0 ?
                                gameInfoContainer.currentGame.releaseYear.toString() : "",
                                showSeparator: !isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.releaseYear > 0 &&
                                (gameInfoContainer.currentGame.players > 1 ||
                                gameInfoContainer.currentGame.rating > 0)
                            },
                            {
                                text: !isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.players > 1 ?
                                (gameInfoContainer.currentGame.players + " Players") : "",
                                showSeparator: !isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.players > 1 &&
                                gameInfoContainer.currentGame.rating > 0
                            },
                            {
                                text: !isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.rating > 0 ?
                                (Math.round(gameInfoContainer.currentGame.rating * 100) + "%") : "",
                                showSeparator: false
                            },
                            {
                                text: isHistoryCollection && gameInfoContainer.currentGame &&
                                gameInfoContainer.currentGame.lastPlayed && gameInfoContainer.currentGame.lastPlayed.getTime() > 0 ?
                                ("Last played: " + Qt.formatDate(gameInfoContainer.currentGame.lastPlayed, "MMM dd, yyyy")) : "",
                                showSeparator: isHistoryCollection && gameInfoContainer.currentGame &&
                                (gameInfoContainer.currentGame.playTime > 0 ||
                                (gameInfoContainer.currentGame.collections && gameInfoContainer.currentGame.collections.count > 0))
                            },
                            {
                                text: isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.playTime > 0 ?
                                ("Play time: " + Math.floor(gameInfoContainer.currentGame.playTime / 3600) + "h " + Math.floor((gameInfoContainer.currentGame.playTime % 3600) / 60) + "m") : "",
                                showSeparator: isHistoryCollection && gameInfoContainer.currentGame && gameInfoContainer.currentGame.collections && gameInfoContainer.currentGame.collections.count > 0
                            },
                            {
                                text: isHistoryCollection && gameInfoContainer.currentGame &&
                                gameInfoContainer.currentGame.collections && gameInfoContainer.currentGame.collections.count > 0 ?
                                ("From: " + gameInfoContainer.currentGame.collections.get(0).name) : "",
                                showSeparator: false
                            }
                        ]

                        Repeater {
                            model: gameMetadataRow.metadataItems
                            delegate: Row {
                                spacing: gameMetadataRow.spacing
                                visible: modelData.text !== "" && modelData.text !== "Unknown"

                                MetadataText {
                                    text: modelData.text
                                }

                                SeparatorCircle {
                                    shouldShow: modelData.showSeparator
                                }
                            }
                        }
                    }

                    Text {
                        id: gameDescription
                        width: Math.min(implicitWidth, root.width * 0.5)
                        anchors {
                            left: parent.left
                        }
                        text: getShortDescription(gameInfoContainer.currentGame)
                        font.family: global.fonts.sans
                        font.pixelSize: root.height * 0.022
                        color: "white"
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        lineHeight: 1.2
                        visible: text !== "" && !gameMetadataRow.isHistoryCollection
                    }
                }
            }

            Item {
                id: nextCollectionContainer
                width: parent.width
                height: parent.height * 0.3
                anchors {
                    top: gameInfoContainer.bottom
                    topMargin: {
                        var collection = getCurrentCollection();
                        return collection && collection.shortName === "history" ?
                        parent.height * 0.01 : parent.height * 0.06;
                    }
                    left: parent.left
                    right: parent.right
                }

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: nextCollectionTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: {
                        var nextIndex = currentCollectionIndex + 1;
                        return nextIndex < allCollections.length ? allCollections[nextIndex].name : "";
                    }
                    font.family: global.fonts.sans
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                    opacity: 0.8
                    visible: currentCollectionIndex + 1 < allCollections.length
                }

                ListView {
                    id: nextCollectionGames
                    anchors {
                        top: nextCollectionTitle.bottom
                        topMargin: 15
                        left: parent.left
                        right: parent.right
                    }
                    height: ((root.height - 40) * 0.7 * 0.9)
                    orientation: ListView.Horizontal
                    spacing: 10
                    visible: currentCollectionIndex + 1 < allCollections.length
                    model: currentCollectionIndex + 1 < allCollections.length ? allCollections[currentCollectionIndex + 1].games.count : 0
                    clip: true

                    Behavior on contentX {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutQuart
                        }
                    }

                    delegate: GameCard {
                        width: (root.width - 80) * 0.5 / 3 - 7
                        height: ((root.height - 40) * 0.7 * 0.9)
                        gameData: {
                            var nextCollectionIndex = currentCollectionIndex + 1;
                            if (nextCollectionIndex < allCollections.length) {
                                var nextCollection = allCollections[nextCollectionIndex];
                                return nextCollection.games.get(index);
                            }
                            return null;
                        }
                        isCurrentItem: false
                        showNetflixInfo: false
                        compactMode: true
                        topBarFocused: topBar.isFocused

                        onGameSelected: {
                            currentCollectionIndex = currentCollectionIndex + 1;
                            currentGameIndex = index;
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.8; color: "transparent" }
            GradientStop { position: 1.0; color: "#030303" }
        }
    }

    GameInfoShow {
        id: gameInfoComponent
        anchors.fill: parent
        visible: gameInfoVisible
        gameData: getCurrentGame()
        isFavorite: gameData ? gameData.favorite : false
        opacity: gameInfoVisible ? 1.0 : 0.0
        sourceContext: "main"

        getFirstGenreFunction: root.getFirstGenre

        onLaunchGame: {
            var launchState = {
                collectionIndex: currentCollectionIndex,
                gameIndex: currentGameIndex,
                topBarFocused: topBar.isFocused
            };
            api.memory.set("preLaunchState", launchState);

            launchCurrentGame();
        }

        onToggleFavorite: {
            toggleCurrentGameFavorite();
            if (topBar.currentSection === 2) {
                updateCollectionsList();
            }
        }

        onClosed: {
            hideGameInfo();
        }

        onGameInfoClosed: {
            if (!statsScreenActive) {
                forceActiveFocus();
                topBar.isFocused = true;
            }
        }

        enabled: visible
    }

    Search {
        id: searchComponent
        anchors.fill: parent
        visible: searchVisible
        opacity: searchVisible ? 1.0 : 0.0
        enabled: visible

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }
    }


    Keys.onPressed: {

        if (statsScreenActive) {
            return;
        }

        if (gameInfoVisible || searchVisible) {
            return;
        }

        if (api.keys.isFilters(event)) {
            showStatsScreen();
            event.accepted = true;
            return;
        }

        if (gameInfoVisible) {
            return;
        }
        if (api.keys.isCancel(event)) {
            if (!topBar.isFocused && topBarVisible) {
                topBar.isFocused = true;

                if (selectedGame && typeof selectedGame.pauseVideo === "function") {
                    selectedGame.pauseVideo();
                }
                event.accepted = true;
            }
        } else if (api.keys.isAccept(event) && !topBar.isFocused && topBarVisible) {
            showGameInfo();
            event.accepted = true;
        } else if (topBar.isFocused && topBarVisible) {
            if (event.key === Qt.Key_Left) {
                topBar.navigate("left");
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                topBar.navigate("right");
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                topBar.sectionSelected(topBar.currentSection);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                topBar.isFocused = false;
                event.accepted = true;
            }
        }
    }

    Keys.onUpPressed: {
        if (statsScreenActive) {
            return;
        }

        if (gameInfoVisible) {
            event.accepted = true;
            return;
        }

        if (topBar.isFocused) {
            event.accepted = true;
        } else {
            if (currentCollectionIndex > 0) {
                currentCollectionIndex--;
                currentGameIndex = 0;
            }
        }
    }

    Keys.onDownPressed: {
        if (statsScreenActive) {
            return;
        }

        if (gameInfoVisible) {
            event.accepted = true;
            return;
        }
        if (topBar.isFocused) {
            topBar.isFocused = false;
            event.accepted = true;

            if (searchVisible) {
                if (searchComponent && typeof searchComponent.takeFocusFromTopBar === "function") {
                    if (selectedGame && typeof selectedGame.pauseVideo === "function" && selectedGame.isPlaying) {
                        selectedGame.pauseVideo();
                        selectedGame.wasPlayingBeforeFocusLoss = false;
                    }
                    searchComponent.takeFocusFromTopBar();
                }
            } else {
                if (selectedGame && typeof selectedGame.resumeVideo === "function") {
                    selectedGame.resumeVideo();
                }
            }
        } else if (!searchVisible) {
            if (currentCollectionIndex < allCollections.length - 1) {
                currentCollectionIndex++;
                currentGameIndex = 0;
            }
        }
    }

    Keys.onLeftPressed: {
        if (statsScreenActive) {
            return;
        }

        if (gameInfoVisible) {
            event.accepted = true;
            return;
        }

        if (topBar.isFocused) {
            topBar.navigate("left");
            event.accepted = true;
        } else {
            if (currentGameIndex > 0) {
                currentGameIndex--;
            }
        }
    }

    Keys.onRightPressed: {
        if (statsScreenActive) {
            return;
        }

        if (gameInfoVisible) {
            event.accepted = true;
            return;
        }

        if (topBar.isFocused) {
            topBar.navigate("right");
            event.accepted = true;
        } else {
            var collection = getCurrentCollection();
            if (collection && currentGameIndex < collection.games.count - 1) {
                currentGameIndex++;
            }
        }
    }

    Component.onCompleted: {
        updateCollectionsList();
        topBar.root = root;

        if (currentCollectionIndex >= allCollections.length) {
            currentCollectionIndex = 0;
        }

        var collection = getCurrentCollection();
        if (collection && currentGameIndex >= collection.games.count) {
            currentGameIndex = 0;
        }

        try {
            var achievementState = api.memory.get("achievementState") || {};
            var result = Utils.Achievements.updateProgress(achievementState, api.allGames);

            api.memory.set("achievementState", result.state);

            totalXP = result.state.xp;
            currentLevel = Utils.getLevelFromXP(totalXP);
            levelProgress = Utils.getProgressToNextLevel(totalXP, currentLevel);

            if (result.newBadges && result.newBadges.length > 0) {
                showBadgeNotifications(result.newBadges);
            }
        } catch (e) {
            totalXP = 0;
            currentLevel = { level: 1, name: "Rookie", icon: "🥚", xpRequired: 0 };
            levelProgress = 0;
        }

        progressUpdateTimer.start();
    }

    function showBadgeNotifications(badges) {
        if (!badges || badges.length === 0) return;

        badgeNotificationComponent.createObject(root, { badges: badges });
    }

    Component {
        id: badgeNotificationComponent

        Item {
            property var badges: []
            property int currentIndex: 0

            anchors.fill: parent
            z: 10000

            Rectangle {
                id: notification
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 100
                    rightMargin: 20
                }
                width: 300
                height: 100
                radius: 10
                color: "#CC1a1a1a"
                border.color: "#44ffffff"
                border.width: 1
                visible: currentIndex < badges.length

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Image {
                        id: badgeIcon
                        width: 60
                        height: 60
                        source: badges[currentIndex] ? badges[currentIndex].icon : ""
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - badgeIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: "¡Achievement Unlocked!"
                            font.family: global.fonts.sans
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                        }

                        Text {
                            text: badges[currentIndex] ? badges[currentIndex].name : ""
                            font.family: global.fonts.sans
                            font.pixelSize: 16
                            color: "#FFD700"
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Timer {
                id: notificationTimer
                interval: 3000
                running: true
                onTriggered: {
                    currentIndex++;
                    if (currentIndex < badges.length) {
                        restart();
                    } else {
                        parent.destroy();
                    }
                }
            }
        }
    }

    onCurrentCollectionIndexChanged: {
        if (topBar.currentSection === 1) {
            api.memory.set("savedCollectionIndex", currentCollectionIndex);
        }
    }

    onCurrentGameIndexChanged: {
        if (topBar.currentSection === 1) {
            api.memory.set("savedGameIndex", currentGameIndex);
        }
    }

    Component {
        id: statsScreenComponent
        StatsScreen {
            id: statsScreenInstance
            focus: true

            onClosed: {
                showing = false;
                statsScreenLoader.active = false;
                if (returnFocusFunction && typeof returnFocusFunction === "function") {
                    returnFocusFunction();
                }
            }

            Component.onCompleted: {
                forceActiveFocus();
            }
        }
    }

    Loader {
        id: statsScreenLoader
        anchors.fill: parent
        sourceComponent: statsScreenComponent
        active: false
        focus: true

        onLoaded: {
            if (item) {
                item.showing = true;
                item.returnFocusFunction = returnFromStatsScreen;
                item.forceActiveFocus();
            }
        }

        onActiveChanged: {
            if (active) {
                forceActiveFocus();
            }
        }
    }
}
