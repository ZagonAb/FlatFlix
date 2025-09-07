
function getUniqueGenresFromGames(maxGenres) {
    var uniqueGenres = new Set();
    var genreCount = {};

    for (var i = 0; i < api.allGames.count; i++) {
        var game = api.allGames.get(i);
        if (game && game.genre) {
            var cleanedGenres = cleanAndSplitGenres(game.genre);
            cleanedGenres.forEach(function(genre) {
                if (genre && genre.trim() !== "") {
                    var cleanGenre = genre.trim();
                    uniqueGenres.add(cleanGenre);

                    if (!genreCount[cleanGenre]) {
                        genreCount[cleanGenre] = 0;
                    }
                    genreCount[cleanGenre]++;
                }
            });
        }
    }

    var genresArray = Array.from(uniqueGenres);
    genresArray.sort(function(a, b) {
        return (genreCount[b] || 0) - (genreCount[a] || 0);
    });

    if (maxGenres && maxGenres > 0) {
        return genresArray.slice(0, maxGenres);
    }

    return genresArray;
}

function cleanAndSplitGenres(genreText) {
    if (!genreText) return [];

    var separators = [",", "/", "-", "&", "|", ";"];
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

        if (cleaned.length > 0 &&
            cleaned.toLowerCase() !== "and" &&
            cleaned.toLowerCase() !== "or" &&
            cleaned.toLowerCase() !== "game" &&
            cleaned.length > 2) {
            cleanedParts.push(cleaned);
            }
    }

    return cleanedParts;
}

function getFirstGenre(gameData) {
    if (!gameData || !gameData.genre) return "Unknown";

    var cleanedGenres = cleanAndSplitGenres(gameData.genre);
    return cleanedGenres.length > 0 ? cleanedGenres[0] : "Unknown";
}

var CFG = {
    XP_PER_HOUR: 10,
    XP_PER_LAUNCH: 3,

    LEVEL_BASE: 100,
    LEVEL_ALPHA: 1.6,

    SESSION_RATE_PER_HOUR: 0.05,
    SESSION_BONUS_CAP: 0.50,

    STREAK_BONUS: [
        { days: 30, mult: 0.40 },
        { days: 14, mult: 0.20 },
        { days: 7,  mult: 0.10 },
        { days: 3,  mult: 0.05 }
    ],

    DAILY_SOFT_HOURS: 4,
    DAILY_MED_HOURS: 8,
    DAILY_HARD_HOURS: 12,
    MULT_FIRST: 1.0,
    MULT_SOFT: 0.5,
    MULT_MED: 0.25,
    MULT_AFTER_HARD: 0.0,

    DISTINCT_MIN_SECONDS: 30 * 60,

    DAILY_HISTORY_KEEP: 90
};

function xpToReachLevel(L) {
    if (L <= 1) return 0;
    return Math.floor(CFG.LEVEL_BASE * Math.pow(L - 1, CFG.LEVEL_ALPHA));
}

function levelFromXP(xp) {
    var L = 1;
    while (xp >= xpToReachLevel(L + 1)) L++;
    return L;
}

function progressWithinLevel(xp) {
    var L = levelFromXP(xp);
    var start = xpToReachLevel(L);
    var next = xpToReachLevel(L + 1);
    return {
        level: L,
        current: xp - start,
        needed: next - start,
        ratio: (next - start) > 0 ? (xp - start) / (next - start) : 1
    };
}

function computeTotals(allGames) {
    var seconds = 0;
    var launches = 0;
    var distinct = 0;
    var lastPlayedMax = 0;
    for (var i = 0; i < allGames.count; i++) {
        var g = allGames.get(i);
        seconds += g.playTime || 0;
        launches += g.playCount || 0;
        if ((g.playTime || 0) >= CFG.DISTINCT_MIN_SECONDS) distinct++;
        if (g.lastPlayed && g.lastPlayed.getTime() > lastPlayedMax) lastPlayedMax = g.lastPlayed.getTime();
    }
    return { seconds: seconds, launches: launches, distinctGames30m: distinct, lastPlayedMax: lastPlayedMax };
}

function isoDay(ts) {
    var d = new Date(ts);
    var y = d.getFullYear();
    var m = ("0" + (d.getMonth() + 1)).slice(-2);
    var day = ("0" + d.getDate()).slice(-2);
    return y + "-" + m + "-" + day;
}

function todayISO() {
    return isoDay(Date.now());
}

function daysBetweenISO(a, b) {
    var da = new Date(a + "T00:00:00");
    var db = new Date(b + "T00:00:00");
    return Math.round((db - da) / 86400000);
}

function clamp(n, a, b) { return Math.max(a, Math.min(b, n)); }

function xpFromHoursWithDailyCurve(hoursAlreadyToday, deltaHours, xpPerHour) {
    var xp = 0;
    var remaining = deltaHours;

    function take(portionHours, mult) {
        var h = Math.max(0, Math.min(remaining, portionHours));
        xp += h * xpPerHour * mult;
        remaining -= h;
    }

    var h1 = clamp(CFG.DAILY_SOFT_HOURS - hoursAlreadyToday, 0, deltaHours);
    take(h1, CFG.MULT_FIRST);

    var after1 = hoursAlreadyToday + h1;
    var h2limitStart = Math.max(after1, CFG.DAILY_SOFT_HOURS);
    var h2limitEnd = CFG.DAILY_MED_HOURS;
    var h2 = clamp(h2limitEnd - h2limitStart, 0, remaining);
    take(h2, CFG.MULT_SOFT);

    var after2 = hoursAlreadyToday + h1 + h2;
    var h3limitStart = Math.max(after2, CFG.DAILY_MED_HOURS);
    var h3limitEnd = CFG.DAILY_HARD_HOURS;
    var h3 = clamp(h3limitEnd - h3limitStart, 0, remaining);
    take(h3, CFG.MULT_MED);

    take(remaining, CFG.MULT_AFTER_HARD);

    return xp;
}

function sessionBonusMultiplier(approxSessionHours) {
    if (approxSessionHours <= 1) return 1;
    var extra = (approxSessionHours - 1) * CFG.SESSION_RATE_PER_HOUR;
    return 1 + Math.min(CFG.SESSION_BONUS_CAP, Math.max(0, extra));
}

function streakBonusMultiplier(streakDays) {
    for (var i = 0; i < CFG.STREAK_BONUS.length; i++) {
        if (streakDays >= CFG.STREAK_BONUS[i].days) {
            return 1 + CFG.STREAK_BONUS[i].mult;
        }
    }
    return 1;
}

var BADGES = {
    time: [
        { id: "time_5h",    hours: 5,    level: "bronze",   name: "Beginner", icon: "assets/badges/time-bronze.svg" },
        { id: "time_10h",   hours: 10,   level: "silver",   name: "Apprentice", icon: "assets/badges/time-silver.svg" },
        { id: "time_25h",   hours: 25,   level: "gold",     name: "Amateur", icon: "assets/badges/time-gold.svg" },
        { id: "time_50h",   hours: 50,   level: "platinum", name: "Advanced", icon: "assets/badges/time-platinum.svg" },
        { id: "time_100h",  hours: 100,  level: "diamond",  name: "Veteran", icon: "assets/badges/time-diamond.svg" },
        { id: "time_250h",  hours: 250,  level: "mythic",   name: "Fanatic", icon: "assets/badges/time-mythic.svg" },
        { id: "time_500h",  hours: 500,  level: "mythic2",  name: "Devotee", icon: "assets/badges/time-mythic2.svg" },
        { id: "time_1000h", hours: 1000, level: "legend",   name: "Legend", icon: "assets/badges/time-legend.svg" },
        { id: "time_2500h", hours: 2500, level: "legend2",  name: "Epic", icon: "assets/badges/time-legend2.svg" },
        { id: "time_5000h", hours: 5000, level: "legend3",  name: "Mythical", icon: "assets/badges/time-legend3.svg" },
        { id: "time_10000h",hours: 10000,level: "immortal", name: "Immortal", icon: "assets/badges/time-immortal.svg" }
    ],
    playcount: [
        { id: "pc_10",  count: 10,  name: "Visitor", icon: "assets/badges/playcount-10.svg" },
        { id: "pc_25",  count: 25,  name: "Curious", icon: "assets/badges/playcount-25.svg" },
        { id: "pc_50",  count: 50,  name: "Regular", icon: "assets/badges/playcount-50.svg" },
        { id: "pc_100", count: 100, name: "Frequent", icon: "assets/badges/playcount-100.svg" },
        { id: "pc_250", count: 250, name: "Constant", icon: "assets/badges/playcount-250.svg" },
        { id: "pc_500", count: 500, name: "Stubborn", icon: "assets/badges/playcount-500.svg" },
        { id: "pc_1000",count: 1000,name: "Tireless", icon: "assets/badges/playcount-1000.svg" }
    ],
    streak: [
        { id: "streak_3",  days: 3,   name: "Warming up", icon: "assets/badges/streak-3.svg" },
        { id: "streak_7",  days: 7,   name: "Routine", icon: "assets/badges/streak-7.svg" },
        { id: "streak_14", days: 14,  name: "Habit", icon: "assets/badges/streak-14.svg" },
        { id: "streak_30", days: 30,  name: "Discipline", icon: "assets/badges/streak-30.svg" },
        { id: "streak_60", days: 60,  name: "Dedication", icon: "assets/badges/streak-60.svg" },
        { id: "streak_100",days: 100, name: "Devotion", icon: "assets/badges/streak-100.svg" }
    ],
    variety: [
        { id: "var_5",  distinct: 5,   name: "Explorer", icon: "assets/badges/variety-5.svg" },
        { id: "var_10", distinct: 10,  name: "Curator", icon: "assets/badges/variety-10.svg" },
        { id: "var_20", distinct: 20,  name: "Select", icon: "assets/badges/variety-20.svg" },
        { id: "var_50", distinct: 50,  name: "Collector", icon: "assets/badges/variety-50.svg" },
        { id: "var_100",distinct: 100, name: "Archivist", icon: "assets/badges/variety-100.svg" }
    ]
};

function checkBadges(state, totals, todaySessionHours, streakDays) {
    var earned = state.badges && state.badges.earned ? state.badges.earned : [];
    var earnedSet = {};
    for (var i = 0; i < earned.length; i++) earnedSet[earned[i]] = true;

    var newly = [];

    var hoursTotal = (totals.seconds || 0) / 3600.0;
    for (i = 0; i < BADGES.time.length; i++) {
        var b = BADGES.time[i];
        if (!earnedSet[b.id] && hoursTotal >= b.hours) { earned.push(b.id); newly.push(b); }
    }

    for (i = 0; i < BADGES.playcount.length; i++) {
        b = BADGES.playcount[i];
        if (!earnedSet[b.id] && (totals.launches || 0) >= b.count) { earned.push(b.id); newly.push(b); }
    }

    for (i = 0; i < BADGES.streak.length; i++) {
        b = BADGES.streak[i];
        if (!earnedSet[b.id] && streakDays >= b.days) { earned.push(b.id); newly.push(b); }
    }

    for (i = 0; i < BADGES.variety.length; i++) {
        b = BADGES.variety[i];
        if (!earnedSet[b.id] && (totals.distinctGames30m || 0) >= b.distinct) { earned.push(b.id); newly.push(b); }
    }

    state.badges = state.badges || {};
    state.badges.earned = earned;
    return newly;
}

function updateProgress(state, allGames) {
    state = state || {};
    state.xp = state.xp || 0;
    state.level = state.level || 1;
    state.totals = state.totals || { seconds: 0, launches: 0, distinctGames30m: 0 };
    state.lastSnapshot = state.lastSnapshot || { seconds: 0, launches: 0 };
    state.daily = state.daily || {};
    state.streak = state.streak || { current: 0, best: 0, lastDay: null };
    state.badges = state.badges || { earned: [] };

    var totals = computeTotals(allGames);

    var deltaSeconds = Math.max(0, (totals.seconds || 0) - (state.lastSnapshot.seconds || 0));
    var deltaLaunches = Math.max(0, (totals.launches || 0) - (state.lastSnapshot.launches || 0));

    var day = totals.lastPlayedMax ? isoDay(totals.lastPlayedMax) : todayISO();

    var lastDay = state.streak.lastDay;
    if (!lastDay) {
        state.streak.current = 1;
    } else {
        var gap = daysBetweenISO(lastDay, day);
        if (gap === 0) {
        } else if (gap === 1) {
            state.streak.current += 1;
        } else if (gap > 1) {
            state.streak.current = 1;
        }
    }
    state.streak.best = Math.max(state.streak.best || 0, state.streak.current || 0);
    state.streak.lastDay = day;

    var secondsTodayBefore = state.daily[day] || 0;
    var hoursBefore = secondsTodayBefore / 3600.0;

    var deltaHours = deltaSeconds / 3600.0;
    var baseXPFromTime = xpFromHoursWithDailyCurve(hoursBefore, deltaHours, CFG.XP_PER_HOUR);
    var approxSessionHours = deltaHours;
    var multSession = sessionBonusMultiplier(approxSessionHours);
    var multStreak = streakBonusMultiplier(state.streak.current || 0);

    var xpTime = Math.floor(baseXPFromTime * multSession * multStreak);
    var xpLaunch = deltaLaunches * CFG.XP_PER_LAUNCH;

    var varietyXP = 0;
    var prevDistinct = state.totals.distinctGames30m || 0;
    var newDistinct = totals.distinctGames30m || 0;
    if (newDistinct > prevDistinct) {
        varietyXP = (newDistinct - prevDistinct) * 20;
    }

    var gainedXP = xpTime + xpLaunch + varietyXP;

    state.daily[day] = secondsTodayBefore + deltaSeconds;
    state.lastSnapshot.seconds = totals.seconds || 0;
    state.lastSnapshot.launches = totals.launches || 0;
    state.totals = totals;

    var keep = {};
    var today = todayISO();
    for (var key in state.daily) {
        if (!state.daily.hasOwnProperty(key)) continue;
        if (daysBetweenISO(key, today) <= CFG.DAILY_HISTORY_KEEP) {
            keep[key] = state.daily[key];
        }
    }
    state.daily = keep;

    state.xp += gainedXP;
    state.level = levelFromXP(state.xp);

    var newly = checkBadges(state, totals, approxSessionHours, state.streak.current || 0);
    var prog = progressWithinLevel(state.xp);

    return {
        state: state,
        gained: { xpTime: xpTime, xpLaunch: xpLaunch, varietyXP: varietyXP, total: gainedXP },
        level: prog.level,
        progress: prog,
        newBadges: newly
    };
}

var Achievements = {
    CFG: CFG,
    updateProgress: updateProgress,
    computeTotals: computeTotals,
    xpToReachLevel: xpToReachLevel,
    levelFromXP: levelFromXP,
    progressWithinLevel: progressWithinLevel,
    getBadgeIcon: function(badgeId) {
        for (var category in BADGES) {
            for (var i = 0; i < BADGES[category].length; i++) {
                if (BADGES[category][i].id === badgeId) {
                    return BADGES[category][i].icon;
                }
            }
        }
        return "";
    },
    getBadgeName: function(badgeId) {
        for (var category in BADGES) {
            for (var i = 0; i < BADGES[category].length; i++) {
                if (BADGES[category][i].id === badgeId) {
                    return BADGES[category][i].name;
                }
            }
        }
        return "";
    }
};

function calculateTotalXP() {
    var state = api.memory.get("achievementState") || {};
    return state.xp || 0;
}

function getLevelFromXP(xp) {
    var level = levelFromXP(xp);

    var levelData = [
        { level: 1, name: "Rookie", icon: "assets/levels/level-1.svg", xpRequired: 0 },
        { level: 2, name: "Apprentice", icon: "assets/levels/level-2.svg", xpRequired: 100 },
        { level: 3, name: "Explorer", icon: "assets/levels/level-3.svg", xpRequired: 300 },
        { level: 4, name: "Advanced", icon: "assets/levels/level-4.svg", xpRequired: 600 },
        { level: 5, name: "Expert", icon: "assets/levels/level-5.svg", xpRequired: 1000 },
        { level: 6, name: "Teacher", icon: "assets/levels/level-6.svg", xpRequired: 1500 },
        { level: 7, name: "Legend", icon: "assets/levels/level-7.svg", xpRequired: 2100 },
        { level: 8, name: "Mythical", icon: "assets/levels/level-8.svg", xpRequired: 2800 },
        { level: 9, name: "Divine", icon: "assets/levels/level-9.svg", xpRequired: 3600 },
        { level: 10, name: "Omnipotent", icon: "assets/levels/level-10.svg", xpRequired: 4500 }
    ];

    if (level <= 10) {
        return levelData[level - 1];
    } else {

        var baseLevel = 10;
        var baseXP = levelData[9].xpRequired;
        var levelRange = "";
        if (level <= 20) levelRange = "I";
        else if (level <= 30) levelRange = "II";
        else if (level <= 40) levelRange = "III";
        else if (level <= 50) levelRange = "IV";
        else levelRange = "V";

        return {
            level: level,
            name: "Teacher " + levelRange,
            icon: "assets/levels/level-master.svg",
            xpRequired: xpToReachLevel(level)
        };
    }
}

function getProgressToNextLevel(xp, currentLevel) {
    var progress = progressWithinLevel(xp);
    return progress.ratio;
}

function calculateGameXP(game) {
    if (!game) return 0;

    const hoursPlayed = game.playTime / 3600;
    const playCount = game.playCount || 0;

    let xp = hoursPlayed * 5;
    xp += playCount * 2;

    if (game.lastPlayed && game.lastPlayed.getTime() > 0) {
        const daysSinceLastPlay = (new Date() - game.lastPlayed) / (1000 * 60 * 60 * 24);
        if (daysSinceLastPlay <= 30) {
            xp += Math.max(0, (30 - daysSinceLastPlay) * 0.5);
        }
    }

    return Math.round(xp);
}

function getGameBadges(game) {
    const badges = [];
    const hoursPlayed = game.playTime / 3600;

    if (hoursPlayed >= 30) badges.push({ type: "time", level: "platinum", name: "Addict", icon: "assets/badges/time-platinum.svg" });
    else if (hoursPlayed >= 10) badges.push({ type: "time", level: "gold", name: "Fanatic", icon: "assets/badges/time-gold.svg" });
    else if (hoursPlayed >= 5) badges.push({ type: "time", level: "silver", name: "Enthusiast", icon: "assets/badges/time-silver.svg" });
    else if (hoursPlayed >= 1) badges.push({ type: "time", level: "bronze", name: "Beginner", icon: "assets/badges/time-bronze.svg" });

    if (game.playCount >= 20) badges.push({ type: "frequency", level: "platinum", name: "Habit", icon: "assets/badges/freq-platinum.svg" });
    else if (game.playCount >= 10) badges.push({ type: "frequency", level: "gold", name: "Regular", icon: "assets/badges/freq-gold.svg" });
    else if (game.playCount >= 5) badges.push({ type: "frequency", level: "silver", name: "Occasional", icon: "assets/badges/freq-silver.svg" });

    if (game.lastPlayed) {
        const daysSinceLastPlay = (new Date() - game.lastPlayed) / (1000 * 60 * 60 * 24);
        if (daysSinceLastPlay <= 7) {
            badges.push({ type: "recent", level: "gold", name: "Recent", icon: "assets/badges/recent.svg" });
        }
    }

    return badges;
}

