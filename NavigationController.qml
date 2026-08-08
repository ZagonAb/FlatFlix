// Copyright (C) [2025] [Gonzalo Abbate]
// This file is part of the [FlatFlix] theme for Pegasus Frontend.
// SPDX-License-Identifier: GPL-3.0-or-later
// See the LICENSE file for more information.

import QtQuick 2.15

QtObject {
    id: nav

    property var allCollections: []
    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property var _gameMemory: ({})

    function _collectionKey(collection, index) {
        if (!collection) return "idx:" + index;
        return (collection.shortName || collection.name || "col") + ":" + index;
    }

    function getCurrentCollection() {
        return (currentCollectionIndex >= 0 && currentCollectionIndex < allCollections.length)
            ? allCollections[currentCollectionIndex]
            : null;
    }

    function getCurrentGame() {
        var collection = getCurrentCollection();
        return (collection && currentGameIndex >= 0 && currentGameIndex < collection.games.count)
            ? collection.games.get(currentGameIndex)
            : null;
    }

    function _rememberCurrentGameIndex() {
        var collection = getCurrentCollection();
        if (!collection) return;
        _gameMemory[_collectionKey(collection, currentCollectionIndex)] = currentGameIndex;
    }

    function _recallGameIndexFor(collectionIndex) {
        if (collectionIndex < 0 || collectionIndex >= allCollections.length) return 0;
        var collection = allCollections[collectionIndex];
        var key = _collectionKey(collection, collectionIndex);
        var remembered = _gameMemory[key];
        if (remembered === undefined) return 0;
        var count = (collection.games && collection.games.count) ? collection.games.count : 0;
        return remembered < count ? remembered : 0;
    }

    function moveGameRight() {
        var collection = getCurrentCollection();
        if (collection && currentGameIndex < collection.games.count - 1) {
            currentGameIndex++;
            _rememberCurrentGameIndex();
        }
    }

    function moveGameLeft() {
        if (currentGameIndex > 0) {
            currentGameIndex--;
            _rememberCurrentGameIndex();
        }
    }

    function moveCollectionDown() {
        if (currentCollectionIndex < allCollections.length - 1) {
            _rememberCurrentGameIndex();
            currentCollectionIndex++;
            currentGameIndex = _recallGameIndexFor(currentCollectionIndex);
        }
    }

    function moveCollectionUp() {
        if (currentCollectionIndex > 0) {
            _rememberCurrentGameIndex();
            currentCollectionIndex--;
            currentGameIndex = _recallGameIndexFor(currentCollectionIndex);
        }
    }

    function selectGame(collectionIndex, gameIndex) {
        if (collectionIndex < 0 || collectionIndex >= allCollections.length) return;
        currentCollectionIndex = collectionIndex;
        currentGameIndex = gameIndex;
        _rememberCurrentGameIndex();
    }

    function clampToValidRange() {
        if (currentCollectionIndex >= allCollections.length) {
            currentCollectionIndex = 0;
        }
        var collection = getCurrentCollection();
        if (collection && currentGameIndex >= collection.games.count) {
            currentGameIndex = 0;
        }
    }

    function resetTo(collectionIndex, gameIndex) {
        currentCollectionIndex = (collectionIndex !== undefined) ? collectionIndex : 0;
        currentGameIndex = (gameIndex !== undefined) ? gameIndex : 0;
    }

    function forgetMemory() {
        _gameMemory = {};
    }
}
