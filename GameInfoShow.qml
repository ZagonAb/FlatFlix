import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.12
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

    opacity: showing ? 1.0 : 0.0
    visible: opacity > 0

    signal launchGame()
    signal toggleFavorite()
    signal toggleShader()
    signal closed()

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    onVisibleChanged: {
        if (visible) {
            showing = true;
            forceActiveFocus();
        }
    }

    function close() {
        showing = false;
        closeTimer.start();
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
            gameInfoShow.closed();
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
                source: gameData && gameData.assets.screenshot ? gameData.assets.screenshot : ""
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
                #version 130
                uniform sampler2D source;
                uniform lowp float qt_Opacity;
                uniform lowp float time;
                varying highp vec2 qt_TexCoord0;

                void main() {
                vec2 uv = qt_TexCoord0;

                // Curvatura CRT sutil
                vec2 centered = uv - 0.5;
                float dist = length(centered);
                uv = centered * (1.0 + 0.08 * dist * dist) + 0.5;

                // Color base
                vec4 color = texture2D(source, uv);

                // LÃ­neas de escaneo
                float scanline = sin(uv.y * 600.0) * 0.04;
                color.rgb -= scanline;

                // ViÃ±eta
                float vignette = 1.0 - 0.2 * dist;
                color.rgb *= vignette;

                // Brillo CRT
                color.rgb *= 1.1;

                // APLICAMOS SOLO LA OPACIDAD NORMAL
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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: gameInfoShow.launchGame()
                    }

                    Keys.onPressed: {
                        if (api.keys.isAccept(event)) {
                            gameInfoShow.launchGame();
                            event.accepted = true;
                        }
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

                    Keys.onPressed: {
                        if (api.keys.isAccept(event) && !isTogglingFavorite) {
                            toggleFavoriteWithLoading();
                            event.accepted = true;
                        }
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

                    Keys.onPressed: {
                        if (api.keys.isAccept(event)) {
                            toggleCrtEffect();
                            event.accepted = true;
                        }
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
        if (api.keys.isCancel(event)) {
            gameInfoShow.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
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
        } else if (event.key === Qt.Key_F) {
            gameInfoShow.toggleFavorite();
            event.accepted = true;
        }
    }
}
