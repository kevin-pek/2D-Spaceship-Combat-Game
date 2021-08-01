local menu = require ("menu")
local game = require ("game")

function love.load()
	info = love.graphics.newFont(20)
	medium = love.graphics.newFont(45)
	header = love.graphics.newFont(75)
	
	gamestate = 'menu'
	menu.init(1)
	
	accum = 0			--ENSURES CONSTANT GAME SPEED
	step = 0.016			--60FPS
	
	love.mouse.setVisible(false)
end

function love.update(dt)
	accum = accum + dt
	while accum >= step do
		if gamestate == 'playing' then													--GAME
			if game.paused == false then
				game.update(dt)
				
				if game.dead_timer == 0 and game.playerdead then
					game.quit()
					menu.init(4)
					
					gamestate = 'menu'
				elseif game.dead_timer == 0 and game.playerdead == false then
					game.quit()
					menu.init(5)
					
					gamestate = 'menu'
				end
			end
		elseif gamestate == 'menu' then													--MAIN MENU
			menu.update()
		end
		accum = accum - step
	end
end

function love.draw()
	love.graphics.setFont(info)
	--love.graphics.print(gamestate, 10, 10)			--SHOW CURRENT GAMESTATE
	
	if gamestate == 'playing' then
		game.draw()
		
		if game.paused then
			love.graphics.setColor(0, 0, 0, 150)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
			
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setFont(header)
			love.graphics.print("Paused", love.graphics.getWidth() / 2 - header:getWidth("Paused") / 2, love.graphics.getHeight() / 4)
			love.graphics.setFont(medium)
			love.graphics.print("X to Resume", love.graphics.getWidth() / 2 - medium:getWidth("X to Resume") / 2, love.graphics.getHeight() / 2)
			love.graphics.print("Esc to Exit", love.graphics.getWidth() / 2 - medium:getWidth("Esc to Exit") / 2, love.graphics.getHeight() / 2 + 75)
		end
	elseif gamestate == 'menu' then
		menu.draw()
	end
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setLineWidth(1)
	love.graphics.push()
		love.graphics.translate(love.mouse.getX(), love.mouse.getY())
		love.graphics.rotate(-math.pi / 4)
		love.graphics.line(0, 0, -5, 15)
		love.graphics.line(-5, 15, 5, 15)
		love.graphics.line(5, 15, 0, 0)
	love.graphics.pop()
end


function love.keypressed(key)
	if gamestate == "playing" then
		if key == "w" then
			game.p.v_throttle = game.p.v_throttle + 1
		elseif key == "s" then
			game.p.v_throttle = game.p.v_throttle - 1
		elseif key == "a" then
			game.p.t_throttle = game.p.t_throttle - 1
		elseif key == "d" then
			game.p.t_throttle = game.p.t_throttle + 1
		elseif key == "x" then
			if game.paused == false then
				game.paused = true
			else
				game.paused = false
			end
		end
		
		if game.paused == true then
			if key == "escape" then
				gamestate = "menu"
				game.quit()
				menu.init(1)
			end
		end
	end
end

function love.mousereleased(x, y, button, isTouch)
	if gamestate == "menu" then
		for i, v in pairs(menu.buttons) do
			if x > v.x - medium:getWidth(v.text) / 2 - 10 and
			x < v.x + medium:getWidth(v.text) / 2 + 10 and
			y > v.y and
			y < v.y + medium:getHeight() then
				if menu.number == 1 then			--MAIN MENU
					if i == 1 then
						gamestate = "playing"
						menu.quit()
						game.init(1)
					elseif i == 2 then
						--STAGE SELECT
						menu.quit()
						menu.init(2)
					elseif i == 3 then
						--SETTINGS
						menu.quit()
						menu.init(3)
					else
						love.quit()
						love.event.push("quit")
					end
				elseif menu.number == 2 then		--STAGE SELECT
					if i < #menu.buttons then
						gamestate = "playing"
						menu.quit()
						game.init(v.text)
					else
						menu.quit()
						menu.init(1)
					end
				elseif menu.number == 3 then		--SETTINGS
					if i == 1 then
						--KEYBOARD
						menu.quit()
						menu.init(6)
					else
						menu.quit()
						menu.init(1)
					end
				elseif menu.number == 4 then		--GAME OVER
					if i == 1 then
						--RETRY
						gamestate = "playing"
						menu.quit()
						game.init(game.lvl)
					elseif i == 2 then
						--MAIN MENU
						menu.quit()
						menu.init(1)
					end
				elseif menu.number == 5 then		--STAGE CLEARED
					if i == 1 then
						--NEXT LEVEL
						gamestate = "playing"
						menu.quit()
						game.init(game.lvl + 1)
					elseif i == 2 then
						--MAIN MENU
						menu.quit()
						menu.init(1)
					end
				elseif menu.number == 6 then		--KEYBOARD
					
				end
			end
		end
	end
end

function love.quit()
	--stuff to save before quitting
end