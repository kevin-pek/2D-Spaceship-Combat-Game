module(..., package.seeall)

local shine = require ("shine-master")

buttons = {}
local menus = {
		{{love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "PLAY"}					--MAIN MENU
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 75, "STAGE SELECT"}
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 150, "SETTINGS"}
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 225, "QUIT"}},
		
		{{love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 4, "1"}						--STAGE SELECT
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 4, "2"}
		, {love.graphics.getWidth() / 2 + 150, love.graphics.getHeight() / 4, "3"}
		, {love.graphics.getWidth() / 2 - 150, love.graphics.getHeight() / 4 + 75, "4"}
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 4 + 75, "5"}
		, {love.graphics.getWidth() / 2 + 150, love.graphics.getHeight() / 4 + 75, "6"}
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 225, "MAIN MENU"}},
		
		{{love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "KEYBOARD"}					--SETTINGS
		},
		
		{{love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "RETRY"}					--GAME OVER
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 75, "MAIN MENU"}},
		
		{{love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "NEXT LEVEL"}					--WIN
		, {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + 75, "MAIN MENU"}},
		
		{}					--KEYBOARD SETTINGS
		}

function new(x, y, text)
	local button = {}
	
	button.x = x
	button.y = y
	button.text = text
	button.over = false

	table.insert(buttons, button)
end

function init(menu_number)
	number = menu_number
	
	for _, v in pairs(menus[number]) do
		new(v[1], v[2], v[3])
	end
	
	glow = shine.glowsimple()
end

function update()
	local x, y = love.mouse.getPosition()
	
	for i, v in pairs(buttons) do
		if x > v.x - medium:getWidth(v.text) / 2 - 10 and
		x < v.x + medium:getWidth(v.text) / 2 + 10 and
		y > v.y and
		y < v.y + medium:getHeight() then
			v.over = true
		else
			v.over = false
		end
	end
end

function draw()
	glow:draw(function()
	
	love.graphics.setFont(medium)
	for i, v in pairs(buttons) do
		if v.over then
			love.graphics.setLineWidth(3)
			love.graphics.setColor(255, 255, 255)
		else
			love.graphics.setLineWidth(1)
			love.graphics.setColor(200, 200, 200)
		end

		love.graphics.setFont(medium)
		love.graphics.print(v.text, v.x - (medium:getWidth(v.text) / 2), v.y)
		love.graphics.rectangle("line", v.x - 10 - (medium:getWidth(v.text) / 2), v.y, medium:getWidth(v.text) + 20, medium:getHeight())
	end
	
	love.graphics.setFont(header)
	if number == 1 then
		love.graphics.print("TITLE", love.graphics.getWidth() / 2 - header:getWidth("TITLE") / 2, love.graphics.getHeight() / 4)
	elseif number == 2 then
		love.graphics.print("STAGE SELECT", love.graphics.getWidth() / 2 - header:getWidth("STAGE SELECT") / 2, love.graphics.getHeight() / 4 - 150)
	elseif number == 3 then
		love.graphics.print("SETTINGS", love.graphics.getWidth() / 2 - header:getWidth("SETTINGS") / 2, love.graphics.getHeight() / 4)
	elseif number == 4 then
		love.graphics.print("GAME OVER", love.graphics.getWidth() / 2 - header:getWidth("GAME OVER") / 2, love.graphics.getHeight() / 4)
	elseif number == 5 then
		love.graphics.print("LEVEL CLEARED", love.graphics.getWidth() / 2 - header:getWidth("LEVEL CLEARED") / 2, love.graphics.getHeight() / 4)
	end
	
	end)
end

function quit()				--WHEN CHANGING STATE
	buttons = {}
end