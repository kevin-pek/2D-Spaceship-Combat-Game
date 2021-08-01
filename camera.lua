module(..., package.seeall)

local game = require("game")

function new(x, y)
	local c = {}
	
	c.x = x
	c.y = y
	c.v = 7
	
	c.update = function(x, y)
		c.x = c.x + x
		c.y = c.y + y
	
		if love.mouse.getX() < 10 then				--MOVE CAMERA BASED ON MOUSE POSITION
			c.x = c.x - c.v
		elseif love.graphics.getWidth() - love.mouse.getX() < 10 then
			c.x = c.x + c.v
		elseif love.mouse.getY() < 10 then
			c.y = c.y - c.v
		elseif love.graphics.getHeight() - love.mouse.getY() < 10 then
			c.y = c.y + c.v
		end
	
		if c.x > game.maxx then				--CHECK CAMERA BORDERS
			c.x = game.maxx
		elseif c.x < game.minx then
			c.x = game.minx
		end
		if c.y > game.maxy then
			c.y = game.maxy
		elseif c.y < game.miny then
			c.y = game.miny
		end
	end
	
	return c
end