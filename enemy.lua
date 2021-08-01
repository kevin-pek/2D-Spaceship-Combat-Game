module(..., package.seeall)

local game = require("game")
local weapon = require("weapon")
local bullet = require("bullet")

function new(x, y, angle, class)
	local p = {}
	
	p.x = x
	p.y = y
	p.angle = angle
	p.v = 0													--VELOCITY
	p.t = 0													--TURN RATE
	p.class = class
	p.parts = {}											--PLAYER SHIP SECTIONS
	p.explosions = {}					--TO SHOW BULLET IMPACTS
	p.spotted = 0
	
	p.state = "seek"		--AI STATE
	p.combat = 1			--WHETHER WEAPONS ARE ACTIVE
	p.target_x = 0	--POSITION TO MOVE TO
	p.target_y = 0
	p.aim_x = 0			--POSITION TO AIM AT
	p.aim_y = 0
	
	if class == "ca" then												--CORE OF SHIP SHOULD ALWAYS BE FIRST PART IN P.PARTS LIST
		p.a = 0.0025						--FORWARD THRUST
		p.tf = 0.000025					--TURNING FORCE
		p.vcap = 0.8						--MAX VELOCITY
		p.tcap = 0.003					--MAX TURN RATE
		p.hp = 15000
		p.thp = 15000
		p.spot = 2000		--DISTANCE FROM WHICH SHIP CAN BE SPOTTED
																							--PART GROUPS: 0 - CORE -> PLAYER DIES IF PART DESTROYED
		table.insert(p.parts, newpart(0, 15, "ca_core", p.x, p.y, p.angle, "ca"))								-- 1 - BODY -> NO EFFECT WHEN DESTROYED
		table.insert(p.parts, newpart(0, -25, "ca_front", p.x, p.y, p.angle, "ca"))								-- 2 - THRUSTER -> ACCELERATION DROPS WHEN DESTROYED
		table.insert(p.parts, newpart(11.5, -25, "ca_frontleft", p.x, p.y, p.angle, "ca"))							-- 3 - SHIELD -> SHIELD IS DISABLED WHEN PART IS DESTROYED
		table.insert(p.parts, newpart(-11.5, -25, "ca_frontright", p.x, p.y, p.angle, "ca"))
		table.insert(p.parts, newpart(21.5, 26, "ca_thruster", p.x, p.y, p.angle, "ca"))
		table.insert(p.parts, newpart(-21.5, 26, "ca_thruster", p.x, p.y, p.angle, "ca"))
	elseif class == "dd" then
		p.a = 0.01
		p.tf = 0.0001
		p.vcap = 1
		p.tcap = 0.005
		p.hp = 6000
		p.thp = 6000
		p.spot = 700		--DISTANCE FROM WHICH SHIP CAN BE SPOTTED
		
		table.insert(p.parts, newpart(0, -7.5, "dd_main", p.x, p.y, p.angle, "dd"))
		table.insert(p.parts, newpart(0, -27, "dd_front", p.x, p.y, p.angle, "dd"))
		table.insert(p.parts, newpart(0, 15, "dd_back", p.x, p.y, p.angle, "dd"))
		table.insert(p.parts, newpart(8.5, 28, "dd_thruster", p.x, p.y, p.angle, "dd"))
		table.insert(p.parts, newpart(-8.5, 28, "dd_thruster", p.x, p.y, p.angle, "dd"))
	elseif class == "bb" then
		p.a = 0.0007
		p.tf = 0.000003
		p.vcap = 0.7
		p.tcap = 0.002
		p.hp = 30000
		p.thp = 30000
		p.spot = 3000
		
		table.insert(p.parts, newpart(0, 0, "bb_core", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(-22.5, 0, "bb_belt", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(22.5, 0, "bb_belt", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(0, 30, "bb_midback", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(0, -30, "bb_midfront", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(0, -42.5, "bb_front", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(0, -55, "bb_nose", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(0, 45, "bb_back", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(-17.5, 60, "bb_thruster", p.x, p.y, p.angle, "bb"))
		table.insert(p.parts, newpart(17.5, 60, "bb_thruster", p.x, p.y, p.angle, "bb"))
	elseif class == "test_box" then
		p.a = 0
		p.tf = 0
		p.vcap = 0
		p.tcap = 0
		p.hp = 60000
		p.thp = 60000
		
		table.insert(p.parts, newpart(0, 0, "box", p.x, p.y, p.angle, "test_box"))
	end
	
	p.update = function()
		p.angle = p.angle + p.t
		p.angle = game.normaliseangle(p.angle)			--NORMALISE PLAYER ANGLE
		
		p.target_x = p.aim_x
		p.target_y = p.aim_y
		
		if p.state == "seek" then						--AI MOVEMENT
			local dx = p.target_x - p.x
			local dy = p.target_y - p.y
			
			local desired_angle = normaliseangle(math.atan2(dx, -dy))
			if normaliseangle(p.angle - desired_angle) > p.tcap then
				p.t = p.t - p.tf
			elseif normaliseangle(p.angle - desired_angle) < -p.tcap then
				p.t = p.t + p.tf
			end
			
			local desired_velocity = math.sqrt(dx * dx + dy * dy) * p.vcap
			if desired_velocity - p.v > p.vcap then
				p.v = p.v + p.a
			elseif desired_velocity - p.v < -p.vcap then
				p.v = p.v - p.a
			end
		end
		
		for _, v in pairs(p.parts) do					--MAKE WEAPONS TURN WITH PLAYER	AND UPDATE PARTS
			if v.fire > 0 then				--FIRE
				if v.fireupdate > 0 then
					v.fireupdate = v.fireupdate - 1
				else
					p.hp = p.hp - (6 / 1000) * p.thp
					v.fireupdate = 60
					v.fire = v.fire - 1
				end
			end
		
			if v.hp <= 0 and v.destroyed == false then					--CHECK HEALTH
				v.hp = 0
				if v.grp == 0 then
					p.hp = 0
				elseif v.grp == 2 then
					p.a = p.a / 2
					p.tf = 3 * p.tf / 4
				end
				v.destroyed = true
			end
		
			local dx, dy = getCoords(v.offx, v.offy, p.angle, v.angle)
			v.x, v.y = p.x + dx, p.y + dy
			
			for _, l in pairs(v.weps) do				--UPDATE WEAPONS
				local dx, dy = getCoords(l.offx, l.offy, p.angle, l.angle)
				l.x, l.y = v.x + dx, v.y + dy
				
				l.reload = l.reload - 1
				
				l.aimangle = l.aimangle + p.t				--TURN WEAPONS
				l.aimangle = game.normaliseangle(l.aimangle)			--NORMALISE WEAPON ANGLES
				
				l.localaim = -game.normaliseangle(p.angle + l.startangle - l.aimangle)
				
				if l.localaim <= l.maxt
				and l.localaim >= l.mint then
					if l.localaim > l.tangle then
						l.aimangle = l.aimangle - l.t
					elseif l.localaim < l.tangle then
						l.aimangle = l.aimangle + l.t
					end
				elseif l.localaim > l.maxt then
					l.aimangle = game.normaliseangle(p.angle + l.maxt + l.startangle)
				elseif l.localaim < l.mint then
					l.aimangle = game.normaliseangle(p.angle + l.mint + l.startangle)
				end
			end
		end
		
		if p.v > 0 then
			p.v = p.v - p.a / 2
		elseif p.v < 0 then
			p.v = p.v + p.a / 2
		end
		
		if p.t > 0 then
			p.t = p.t - p.tf / 2
		elseif p.t < 0 then
			p.t = p.t + p.tf / 2
		end
		
		if p.v > p.vcap then								--CHECK VELOCITY
			p.v = p.vcap
		elseif p.v < -p.vcap then
			p.v = -p.vcap
		end
		
		if p.t > p.tcap then								--CHECK TURN RATE
			p.t = p.tcap
		elseif p.t < -p.tcap then
			p.t = -p.tcap
		end
		
		p.x = p.x + p.v * math.cos(p.angle - math.pi / 2)	--MOVING PLAYER
		p.y = p.y + p.v * math.sin(p.angle - math.pi / 2)
		
		if p.x > game.maxx then				--CHECK LEVEL BORDERS
			p.x = game.maxx
		elseif p.x < game.minx then
			p.x = game.minx
		end
		if p.y > game.maxy then
			p.y = game.maxy
		elseif p.y < game.miny then
			p.y = game.miny
		end
		
		for _, v in pairs(p.parts) do					--FINDING ALL POINTS ON PLAYER
			v.pointcoords = {}
			for k, l in pairs(v.points) do
				if k % 2 == 0 then
					local offx = v.points[k - 1]
					local offy = v.points[k]
					local angle = math.atan2(offx, -offy)
					local dx, dy = getCoords(offx, offy, p.angle, angle)
			
					local coord = {v.x + dx, v.y + dy}
					v.pointcoords[#v.pointcoords + 1] = coord
				end
			end
			
			for _, l in pairs(v.activefire) do
				l.effect:setPosition(v.x, v.y)
			end
			
			local maxx, minx, maxy, miny = 0, 0, 0, 0		--FIND RANGE OF X AND Y VALUES OF PART
			for k, l in pairs(v.pointcoords) do
				if k > 1 then
					if l[1] > maxx then
						maxx = l[1]
					elseif l[1] < minx then
						minx = l[1]
					end
					if l[2] > maxy then
						maxy = l[2]
					elseif l[2] < miny then
						miny = l[2]
					end
				else
					maxx, minx = l[1], l[1]
					maxy, miny = l[2], l[2]
				end
			end
			v.w = math.abs(maxx - minx)
			v.h = math.abs(maxy - miny)
		end
	end
	
	return p
end

function newpart(offx, offy, class, px, py, pangle, ship)
	local p = {}
	
	p.offx = offx				--POSITIVE MOVES TO LEFT
	p.offy = offy				--POSITIVE MOVES DOWNWARDS
	p.class = class
	
	p.angle = math.atan2(offx, -offy)	
	local dx, dy = getCoords(p.offx, p.offy, pangle, p.angle)
	p.x, p.y = px + dx, py + dy

	p.destroyed = false				--TO INDICATE WHETHER DESTRUCTION CALCULATIONS ARE DONE ALREADY
	p.pointcoords = {}
	p.w, p.h = 0, 0
	p.weps = {}					--WEAPONS
	p.fire = 0
	p.activefire = {}
	p.fireupdate = 0		--DURATION BETWEEN EACH FIRE UPDATE
	
	if ship == "ca" then
		if class == "ca_core" then
			table.insert(p.weps, weapon.new(10, -10, -math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-10, -10, math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(0, 5, math.pi, "325mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(10, 10, math.pi, "112mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-10, 10, math.pi, "112mm", p.x, p.y, pangle, 2))
			
			p.hp = 15000
			p.thp = 15000
			p.arm = 104
			
			p.grp = 0
			
			p.points = {-15, -15, -15, 15, 15, 15, 15, -15}
		elseif class == "ca_front" then
			table.insert(p.weps, weapon.new(0, 15, 0, "325mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(0, 0, 0, "325mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(0, -25, 0, "railgun", p.x, p.y, pangle, 3))
			
			p.hp = 7500
			p.thp = 7500
			p.arm = 25
			
			p.grp = 1
			
			p.points = {-7, -25, -7, 25, 7, 25, 7, -25}
		elseif class == "ca_frontleft" then
			table.insert(p.weps, weapon.new(0, 7.5, -math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(0, -7.5, -math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			
			p.hp = 7500
			p.thp = 7500
			p.arm = 32
			
			p.grp = 1
			
			p.points = {-4.5, -15, -4.5, 15, 4.5, 15, 4.5, -15}
		elseif class == "ca_frontright" then
			table.insert(p.weps, weapon.new(0, 7.5, math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(0, -7.5, math.pi / 2, "112mm", p.x, p.y, pangle, 2))
			
			p.hp = 7500
			p.thp = 7500
			p.arm = 32
			
			p.grp = 1
			
			p.points = {-4.5, -15, -4.5, 15, 4.5, 15, 4.5, -15}
		elseif class == "ca_thruster" then
			p.hp = 3000
			p.thp = 3000
			p.arm = 25
			p.ty = 12.5				--FOR THRUSTER EFFECT
			
			p.grp = 2
			
			p.points = {6.5, -14, 6.5, 14, -6.5, 14, -6.5, -14}
		end
	elseif ship == "dd" then
		if class == "dd_main" then
			table.insert(p.weps, weapon.new(-5, 0, math.pi / 2, "127mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(5, 0, -math.pi / 2, "127mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(5, 10, -math.pi / 2, "720mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-5, 10, math.pi / 2, "720mm", p.x, p.y, pangle, 2))
			
			p.hp = 5000
			p.thp = 5000
			p.arm = 25
			
			p.grp = 1
			
			p.points = {7.5, 12.5, 7.5, -12.5, -7.5, -12.5, -7.5, 12.5}
		elseif class == "dd_front" then
			table.insert(p.weps, weapon.new(0, 0, 0, "127mm", p.x, p.y, pangle, 1))
			
			p.hp = 1500
			p.thp = 1500
			p.arm = 16
			
			p.grp = 1
			
			p.points = {5, 7, 5, -7, -5, -7, -5, 7}
		elseif class == "dd_back" then
			table.insert(p.weps, weapon.new(0, -5, math.pi, "127mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(7.5, 5, -math.pi / 2, "720mm", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-7.5, 5, math.pi / 2, "720mm", p.x, p.y, pangle, 2))
			
			p.hp = 1500
			p.thp = 1500
			p.arm = 16
			
			p.grp = 1
			
			p.points = {10, 10, 10, -10, -10, -10, -10, 10}
		elseif class == "dd_thruster" then
			p.hp = 500
			p.thp = 500
			p.arm = 16
			p.ty = 5
			
			p.grp = 2
			
			p.points = {5, 3, 5, -3, -5, -3, -5, 3}
		end
	elseif ship == "test_box" then
		if class == "box" then
			p.hp = 60000
			p.thp = 60000
			p.arm = 300
			
			p.grp = 0
			
			p.points = {50, 50, 50, -50, -50, -50, -50, 50}
		end
	elseif ship == "bb" then
		if class == "bb_core" then
			table.insert(p.weps, weapon.new(0, -15, 0, "476mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(0, 15, math.pi, "476mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(13, 19, -math.pi / 2, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(15, 0, -math.pi / 2, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(13, -19, -math.pi / 2, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-13, 19, math.pi / 2, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-15, 0, math.pi / 2, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-13, -19, math.pi / 2, "laser", p.x, p.y, pangle, 2))
			
			p.hp = 27500
			p.thp = 27500
			p.arm = 65
			
			p.grp = 0
			
			p.points = {-20, 25, -20, -25, 20, -25, 20, 25}
		elseif class == "bb_belt" then
			p.hp = 27500
			p.thp = 27500
			p.arm = 300
			
			p.grp = 0
			
			p.points = {-2.5, 20, -2.5, -20, 2.5, -20, 2.5, 20}
		elseif class == "bb_midfront" then
			p.hp = 15000
			p.thp = 15000
			p.arm = 32
			
			p.grp = 1
			
			p.points = {-12.5, 5, -12.5, -5, 12.5, -5, 12.5, 5}
		elseif class == "bb_midback" then
			p.hp = 15000
			p.thp = 15000
			p.arm = 32
			
			p.grp = 1
			
			p.points = {-15, 5, -15, -5, 15, -5, 15, 5}
		elseif class == "bb_front" then
			table.insert(p.weps, weapon.new(0, 0, 0, "476mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(-11, -4, math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-11, 4, 3 * math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(11, -4, -math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(11, 4, -3 * math.pi / 4, "laser", p.x, p.y, pangle, 2))
			
			p.hp = 20000
			p.thp = 20000
			p.arm = 76
			
			p.grp = 1
			
			p.points = {-15, 7.5, -15, -7.5, 15, -7.5, 15, 7.5}
		elseif class == "bb_nose" then
			p.hp = 10000
			p.thp = 10000
			p.arm = 32
			
			p.grp = 1
			
			p.points = {-7.5, 5, -7.5, -5, 7.5, -5, 7.5, 5}
		elseif class == "bb_back" then
			table.insert(p.weps, weapon.new(0, 0, math.pi, "476mm", p.x, p.y, pangle, 1))
			table.insert(p.weps, weapon.new(-16, -7, math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(-16, 7, 3 * math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(16, -7, -math.pi / 4, "laser", p.x, p.y, pangle, 2))
			table.insert(p.weps, weapon.new(16, 7, -3 * math.pi / 4, "laser", p.x, p.y, pangle, 2))
			
			p.hp = 20000
			p.thp = 20000
			p.arm = 76
			
			p.grp = 1
			
			p.points = {-22.5, 10, -22.5, -10, 22.5, -10, 22.5, 10}
		elseif class == "bb_thruster" then
			p.hp = 5000
			p.thp = 5000
			p.arm = 32
			p.ty = 5
			
			p.grp = 2
			
			p.points = {-10, 5, -10, -5, 10, -5, 10, 5}
		end
	end
	
	return p
end

function normaliseangle(angle)			--KEEPS ANGLE BETWEEN -180 AND 180
	while angle <= -math.pi do
		angle = angle + (2 * math.pi)
	end
	while angle > math.pi do
		angle = angle - (2 * math.pi)
	end

	return angle
end

function getCoords(offx, offy, angle1, angle2)				--GET RELATIVE OBJECT'S XY COORDS
	local distance = math.sqrt(offx * offx + offy * offy)
	local x = (math.sin(angle1 - angle2) * distance)
	local y = -(math.cos(angle1 - angle2) * distance)
	
	return x, y
end