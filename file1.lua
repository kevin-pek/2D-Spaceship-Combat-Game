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
	
	game.p = player.new(0, 1900, 0, "dd")

	game.c = camera.new(game.p.x, game.p.y)

	table.insert(game.enemies, enemy.new(0, 400, math.pi, "bb"))
	--[[table.insert(game.enemies, enemy.new(100, 500, math.pi, "dd"))
	table.insert(game.enemies, enemy.new(-100, 500, math.pi, "dd"))
	table.insert(game.enemies, enemy.new(0, 250, math.pi, "ca"))]]--

	table.insert(game.objects, object.new(500, 1600, 150, 1))
	table.insert(game.objects, object.new(0, 1200, 200, 1))
	table.insert(game.objects, object.new(-400, 1400, 100, 1))
end