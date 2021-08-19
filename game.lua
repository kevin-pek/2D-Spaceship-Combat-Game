module(..., package.seeall)

local player = require ("player")
local bullet = require ("bullet")
local enemy = require ("enemy")
local camera = require ("camera")
local particle = require ("particle")
local object = require ("object")
local point_within_area = require ("point_within_area")

local shine = require ("shine-master")

--local isColliding = 0
--local interpts = {}

function init(lvl_number)
	enemies = {}
	bullets = {}		--PROJECTILES
	hitscan = {}		--HITSCAN WEAPONS
	particles = {}			--FOR PARTICLE SYSTEMS
	objects = {}
	shake_magnitudes = {}		--CONTAINS ALL SHAKE EFFECT MAGNITUDES		1ST ELEMENT: MAGNITUDE	2ND ELEMENT: DURATION

	lvl = lvl_number
	level = require ("file" .. lvl_number)
	level.init_lvl()
	
	paused = false
	playerdead = false

	dead_timer = 240
	dx = 0
	dy = 0
	
	fire = love.graphics.newImage("fire.png")
	circle = love.graphics.newImage("circle.png")
	circleline = love.graphics.newImage("circle_line.png")
	detected_icon = love.graphics.newImage("detected_icon.png")
	
	glow = shine.glowsimple()
	blur = shine.boxblur()
end

function update(dt)
	local m = 0				--SHAKE MAGNITUDE
	for i, v in pairs(shake_magnitudes) do
		if v[2] > 0 then
			v[2] = v[2] - 1
			m = m + v[1]
		else
			table.remove(shake_magnitudes, i)
		end
	end
	
	dx = math.random(-m, m)
	dy = math.random(-m, m)
	
	p.spotted = 0
	for _, b in pairs(enemies) do
		b.spotted = 0
	end
	
	if playerdead == false then
		--[[if love.keyboard.isDown("w") then		--PLAYER CONTROLS	movement controls shifted to main.lua
			p.v = p.v + p.a
		elseif love.keyboard.isDown("s") then
			p.v = p.v - p.a
		end
		
		if love.keyboard.isDown("d") then
			p.t = p.t + p.tf
		elseif love.keyboard.isDown("a") then
			p.t = p.t - p.tf
		end]]--
		
		if love.mouse.isDown(1) then
			p.shoot(1)
		end
		if love.mouse.isDown(2) then
			p.shoot(2)
		end
		if love.keyboard.isDown("space") then
			p.shoot(3)
		end
		
		if love.keyboard.isDown("r") then
			if p.repair_cool == 0 then
				p.repair_duration = 600			--10 SECONDS REPAIR
				p.repair_cool = p.trepair_cool
			end
		end
		
		p.update()
		if p.v > 0 then
			for _, v in pairs(p.parts) do
				if v.grp == 2 and v.destroyed == false then
					local x = (math.sin(p.angle - math.pi) * v.ty)
					local y = -(math.cos(p.angle - math.pi) * v.ty)
					
					local particlesystem = particle.thruster(v.x + x, v.y + y, 1, circle)
					table.insert(particles, particlesystem)
					particles[#particles].effect:emit(10)
				end
			end
		end
		
		c.update(p.v * math.cos(p.angle - math.pi / 2), p.v * math.sin(p.angle - math.pi / 2), p.minx, p.maxx, p.miny, p.maxy)				--UPDATE CAMERA
		
		for _, v in pairs(p.parts) do				--UPDATE PLAYER GUN TARGET
			for _, l in pairs(v.weps) do
				local dx, dy = love.mouse.getX() - l.x + c.x - love.graphics.getWidth() / 2, love.mouse.getY() - l.y + c.y - love.graphics.getHeight() / 2
				l.tangle = math.atan2(dx, -dy) - p.angle - l.startangle
				l.tangle = game.normaliseangle(l.tangle)
			end
		end
		
		if p.s_isup then
			for i, v in pairs(bullets) do					--DETECT SHIELD COLLISIONS
				if v.team == 1 then
					local dx, dy = v.x - p.x, v.y - p.y
					local distance = math.sqrt(dx * dx + dy * dy)
					if distance <= p.sr + v.r / 2 then
						p.shp = p.shp - v.dmg
						p.s_recharge = 300					--5 SECOND WAIT FOR SHIELDS TO RECHARGE
						p.s_isrecharging = false
						table.remove(bullets, i)
						
						local particlesystem = particle.new(v.x, v.y, 5, circle)
						table.insert(particles, particlesystem)
						particles[#particles].effect:emit(1)
					end
				end
			end
			if p.shp <= 0 then				--SHIELD DEPLETED
				p.shp = 0
				
				local particlesystem = particle.new(p.x, p.y, 4, circleline)
				table.insert(particles, particlesystem)
				particles[#particles].effect:emit(1)
			end
		end
	end
	
	for _, l in pairs(enemies) do
		if math.sqrt((p.x - l.x) * (p.x - l.x) + (p.y - l.y) * (p.y - l.y)) <= p.spot then		--CHECK IF PLAYER SPOTTED FOR USE IN AI
			p.spotted = 1
		end
		if math.sqrt((p.x - l.x) * (p.x - l.x) + (p.y - l.y) * (p.y - l.y)) <= l.spot then		--CHECK IF ENEMY IS SPOTTED BY PLAYER
			l.spotted = 1
		end
	end
	
	--interpts = {}
	--local collisions = 0
	for _, v in pairs(p.parts) do
		for _, l in pairs(v.activefire) do
			if v.fire < 1 then
				l.effect:stop()
			end
			l.effect:update(dt)
		end
	
		for k, l in pairs(v.pointcoords) do				--CHECKING COLLISION FOR PLAYER
			for a, g in pairs(bullets) do
				if g.team == 1 and math.sqrt((g.x - p.x) * (g.x - p.x) + (g.y - p.y) * (g.y - p.y)) < p.sr then
					if k > 1 then
						colliding = clcollision(v.pointcoords[k - 1][1], v.pointcoords[k - 1][2], l[1], l[2], g.x, g.y, g.r)
					else
						colliding = clcollision(v.pointcoords[#v.pointcoords][1], v.pointcoords[#v.pointcoords][2], l[1], l[2], g.x, g.y, g.r)
					end
					
					if colliding == 1 then
						--collisions = collisions + 1		--DO DAMAGE CALCULATIONS
						if k > 1 then
							midx, midy = (v.pointcoords[k - 1][1] + l[1]) / 2, (v.pointcoords[k - 1][2] + l[2]) / 2
						else
							midx, midy = (v.pointcoords[#v.pointcoords][1] + l[1]) / 2, (v.pointcoords[#v.pointcoords][2] + l[2]) / 2
						end
						local surfaceangle = normaliseangle(math.atan2(midy - v.y, midx - v.x) + math.pi / 2)
						local bulletangle = normaliseangle(g.angle)
						local incidentangle = anglecollision(surfaceangle, bulletangle)
							
						local damage, reflect, pen, setfire = calculatedmg(g, v, incidentangle)
						if setfire and v.fire < 1 then
							v.fire = 50
							v.fireupdate = 60
							
							if #v.activefire > 0 then
								v.activefire[#v.activefire].effect:start()
								v.activefire[#v.activefire].effect:setEmitterLifetime(50)
								v.activefire[#v.activefire].effect:setEmissionRate(8)
							else
								local particlesystem = particle.fire(v.x, v.y, fire)
								table.insert(v.activefire, particlesystem)
							end
						end
						
						if reflect then
							local particlesystem = particle.ricochet(g.x, g.y, 2, surfaceangle + incidentangle, fire)		--REFLECT BULLET
							table.insert(particles, particlesystem)
							particles[#particles].effect:emit(10)
							
							table.remove(bullets, a)
						else
							if pen == false then
								v.hp = v.hp - damage			--DAMAGE TO PART
								
								particlesystem = particle.ricochet(g.x, g.y, 1, surfaceangle, fire)		--NORMALPEN
							else
								particlesystem = particle.ricochet(g.x, g.y, 3, surfaceangle, fire)		--OVERPEN
								
							end
							if g.p == "torpedo" then
								particlesystem = particle.ricochet(g.x, g.y, 4, surfaceangle, fire)
								
								table.insert(shake_magnitudes, {2.5, 15})		--TORPEDO HIT SHAKE
								table.insert(shake_magnitudes, {2.5, 45})
							end
							table.insert(particles, particlesystem)
							particles[#particles].effect:emit(10)
								
							p.hp = p.hp - damage				--DOES DAMAGE TO OVERAL HP
							table.remove(bullets, a)
						end
					end
				end
			end
		end
		if v.hp < 0 then
			v.hp = 0
		end
	end
	
	for d, b in pairs(enemies) do				--UPDATING ENEMIES
		if b.hp <= 0 then
			table.insert(shake_magnitudes, {1, 50})				--SHIP EXPLOSION SHAKE
			table.insert(shake_magnitudes, {1, 100})
			table.insert(shake_magnitudes, {0.5, 150})
		
			local particlesystem = particle.new(b.x, b.y, 1, fire)
			table.insert(particles, particlesystem)
			particles[#particles].effect:emit(40)
			local particlesystem = particle.new(b.x, b.y, 2, fire)
			table.insert(particles, particlesystem)
			particles[#particles].effect:emit(45)
			local particlesystem = particle.new(b.x, b.y, 3, fire)
			table.insert(particles, particlesystem)
			particles[#particles].effect:emit(50)
				
			table.remove(enemies, d)
		end
		
		b.update()
		
		for _, v in pairs(b.parts) do
			if v.grp == 2 and b.v > 0 and v.destroyed == false then
				local x = (math.sin(b.angle - math.pi) * v.ty)
				local y = -(math.cos(b.angle - math.pi) * v.ty)
				
				if b.spotted == 1 then
					local particlesystem = particle.thruster(v.x + x, v.y + y, 1, circle)
					table.insert(particles, particlesystem)
					particles[#particles].effect:emit(10)
				end
			end
			
			for _, l in pairs(v.activefire) do
				if v.fire < 1 then
					l.effect:stop()
				end
				l.effect:update(dt)
			end
			
			if b.combat == 1 then
				if p.spotted == 1 then		--IF PLAYER SPOTTED
					for _, l in pairs(v.weps) do
						if l.type == "projectile" then
							local dx = p.x - l.x						--AI WEAPON CONTROL
							local dy = p.y - l.y
							local distance = math.sqrt(dx * dx + dy * dy)
							local diff_v = l.v - p.v
							local t = distance / diff_v
							local x_velocity = p.v * math.cos(p.angle - math.pi / 2)
							local y_velocity = p.v * math.sin(p.angle - math.pi / 2)
							b.aim_x = p.x + x_velocity * t
							b.aim_y = p.y + y_velocity * t
						elseif l.type == "hitscan" then
							b.aim_x = p.x
							b.aim_y = p.y
						end
						
						local dx, dy = b.aim_x - l.x, b.aim_y - l.y
						l.tangle = math.atan2(dx, -dy) - b.angle - l.startangle
						l.tangle = game.normaliseangle(l.tangle)
						
						if (l.tangle - l.localaim < l.t) and (l.tangle - l.localaim > -l.t)
						and l.reload <= 0
						and math.sqrt(dx * dx + dy * dy) <= l.max_range then
							if l.type == "projectile" then
								table.insert(bullets, bullet.new(l.x, l.y, l.aimangle, l.class, 1))
							elseif l.type == "hitscan" then
								table.insert(hitscan, bullet.hitscan(l.x, l.y, l.aimangle, l.class, 1))
							end
							l.reload = l.reloadt
						end
					end
				end
			end
	
			for k, l in pairs(v.pointcoords) do			--ENEMY COLLISION
				for a, g in pairs(bullets) do
					if g.team == 0 and math.sqrt((g.x - b.x) * (g.x - b.x) + (g.y - b.y) * (g.y - b.y)) < 100 then
						if k > 1 then
							colliding = clcollision(v.pointcoords[k - 1][1], v.pointcoords[k - 1][2], l[1], l[2], g.x, g.y, g.r)
						else
							colliding = clcollision(v.pointcoords[#v.pointcoords][1], v.pointcoords[#v.pointcoords][2], l[1], l[2], g.x, g.y, g.r)
						end
						
						if colliding == 1 then
							--collisions = collisions + 1		--DO DAMAGE CALCULATIONS
							if k > 1 then
								midx, midy = (v.pointcoords[k - 1][1] + l[1]) / 2, (v.pointcoords[k - 1][2] + l[2]) / 2
							else
								midx, midy = (v.pointcoords[#v.pointcoords][1] + l[1]) / 2, (v.pointcoords[#v.pointcoords][2] + l[2]) / 2
							end
							local surfaceangle = normaliseangle(math.atan2(midy - v.y, midx - v.x) + math.pi / 2)
							local bulletangle = normaliseangle(g.angle)
							local incidentangle = anglecollision(surfaceangle, bulletangle)
								
							local damage, reflect, pen, setfire = calculatedmg(g, v, incidentangle)
							if setfire and v.fire < 1 then
								v.fire = 50
								v.fireupdate = 60
								
								if #v.activefire > 0 then
									v.activefire[#v.activefire].effect:start()
									v.activefire[#v.activefire].effect:setEmitterLifetime(50)
									v.activefire[#v.activefire].effect:setEmissionRate(8)
								else
									local particlesystem = particle.fire(v.x, v.y, fire)
									table.insert(v.activefire, particlesystem)
								end
							end
							
							if reflect then
								local particlesystem = particle.ricochet(g.x, g.y, 2, surfaceangle + incidentangle, fire)		--REFLECT BULLET
								table.insert(particles, particlesystem)
								particles[#particles].effect:emit(10)
								
								table.remove(bullets, a)
							else
								if pen == false then
									v.hp = v.hp - damage			--DAMAGE TO PART
									
									particlesystem = particle.ricochet(g.x, g.y, 1, surfaceangle, fire)		--NORMALPEN
								else
									particlesystem = particle.ricochet(g.x, g.y, 3, surfaceangle, fire)		--OVERPEN
									
								end
								if g.p == "torpedo" then
									particlesystem = particle.ricochet(g.x, g.y, 4, surfaceangle, fire)
								end
								table.insert(particles, particlesystem)
								particles[#particles].effect:emit(10)
									
								b.hp = b.hp - damage				--DOES DAMAGE TO OVERAL HP
								table.remove(bullets, a)
							end
						end
					end
				end
			end
			if v.hp < 0 then
				v.hp = 0
			end
		end
	end
	
	for k, l in pairs(bullets) do			--MOVE PROJECTILES
		l.move()
		
		if l.distance_traveled > l.max_range then
			table.remove(bullets, k)
		end
		
		for _, v in pairs(objects) do				--OBJECT COLLISION
			local dx, dy = l.x - v.x, l.y - v.y
			local distance = math.sqrt(dx * dx + dy * dy)
			if distance <= v.r + l.r and distance >= v.r - l.r then
				table.remove(bullets, k)
			end
		end
	end
	
	for b, v in pairs(hitscan) do				--CHECK HITSCAN
		if v.width > 0 then
			v.width = v.width - 1
		else
			table.remove(hitscan, b)
		end
		
		if v.fired == false then
			if v.class == "railgun" and v.class == 0 then
				table.insert(shake_magnitudes, {10, 5})
			end
			
			for _, l in pairs(objects) do				--OBJECT COLLISION
				local collision, points = clcollision(v.x, v.y, v.maxx, v.maxy, l.x, l.y, l.r + v.width / 2)
				
				if collision == 1 then
					for _, g in pairs(points) do
						table.insert(g, 0)			--THIRD ELEMENT INDICATES TYPE OF OBJECT COLLIDED WITH
						table.insert(v.points, g)		--0: OBJECT		1: SHIP
					end
				end
			end
			
			for k, l in pairs(v.points) do
				local index = k
				local temp = l		--SORT ACCORDING TO DISTANCE FROM START OF HITSCAN
				while index > 1 and math.sqrt((v.x - temp[1]) * (v.x - temp[1]) + (v.y - temp[2]) * (v.y - temp[2])) < math.sqrt((v.x - v.points[index-1][1]) * (v.x - v.points[index-1][1]) + (v.y - v.points[index-1][2]) * (v.y - v.points[index-1][2])) do
					v.points[index] = v.points[index-1]
					v.points[index - 1] = temp
					index = index - 1
				end
			end
			while #v.points > 1 do					--GET THE CLOSEST OBJECT COLLISION
				table.remove(v.points, #v.points)
			end
			if #v.points > 0 then
				v.maxx = v.points[1][1]
				v.maxy = v.points[1][2]
			end
			
			if v.team == 0 then		--ON PLAYER TEAM
				for _, l in pairs(enemies) do
					for _, g in pairs(l.parts) do
						local collisions = 0
						
						for k, h in pairs(g.pointcoords) do
							if k > 1 then
								collision, points = llcollision(g.pointcoords[k - 1][1], g.pointcoords[k - 1][2], h[1], h[2], v.x, v.y, v.maxx, v.maxy)
							else
								collision, points = llcollision(g.pointcoords[#g.pointcoords][1], g.pointcoords[#g.pointcoords][2], h[1], h[2], v.x, v.y, v.maxx, v.maxy)
							end
							
							if collision == 1 then		--IF COLLISION IS CLOSER THAN CLOSEST OBJECT COLLISION
								if #v.points == 0 and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) then
									collisions = collisions + 1
									
									table.insert(points, 1)			--THIRD ELEMENT INDICATES TYPE OF OBJECT COLLIDED WITH
									table.insert(v.points, points)		--0: OBJECT		1: SHIP
								elseif #v.points > 0 then		--IF COLLISION IS CLOSER THAN CLOSEST OBJECT COLLISION
									if v.points[1][3] == 1 or v.points[1][3] == 0 and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) < math.sqrt((v.x - v.points[1][1]) * (v.x - v.points[1][1]) + (v.y - v.points[1][2]) * (v.y - v.points[1][2])) then
										collisions = collisions + 1
										
										table.insert(points, 1)			--THIRD ELEMENT INDICATES TYPE OF OBJECT COLLIDED WITH
										table.insert(v.points, points)		--0: OBJECT		1: SHIP
									end
								end
							end
						end
						
						if collisions > 0 then
							local dmg = hitscandmg(v, g)
							g.hp = g.hp - dmg
							l.hp = l.hp - dmg
						end
					end
				end
				
				for _, h in pairs(v.points) do
					local particlesystem = particle.ricochet(h[1], h[2], 1, 0, fire)
					table.insert(particles, particlesystem)
					particles[#particles].effect:emit(10)
				end
			else			--ENEMY TEAM
				if p.s_isup then
					colliding, points = clcollision(v.x, v.y, v.maxx, v.maxy, p.x, p.y, p.sr)
							
					if colliding == 1 then
						p.shp = p.shp - v.dmg
						p.s_recharge = 300					--5 SECOND WAIT FOR SHIELDS TO RECHARGE
						p.s_isrecharging = false
						table.remove(hitscan, b)
						
						for _, h in pairs(points) do
							local particlesystem = particle.new(h[1], h[2], 5, circle)
							table.insert(particles, particlesystem)
							particles[#particles].effect:emit(1)
						end
					end
					
					if p.shp <= 0 then				--SHIELD DEPLETED
						p.shp = 0
						
						local particlesystem = particle.new(p.x, p.y, 4, circleline)
						table.insert(particles, particlesystem)
						particles[#particles].effect:emit(1)
					end
				else
					for _, l in pairs(p.parts) do
						local collisions = 0
						
						for k, h in pairs(l.pointcoords) do
							if k > 1 then
								collision, points = llcollision(l.pointcoords[k - 1][1], l.pointcoords[k - 1][2], h[1], h[2], v.x, v.y, v.maxx, v.maxy)
							else
								collision, points = llcollision(l.pointcoords[#l.pointcoords][1], l.pointcoords[#l.pointcoords][2], h[1], h[2], v.x, v.y, v.maxx, v.maxy)
							end
							
							if collision == 1 then
								if #v.points == 0 and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) <= v.max_range then
									collisions = collisions + 1
									
									table.insert(points, 1)			--THIRD ELEMENT INDICATES TYPE OF OBJECT COLLIDED WITH
									table.insert(v.points, points)		--0: OBJECT		1: SHIP
								elseif #v.points > 0 then
									if v.points[1][3] == 1 or v.points[1][3] == 0 and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) and math.sqrt((v.x - points[1]) * (v.x - points[1]) + (v.y - points[2]) * (v.y - points[2])) < math.sqrt((v.x - v.points[1][1]) * (v.x - v.points[1][1]) + (v.y - v.points[1][2]) * (v.y - v.points[1][2])) then
										collisions = collisions + 1
										
										table.insert(points, 1)			--THIRD ELEMENT INDICATES TYPE OF OBJECT COLLIDED WITH
										table.insert(v.points, points)		--0: OBJECT		1: SHIP
									end
								end
							end
						end
						
						if collisions > 0 then
							local dmg = hitscandmg(v, l)
							p.hp = p.hp - dmg
							l.hp = l.hp - dmg
						end
					end
					
					for _, h in pairs(v.points) do
						local particlesystem = particle.ricochet(h[1], h[2], 1, 0, fire)
						table.insert(particles, particlesystem)
						particles[#particles].effect:emit(10)
					end
				end
			end
			
			v.fired = true
		end
	end
	
	if p.hp <= 0 and playerdead == false then
		playerdead = true
		
		table.insert(shake_magnitudes, {1, 50})				--SHIP EXPLOSION SHAKE
		table.insert(shake_magnitudes, {1, 100})
		table.insert(shake_magnitudes, {0.5, 150})
		
		local particlesystem = particle.new(p.x, p.y, 1, fire)
		table.insert(particles, particlesystem)
		particles[#particles].effect:emit(40)
		local particlesystem = particle.new(p.x, p.y, 2, fire)
		table.insert(particles, particlesystem)
		particles[#particles].effect:emit(45)
		local particlesystem = particle.new(p.x, p.y, 3, fire)
		table.insert(particles, particlesystem)
		particles[#particles].effect:emit(50)
	end
	
	if dead_timer > 0 and (playerdead or #enemies == 0) then
		dead_timer = dead_timer - 1
	end
	
	for h, v in pairs(particles) do						--UPDATE EFFECTS
		if v.effect:isActive() == false then
			table.remove(particles, h)
		end
		v.effect:update(dt)
	end
end

function draw()
	love.graphics.translate(dx, dy)

	blur:draw(function()
		blur.radius = 15
		love.graphics.setLineWidth(1)
		if love.mouse.getX() < 10 then				--MOVE CAMERA BASED ON MOUSE POSITION
			love.graphics.line(0, 0, 0, love.graphics.getHeight())
		elseif love.graphics.getWidth() - love.mouse.getX() < 10 then
			love.graphics.line(love.graphics.getWidth(), 0, love.graphics.getWidth(), love.graphics.getHeight())
		elseif love.mouse.getY() < 10 then
			love.graphics.line(0, 0, love.graphics.getWidth(), 0)
		elseif love.graphics.getHeight() - love.mouse.getY() < 10 then
			love.graphics.line(0, love.graphics.getHeight(), love.graphics.getWidth(), love.graphics.getHeight())
		end
	end)

	-- DRAWING OBJECTS
	blur:draw(function()
	love.graphics.push()
		love.graphics.translate(love.graphics.getWidth() / 2 - c.x, love.graphics.getHeight() / 2 - c.y)			--TO SET CAMERA TO CENTRE OF SCREEN INSTEAD OF ORIGIN
		
		blur.radius = 50
		for _, v in pairs(objects) do				--DRAW OBJECTS OUTER GLOW
			love.graphics.setColor(255, 255, 255)
			love.graphics.circle("fill", v.x, v.y, v.r + 50)
		end
	
	love.graphics.pop()
	end)
	
	blur:draw(function()
	love.graphics.push()
		love.graphics.translate(love.graphics.getWidth() / 2 - c.x, love.graphics.getHeight() / 2 - c.y)
		
		blur.radius = 4
		for _, v in pairs(objects) do				--DRAW OBJECTS INNER CIRCLE
			if v.grp == 1 then
				love.graphics.setColor(0, 0, 0)
				love.graphics.circle("fill", v.x, v.y, v.r)
			end
		end
	
	love.graphics.pop()
	end)
	
	-- DRAWING HITSCAN LASERS AND BULLET PROJECTILES
	glow:draw(function()
	love.graphics.push()
		love.graphics.translate(love.graphics.getWidth() / 2 - c.x, love.graphics.getHeight() / 2 - c.y)
		love.graphics.setColor(255, 255, 255)
		for k, v in pairs(hitscan) do			--DRAW HITSCAN
			love.graphics.setLineWidth(v.width)
			love.graphics.line(v.x, v.y, v.maxx, v.maxy)
			
			--[[love.graphics.print(#v.points, 100, 150)
			love.graphics.setLineWidth(2)
			for _, l in pairs(v.points) do
				love.graphics.circle("line", l[1], l[2], 10)
			end]]--
		end
		
		love.graphics.setColor(255, 255, 255)
		for _, v in pairs(bullets) do			--DRAW BULLETS
			if v.p ~= "torpedo" or v.team == 0 then
				love.graphics.push()
					love.graphics.translate(v.x, v.y)
					love.graphics.rotate(v.angle)
					love.graphics.polygon("fill", v.points)
				love.graphics.pop()
			elseif math.sqrt((p.x - v.x) * (p.x - v.x) + (p.y - v.y) * (p.y - v.y)) <= v.range and v.team == 1 then
				love.graphics.push()
					love.graphics.translate(v.x, v.y)
					love.graphics.rotate(v.angle)
					love.graphics.polygon("fill", v.points)
				love.graphics.pop()
			end
		end
	love.graphics.pop()
	end)

	-- DRAWING PLAYER
	glow:draw(function()		--FOR PARTS WITH GLOW EFFECT
		love.graphics.push()
		love.graphics.translate(love.graphics.getWidth() / 2 - c.x, love.graphics.getHeight() / 2 - c.y)
		
		if playerdead == false then						--DRAW PLAYER
			if p.s_isup then
				love.graphics.setColor(255, 255, 255)				--SHIELDS
				love.graphics.setLineWidth(p.shp / p.tshp * 4 + 0.1)
				love.graphics.circle("line", p.x, p.y, p.sr)
			end
			
			for i, v in pairs(p.parts) do								--SHIP
				love.graphics.push()
					love.graphics.translate(v.x, v.y)
					love.graphics.rotate(p.angle)
					
					local value = 100 * (v.hp / v.thp)					--MAKES MORE DAMAGED PARTS BECOME DIMMER
					love.graphics.setColor(value + 155, value + 155, value + 155)
					love.graphics.setLineWidth(2)
					love.graphics.polygon("line", v.points)
				love.graphics.pop()
					
				for _, l in pairs(v.weps) do
					love.graphics.push()
						love.graphics.translate(l.x, l.y)
						love.graphics.rotate(l.aimangle)
						
						local value = 100 * (v.hp / v.thp)
						love.graphics.setColor(value + 155, value + 155, value + 155)
						love.graphics.setLineWidth(2)
						love.graphics.polygon("line", l.points)
					love.graphics.pop()
				end
				
				love.graphics.setColor(255, 255, 255)
				for _, l in pairs(v.activefire) do
					love.graphics.draw(l.effect)
				end
					
				--for k, l in pairs(v.pointcoords) do
					--love.graphics.circle("line", l[1], l[2], 3)
				--end
			end
		end
		
		-- DRAWING ENEMY
		for _, b in pairs(enemies) do
			--love.graphics.circle("fill", b.aim_x, b.aim_y, 15)	--SHOW WHERE ENEMY IS AIMING DEFAULT IS THE SPAWN POINT OF THE ENEMY
			if b.spotted == 1 then
				for _, v in pairs(b.parts) do						--DRAW ENEMIES
					love.graphics.push()
						love.graphics.translate(v.x, v.y)
						love.graphics.rotate(b.angle)
						
						local value = 100 * (v.hp / v.thp)
						love.graphics.setColor(value + 155, value + 155, value + 155)
						love.graphics.setLineWidth(2)
						love.graphics.polygon("line", v.points)
					love.graphics.pop()
						
					for _, l in pairs(v.weps) do
						love.graphics.push()
							love.graphics.translate(l.x, l.y)
							love.graphics.rotate(l.aimangle)
							
							local value = 100 * (v.hp / v.thp)
							love.graphics.setColor(value + 155, value + 155, value + 155)
							love.graphics.setLineWidth(2)
							love.graphics.polygon("line", l.points)
						love.graphics.pop()
					end
					
					love.graphics.setColor(255, 255, 255)
					for _, l in pairs(v.activefire) do
						love.graphics.draw(l.effect)
					end
					
					--for k, l in pairs(v.pointcoords) do
						--love.graphics.circle("line", l[1], l[2], 3)
					--end
				end
			end
		end
		
		love.graphics.setColor(255, 255, 255)			--DRAW PARTICLES
		for _, v in pairs(particles) do
			love.graphics.draw(v.effect)
		end
	
	love.graphics.pop()
	
	-- PLAYER UI ELEMENTS
	--[[
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 25, love.graphics.getHeight() - 160, 50, 50)
	if p.repair_cool > 0 then						--SHOW REPAIR BAR
		love.graphics.setColor(50, 50, 50)
		love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 25, love.graphics.getHeight() - 160 + (p.trepair_cool - p.repair_cool) / p.trepair_cool * 50, 50, 50 * p.repair_cool / p.trepair_cool)
		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(info)
		love.graphics.print(math.ceil(p.repair_cool / 60), love.graphics.getWidth() / 2 - info:getWidth(math.ceil(p.repair_cool / 60)) / 2, love.graphics.getHeight() - 145)
	end
	love.graphics.setColor(255, 255, 255)
	love.graphics.setLineWidth(2)
	if p.repair_cool > 0 then
		love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 25, love.graphics.getHeight() - 160, 50, 50)
	else
		love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 25, love.graphics.getHeight() - 160, 50, 50)
	end
	
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(info)
	local fires = {}
	for i, v in pairs(p.parts) do								--GET NUMBER OF FIRES
		if v.fire > 0 then
			table.insert(fires, v.fire)
		end
	end
	for i, v in pairs(fires) do								--SHOW FIRE TIMERS
		if #fires % 2 == 1 then
			love.graphics.print(v, love.graphics.getWidth() / 2 + (i - 1 - math.floor(#fires / 2)) * 50 - info:getWidth(v) / 2, love.graphics.getHeight() - 200)
		else
			love.graphics.print(v, love.graphics.getWidth() / 2 + (i - 1 - math.floor(#fires / 2)) * 50 - info:getWidth(v) / 2 + 25, love.graphics.getHeight() - 200)
		end
	end
	
	local weps_groups = {{}, {}, {}}
	for _, v in pairs(p.parts) do
		for _, l in pairs(v.weps) do				--ORGANISE ALL WEAPONS INTO TABLE
			table.insert(weps_groups[l.grp], math.ceil(l.reload / 60))
		end
	end
	for i, v in pairs(weps_groups) do				--DISPLAY RELOAD TIMES
		for k, l in pairs(v) do
			if l > 0 then
				love.graphics.setColor(175, 175, 175)
			else
				love.graphics.setColor(255, 255, 255)
			end
			if #v % 2 == 1 then
				love.graphics.print(l, love.graphics.getWidth() / 2 + (k - 1 - math.floor(#v / 2)) * 50 - info:getWidth(l) / 2, love.graphics.getHeight() - 100 + (i - 1) * 30)
			else
				love.graphics.print(l, love.graphics.getWidth() / 2 + (k - 1 - math.floor(#v / 2)) * 50 - info:getWidth(l) / 2 + 25, love.graphics.getHeight() - 100 + (i - 1) * 30)
			end
		end
	end
	--]]
	end)

	love.graphics.push()
		love.graphics.translate(love.graphics.getWidth() / 2 - c.x, love.graphics.getHeight() / 2 - c.y)			--TO SET CAMERA TO CENTRE OF SCREEN INSTEAD OF ORIGIN
		
		love.graphics.setLineWidth(1)						--SHOW PLAYER BOUNDARIES
		love.graphics.rectangle("line", game.minx, game.miny, math.abs(game.maxx - game.minx), math.abs(game.maxy - game.miny))
		
		if playerdead == false then
			love.graphics.setColor(255, 255, 255)				--HEALTH BAR
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", p.x - 75, p.y - 150, 150, 10)
			love.graphics.rectangle("fill", p.x - 75, p.y - 150, p.hp / p.thp * 150, 10)
			love.graphics.setLineWidth(1)							--SHIELD
			love.graphics.rectangle("line", p.x - 75, p.y - 130, 150, 5)
			love.graphics.rectangle("fill", p.x - 75, p.y - 130, p.shp / p.tshp * 150, 5)
		end
		
		for _, b in pairs(enemies) do
			if b.spotted == 1 then
				love.graphics.setColor(255, 255, 255)				--ENEMY HEALTH BAR
				love.graphics.setLineWidth(2)
				love.graphics.rectangle("line", b.x - 75, b.y - 150, 150, 10)
				love.graphics.rectangle("fill", b.x - 75, b.y - 150, b.hp / b.thp * 150, 10)
			end
		end
	love.graphics.pop()
	
	if p.spotted == 1 then				--SHOW DETECTED ICON												--DETECTED ICON HAS TO BE REMADE
		--love.graphics.draw(detected_icon, 50 - 32, love.graphics.getHeight() / 4)
		love.graphics.setFont(info)			--^^^ WIDTH OF IMAGE OF ICON
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("Detected!", 75 - info:getWidth("Detected!") / 2, 5)
	end
	
	-- ENEMY RADAR THING
	--[[
	love.graphics.push()			--SHOWS ENEMIES OUTSIDE CAMERA VIEW
		love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.setLineWidth(1)
		love.graphics.circle("line", 0, 0, love.graphics.getHeight() / 4)
		love.graphics.setLineWidth(15)
		for _, b in pairs(enemies) do
			if b.x > c.x + love.graphics.getWidth() / 2 or b.x < c.x - love.graphics.getWidth() / 2 or b.y > c.y + love.graphics.getHeight() / 2 or b.y < c.y - love.graphics.getHeight() / 2 then
				local dx, dy = b.x - c.x, b.y - c.y
				local angle = math.atan2(dx, -dy) - math.pi / 2
				
				love.graphics.stencil(function() love.graphics.circle("fill", 0, 0, love.graphics.getHeight() / 4) end)
				love.graphics.setStencilTest("less", 1)
				love.graphics.arc("line", 0, 0, love.graphics.getHeight() / 4 + 5, angle - math.pi / 36, angle + math.pi / 36)
			end
		end
		
		love.graphics.setStencilTest()
	love.graphics.pop()

	love.graphics.push()			--SHOWS CURRENT VELOCITY THROTTLE SETTINGS
		love.graphics.translate(love.graphics.getWidth() - 50, love.graphics.getHeight() - 200)
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", -12.5, -125, 25, 250)
		love.graphics.rectangle("fill", -12.5, 0, 25, -p.v / p.vcap * 125)
		
		love.graphics.setLineWidth(3)
		love.graphics.line(-20, -p.v_throttle / 4 * 125, 20, -p.v_throttle / 4 * 125)
	love.graphics.pop()
	
	love.graphics.push()			--SHOWS CURRENT TURNING THROTTLE SETTINGS
		love.graphics.translate(love.graphics.getWidth() - 160, love.graphics.getHeight() - 175)
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", -75, -10, 150, 20)
		love.graphics.rectangle("fill", 0, -10, p.t / p.tcap * 75, 20)
		
		love.graphics.setLineWidth(3)
		love.graphics.line(p.t_throttle / 2 * 75, -20, p.t_throttle / 2 * 75, 20)
	love.graphics.pop()
	--]]
	--[[if isColliding == 1 then
		for _, v in pairs(interpts) do
			love.graphics.circle("line", love.mouse.getX() - c.x, love.mouse.getY() - c.y, 3)
		end
	end]]--

	--love.graphics.setColor(255, 255, 255, 255)
	--love.graphics.setFont(info)
	--if playerdead then
	--else
		--love.graphics.print(p.v_throttle, 600, 25)
		--love.graphics.print(p.t_throttle, 600, 50)
		--love.graphics.print(p.v, 600, 75)
		--love.graphics.print(p.t, 600, 100)
	--end
	--love.graphics.print(fire_count, 200, 75)
end

function clcollision(x1, y1, x2, y2, cx, cy, r)						--USING DISCRIMINANT B^2 - 4AC		CIRCLE LINE SEGMENT COLLISION
	local dx1, dy1 = x1 - cx, y1 - cy
	local dx2, dy2 = x2 - cx, y2 - cy
	--local vx, vy = x1 - x2, y1 - y2
	local dx, dy = dx2 - dx1, dy2 - dy1
	
	--if ((vx * dx1) >= 0
	--and (vy * dy1) >= 0)
	--and (math.abs(dx1) <= math.abs(vx))
	--and	(math.abs(dy1) <= math.abs(vy)) then
		local a = (dx * dx) + (dy * dy)
		local b = 2 * ((dx * dx1) + (dy * dy1))
		local c = (dx1 * dx1) + (dy1 * dy1) - (r * r)
		
		local delta = (b * b) - (4 * a * c)
		
		--if delta < 0 then						--NO INTERSECT
		--	return 0
		--else									--INTERSECT
		--	return 1
		--end
	if delta == 0 then
		local u = -b / (2 * a)
		
		local x = x1 + (u * dx)
		local y = y1 + (u * dy)
		
		if (x > x1 and x > x2)		--IF POINT IS NOT WITHIN BOUNDING BOX OF LINE
		or (x < x1 and x < x2)
		or (x > x1 and x > x2)
		or (x < x1 and x < x2)
		or (y > y1 and y > y2)
		or (y < y1 and y < y2)
		or (y > y1 and y > y2)
		or (y < y1 and y < y2) then
			return 0
		else
			return 1, {{x, y}}
		end
	elseif delta > 0 then
		root = math.sqrt(delta)
		
		local u1 = (-b + root) / (2 * a)
		local u2 = (-b - root) / (2 * a)
		
		local x = x1 + (u1 * dx)
		local y = y1 + (u1 * dy)
		
		local points = {}
		
		if (x > x1 and x > x2)		--IF POINT IS WITHIN BOUNDING BOX OF LINE
		or (x < x1 and x < x2)
		or (y > y1 and y > y2)
		or (y < y1 and y < y2) then
		else
			table.insert(points, {x, y})
		end
		
		local x = x1 + (u2 * dx)
		local y = y1 + (u2 * dy)
		if (x > x1 and x > x2)		--IF POINT IS WITHIN BOUNDING BOX OF BOTH LINES
		or (x < x1 and x < x2)
		or (y > y1 and y > y2)
		or (y < y1 and y < y2) then
		else
			table.insert(points, {x, y})
		end
		
		if #points == 0 then
			return 0
		else
			return 1, points
		end
	else
		return 0
	end
end

function llcollision(l1x1, l1y1, l1x2, l1y2, l2x1, l2y1, l2x2, l2y2)			--LINE SEGMENTS COLLISION
	if l1x1 ~= l1x2 then
		m1 = (l1y1 - l1y2) / (l1x1 - l1x2)
		c1 = l1y1 - (m1 * l1x1)
	else
		m1 = 0
	end
	
	if l2x1 ~= l2x2 then
		m2 = (l2y1 - l2y2) / (l2x1 - l2x2)
		c2 = l2y1 - (m2 * l2x1)
	else
		m2 = 0
	end
	
	if m1 == m2 then
		return 0
	else
		if l2x1 ~= l2x2 and l1x1 ~= l1x2 then
			x = (c2 - c1) / (m1 - m2)		--FIND POINT OF INTERSECTION
			y = (m1 * x) + c1
		elseif l1x1 == l1x2 and l2x1 ~= l2x2 then
			x = l1x1
			y = (m2 * x) + c2
		elseif l1x1 ~= l1x2 and l2x1 == l2x2 then
			x = l2x1
			y = (m1 * x) + c1
		end
		
		if (x > l1x1 and x > l1x2)		--IF POINT IS NOT WITHIN BOUNDING BOX OF BOTH LINES
		or (x < l1x1 and x < l1x2)
		or (x > l2x1 and x > l2x2)
		or (x < l2x1 and x < l2x2)
		or (y > l1y1 and y > l1y2)
		or (y < l1y1 and y < l1y2)
		or (y > l2y1 and y > l2y2)
		or (y < l2y1 and y < l2y2) then
			return 0
		else
			return 1, {x, y}
		end
	end
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

function normalise90(angle)
	while angle <= -math.pi / 2 do
		angle = angle + math.pi
	end
	while angle > math.pi / 2 do
		angle = angle - math.pi
	end
	
	return angle
end

function anglecollision(surfaceangle, bulletangle)			--FINDS ANGLE OF INCIDENCE
	local incidentangle = surfaceangle - bulletangle

	return normalise90(incidentangle)
end

function calculatedmg(bullet, part, incidentangle)
	local angle = math.abs(incidentangle)
	local penetration								--<1 NO PENETRATION, >1 AND <4 PENETRATION >4 OVER PENETRATION
	local fire = false
	
	if bullet.p == "torpedo" then
		return bullet.dmg, false, false, fire
	else
		if angle ~= 0 then
			penetration = math.sqrt(((math.pi / 2) - angle) / (math.pi / 2)) * (bullet.p / part.arm) * (bullet.p / part.arm) * (bullet.v / 10)
		else
			penetration = (bullet.p / part.arm) * (bullet.p / part.arm) * (bullet.v / 10)				--PENETRATION FORMULA <1 NO PENETRATION, >1 AND <4 PENETRATION >4 OVER PENETRATION
		end
		
		if math.random(1, 100) <= bullet.f then					--CHECK IF FIRE IS SET
			fire = true
		end
		
		if penetration >= 4 or part.hp <= 0 then
			return math.floor(bullet.dmg / 10), false, true, fire			--OVER PENETRATION
		elseif (penetration < 1 and penetration >= 0) then--NO PENETRATION
			return 0, true, false, fire
		else
			if part.grp == 0 then
				return bullet.dmg, false, false, fire
			else
				return math.floor(bullet.dmg / 3), false, false, fire				--PENETRATION
			end
		end			  							 --^REFLECT ^OVERPENETRATION
	end
end

function hitscandmg(bullet, part)
	local p = bullet.p / part.arm
	
	if p >= 1 then
		return bullet.dmg
	else
		return bullet.dmg * p * p * p
	end
end

--function partition(a, start, ending)
	--local pivot = a[ending]
	--local pIndex = start

	--for i = start, ending do
		--if a[i] <= pivot then
			--local tmp = a[i]			--SWAP VALUES OF TABLE ELEMENTS
			--a[i] = a[pIndex]
			--a[pIndex] = tmp
			--pIndex = pIndex + 1
		--end
	--end								--{3, 4, 1, 43, 5, 23, 4}
	
	--local tmp = a[pIndex]
	--a[pIndex] = a[ending]
	--a[ending] = tmp
	
	--return pIndex
--end

--function quicksort(a, start, ending)
	--if start < ending then
		--local pIndex = partition(a, start, ending)
		
		--if (pIndex - 1) - start <= ending - (pIndex + 1) then
			--quicksort(a, start, pIndex - 1)
		--else
			--quicksort(a, pIndex + 1, ending)
		--end
	--end
	
	--return a
--end

function quit()
	particles = {}
	enemies = {}
	hitscan = {}
	bullets = {}
	objects = {}
end