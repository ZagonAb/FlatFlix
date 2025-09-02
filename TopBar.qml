import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: topBar
    width: parent.width
    height: root.height * 0.08
    z: 1000

    property int currentSection: 1
    property bool isFocused: false
    property var root: null
    property bool isInitialized: false

    signal focusChanged(bool hasFocus)
    signal sectionSelected(int index)

    Component.onCompleted: {
        var parentItem = parent;
        while (parentItem && parentItem.objectName !== "root") {
            parentItem = parentItem.parent;
        }
        if (parentItem) {
            root = parentItem;
        }

        Qt.callLater(function() {
            initializeTabIndicator();
        });
    }

    Item {
        id: slidingIndicator
        anchors.fill: parent

        property int targetX: 0
        property int targetWidth: 0
        property int targetHeight: 0

        Rectangle {
            id: tabIndicator
            width: slidingIndicator.targetWidth
            height: slidingIndicator.targetHeight
            x: slidingIndicator.targetX
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: topBar.isFocused ? "#ffffff" : "#1d1c1d"
            visible: isInitialized
            Behavior on x {
                enabled: isInitialized
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                enabled: isInitialized
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }
    }

    Row {
        id: navButtons
        anchors.centerIn: parent
        spacing: root ? root.width * 0.03 : 40

        NavButton {
            id: searchButton
            isIcon: true
            iconSource: "assets/icons/search.svg"
            isSelected: topBar.currentSection === 0
            isFocused: topBar.isFocused
            root: topBar.root
            showSelectionIndicator: false
            onClicked: {
                topBar.sectionSelected(0);
                updateTabIndicator(searchButton);
            }
        }

        NavButton {
            id: homeButton
            text: "Home"
            isSelected: topBar.currentSection === 1
            isFocused: topBar.isFocused
            root: topBar.root
            showSelectionIndicator: false
            onClicked: {
                topBar.sectionSelected(1);
                updateTabIndicator(homeButton);
            }
        }

        NavButton {
            id: myBitflixButton
            text: "Mi FlatFlix"
            isSelected: topBar.currentSection === 2
            isFocused: topBar.isFocused
            root: topBar.root
            showSelectionIndicator: false
            onClicked: {
                topBar.sectionSelected(2);
                updateTabIndicator(myBitflixButton);
            }
        }
    }

    function initializeTabIndicator() {
        var button;
        if (currentSection === 0) button = searchButton;
        else if (currentSection === 1) button = homeButton;
        else if (currentSection === 2) button = myBitflixButton;

        if (button) {
            var buttonPos = button.mapToItem(slidingIndicator, 0, 0);
            slidingIndicator.targetX = buttonPos.x;
            slidingIndicator.targetWidth = button.width;
            slidingIndicator.targetHeight = button.height;
        }

        isInitialized = true;
    }

    function updateTabIndicator(button) {
        if (!isInitialized) return;

        var buttonPos = button.mapToItem(slidingIndicator, 0, 0);
        slidingIndicator.targetX = buttonPos.x;
        slidingIndicator.targetWidth = button.width;
        slidingIndicator.targetHeight = button.height;
    }

    function navigate(direction) {
        if (!isFocused) return;

        var previousSection = currentSection;

        if (direction === "left" && currentSection > 0) {
            currentSection--;
        } else if (direction === "right" && currentSection < 2) {
            currentSection++;
        }

        if (previousSection !== currentSection) {
            if (currentSection === 0) updateTabIndicator(searchButton);
            else if (currentSection === 1) updateTabIndicator(homeButton);
            else if (currentSection === 2) updateTabIndicator(myBitflixButton);

            if (root && typeof root.handleSectionChangeFromTopBar === "function") {
                root.handleSectionChangeFromTopBar(currentSection);
            } else {
                sectionSelected(currentSection);
            }
        }
    }

    onIsFocusedChanged: {
        searchButton.isFocused = isFocused;
        homeButton.isFocused = isFocused;
        myBitflixButton.isFocused = isFocused;

        focusChanged(isFocused);
    }

    onWidthChanged: {
        if (isInitialized) {
            Qt.callLater(function() {
                var button;
                if (currentSection === 0) button = searchButton;
                else if (currentSection === 1) button = homeButton;
                else if (currentSection === 2) button = myBitflixButton;

                if (button) {
                    updateTabIndicator(button);
                }
            });
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
        }
    }
}
