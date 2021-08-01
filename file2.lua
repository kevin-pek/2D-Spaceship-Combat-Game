module(..., package.seeall)

local game = require ("game")
local player = require ("player")
local enemy = require ("enemy")
local camera = require ("camera")
local object = require ("object")

function init_lvl()
	game.minx = -1000
	game.miny = -1000
	game.maxx = 1000
	game.maxy = 2000
	
	game.p = player.new(700, 400, 0, "bb")

	game.c = camera.new(game.p.x, game.p.y)

	table.insert(game.enemies, enemy.new(400, 400, 0, "bb"))
	table.insert(game.enemies, enemy.new(1400, 400, 0, "ca"))

	table.insert(game.objects, object.new(700, 200, 70, 1))
	table.insert(game.objects, object.new(700, 500, 100, 1))
	table.insert(game.objects, object.new(1500, 500, 70, 1))
	table.insert(game.objects, object.new(500, 30, 120, 1))
end