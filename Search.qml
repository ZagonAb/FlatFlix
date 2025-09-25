// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15
import QtGraphicalEffects 1.12
import "utils.js" as Utils

FocusScope {
    id: root

    property string searchText: ""
    property bool keyboardFocused: true
    property bool genreListFocused: false
    property bool resultsGridFocused: false
    property int selectedKeyRow: 0
    property int selectedKeyCol: 0
    property int selectedGenreIndex: 0
    property int selectedResultIndex: 0
    property var searchResults: []
    property var filteredGames: []
    property real themeOpacity: 1.0
    property string lastFocusOrigin: "keyboard"
    property var genres: []
    property bool isLoading: false
    property bool showingAllGames: true
    property bool gameInfoVisible: false
    property var selectedGameForInfo: null
    property bool showingMultiplayerFilter: false

    property var lettersAndNumbers: [
        "a", "b", "c", "d", "e", "f",
        "g", "h", "i", "j", "k", "l",
        "m", "n", "o", "p", "q", "r",
        "s", "t", "u", "v", "w", "x",
        "y", "z", "1", "2", "3", "4",
        "5", "6", "7", "8", "9", "0"
    ]

    function restoreFocus() {
        if (root.parent && root.parent.searchFocusState) {
            var state = root.parent.searchFocusState;
            keyboardFocused = state.keyboardFocused;
            genreListFocused = state.genreListFocused;
            resultsGridFocused = state.resultsGridFocused;
            selectedKeyRow = state.selectedKeyRow;
            selectedKeyCol = state.selectedKeyCol;
            selectedGenreIndex = state.selectedGenreIndex;
            selectedResultIndex = state.selectedResultIndex;
            searchText = state.searchText;
        }
        forceActiveFocus();
    }

    Behavior on themeOpacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: "#030303"
        opacity: themeOpacity
    }

    Row {
        anchors {
            top: parent.top
            topMargin: parent.height * 0.14
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 40
            rightMargin: 40
            bottomMargin: 40
        }
        spacing: 20

        Item {
            id: leftColumn
            width: parent.width * 0.3
            height: parent.height

            Item {
                id: keyboardContainer
                width: parent.width
                height: parent.height * 0.6
                anchors.top: parent.top

                Row {
                    id: specialKeysRow
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    width: parent.width
                    height: root.height * 0.06
                    spacing: 5

                    Rectangle {
                        id: spaceKey
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 0 ? "#ffffff" : "#1d1c1d"
                        border.color: "#343434"
                        border.width: 1
                        radius: 4

                        Item {
                            anchors.centerIn: parent
                            width: parent.height
                            height: parent.height

                            Image {
                                id: spaceIcon
                                anchors.fill: parent
                                source: "assets/icons/space.svg"
                                fillMode: Image.PreserveAspectFit
                                visible: source !== "" && status === Image.Ready
                                sourceSize.width: width
                                sourceSize.height: height
                            }

                            ColorOverlay {
                                anchors.fill: spaceIcon
                                source: spaceIcon
                                color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 0 ? "#000000" : "white"
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "space"
                            font.family: global.fonts.sans
                            font.pixelSize: parent.height * 0.4
                            font.bold: true
                            color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 0 ? "#000000" : "white"
                            visible: !spaceIcon.visible
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: handleKeyPress("space")
                        }
                    }

                    Rectangle {
                        id: backspaceKey
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 1 ? "#ffffff" : "#1d1c1d"
                        border.color: "#343434"
                        border.width: 1
                        radius: 4

                        Item {
                            anchors.centerIn: parent
                            width: parent.height
                            height: parent.height

                            Image {
                                id: deleteIcon
                                anchors.fill: parent
                                source: "assets/icons/delete.svg"
                                fillMode: Image.PreserveAspectFit
                                visible: source !== "" && status === Image.Ready
                                sourceSize.width: width
                                sourceSize.height: height
                            }

                            ColorOverlay {
                                anchors.fill: deleteIcon
                                source: deleteIcon
                                color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 1 ? "#000000" : "white"
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "delete"
                            font.family: global.fonts.sans
                            font.pixelSize: parent.height * 0.4
                            font.bold: true
                            color: keyboardFocused && selectedKeyRow === -1 && selectedKeyCol === 1 ? "#000000" : "white"
                            visible: !deleteIcon.visible
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: handleKeyPress("←")
                        }
                    }
                }

                Grid {
                    id: keyboard
                    anchors {
                        top: specialKeysRow.bottom
                        topMargin: 15
                        left: parent.left
                    }
                    width: parent.width
                    height: parent.height - specialKeysRow.height - 15
                    columns: 6
                    spacing: 5

                    Repeater {
                        model: lettersAndNumbers.length
                        delegate: Rectangle {
                            property int row: Math.floor(index / 6)
                            property int col: index % 6
                            property string keyText: lettersAndNumbers[index]
                            property bool isSelected: keyboardFocused && selectedKeyRow === row && selectedKeyCol === col

                            width: (keyboard.width - (keyboard.spacing * 5)) / 6
                            height: (keyboard.height - (keyboard.spacing * 5)) / 6
                            color: isSelected ? "#ffffff" : "#1d1c1d"
                            border.color: "#343434"
                            border.width: 1
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: keyText
                                font.family: global.fonts.sans
                                font.pixelSize: parent.height * 0.4
                                font.bold: true
                                color: isSelected ? "#000000" : "white"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: handleKeyPress(keyText)
                            }
                        }
                    }
                }
            }

            Item {
                id: genresContainer
                width: parent.width
                height: parent.height * 0.4
                anchors {
                    top: keyboardContainer.bottom
                    topMargin: 20
                    left: parent.left
                }

                Text {
                    id: genresTitle
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: "Genres"
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.03
                    font.bold: true
                    color: "white"
                }

                ListView {
                    id: genresList
                    anchors {
                        top: genresTitle.bottom
                        topMargin: 15
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    spacing: 5
                    clip: true
                    model: genres
                    currentIndex: genreListFocused ? selectedGenreIndex : -1

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && genreListFocused) {
                            positionViewAtIndex(currentIndex, ListView.Contain)
                            var genre = genres[currentIndex];
                            if (genre) {
                                searchByGenre(genre);
                                showingAllGames = false;
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: genresList.width
                        height: root.height * 0.07
                        color: {
                            if (genreListFocused && selectedGenreIndex === index) {
                                return "#ffffff"
                            } else if (resultsGridFocused && selectedGenreIndex === index && lastFocusOrigin === "genres") {
                                return "#1d1c1d"
                            } else {
                                return "transparent"
                            }
                        }
                        radius: 30

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            font.family: global.fonts.sans
                            font.pixelSize: root.height * 0.025
                            color: genreListFocused && selectedGenreIndex === index ? "#000000" : "white"
                            opacity: genreListFocused && selectedGenreIndex === index ? 1.0 : 0.7
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectedGenreIndex = index
                                searchByGenre(modelData)
                                showingAllGames = false;
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: rightColumn
            width: parent.width * 0.7
            height: parent.height

            Text {
                id: resultsTitle
                anchors {
                    top: parent.top
                    left: parent.left
                }
                text: {
                    if (searchText !== "") {
                        return searchText
                    } else if (!showingAllGames && filteredGames.length > 0) {
                        return genres[selectedGenreIndex] || "Filtered Games"
                    } else {
                        return "All the games here..."
                    }
                }
                font.family: global.fonts.sans
                font.pixelSize: root.height * 0.04
                font.bold: false
                color: "white"

                Rectangle {
                    id: titleCursor
                    width: 3
                    height: parent.height * 0.8
                    color: "white"
                    anchors {
                        left: parent.left
                        leftMargin: resultsTitle.contentWidth + 2
                        verticalCenter: parent.verticalCenter
                    }
                    visible: searchText !== "" && keyboardFocused

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: searchText !== "" && keyboardFocused
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }

            Item {
                id: spinnerContainer
                anchors.centerIn: resultsGrid
                width: parent.width
                height: parent.height
                visible: isLoading

                Image {
                    id: spinner
                    anchors.centerIn: parent
                    width: root.width * 0.3
                    height: root.height * 0.15
                    source: "assets/icons/spinner.svg"
                    fillMode: Image.PreserveAspectFit
                    visible: source !== ""
                    mipmap: true

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: spinner.visible
                    }
                }

                Text {
                    anchors {
                        top: spinner.bottom
                        topMargin: 10
                        horizontalCenter: parent.horizontalCenter
                    }
                    text: "Loading..."
                    font.family: global.fonts.sans
                    font.pixelSize: root.height * 0.02
                    color: "white"
                }
            }

            GridView {
                id: resultsGrid
                anchors {
                    top: resultsTitle.bottom
                    topMargin: 20
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                cellWidth: width / 4
                cellHeight: height / 2
                clip: true
                currentIndex: resultsGridFocused ? selectedResultIndex : -1

                opacity: isLoading ? 0.02 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                model: showingAllGames && searchText === "" ? getAllGames() : filteredGames

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        positionViewAtIndex(currentIndex, GridView.Contain)
                    }
                }

                delegate: Item {
                    width: resultsGrid.cellWidth
                    height: resultsGrid.cellHeight

                    GameCard {
                        id: gameCard
                        anchors.centerIn: parent
                        width: parent.width * 0.95
                        height: parent.height * 0.95
                        gameData: modelData
                        isCurrentItem: resultsGridFocused && selectedResultIndex === index
                        showNetflixInfo: false
                        compactMode: true
                        topBarFocused: false

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: resultsGridFocused && selectedResultIndex === index ? "#ffffff" : "transparent"
                            border.width: 3
                            radius: 8
                        }

                        onGameSelected: {
                            if (gameData) {
                                selectedResultIndex = index
                                gameData.launch()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedResultIndex = index
                            resultsGridFocused = true
                            keyboardFocused = false
                            genreListFocused = false
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: searchTimer
        interval: 500
        onTriggered: {
            performSearchActual();
            isLoading = false;
        }
    }

    Timer {
        id: genreSearchTimer
        interval: 500
        onTriggered: {
            performGenreSearchActual();
            isLoading = false;
        }
    }

    Timer {
        id: multiplayerSearchTimer
        interval: 500
        onTriggered: {
            performMultiplayerSearchActual();
            isLoading = false;
        }
    }

    function handleKeyPress(key) {
        if (key === "←" || key === "backspace" || key === "←") {
            if (searchText.length > 0) {
                searchText = searchText.slice(0, -1)
                performSearch()
            }
        } else if (key === "space") {
            searchText += " "
            performSearch()
        } else if (key === "clear") {
            searchText = ""
            searchResults = []
            showingAllGames = true
            filteredGames = []
        } else if (key.length === 1) {
            searchText += key
            performSearch()
            showingAllGames = false
        }
    }

    function performSearch() {
        isLoading = true;
        searchTimer.restart();
    }

    function performSearchActual() {
        if (searchText.length === 0) {
            showingAllGames = true;
            filteredGames = []
            return
        }

        var results = []
        var searchLower = searchText.toLowerCase()
        var searchWords = searchLower.split(/\s+/).filter(function(word) { return word.length > 0; })
        showingAllGames = false;

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i)
            if (game) {
                var matchScore = calculateMatchScore(game, searchLower, searchWords);
                if (matchScore > 0) {
                    results.push({
                        game: game,
                        score: matchScore
                    });
                }
            }
        }

        results.sort(function(a, b) {
            if (a.score !== b.score) {
                return b.score - a.score;
            }
            return (a.game.title || "").localeCompare(b.game.title || "");
        });

        filteredGames = results.map(function(result) { return result.game; });
    }

    function calculateMatchScore(game, searchLower, searchWords) {
        var score = 0;
        var title = (game.title || "").toLowerCase();
        var developer = (game.developer || "").toLowerCase();
        var publisher = (game.publisher || "").toLowerCase();
        var genre = (game.genre || "").toLowerCase();
        var description = (game.description || "").toLowerCase();

        if (title === searchLower) {
            score += 1000;
        }

        else if (title.indexOf(searchLower) === 0) {
            score += 800;
        }

        else if (title.indexOf(searchLower) !== -1) {
            score += 600;
        }

        for (var i = 0; i < searchWords.length; i++) {
            var word = searchWords[i];
            if (title.indexOf(word) !== -1) {
                if (title.indexOf(word) === 0) {
                    score += 400;
                } else {
                    score += 200;
                }
            }
        }

        if (developer.indexOf(searchLower) !== -1) {
            score += 300;
        }
        for (var i = 0; i < searchWords.length; i++) {
            if (developer.indexOf(searchWords[i]) !== -1) {
                score += 150;
            }
        }

        if (publisher.indexOf(searchLower) !== -1) {
            score += 250;
        }
        for (var i = 0; i < searchWords.length; i++) {
            if (publisher.indexOf(searchWords[i]) !== -1) {
                score += 120;
            }
        }

        if (genre.indexOf(searchLower) !== -1) {
            score += 200;
        }
        for (var i = 0; i < searchWords.length; i++) {
            if (genre.indexOf(searchWords[i]) !== -1) {
                score += 100;
            }
        }

        if (description.indexOf(searchLower) !== -1) {
            score += 50;
        }
        for (var i = 0; i < searchWords.length; i++) {
            if (description.indexOf(searchWords[i]) !== -1) {
                score += 25;
            }
        }

        var fieldsMatched = 0;
        if (title.indexOf(searchLower) !== -1) fieldsMatched++;
        if (developer.indexOf(searchLower) !== -1) fieldsMatched++;
        if (publisher.indexOf(searchLower) !== -1) fieldsMatched++;
        if (genre.indexOf(searchLower) !== -1) fieldsMatched++;
        if (description.indexOf(searchLower) !== -1) fieldsMatched++;

        if (fieldsMatched > 1) {
            score += fieldsMatched * 50;
        }

        return score;
    }

    function searchByGenre(genre) {
        if (genre === "Two or more players") {
            searchByMultiplayer();
        } else {
            isLoading = true;
            genreSearchTimer.restart();
        }
    }

    function performGenreSearchActual() {
        var genre = genres[selectedGenreIndex];
        if (!genre) return;

        if (genre === "Two or more players") {
            performMultiplayerSearchActual();
            return;
        }

        var results = []
        var genreLower = genre.toLowerCase()
        showingAllGames = false;
        showingMultiplayerFilter = false;

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i)
            if (game && game.genre) {
                var gameGenreLower = game.genre.toLowerCase()

                if (gameGenreLower.indexOf(genreLower) !== -1) {
                    results.push(game)
                }
            }
        }

        filteredGames = results
        searchText = genre
    }

    function getAllGames() {
        var allGames = []

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i)
            if (game) {
                allGames.push(game)
            }
        }

        return allGames
    }

    function canMoveRightFromKeyboard() {
        if (selectedKeyRow === -1 && selectedKeyCol === 1) {
            return true
        }

        if (selectedKeyRow >= 0) {
            var keyIndex = selectedKeyRow * 6 + selectedKeyCol
            var currentKey = lettersAndNumbers[keyIndex]
            if (currentKey === "f" || currentKey === "l" || currentKey === "r" ||
                currentKey === "x" || currentKey === "4" || currentKey === "0") {
                return true
                }
        }

        return false
    }

    function canMoveDownFromKeyboard() {
        if (selectedKeyRow >= 0) {
            var keyIndex = selectedKeyRow * 6 + selectedKeyCol
            var currentKey = lettersAndNumbers[keyIndex]
            if (currentKey === "5" || currentKey === "6" || currentKey === "7" ||
                currentKey === "8" || currentKey === "9" || currentKey === "0") {
                return true
                }
        }

        return false
    }

    function isInFirstColumnOfGrid() {
        return selectedResultIndex % 4 === 0
    }

    function ensureGenreVisible() {
        if (genreListFocused && selectedGenreIndex >= 0) {
            genresList.currentIndex = selectedGenreIndex
        }
    }

    function ensureResultVisible() {
        if (resultsGridFocused && selectedResultIndex >= 0) {
            resultsGrid.currentIndex = selectedResultIndex
        }
    }

    function restoreAllGamesView() {
        showingAllGames = true;
        showingMultiplayerFilter = false;
        searchText = "";
        filteredGames = [];
    }

    Keys.onPressed: {
        if (!keyboardFocused && !genreListFocused && !resultsGridFocused) {
            return;
        }

        if (api.keys.isFilters(event)) {
            if (root.parent && typeof root.parent.showStatsScreen === "function") {
                root.parent.showStatsScreen();
            }
            event.accepted = true;
            return;
        }

        if (api.keys.isCancel(event)) {
            event.accepted = true
            if (keyboardFocused) {
                keyboardFocused = false
                genreListFocused = false
                resultsGridFocused = false
                if (root.parent && typeof root.parent.restoreTopBarFocus === "function") {
                    root.parent.restoreTopBarFocus()
                }
            } else if (resultsGridFocused) {
                if (lastFocusOrigin === "genres") {
                    resultsGridFocused = false
                    genreListFocused = true
                    ensureGenreVisible()
                } else if (lastFocusOrigin === "keyboard") {
                    resultsGridFocused = false
                    keyboardFocused = true
                }
            } else if (genreListFocused) {
                genreListFocused = false
                keyboardFocused = true
                lastFocusOrigin = "keyboard"
                restoreAllGamesView();
            }
        } else if (api.keys.isAccept(event)) {
            if (keyboardFocused) {
                if (selectedKeyRow === -1) {
                    if (selectedKeyCol === 0) {
                        handleKeyPress("space")
                    } else if (selectedKeyCol === 1) {
                        handleKeyPress("←")
                    }
                } else {
                    var keyIndex = selectedKeyRow * 6 + selectedKeyCol
                    if (keyIndex < lettersAndNumbers.length) {
                        handleKeyPress(lettersAndNumbers[keyIndex])
                    }
                }
            } else if (genreListFocused) {

            }  else if (resultsGridFocused) {
                var selectedGame = null

                if (showingAllGames && searchText === "") {
                    var allGames = getAllGames()
                    if (selectedResultIndex < allGames.length) {
                        selectedGame = allGames[selectedResultIndex]
                    }
                }

                else if (filteredGames.length > selectedResultIndex) {
                    selectedGame = filteredGames[selectedResultIndex]
                }

                if (selectedGame) {
                    selectedGameForInfo = selectedGame
                    gameInfoVisible = true
                }
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (keyboardFocused) {
                if (selectedKeyRow === -1) {
                    return
                } else if (selectedKeyRow === 0) {
                    selectedKeyRow = -1
                    selectedKeyCol = Math.min(1, selectedKeyCol)
                } else {
                    selectedKeyRow = selectedKeyRow - 1
                }
            } else if (genreListFocused) {
                if (selectedGenreIndex === 0) {
                    genreListFocused = false
                    keyboardFocused = true
                    lastFocusOrigin = "keyboard"
                    restoreAllGamesView();
                } else {
                    selectedGenreIndex = Math.max(0, selectedGenreIndex - 1)
                    ensureGenreVisible()
                }
            } else if (resultsGridFocused) {
                if (selectedResultIndex >= 4) {
                    selectedResultIndex -= 4
                    ensureResultVisible()
                }
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (keyboardFocused) {
                if (selectedKeyRow === -1) {
                    selectedKeyRow = 0
                } else if (canMoveDownFromKeyboard()) {
                    genreListFocused = true
                    keyboardFocused = false
                    selectedGenreIndex = 0
                    lastFocusOrigin = "keyboard"
                    ensureGenreVisible()

                    if (genres.length > 0) {
                        searchByGenre(genres[0]);
                    }
                } else {
                    var maxRow = Math.floor((lettersAndNumbers.length - 1) / 6)
                    if (selectedKeyRow < maxRow) {
                        selectedKeyRow = selectedKeyRow + 1
                    }
                }
            } else if (genreListFocused) {
                selectedGenreIndex = Math.min(genres.length - 1, selectedGenreIndex + 1)
                ensureGenreVisible()

            } else if (resultsGridFocused) {
                var totalResults = filteredGames.length > 0 ? filteredGames.length : getAllGames().length
                if (selectedResultIndex + 4 < totalResults) {
                    selectedResultIndex += 4
                    ensureResultVisible()
                }
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            if (keyboardFocused) {
                if (selectedKeyRow === -1) {
                    selectedKeyCol = Math.max(0, selectedKeyCol - 1)
                } else {
                    selectedKeyCol = Math.max(0, selectedKeyCol - 1)
                }
            } else if (resultsGridFocused) {
                if (isInFirstColumnOfGrid()) {
                    resultsGridFocused = false
                    if (lastFocusOrigin === "genres") {
                        genreListFocused = true
                        ensureGenreVisible()
                    } else {
                        keyboardFocused = true
                    }
                } else {
                    selectedResultIndex = Math.max(0, selectedResultIndex - 1)
                    ensureResultVisible()
                }
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            if (keyboardFocused) {
                if (selectedKeyRow === -1) {
                    if (selectedKeyCol === 1) {
                        var totalResults = filteredGames.length > 0 ? filteredGames.length : getAllGames().length
                        if (totalResults > 0) {
                            resultsGridFocused = true
                            keyboardFocused = false
                            selectedResultIndex = 0
                            lastFocusOrigin = "keyboard"
                            ensureResultVisible()
                        }
                    } else {
                        selectedKeyCol = Math.min(1, selectedKeyCol + 1)
                    }
                } else if (canMoveRightFromKeyboard()) {
                    var totalResults = filteredGames.length > 0 ? filteredGames.length : getAllGames().length
                    if (totalResults > 0) {
                        resultsGridFocused = true
                        keyboardFocused = false
                        selectedResultIndex = 0
                        lastFocusOrigin = "keyboard"
                        ensureResultVisible()
                    }
                } else {
                    selectedKeyCol = Math.min(5, selectedKeyCol + 1)
                }
            } else if (genreListFocused) {
                var totalResults = filteredGames.length > 0 ? filteredGames.length : getAllGames().length
                if (totalResults > 0) {
                    resultsGridFocused = true
                    genreListFocused = false
                    selectedResultIndex = 0
                    lastFocusOrigin = "genres"
                    ensureResultVisible()
                }
            } else if (resultsGridFocused) {
                var totalResults = filteredGames.length > 0 ? filteredGames.length : getAllGames().length
                if (selectedResultIndex < totalResults - 1) {
                    selectedResultIndex++
                    ensureResultVisible()
                }
            }
            event.accepted = true
        }
    }

    Component.onCompleted: {
        keyboardFocused = false
        selectedKeyRow = 0
        selectedKeyCol = 0
        genreListFocused = false
        resultsGridFocused = false
        lastFocusOrigin = "keyboard"

        var uniqueGenres = Utils.getUniqueGenresFromGames(30);
        genres = ["Two or more players"].concat(uniqueGenres);

        showingAllGames = true;
    }

    onVisibleChanged: {
        if (visible) {
            keyboardFocused = false
            selectedKeyRow = 0
            selectedKeyCol = 0
            genreListFocused = false
            resultsGridFocused = false
            lastFocusOrigin = "keyboard"
            showingAllGames = true;
            searchText = "";
            filteredGames = [];

            var uniqueGenres = Utils.getUniqueGenresFromGames(30);
            genres = ["Two or more players"].concat(uniqueGenres);
        }
    }

    function searchByMultiplayer() {
        isLoading = true;
        multiplayerSearchTimer.restart();
    }

    function performMultiplayerSearchActual() {
        var results = []
        showingAllGames = false;

        for (var i = 0; i < api.allGames.count; i++) {
            var game = api.allGames.get(i)
            if (game) {
                var playerCount = game.players || 1;
                if (playerCount > 1) {
                    results.push(game);
                }
            }
        }

        results.sort(function(a, b) {
            var ratingA = a.rating || 0.0;
            var ratingB = b.rating || 0.0;
            return ratingB - ratingA;
        });

        filteredGames = results
        searchText = "Two or more players"
        showingMultiplayerFilter = true;
    }

    function takeFocusFromTopBar() {
        keyboardFocused = true
        selectedKeyRow = 0
        selectedKeyCol = 0
        genreListFocused = false
        resultsGridFocused = false
        lastFocusOrigin = "keyboard"
        showingAllGames = true;
        searchText = "";
        filteredGames = [];
        forceActiveFocus()
    }

    GameInfoShow {
        id: gameInfoComponent
        anchors.fill: parent
        visible: gameInfoVisible
        gameData: selectedGameForInfo
        isFavorite: gameData ? gameData.favorite : false
        opacity: gameInfoVisible ? 1.0 : 0.0

        property var parentRoot: root.parent

        getFirstGenreFunction: function(gameData) {

            if (!gameData || !gameData.genre) return "Unknown";
            var genre = gameData.genre;
            var separators = [",", "/", "-"];
            var firstPart = genre.split(separators[0])[0];
            for (var i = 1; i < separators.length; i++) {
                firstPart = firstPart.split(separators[i])[0];
            }
            return firstPart.trim() || "Unknown";
        }

        onShowingChanged: {
            if (parentRoot && typeof parentRoot.setTopBarVisible === "function") {
                parentRoot.setTopBarVisible(!showing);
            }

            if (parentRoot && parentRoot.hasOwnProperty("themeOpacity")) {
                parentRoot.themeOpacity = showing ? 0.3 : 1.0;
            }
        }

        onLaunchGame: {
            if (selectedGameForInfo) {
                selectedGameForInfo.launch()
            }
        }

        onToggleFavorite: {
            if (selectedGameForInfo) {
                selectedGameForInfo.favorite = !selectedGameForInfo.favorite
            }
        }

        onClosed: {
            gameInfoVisible = false
            selectedGameForInfo = null
            resultsGridFocused = true
            keyboardFocused = false
            genreListFocused = false
            forceActiveFocus()
        }

        enabled: visible
    }
}
