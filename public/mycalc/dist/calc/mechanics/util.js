"use strict";
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
exports.__esModule = true;

var util_1 = require("../util");
var stats_1 = require("../stats");
var EV_ITEMS = [
    'Macho Brace',
    'Power Anklet',
    'Power Band',
    'Power Belt',
    'Power Bracer',
    'Power Lens',
    'Power Weight',
];
function isGrounded(pokemon, field) {
    return (field.isGravity || pokemon.hasItem('Iron Ball') ||
        (!pokemon.hasType('Flying') &&
            !pokemon.hasAbility('Levitate') &&
            !pokemon.hasItem('Air Balloon')));
}
exports.isGrounded = isGrounded;
function getModifiedStat(stat, mod, gen) {
    if (gen && gen.num < 3) {
        if (mod >= 0) {
            var pastGenBoostTable = [1, 1.5, 2, 2.5, 3, 3.5, 4];
            stat = Math.floor(stat * pastGenBoostTable[mod]);
        }
        else {
            var numerators = [100, 66, 50, 40, 33, 28, 25];
            stat = Math.floor((stat * numerators[-mod]) / 100);
        }
        return Math.min(999, Math.max(1, stat));
    }
    var numerator = 0;
    var denominator = 1;
    var modernGenBoostTable = [
        [2, 8],
        [2, 7],
        [2, 6],
        [2, 5],
        [2, 4],
        [2, 3],
        [2, 2],
        [3, 2],
        [4, 2],
        [5, 2],
        [6, 2],
        [7, 2],
        [8, 2],
    ];
    stat = OF16(stat * modernGenBoostTable[6 + mod][numerator]);
    stat = Math.floor(stat / modernGenBoostTable[6 + mod][denominator]);
    return stat;
}
exports.getModifiedStat = getModifiedStat;
function computeFinalStats(gen, attacker, defender, field) {
    var e_1, _a, e_2, _b;
    var stats = [];
    for (var _i = 4; _i < arguments.length; _i++) {
        stats[_i - 4] = arguments[_i];
    }
    var sides = [[attacker, field.attackerSide], [defender, field.defenderSide]];
    try {
        for (var sides_1 = __values(sides), sides_1_1 = sides_1.next(); !sides_1_1.done; sides_1_1 = sides_1.next()) {
            var _c = __read(sides_1_1.value, 2), pokemon = _c[0], side = _c[1];
            try {
                for (var stats_2 = (e_2 = void 0, __values(stats)), stats_2_1 = stats_2.next(); !stats_2_1.done; stats_2_1 = stats_2.next()) {
                    var stat = stats_2_1.value;
                    if (stat === 'spe') {
                        pokemon.stats.spe = getFinalSpeed(gen, pokemon, field, side);
                    }
                    else {
                        pokemon.stats[stat] = getModifiedStat(pokemon.rawStats[stat], pokemon.boosts[stat], gen);
                    }
                }
            }
            catch (e_2_1) { e_2 = { error: e_2_1 }; }
            finally {
                try {
                    if (stats_2_1 && !stats_2_1.done && (_b = stats_2["return"])) _b.call(stats_2);
                }
                finally { if (e_2) throw e_2.error; }
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (sides_1_1 && !sides_1_1.done && (_a = sides_1["return"])) _a.call(sides_1);
        }
        finally { if (e_1) throw e_1.error; }
    }
}
exports.computeFinalStats = computeFinalStats;
function getFinalSpeed(gen, pokemon, field, side) {
    var weather = field.weather || '';
    var terrain = field.terrain;
    var speed = getModifiedStat(pokemon.rawStats.spe, pokemon.boosts.spe, gen);
    var speedMods = [];
    if (side.isTailwind)
        speedMods.push(8192);
    if ((pokemon.hasAbility('Unburden') && pokemon.abilityOn) ||
        (pokemon.hasAbility('Chlorophyll') && weather.includes('Sun')) ||
        (pokemon.hasAbility('Sand Rush') && weather === 'Sand') ||
        (pokemon.hasAbility('Swift Swim') && weather.includes('Rain')) ||
        (pokemon.hasAbility('Slush Rush') && weather === 'Hail') ||
        (pokemon.hasAbility('Surge Surfer') && terrain === 'Electric')) {
        speedMods.push(8192);
    }
    else if (pokemon.hasAbility('Quick Feet') && pokemon.status) {
        speedMods.push(6144);
    }
    else if (pokemon.hasAbility('Slow Start') && pokemon.abilityOn) {
        speedMods.push(2048);
    }
    if (pokemon.hasItem('Choice Scarf')) {
        speedMods.push(6144);
    }
    else if (pokemon.hasItem.apply(pokemon, __spreadArray(['Iron Ball'], __read(EV_ITEMS), false))) {
        speedMods.push(2048);
    }
    else if (pokemon.hasItem('Quick Powder') && pokemon.named('Ditto')) {
        speedMods.push(8192);
    }
    speed = OF32(pokeRound((speed * chainMods(speedMods, 410, 131172)) / 4096));
    if (pokemon.hasStatus('par') && !pokemon.hasAbility('Quick Feet')) {
        speed = Math.floor(OF32(speed * (gen.num < 7 ? 25 : 50)) / 100);
    }
    speed = Math.min(gen.num <= 2 ? 999 : 10000, speed);
    return Math.max(0, speed);
}
exports.getFinalSpeed = getFinalSpeed;
function getMoveEffectiveness(gen, move, type, isGhostRevealed, isGravity) {
    if (isGhostRevealed && type === 'Ghost' && move.hasType('Normal', 'Fighting')) {
        return 1;
    }
    else if (isGravity && type === 'Flying' && move.hasType('Ground')) {
        return 1;
    }
    else if (move.named('Freeze-Dry') && type === 'Water') {
        return 2;
    }
    else if (move.named('Flying Press')) {
        return (gen.types.get('fighting').effectiveness[type] *
            gen.types.get('flying').effectiveness[type]);
    }
    else {
        return gen.types.get((0, util_1.toID)(move.type)).effectiveness[type];
    }
}
exports.getMoveEffectiveness = getMoveEffectiveness;
function checkAirLock(pokemon, field) {
    if (pokemon.hasAbility('Air Lock', 'Cloud Nine')) {
        field.weather = undefined;
    }
}
exports.checkAirLock = checkAirLock;
function checkForecast(pokemon, weather) {
    if (pokemon.hasAbility('Forecast') && pokemon.named('Castform')) {
        switch (weather) {
            case 'Sun':
            case 'Harsh Sunshine':
                pokemon.types = ['Fire'];
                break;
            case 'Rain':
            case 'Heavy Rain':
                pokemon.types = ['Water'];
                break;
            case 'Hail':
                pokemon.types = ['Ice'];
                break;
            default:
                pokemon.types = ['Normal'];
        }
    }
}
exports.checkForecast = checkForecast;
function checkItem(pokemon, magicRoomActive) {
    if (pokemon.hasAbility('Klutz') && !EV_ITEMS.includes(pokemon.item) ||
        magicRoomActive) {
        pokemon.item = '';
    }
}
exports.checkItem = checkItem;
function checkWonderRoom(pokemon, wonderRoomActive) {
    var _a;
    if (wonderRoomActive) {
        _a = __read([pokemon.rawStats.spd, pokemon.rawStats.def], 2), pokemon.rawStats.def = _a[0], pokemon.rawStats.spd = _a[1];
    }
}
exports.checkWonderRoom = checkWonderRoom;
function checkIntimidate(gen, source, target) {
    var blocked = target.hasAbility('Clear Body', 'White Smoke', 'Hyper Cutter', 'Full Metal Body') ||
        (gen.num === 8 && target.hasAbility('Inner Focus', 'Own Tempo', 'Oblivious', 'Scrappy'));
    if (source.hasAbility('Intimidate') && source.abilityOn && !blocked) {
        if (target.hasAbility('Contrary', 'Defiant')) {
            target.boosts.atk = Math.min(6, target.boosts.atk + 1);
        }
        else if (target.hasAbility('Simple')) {
            target.boosts.atk = Math.max(-6, target.boosts.atk - 2);
        }
        else {
            target.boosts.atk = Math.max(-6, target.boosts.atk - 1);
        }
        if (target.hasAbility('Competitive')) {
            target.boosts.spa = Math.min(6, target.boosts.spa + 2);
        }
    }
}
exports.checkIntimidate = checkIntimidate;
function checkDownload(source, target, wonderRoomActive) {
    var _a;
    if (source.hasAbility('Download')) {
        var def = target.stats.def;
        var spd = target.stats.spd;
        if (wonderRoomActive)
            _a = __read([spd, def], 2), def = _a[0], spd = _a[1];
        if (spd <= def) {
            source.boosts.spa = Math.min(6, source.boosts.spa + 1);
        }
        else {
            source.boosts.atk = Math.min(6, source.boosts.atk + 1);
        }
    }
}
exports.checkDownload = checkDownload;
function checkIntrepidSword(source) {
    if (source.hasAbility('Intrepid Sword')) {
        source.boosts.atk = Math.min(6, source.boosts.atk + 1);
    }
}
exports.checkIntrepidSword = checkIntrepidSword;
function checkDauntlessShield(source) {
    if (source.hasAbility('Dauntless Shield')) {
        source.boosts.def = Math.min(6, source.boosts.def + 1);
    }
}
exports.checkDauntlessShield = checkDauntlessShield;
function checkInfiltrator(pokemon, affectedSide) {
    if (pokemon.hasAbility('Infiltrator')) {
        affectedSide.isReflect = false;
        affectedSide.isLightScreen = false;
        affectedSide.isAuroraVeil = false;
    }
}
exports.checkInfiltrator = checkInfiltrator;
function checkSeedBoost(pokemon, field) {
    if (!pokemon.item)
        return;
    if (field.terrain && pokemon.item.includes('Seed')) {
        var terrainSeed = pokemon.item.substring(0, pokemon.item.indexOf(' '));
        if (field.hasTerrain(terrainSeed)) {
            if (terrainSeed === 'Grassy' || terrainSeed === 'Electric') {
                pokemon.boosts.def = pokemon.hasAbility('Contrary')
                    ? Math.max(-6, pokemon.boosts.def - 1)
                    : Math.min(6, pokemon.boosts.def + 1);
            }
            else {
                pokemon.boosts.spd = pokemon.hasAbility('Contrary')
                    ? Math.max(-6, pokemon.boosts.spd - 1)
                    : Math.min(6, pokemon.boosts.spd + 1);
            }
        }
    }
}
exports.checkSeedBoost = checkSeedBoost;
function checkMultihitBoost(gen, attacker, defender, move, field, desc, usedWhiteHerb) {
    if (usedWhiteHerb === void 0) { usedWhiteHerb = false; }
    if (move.named('Gyro Ball', 'Electro Ball') && defender.hasAbility('Gooey', 'Tangling Hair')) {
        if (attacker.hasItem('White Herb') && !usedWhiteHerb) {
            desc.attackerItem = attacker.item;
            usedWhiteHerb = true;
        }
        else {
            attacker.boosts.spe = Math.max(attacker.boosts.spe - 1, -6);
            attacker.stats.spe = getFinalSpeed(gen, attacker, field, field.attackerSide);
            desc.defenderAbility = defender.ability;
        }
    }
    else if (move.named('Power-Up Punch')) {
        attacker.boosts.atk = Math.min(attacker.boosts.atk + 1, 6);
        attacker.stats.atk = getModifiedStat(attacker.rawStats.atk, attacker.boosts.atk, gen);
    }
    if (defender.hasAbility('Stamina')) {
        if (attacker.hasAbility('Unaware')) {
            desc.attackerAbility = attacker.ability;
        }
        else {
            defender.boosts.def = Math.min(defender.boosts.def + 1, 6);
            defender.stats.def = getModifiedStat(defender.rawStats.def, defender.boosts.def, gen);
            desc.defenderAbility = defender.ability;
        }
    }
    else if (defender.hasAbility('Weak Armor')) {
        if (attacker.hasAbility('Unaware')) {
            desc.attackerAbility = attacker.ability;
        }
        else {
            if (defender.hasItem('White Herb') && !usedWhiteHerb) {
                desc.defenderItem = defender.item;
                usedWhiteHerb = true;
            }
            else {
                defender.boosts.def = Math.max(defender.boosts.def - 1, -6);
                defender.stats.def = getModifiedStat(defender.rawStats.def, defender.boosts.def, gen);
            }
        }
        defender.boosts.spe = Math.min(defender.boosts.spe + 2, 6);
        defender.stats.spe = getFinalSpeed(gen, defender, field, field.defenderSide);
        desc.defenderAbility = defender.ability;
    }
    var simple = attacker.hasAbility('Simple') ? 2 : 1;
    if (move.dropsStats) {
        if (attacker.hasAbility('Unaware')) {
            desc.attackerAbility = attacker.ability;
        }
        else {
            var stat = move.category === 'Special' ? 'spa' : 'atk';
            var boosts = attacker.boosts[stat];
            if (attacker.hasAbility('Contrary')) {
                boosts = Math.min(6, boosts + move.dropsStats);
                desc.attackerAbility = attacker.ability;
            }
            else {
                boosts = Math.max(-6, boosts - move.dropsStats * simple);
                if (simple > 1)
                    desc.attackerAbility = attacker.ability;
            }
            if (attacker.hasItem('White Herb') && attacker.boosts[stat] < 0 && !usedWhiteHerb) {
                boosts += move.dropsStats * simple;
                desc.attackerItem = attacker.item;
                usedWhiteHerb = true;
            }
            attacker.boosts[stat] = boosts;
            attacker.stats[stat] = getModifiedStat(attacker.rawStats[stat], defender.boosts[stat], gen);
        }
    }
    return usedWhiteHerb;
}
exports.checkMultihitBoost = checkMultihitBoost;
function chainMods(mods, lowerBound, upperBound) {
    var e_3, _a;
    var M = 4096;
    try {
        for (var mods_1 = __values(mods), mods_1_1 = mods_1.next(); !mods_1_1.done; mods_1_1 = mods_1.next()) {
            var mod = mods_1_1.value;
            if (mod !== 4096) {
                M = (M * mod + 2048) >> 12;
            }
        }
    }
    catch (e_3_1) { e_3 = { error: e_3_1 }; }
    finally {
        try {
            if (mods_1_1 && !mods_1_1.done && (_a = mods_1["return"])) _a.call(mods_1);
        }
        finally { if (e_3) throw e_3.error; }
    }
    return Math.max(Math.min(M, upperBound), lowerBound);
}
exports.chainMods = chainMods;
function getBaseDamage(level, basePower, attack, defense) {
    return Math.floor(OF32(Math.floor(OF32(OF32(Math.floor((2 * level) / 5 + 2) * basePower) * attack) / defense) / 50 + 2));
}
exports.getBaseDamage = getBaseDamage;
function getFinalDamage(baseAmount, i, effectiveness, isBurned, stabMod, finalMod, protect) {
    var damageAmount = Math.floor(OF32(baseAmount * (85 + i)) / 100);
    if (stabMod !== 4096)
        damageAmount = OF32(damageAmount * stabMod) / 4096;
    damageAmount = Math.floor(OF32(pokeRound(damageAmount) * effectiveness));
    if (isBurned)
        damageAmount = Math.floor(damageAmount / 2);
    if (protect)
        damageAmount = pokeRound(OF32(damageAmount * 1024) / 4096);
    return OF16(pokeRound(Math.max(1, OF32(damageAmount * finalMod) / 4096)));
}
exports.getFinalDamage = getFinalDamage;
function getShellSideArmCategory(source, target) {
    var physicalDamage = source.stats.atk / target.stats.def;
    var specialDamage = source.stats.spa / target.stats.spd;
    return physicalDamage > specialDamage ? 'Physical' : 'Special';
}
exports.getShellSideArmCategory = getShellSideArmCategory;
function getWeightFactor(pokemon) {
    return pokemon.hasAbility('Heavy Metal') ? 2
        : (pokemon.hasAbility('Light Metal') || pokemon.hasItem('Float Stone')) ? 0.5 : 1;
}
exports.getWeightFactor = getWeightFactor;
function countBoosts(gen, boosts) {
    var e_4, _a;
    var sum = 0;
    var STATS = gen.num === 1
        ? ['atk', 'def', 'spa', 'spe']
        : ['atk', 'def', 'spa', 'spd', 'spe'];
    try {
        for (var STATS_1 = __values(STATS), STATS_1_1 = STATS_1.next(); !STATS_1_1.done; STATS_1_1 = STATS_1.next()) {
            var stat = STATS_1_1.value;
            var boost = boosts[stat];
            if (boost && boost > 0)
                sum += boost;
        }
    }
    catch (e_4_1) { e_4 = { error: e_4_1 }; }
    finally {
        try {
            if (STATS_1_1 && !STATS_1_1.done && (_a = STATS_1["return"])) _a.call(STATS_1);
        }
        finally { if (e_4) throw e_4.error; }
    }
    return sum;
}
exports.countBoosts = countBoosts;
function getEVDescriptionText(gen, pokemon, stat, natureName) {
    var nature = gen.natures.get((0, util_1.toID)(natureName));
    return (pokemon.evs[stat] +
        (nature.plus === nature.minus ? ''
            : nature.plus === stat ? '+'
                : nature.minus === stat ? '-'
                    : '') + ' ' +
        stats_1.Stats.displayStat(stat));
}
exports.getEVDescriptionText = getEVDescriptionText;
function handleFixedDamageMoves(attacker, move) {
    if (move.named('Seismic Toss', 'Night Shade')) {
        return attacker.level;
    }
    else if (move.named('Dragon Rage')) {
        return 40;
    }
    else if (move.named('Sonic Boom')) {
        return 20;
    }
    return 0;
}
exports.handleFixedDamageMoves = handleFixedDamageMoves;
function pokeRound(num) {
    return num % 1 > 0.5 ? Math.ceil(num) : Math.floor(num);
}
exports.pokeRound = pokeRound;
function OF16(n) {
    return n > 65535 ? n % 65536 : n;
}
exports.OF16 = OF16;
function OF32(n) {
    return n > 4294967295 ? n % 4294967296 : n;
}
exports.OF32 = OF32;
//# sourceMappingURL=util.js.map