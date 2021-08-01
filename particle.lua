module(..., package.seeall)

function new(x, y, grp, texture)
	local s = {}
	
	s.effect = love.graphics.newParticleSystem(texture, 50)
	
	if grp == 1 then								--LARGE EXPLOSION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(7)
		s.effect:setParticleLifetime(5, 7)
		s.effect:setSpeed(0, 100)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(2 * math.pi)
		s.effect:setLinearDamping(0.1, 1)
		s.effect:setSizes(0.3, 0.15)
		s.effect:setSizeVariation(1)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 2 then								--MEDIUM EXPLOSION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(6)
		s.effect:setParticleLifetime(3, 6)
		s.effect:setSpeed(150, 200)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(2 * math.pi)
		s.effect:setLinearDamping(1, 2)
		s.effect:setSizes(0.15, 0.05)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 3 then								--SMALL EXPLOSION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(5)
		s.effect:setParticleLifetime(2, 5)
		s.effect:setSpeed(250, 350)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(2 * math.pi)
		s.effect:setLinearDamping(1, 3)
		s.effect:setSizes(0.05, 0.025)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 4 then								--SHIELD EXPLOSION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(0.25)
		s.effect:setParticleLifetime(0.25)
		s.effect:setSizes(0.5, 0.75)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 5 then								--SHIELD HIT
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(0.5)
		s.effect:setParticleLifetime(0.5)
		s.effect:setSizes(0.05, 0.1)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0)
	end
	
	return s
end

function ricochet(x, y, grp, angle, texture)
	local s = {}
	
	s.effect = love.graphics.newParticleSystem(texture, 10)
	
	if grp == 1 then								--BULLET PENETRATION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(2)
		s.effect:setParticleLifetime(1, 2)
		s.effect:setSpeed(0, 15)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(2 * math.pi)
		s.effect:setLinearDamping(0.1, 1)
		s.effect:setSizes(0.05, 0.03)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 2 then								--BULLET RICOCHET
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(2)
		s.effect:setParticleLifetime(1, 2)
		s.effect:setSpeed(40, 80)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(math.pi / 6)
		s.effect:setDirection(angle - math.pi / 2)
		s.effect:setLinearDamping(1, 3)
		s.effect:setSizes(0.025, 0.005)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 175)
	elseif grp == 3 then								--OVERPENETRATION
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(2)
		s.effect:setParticleLifetime(1, 2)
		s.effect:setSpeed(30, 40)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(math.pi / 3)
		s.effect:setDirection(angle - math.pi / 2)
		s.effect:setLinearDamping(1, 3)
		s.effect:setSizes(0.025, 0.015)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	elseif grp == 4 then								--TORPEDO HIT
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(2)
		s.effect:setParticleLifetime(1, 2)
		s.effect:setSpeed(0, 30)
		s.effect:setRotation(-math.pi, math.pi)
		s.effect:setSpread(math.pi)
		s.effect:setLinearDamping(0.1, 1)
		s.effect:setSizes(0.1, 0.075)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	end
	
	return s
end

function thruster(x, y, grp, texture)
	local s = {}
	
	s.effect = love.graphics.newParticleSystem(texture, 10)
	
	if grp == 1 then
		s.effect:setPosition(x, y)
		s.effect:setEmitterLifetime(0.2)
		s.effect:setParticleLifetime(0.2)
		s.effect:setSizes(0.03, 0.01)
		s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	end
	
	return s
end

function fire(x, y, texture)
	local s = {}
	
	s.effect = love.graphics.newParticleSystem(texture, 30)
	
	s.effect:setPosition(x, y)
	s.effect:setEmitterLifetime(50)
	s.effect:setEmissionRate(8)
	s.effect:setParticleLifetime(2, 3)
	s.effect:setSpeed(20, 40)
	s.effect:setRotation(-math.pi, math.pi)
	s.effect:setSpread(2 * math.pi)
	s.effect:setLinearDamping(0.1, 1)
	s.effect:setSizes(0.075, 0.03)
	s.effect:setColors(255, 255, 255, 255, 255, 255, 255, 0)

	return s
end