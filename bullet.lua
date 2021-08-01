module(..., package.seeall)

function new(x, y, angle, class, team)
	local b = {}
	
	b.x = x
	b.y = y
	b.angle = angle
	b.class = class
	b.distance_traveled = 0
	b.team = team			--0: PLAYER
							--1: ENEMY
	if b.class == "112mm" then									--HE SHELLS
		b.v = 7
		b.dmg = 250				--SHOULD BE DETERMINED BY SIZE OF R
		b.r = 4
		b.f = 3					--f : PERCENTAGE CHANCE TO SET FIRE, ONLY 1 FIRE PER PART OF SHIP
		b.p = 50				--p : PENETRATION CAPABILITY
		b.max_range = 1500		--WEAPON RANGE
		
		b.points = {0.75, -1.5, -0.75, -1.5, -0.75, 1.5, 0.75, 1.5}
	elseif b.class == "127mm" then
		b.v = 7
		b.dmg = 300
		b.r = 4
		b.f = 6
		b.p = 60
		b.max_range = 1500
		
		b.points = {0.75, -1.5, -0.75, -1.5, -0.75, 1.5, 0.75, 1.5}
	elseif b.class == "325mm" then								--AP SHELLS
		b.v = 8
		b.dmg = 2000
		b.r = 4
		b.f = 0
		b.p = 350
		b.max_range = 3000
		
		b.points = {1.5, 3, -1.5, 3, -1.5, -3, 1.5, -3}
	elseif b.class == "476mm" then
		b.v = 9
		b.dmg = 3000
		b.r = 5
		b.f = 0
		b.p = 450
		b.max_range = 5000
		
		b.points = {1.5, 3, -1.5, 3, -1.5, -3, 1.5, -3}
	elseif b.class == "720mm" then								--TORPEDO
		b.v = 1.25
		b.dmg = 4500
		b.r = 2
		b.f = 0
		b.p = "torpedo"
		b.range = 600		--SPOTTING RANGE
		b.max_range = 2000
		
		b.points = {1.5, 4.5, -1.5, 4.5, -1.5, -4.5, 1.5, -4.5}
	end
	
	b.move = function()
		b.x = b.x + b.v * math.cos(b.angle - math.pi / 2)	--MOVING BULLET
		b.y = b.y + b.v * math.sin(b.angle - math.pi / 2)
		
		b.distance_traveled = b.distance_traveled + b.v
	end
	
	return b
end

function hitscan(x, y, angle, class, team)
	local b = {}
	
	b.x = x
	b.y = y
	b.angle = angle
	b.class = class
	b.team = team			--0: PLAYER
							--1: ENEMY
	b.fired = false
	b.points = {}
	
	if b.class == "railgun" then
		b.dmg = 2000
		b.p = 250
		b.max_range = 10000			--WEAPON MAX RANGE
		b.width = 15
	elseif b.class == "laser" then
		b.dmg = 100
		b.p = 60
		b.max_range = 600
		b.width = 5
	end
	
	b.maxx = b.x + b.max_range * math.cos(b.angle - math.pi / 2)
	b.maxy = b.y + b.max_range * math.sin(b.angle - math.pi / 2)
	
	return b
end