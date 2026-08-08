// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

pragma Singleton
import QtQuick 2.15

QtObject {
    id: style

    property real scale: 1.0
    property real screenAspectRatio: 16 / 9

    readonly property real narrowScreenThreshold: 1.5
    readonly property bool isNarrowScreen: screenAspectRatio <= narrowScreenThreshold

    function updateScale(windowWidth, windowHeight) {
        if (windowHeight <= 0)
            return;

        scale = Math.max(0.6, Math.min(1.9, windowHeight / 600));

        if (windowWidth > 0)
            screenAspectRatio = windowWidth / windowHeight;
    }

    readonly property int spacingTiny: Math.round(5 * scale)
    readonly property int spacingSmall: Math.round(8 * scale)
    readonly property int spacingMedium: Math.round(10 * scale)
    readonly property int spacingLarge: Math.round(15 * scale)
    readonly property int spacingXLarge: Math.round(20 * scale)
    readonly property int spacingXXLarge: Math.round(30 * scale)
    readonly property int marginPage: Math.round(40 * scale)

    readonly property int fontSizeSmall: Math.round(14 * scale)
    readonly property int fontSizeMedium: Math.round(16 * scale)
    readonly property int fontSizeLarge: Math.round(28 * scale)

    readonly property int borderThin: Math.max(1, Math.round(1 * scale))
    readonly property int borderMedium: Math.max(1, Math.round(3 * scale))
    readonly property int borderThick: Math.max(1, Math.round(4 * scale))

    readonly property int radiusSmall: Math.round(4 * scale)
    readonly property int radiusMedium: Math.round(10 * scale)
    readonly property int radiusLarge: Math.round(25 * scale)

    readonly property int iconBadgeSize: Math.round(60 * scale)
    readonly property int notificationWidth: Math.round(300 * scale)
    readonly property int notificationHeight: Math.round(100 * scale)
    readonly property int scrollbarWidth: Math.max(2, Math.round(4 * scale))
    readonly property int dividerHeight: Math.max(1, Math.round(1 * scale))
    readonly property int cursorWidth: Math.max(2, Math.round(3 * scale))

    readonly property int gridColumnsWide: 4
    readonly property int gridColumnsNarrow: 3
}
