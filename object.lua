module(..., package.seeall)

function new(x, y, r, grp)
	local b = {}
	
	b.x = x
	b.y = y
	b.r = r
	
	b.grp = grp			--TYPE OF OBJECT
							--1.DARK POCKETS -> ABSORBS ALL BULLETS, PLAYER CAN HIDE INSIDE
	return b				--2.
end