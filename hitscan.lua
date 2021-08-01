module(..., package.seeall)

function new(x, y, angle, class)
	local b = {}
	
	b.x = x
	b.y = y
	b.angle = angle
	b.class = class
	
	if b.class == "railgun" then
		b.v = 25
		b.dmg = 3000
		b.f = 0
		b.p = 300
		
		b.points = {1.5, -5, -1.5, -5, -1.5, 5, 1.5, 5}
	end
end