module(..., package.seeall)

local player = require("player")

function new(offx, offy, aimangle, class, px, py, pangle, grp)		--MINIMUM AND MAXIMUM CANNOT EXCEED 180 DEGREES
	local w = {}
	
	w.offx = offx
	w.offy = offy
	w.aimangle = aimangle			--ACTUAL ANGLE
	w.startangle = aimangle			--ANGLE RELATIVE TO PLAYER
	w.class = class
	w.tangle = 0					--ANGLE RELATIVE TO PLAYER
	w.localaim = aimangle			--ANGLE RELATIVE TO PLAYER
	w.grp = grp						--DETERMINES BUTTON TO FIRE WEAPON
	
	w.angle = math.atan2(offx, -offy)	
	local dx, dy = player.getCoords(w.offx, w.offy, pangle, w.angle)
	w.x, w.y = px + dx, py + dy
	
	if class == "112mm" then
		w.v = 7
		w.reloadt = 150
		w.reload = w.reloadt
		w.t = 0.05						--TURN RATE
		w.mint = -math.pi / 2
		w.maxt = math.pi / 2
		w.points = {0, -3, -2, 2, 2, 2}
		w.type = "projectile"
		w.max_range = 1500
	elseif class == "325mm" then
		w.v = 9
		w.reloadt = 480
		w.reload = w.reloadt
		w.t = 0.015						--TURN RATE
		w.mint = -3 * math.pi / 4
		w.maxt = 3 * math.pi / 4
		w.points = {0, -6, -4, 4, 4, 4}
		w.type = "projectile"
		w.max_range = 3000
	elseif class == "476mm" then
		w.v = 10
		w.reloadt = 600
		w.reload = w.reloadt
		w.t = 0.01						--TURN RATE
		w.mint = -3 * math.pi / 4
		w.maxt = 3 * math.pi / 4
		w.points = {0, -8, -5, 5, 5, 5}
		w.type = "projectile"
		w.max_range = 5000
	elseif class == "railgun" then
		w.reloadt = 1500
		w.reload = w.reloadt
		w.t = 0						--TURN RATE
		w.mint = 0
		w.maxt = 0
		w.points = {2.5, -2.5, -2.5, -2.5, -2.5, 2.5, 2.5, 2.5}
		w.type = "hitscan"
		w.max_range = 10000
	elseif class == "127mm" then
		w.v = 7
		w.reloadt = 180
		w.reload = w.reloadt
		w.t = 0.05						--TURN RATE
		w.mint = -3 * math.pi / 4
		w.maxt = 3 * math.pi / 4
		w.points = {0, -3, -2, 2, 2, 2}
		w.type = "projectile"
		w.max_range = 1500
	elseif class == "720mm" then
		w.v = 9
		w.reloadt = 1800
		w.reload = w.reloadt
		w.t = 0.025						--TURN RATE
		w.mint = -math.pi / 3
		w.maxt = math.pi / 3
		w.points = {1, -3, -1, -3, -1, 3, 1, 3}
		w.type = "projectile"
		w.max_range = 2000
	elseif class == "laser" then
		w.reloadt = 180
		w.reload = w.reloadt
		w.t = 0.05
		w.mint = -math.pi / 3
		w.maxt = math.pi / 3
		w.points = {0, -3, -2, 2, 2, 2}
		w.type = "hitscan"
		w.max_range = 600
	end
	
	return w
end