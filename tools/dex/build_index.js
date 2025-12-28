#!/usr/bin/env node
'use strict';

const gameName = process.argv[2]
const fs = require("fs");
const path = require('path');
const child_process = require("child_process");

const rootDir = path.resolve(__dirname, '..');
process.chdir(rootDir);

const Pokedex = require('../../exports/dex/species.js').BattlePokedex;
const Moves = require('../../exports/dex/moves.js').BattleMovedex;
const Items = require('../../exports/dex/items.js').BattleItems;
const Abilities = require('../../exports/dex/abilities.js').BattleAbilities;
const TypeChart = require('./typechart.js').BattleTypeChart;

require(`../../exports/dex/${gameName}.js`)
const Locations = overrides.encs




const CompoundWordNames = require('./alias.js').BattleAliases;

function cleanString(str) {return str.replace(/[^a-zA-Z0-9]/g, '').toLowerCase()};

function toID(text) {
  var _text, _text2;
  if ((_text = text) != null && _text.id) {
    text = text.id;
  } else if ((_text2 = text) != null && _text2.userid) {
    text = text.userid;
  }
  if (typeof text !== "string" && typeof text !== "number") return "";
  return ("" + text)
    .toLowerCase()
    .replace(/é/g, "e")
    .replace(/[^a-z0-9]+/g, "");
}

function es3stringify(obj) {
	const buf = JSON.stringify(obj);
	return buf.replace(/"([A-Za-z][A-Za-z0-9]*)":/g, (fullMatch, key) => (
		['return', 'new', 'delete'].includes(key) ? fullMatch : `${key}:`
	));
}

function requireNoCache(pathSpec) {
	delete require.cache[require.resolve(pathSpec)];
	return require(pathSpec);
}


function getItem(collection, str) {
	if (collection[str]) {
		return collection[str]
	} else {
		if (CompoundWordNames[str]) {		
			return {name: collection[CompoundWordNames[str]]}
		}
	}
	return {name: str}
}

/*********************************************************
 * Build search-index.js
 *********************************************************/

{
	process.stdout.write("Building `searchindex`... ");

	let index = [];

	index = index.concat(Object.keys(Pokedex).map(x => cleanString(x) + ' pokemon'));
	index = index.concat(Object.keys(Moves).map(x => cleanString(x) + ' move'));
	index = index.concat(Object.keys(Items).map(x => x + ' item'));
	index = index.concat(Object.keys(Abilities).map(x => x + ' ability'));
	index = index.concat(Object.keys(TypeChart).map(x => toID(x) + ' type'));
	index = index.concat(Object.keys(Locations).map(x => toID(x) + ' location'));
	index = index.concat(['physical', 'special', 'status'].map(x => toID(x) + ' category'));

	const compoundTable = CompoundWordNames;
	// generate aliases
	function generateAlias(id, name, type) {
		name = compoundTable[id] || name;
		
		// name = name.toLowerCase()
		
		if (type === 'pokemon' && !compoundTable[id]) {
			const species = Pokedex[id];
			const baseid = toID(species.baseSpecies);
			if (baseid !== id) {
				name = (compoundTable[baseid] || species.baseSpecies) + ' ' + species.forme;
			}
		}
		if (name.endsWith(' Mega-X') || name.endsWith(' Mega-Y')) {
			index.push('mega' + toID(name.slice(0, -7) + name.slice(-1)) + ' ' + type + ' ' + id + ' 0');
			index.push('m' + toID(name.slice(0, -7) + name.slice(-1)) + ' ' + type + ' ' + id + ' 0');
			index.push('mega' + toID(name.slice(-1)) + ' ' + type + ' ' + id + ' ' + toID(name.slice(0, -7)).length);
		} else if (name.endsWith(' Mega')) {
			index.push('mega' + toID(name.slice(0, -5)) + ' ' + type + ' ' + id + ' 0');
			index.push('m' + toID(name.slice(0, -5)) + ' ' + type + ' ' + id + ' 0');
		} else if (name.endsWith(' Alola')) {
			index.push('alolan' + toID(name.slice(0, -6)) + ' ' + type + ' ' + id + ' 0');
		} else if (name.endsWith(' Galar')) {
			index.push('galarian' + toID(name.slice(0, -6)) + ' ' + type + ' ' + id + ' 0');
		} else if (name.endsWith(' Hisui')) {
			index.push('hisuian' + toID(name.slice(0, -6)) + ' ' + type + ' ' + id + ' 0');
		}
		const fullSplit = name.split(/ |-/).map(toID);
		if (fullSplit.length < 2) return;
		const fullAcronym = fullSplit.map(x => x.charAt(0)).join('') + fullSplit.at(-1).slice(1);
		index.push('' + fullAcronym + ' ' + type + ' ' + id + ' 0');
		for (let i = 1; i < fullSplit.length; i++) {
			index.push('' + fullSplit.slice(i).join('') + ' ' + type + ' ' + id + ' ' + fullSplit.slice(0, i).join('').length);
		}

		const spaceSplit = name.split(' ').map(toID);
		if (spaceSplit.length !== fullSplit.length) {
			const spaceAcronym = spaceSplit.map(x => x.charAt(0)).join('') + spaceSplit.at(-1).slice(1);
			if (spaceAcronym !== fullAcronym) {
				index.push('' + spaceAcronym + ' ' + type + ' ' + id + ' 0');
			}
		}
	}
	for (const id in Pokedex) {
		const name = Pokedex[id].name;
		if (Pokedex[id].isCosmeticForme) continue;
		generateAlias(id, name, 'pokemon');
	}
	for (const id in Moves) {
		const name = Moves[id].name;
		generateAlias(id, name, 'move');
	}
	for (const id in Items) {
		const name = Items[id].name;
		generateAlias(id, name, 'item');
	}
	for (const id in Abilities) {
		const name = Abilities[id].name;
		generateAlias(id, name, 'ability');
	}

	for (const id in Locations) {
		if (id == "rates") {
			continue;
		}
		const name = Locations[id].name;
		generateAlias(id, name, 'location');
	}

	// hardcode ultra beasts
	const ultraBeasts = {
		ub01symbiont: "nihilego",
		ub02absorption: "buzzwole",
		ub02beauty: "pheromosa",
		ub03lightning: "xurkitree",
		ub04blade: "kartana",
		ub04blaster: "celesteela",
		ub05glutton: "guzzlord",
		ubburst: "blacephalon",
		ubassembly: "stakataka",
		ubadhesive: "poipole",
		ubstinger: "naganadel",
	};
	for (const [ubCode, id] of Object.entries(ultraBeasts)) {
		index.push(`${ubCode} pokemon ${id} 0`);
	}

	index.sort();

	// manually rearrange
	index[index.indexOf('grass type')] = 'grass egggroup';
	index[index.indexOf('grass egggroup')] = 'grass type';

	index[index.indexOf('fairy type')] = 'fairy egggroup';
	index[index.indexOf('fairy egggroup')] = 'fairy type';

	index[index.indexOf('flying type')] = 'flying egggroup';
	index[index.indexOf('flying egggroup')] = 'flying type';

	index[index.indexOf('dragon type')] = 'dragon egggroup';
	index[index.indexOf('dragon egggroup')] = 'dragon type';

	index[index.indexOf('bug type')] = 'bug egggroup';
	index[index.indexOf('bug egggroup')] = 'bug type';

	index[index.indexOf('psychic type')] = 'psychic move';
	index[index.indexOf('psychic move')] = 'psychic type';

	index[index.indexOf('ditto pokemon')] = 'ditto egggroup';
	index[index.indexOf('ditto egggroup')] = 'ditto pokemon';

	const BattleSearchIndex = index.map(x => {
		x = x.split(' ');
		if (x.length > 3) {
			x[3] = Number(x[3]);
			x[2] = index.indexOf(x[2] + ' ' + x[1]);
		}
		return x;
	});


	const BattleSearchIndexOffset = BattleSearchIndex.map(entry => {
		const id = entry[0];
		let name = '';

		switch (entry[1]) {
		case 'pokemon': name = getItem(Pokedex, id).name || id; break;
		case 'move': name = getItem(Moves, id).name || id; break;
		case 'item': name = getItem(Items, id).name || id; break;
		case 'ability': name = getItem(Abilities, id).name || id; break;
		case 'location': name = getItem(Locations, id).name || id; break;
		case 'article': name = '' || ''; break;
		}
		let res = '';
		let nonAlnum = 0;
		for (let i = 0, j = 0; i < id.length; i++, j++) {
			while (!/[a-zA-Z0-9]/.test(name[j])) {
				j++;
				nonAlnum++;
			}
			res += nonAlnum;
		}
		if (nonAlnum) return res;
		return '';
	});

	const BattleSearchCountIndex = {};
	for (const type in TypeChart) {
		BattleSearchCountIndex[type + ' move'] = Object.keys(Moves)
			.filter(id => (Moves[id].type === type)).length;
	}

	for (const type in TypeChart) {
		BattleSearchCountIndex[type + ' pokemon'] = Object.keys(Pokedex)
			.filter(id => (
				!Pokedex[id].isCosmeticForme &&
				Pokedex[id].types.indexOf(type) >= 0
			)).length;
	}

	let buf = '// DO NOT EDIT - automatically built with build-tools/build-indexes\n\n';

	buf += 'exports.BattleSearchIndex = ' + JSON.stringify(BattleSearchIndex) + ';\n\n';

	buf += 'exports.BattleSearchIndexOffset = ' + JSON.stringify(BattleSearchIndexOffset) + ';\n\n';

	buf += 'exports.BattleSearchCountIndex = ' + JSON.stringify(BattleSearchCountIndex) + ';\n\n';

	buf += 'exports.BattleArticleTitles = {}' + ';\n\n';

	fs.writeFileSync(`../exports/dex/${gameName}-searchindex.js`, buf);
}

console.log("DONE");