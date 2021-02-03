pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--canyon run
--by benjamin smith

function _init()
	gameover=false
	
	particles={}
	
	map_y=0
	map_speed=1.5
	cliff_y=0
	cliff_speed=1.65
	
	actors={}
	make_player()
	
	ground_time=0
	max_ground_time=45
	
	enemy_timer=0
	enemy_spwn=90
	min_enemy_spwn=20
	obst_timer=0
	obst_spwn=60
	min_obst_spwn=20
	
	ai_sight_radius=20
	
	v_collide_distance=2
	
	first_input=false
	
	score=0
	game_time=0
	difficulty_up_time=300
	
	debug=false
	menuitem(1,"debug (off)",toggle_debug)
	
	--music(0)
	--test_obst()
end

function _update60()
	update_map()
	if (gameover==false) then
		move_player()
		
		if (first_input) then
			update_score()
			
			game_time+=1
			if (game_time%difficulty_up_time)==0 then
				if (enemy_spwn>min_enemy_spwn) enemy_spwn-=1
				if (obst_spwn>min_obst_spwn) obst_spwn-=1
			end
		
			obst_timer+=1
			if (obst_timer%obst_spwn==0) then
				make_obstacle()
			end
			
			enemy_timer+=1
			if (enemy_timer%enemy_spwn==0 and #actors <20) then
				make_enemy()
			end
		elseif btn(0) or btn(1) or btn(2) or btn(3) or btn(4) then
			first_input=true
		end
	end
	foreach(actors,move_actor)
	foreach(actors,collision_check)

	if (gameover and btn(5)) _init()
end

function _draw()
	cls(15)
	draw_map()
	
	foreach(particles[1],update_particle)
	
	if (gameover==false and player_z<8) draw_player()
	foreach(actors,draw_shadow)
	foreach(actors,draw_actors)
	if (gameover==false and player_z>=8) draw_player()
	draw_clifftop()
	
	particle_layers(2,#particles)
	
	if (first_input==false) then
		message("arrows to move",0)
		message("z to dive under arches",8)
	end
	
	if gameover and map_speed<=1.2 then
		message("game over",-8)
		message(score.."m traveled",0)
		message("press x to restart",8)
	end
	
	print(score.."m",5,5,0)
	
	if (debug) show_debug()
end

function rndb(low,high)
	return flr(rnd(high-low+1)+low)
end

function message(s,offset)
	print(s,64-#s*2,61+offset,0)
end

function update_score()
	if (game_time%30==0) score+=1
end

function toggle_debug()
	if (debug) then
		debug=false
		menuitem(1,"debug (off)",toggle_debug)
	else
		debug=true
		menuitem(1,"debug (on)",toggle_debug)
	end
end

function show_debug()
	color(1)
	cursor(5,13)
	print("fps:"..stat(7).."/"..stat(8))
	print("cpu:"..stat(1))
	print("s_cpu:"..stat(2))
	print("mem:"..stat(0))
	
	print("---")
	print("obst time:"..obst_spwn)
	print("enemy time:"..enemy_spwn)

	draw_player_collider()
	foreach(actors,draw_collider)
end
-->8
--actors
function make_enemy()
	local enemy={
		sprite=8,
		spr_w=1,
		spr_h=1,
		flipped=false,
		kind="shoot",
		x=rndb(10,100),
		y=-10,
		z=0,
		speed=0.8,
		hit_radius=4,
		state="parked",
		target_x=rndb(28,100),
		target_y=rndb(28,100)
	}
	add_actor(enemy)
end

function test_obst()
	local obst={
		sprite=83,
		spr_w=2,
		spr_h=2,
		flipped=false,
		kind="obst",
		x=56,
		y=32,
		z=10,
		speed=0,
		hit_radius=4
	}
	
	add_actor(obst)
end

function make_obstacle()
	local arch,arch_chance,arch_w=rndb(1,100),30,42
	local obst_speed,base_speed=map_speed,map_speed
	local obst_x,obst_y,obst_z=64,-10,0

	if arch>arch_chance then
		obst_x=rndb(10,100)
	else
		obst_x=rndb(10,100-arch_w)
	end

	for i=1,3 do
		local obst={
			sprite=83,
			spr_w=2,
			spr_h=2,
			flipped=false,
			kind="obst",
			x=obst_x+rndb(-1,1),
			y=obst_y-i*2,
			z=obst_z+i*3,
			speed=obst_speed,
			hit_radius=4
		}
		
		add_actor(obst)
		
		if arch<=arch_chance then
			--add a 2nd column
			local c2_obst={
				sprite=83,
				spr_w=2,
				spr_h=2,
				flipped=false,
				kind="obst",
				x=obst_x+rndb(-1,1)+arch_w,
				y=obst_y-i*2,
				z=obst_z+i*2,
				speed=obst_speed,
				hit_radius=4
			}
			add_actor(c2_obst)
		end
		
		obst_speed=base_speed+i/20
	end
	
	if arch<=arch_chance then
		--add the top of the arch
		for i=1,3 do
			local a1_obst={
				sprite=83,
				spr_w=2,
				spr_h=2,
				flipped=false,
				kind="obst",
				x=obst_x+rndb(-1,1)+i*5,
				y=obst_y-8+rndb(-1,1),
				z=10,
				speed=obst_speed,
				hit_radius=4
			}
			local a2_obst={
				sprite=83,
				spr_w=2,
				spr_h=2,
				flipped=false,
				kind="obst",
				x=obst_x+rndb(-1,1)+arch_w-i*5,
				y=obst_y-8+rndb(-1,1),
				z=10,
				speed=obst_speed,
				hit_radius=4
			}
			add_actor(a1_obst)
			add_actor(a2_obst)
		end
	end
end

function shoot(bullet_x,bullet_y)
	local bullet={
		sprite=33,
		spr_w=1,
		spr_h=1,
		flipped=false,
		kind="bullet",
		x=bullet_x,
		y=bullet_y,
		z=10,
		speed=2,
		hit_radius=2
	}
	sfx(4)
	add_actor(bullet)
end

function move_actor(a)
	if (a.kind=="obst") then
		a.y+=a.speed
	elseif (a.state=="parked") then
		if player_y<a.y then
			a.state="scatter"
		else
			a.y+=map_speed
		end
	else
		local action=actor_ai(a)
		a.x+=a.speed*action.x
		a.y+=a.speed*action.y
	end
end

function add_actor(new_actor)
	add(actors,new_actor)
end

function draw_actors(a)
	spr(a.sprite,a.x,a.y,a.spr_w,a.spr_h,a.flipped)
end

function draw_shadow(a)
	if game_time%2==0 then
	for i=1,15 do
		pal(i,0)
	end
	spr(a.sprite,a.x+a.z/2,a.y+a.z/2,a.spr_w,a.spr_h,a.flipped)
	pal()
	end
end

function kill(a)
	local x,y=player_x,player_y
	if a!="player" then
		del(actors,a)
		x,y=a.x,a.y
		if (a.kind!="obst" and a.kind!="bullet") then
			sfx(3)
			explosion_small(x,y)
		end
	else
		sfx(1)
		explosionb(x,y)
		gameover=true
	end
end
-->8
--map
function update_map()
	if gameover then
		map_speed=max(0,map_speed-0.1)
		cliff_speed=max(0,cliff_speed-0.1)
	end
	map_y+=map_speed
	if map_y>=127 then map_y=0 end
	cliff_y+=cliff_speed
	if cliff_y>=127 then cliff_y=0 end
end

function draw_map()
	map(0,0,0,map_y)
	map(0,0,0,map_y-128)
end

function draw_clifftop()
	map(16,0,-8,cliff_y,3,16)
	map(16,0,-8,cliff_y-128,3,16)
	map(19,0,112,cliff_y,3,16)
	map(19,0,112,cliff_y-128,3,16)
end
-->8
--vfx
function sparks(x,y)
	add_particles(
		1, --number of particles
		3,8, --velocity min/max
		x,x,y,y, --spawn zone
		260,280, --angle degrees min/max
		5,20, --life min/max
		0,1, --size min/max
		.9, --scale over time
		0.2, --friction
		0, --external force (gravity,wind,etc.)
		0, --force angle in degrees
		{7,10,9,8,2}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		3, --trail length
		2 --layer
	)
end

function explosion(x,y)
	--smoke
	local smoke_scale={1.1,1.1,1.05,1.05,1.05,1.05,.7}
	add_particles(
		15, --number of particles
		2,4, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		7,16, --life min/max
		2,4, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--sparks
	add_particles(
		10, --number of particles
		3,8, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		5,20, --life min/max
		1,3, --size min/max
		.9, --scale over time
		0.2, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		5, --trail length
		2 --layer
	)
	
	--fire
	add_particles(
		8, --number of particles
		2,3, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		7,20, --life min/max
		9,10, --size min/max
		{1,1,1,.95,.95,.95,.95,.7}, --scale over time
		0.2, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,0,7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--smoke top
	add_particles(
		7, --number of particles
		2,4, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		5,10, --life min/max
		2,4, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
end

function dust(x,y)
	add_particles(
		5, --number of particles
		2,4, --velocity min/max
		x-8,x+8,y,y, --spawn zone
		250,290, --angle degrees min/max
		5,10, --life min/max
		2,3, --size min/max
		{1.2,1,1,.6}, --scale over time
		0.1, --friction
		0, --external force (gravity,wind,etc.)
		0, --force angle in degrees
		{4,4,4,4,15,5}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		1 --layer
	)
end

function explosionb(x,y)
	--smoke
	local smoke_scale={1.1,1.1,1.05,1.05,1.05,1.05,.7}
	add_particles(
		15, --number of particles
		2,4, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		7,16, --life min/max
		2,4, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--sparks
	add_particles(
		10, --number of particles
		3,8, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		5,20, --life min/max
		1,3, --size min/max
		.9, --scale over time
		0.2, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		5, --trail length
		2 --layer
	)
	
	--ship
	add_particles(
		3, --number of particles
		2,7, --velocity min/max
		x,x,y,y, --spawn zone
		60,120, --angle degrees min/max
		200,200, --life min/max
		1,1, --size min/max
		1, --scale over time
		0.2, --friction
		0, --external force (gravity,wind,etc.)
		0, --force angle in degrees
		0, --colors
		7, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--fire
	add_particles(
		8, --number of particles
		2,3, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		7,20, --life min/max
		9,10, --size min/max
		{1,1,1,.95,.95,.95,.95,.7}, --scale over time
		0.2, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,0,7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--smoke top
	add_particles(
		7, --number of particles
		2,4, --velocity min/max
		x-4,x+4,y-4,y+4, --spawn zone
		0,360, --angle degrees min/max
		5,10, --life min/max
		2,4, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
end

function explosion_small(x,y)
	--smoke
	local smoke_scale={1.1,1.1,1.05,1.05,1.05,1.05,.7}
	add_particles(
		5, --number of particles
		1,3, --velocity min/max
		x-2,x+2,y-2,y+2, --spawn zone
		0,360, --angle degrees min/max
		4,10, --life min/max
		1,3, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--sparks
	add_particles(
		5, --number of particles
		2,6, --velocity min/max
		x-2,x+2,y-2,y+2, --spawn zone
		0,360, --angle degrees min/max
		3,15, --life min/max
		1,2, --size min/max
		.9, --scale over time
		0.2, --friction
		1.5, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		3, --trail length
		2 --layer
	)
	
	--fire
	add_particles(
		4, --number of particles
		1,2, --velocity min/max
		x-2,x+2,y-2,y+2, --spawn zone
		0,360, --angle degrees min/max
		3,15, --life min/max
		6,7, --size min/max
		{1,1,1,.95,.95,.95,.95,.7}, --scale over time
		0.2, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{7,0,7,10,9,8}, --colors
		nil, --sprites
		false, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
	
	--smoke top
	add_particles(
		5, --number of particles
		1,3, --velocity min/max
		x-2,x+2,y-2,y+2, --spawn zone
		0,360, --angle degrees min/max
		4,10, --life min/max
		1,3, --size min/max
		smoke_scale, --scale over time
		0.3, --friction
		3, --external force (gravity,wind,etc.)
		270, --force angle in degrees
		{5,13}, --colors
		nil, --sprites
		true, --random color (false means the particle will move through the colors over it's life)
		0, --trail length
		2 --layer
	)
end
-->8
--particles
function update_particle(p)	
	local col,sprite=p.col,p.sprite
	if (not col) col=7
		if type(col)=="table" then
		local col_id=max(1,#col-flr(p.life/p.life_start*#col))
		col=col[col_id]
	end
	
	if type(sprite)=="table" then
		local spr_id=max(1,#sprite-flr(p.life/p.life_start*#sprite))
		sprite=sprite[spr_id]
	end
	
	if p.trail>0 then
		draw_trail(p.x,p.y,p.last_x,p.last_y,p.trail,p.life,col)
	end
	
	if sprite then
		spr(sprite,p.x,p.y)
	else
		circfill(p.x,p.y,p.size,col)
	end
	
	add(p.last_x,p.x,1)
	add(p.last_y,p.y,1)
	if #p.last_x>p.trail then
		deli(p.last_x)
		deli(p.last_y)
	end
	
	p.x+=p.v*cos(p.angle)+p.force*cos(p.force_a)
	p.y+=p.v*sin(p.angle)+p.force*sin(p.force_a)
	
	p.v-=p.v*p.friction
	p.life-=1
	
	local scale=p.scale
	if type(scale)=="table" then
		local scale_id=max(1,#scale-flr(p.life/p.life_start*#scale))
		scale=scale[scale_id]
	end
	p.size=p.size*scale
	
	if p.life<=0 then
		del(particles[p.layer],p)
	end
end

function draw_trail(x,y,last_x,last_y,length,life,col)
	length=min(#last_x,life-1,length)
	
	for i=1,length do
		local end_x,end_y=last_x[i],last_y[i]
		line(x,y,end_x,end_y,col)
		x,y=end_x,end_y
	end
end

function add_particles(num,min_v,max_v,min_x,max_x,min_y,max_y,min_a,max_a,min_life,max_life,min_size,max_size,scale,friction,force,force_a,cols,sprites,col_rnd,p_trail,layer)
	for i=1,num do
		local life=rndb(min_life,max_life)
		local col,sprite=cols,sprites
		if (col_rnd and type(col)=="table") col=rnd(cols)
		if (col_rnd and type(sprite)=="table") sprite=rnd(sprites)
		
		local p={
			v=rndb(min_v,max_v),
			x=rndb(min_x,max_x),
			y=rndb(min_y,max_y),
			last_x={},
			last_y={},
			angle=rndb(min_a,max_a)/360,
			life=life,
			life_start=life,
			size=rndb(min_size,max_size),
			scale=scale,
			friction=friction,
			force=force,
			force_a=force_a/360,
			col=col,
			sprite=sprite,
			trail=p_trail,
			layer=layer
		}
		for j=#particles+1,layer do
			add(particles,{})
		end
		add(particles[layer],p)
	end
end

function particle_layers(l_start,l_end)
	for i=l_start,l_end do
		foreach(particles[i],update_particle)
	end
end
-->8
--player
function make_player()
	player_x=55
	player_y=85
	player_z=10
	player_speed=1.2
	player_sprite=1
	player_hitbox={
		back={
			x=7,
			y=10,
			r=2,
			spark=false
		},
		front={
			x=7,
			y=5,
			r=2,
			spark=false
		},
		l_wing={
			x=3,
			y=11,
			r=1,
			spark=true,
			spark_offset_x=-2,
			spark_offset_y=2
		},
		r_wing={
			x=12,
			y=11,
			r=1,
			spark=true,
			spark_offset_x=2,
			spark_offset_y=2
		}
	}
end

function move_player()
	local next_x,next_y,next_z=player_x,player_y,player_z
	
	--left/right controls
	if btn(0) then
			next_x-=player_speed
	elseif btn(1) then
		next_x+=player_speed
	end
	
	--forward/back controls
	if btn(2) then
			next_y-=player_speed
	elseif btn(3) then
		next_y+=player_speed
	end
	
	--dive controls
	if btn(4) then
		next_z-=0.5
	else
		next_z+=0.25
	end
	
	player_sprite=1
	local flipped=false
	if(btn(1)) player_sprite=2
	if(btn(0)) player_sprite=3
	
	next_x=mid(0,next_x,127)
	next_y=mid(0,next_y,112)
	next_z=mid(0,next_z,10)
	
	player_x=next_x
	player_y=next_y
	player_z=next_z
	
	--sparks from walls
	if player_x>=98 then
		sparks(player_x+16,player_y+14)
		sfx(0)
	elseif player_x<=14 then
		sparks(player_x,player_y+14)
		sfx(0)
	end
	
	--death from walls
	if player_x>=105 then
		kill("player")
	elseif player_x<=7 then
		kill("player")
	end
	
	--death and dust from ground
	if player_z<=2 then
		sfx(2)
		dust(player_x+8,player_y+14)
		ground_time+=1
		if ground_time>=max_ground_time then
			kill("player")
		end
	else
		ground_time=0
	end
end

function draw_player()
	draw_shadow_player()
	sprite,flipped=p_sprite()
	spr(sprite,player_x,player_y,2,2,flipped)
end

function p_sprite()
	if player_sprite==2 then
		return 3,false
	elseif player_sprite==3 then
		return 3,true
	end
	return 1,false
end

function draw_shadow_player()
	local p_spr,p_flip=p_sprite()
	local p_tbl={
		sprite=p_spr,
		flipped=p_flip,
		x=player_x,
		y=player_y,
		z=player_z,
		spr_w=2,
		spr_h=2
	}
	draw_shadow(p_tbl)
end
-->8
--collision
function collision_check(a)
	--check collision with player
	if (gameover==false) then
		for key,box in pairs(player_hitbox) do
			if overlap(a.x,a.y,a.z,a.hit_radius,box.x+player_x-8,box.y+player_y-8,player_z,box.r) then
				--collision
				kill("player")
				kill(a)
			elseif overlap(a.x,a.y,a.z,a.hit_radius,box.x+player_x-8,box.y+player_y-8,player_z,box.r+8) and box.spark==true then
				--close shave
				sfx(0)
				sparks(box.x+player_x+box.spark_offset_x,box.y+player_y+box.spark_offset_y)
			end
		end
	end
	
	if a.kind=="obst" then
		if (a.y>200) kill(a)
	elseif a.kind=="bullet" then
		if (a.y<-20) kill(a)
	else
		--enemies
		for obst in all(actors) do
			if a.x!=obst.x and a.y!=obst.y then
				if overlap(a.x,a.y,a.z,a.hit_radius,obst.x,obst.y,obst.z,obst.hit_radius) then
					kill(a)
				end
			end
		end
		
		--walls
		if a.x+a.spr_w*8>=121 or a.x<=7 then
			kill(a)
		end
	end
end

function overlap(x1,y1,z1,r1,x2,y2,z2,r2)
	if abs(z1-z2)<=v_collide_distance then
		local dx=abs(x1-x2)
		local dy=abs(y1-y2)
		if dx+dy<r1+r2 then
			return true
		end
	end
	return false
end

function draw_collider(a)
	--npc or obstacle
	local coord={
		x=a.x+8*(a.spr_w/2),
		y=a.y+8*(a.spr_h/2)
	}
	circ(coord.x,coord.y,a.hit_radius,8)

	if (a.kind!="obst") then
		circ(spr_center(a).x,spr_center(a).y,ai_sight_radius,10)
	end
end

function draw_player_collider()
	for key,box in pairs(player_hitbox) do
		circ(player_x+box.x,player_y+box.y,box.r,8)
	end
end

function spr_center(a)
	local center={
		x=a.x+(4*a.spr_w),
		y=a.y+(4*a.spr_h)
	}
	return center
end
-->8
--npc ai
function actor_ai(a)
	local dist=obst_distance(a)
	local a_dir={
		x=-direction(dist),
		y=0
	}
	local a_center=spr_center(a)
	
	if a.kind=="shoot" then
		--if we aren't avoiding an obstacle
		--then move toward the target x
		if dist==999 and a_center.x!=a.target_x then
			a_dir.x=-direction(a_center.x-a.target_x)
		end
		
		--move toward target y
		if spr_center(a).y<a.target_y then
			a_dir.y=1
		elseif spr_center(a).y>a.target_y then
			a_dir.y=-1
		end
		
		if (a.z<10 and a.state!="parked") a.z+=1
	
		--switch state
		if at_target(a.target_x,a.target_y,a_center) then
			if a.state=="scatter" then
				if rndb(1,10)<=3 then
					a.target_x,a.target_y=player_x+8,player_y+48
					a.state="target"
				else
					a.target_x,a.target_y=rndb(28,100),rndb(28,100)
				end
			elseif a.state=="target" then
				shoot(a_center.x,a.y-8)
				a.state="scatter"
			end
		end
	elseif a.kind=="bullet" then
		a_dir.x,a_dir.y=0,-1
	end
	return a_dir
end

function obst_distance(a)
	local dist=999
	local a_center=spr_center(a)
	for obst in all(actors) do
		if a.x!=obst.x and a.y!=obst.y then
			local obst_center=spr_center(obst)
			local dx,dy,dz=abs(obst_center.x-a_center.x),abs(obst_center.y-a_center.y),abs(a.z-obst.z)
			
			if dx+dy<=ai_sight_radius and dz<=v_collide_distance then
				if min(abs(dist),dx)==dx then
					dist=obst_center.x-a_center.x
				end
			end
		end
	end
	
	return dist
end

function direction(n)
	return (n<0 and -1) or 1
end

function at_target(tx,ty,loc)
	local m=1 --margin of error
	local at_x,at_y=false,false
	if (loc.x<=flr(tx)+m and loc.x>=flr(tx)-m) at_x=true
	if (loc.y<=flr(ty)+m and loc.y>=flr(ty)-m) at_y=true
	
	if (at_x) and (at_y) then
		return(true)
	else
		return(false)
	end
end
__gfx__
000000000000000dd00000000000000dd00000000000000660000000000dd0000005500000055000000000000000000000000000000000000000000000000000
00000000000000d22d000000000000d22d000000000000622600000000d22d0000566500005bb500000000000000000000000000000000000000000000000000
00700700000000d22d000000000000d22d000000000000622600000000d22d0005566550055bb550000000000000000000000000000000000000000000000000
0007700000000d5225d0000000000d5225d000000000055225500000055225505866668558bbbb85000000000000000000000000000000000000000000000000
0007700000000dd22dd0000000000dd22dd0000000000652256000000d5225d05866668558bbbb85000000000000000000000000000000000000000000000000
007007000000d9d22d9d000000005d922dd0000000000652256000000d5525d058866885588bb885000000000000000000000000000000000000000000000000
000000000000dad22dad00000000da922dad000000000652256000000d5d5d5d0588885005888850000000000000000000000000000000000000000000000000
00000000000d9ad11da9d0000000da9215ad0000000006511560000000d0d00d0055550000555500000000000000000000000000000000000000000000000000
00000000000dad1111dad0000005da21115d00000000061111600000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d9ad2222da9d00000da92222dad0000000062222600000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000da9d2222d9ad00000da92222dad0000000062222600000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d9a9d2222d9a9d0005da92222dad0000000652222560000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d992d2222d299d000d9992222d29d000000652222560000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d9220d2222d0229d00d92d2222d02d000000652222560000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d20000d22d00002d00d200d22d000d000000606226060000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000055000000000000005500000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000
000a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0089a900000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099900008778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00089800008778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009a9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00898000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fff44000044fff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44f4440000444f440000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff44000044ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff400004fffff000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fffff4004fffff40000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44fff440044fff44000004000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4ff4444004444ff40400000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4fff44000044fff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000004f4ffffff00004440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f40000000000004fffffff4f00044444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000004ffffffff0044fff4444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000000000004ffffffff00444ffffff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f40000000000004fffffffff0044ffffff4f44000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f40000000000004fff4fffff044ffffffffff4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f40000000000004ffffff4ff444ffffffffff4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f00000000000000fffffffff44ffffff4ffff4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff4444ffffff0000000044ff4fffffffff400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff444ff444ffff0000000044ffffffffffff400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44ffffffffffff440000000044ffff4fffffff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff00000000044fffffffffff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444ffff44ffff44400000000044444fffff4ff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff44fff44fff44ff0000000000444444444ff4440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff4444ffffff0000000000000444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff44444444ffff0000000000000000044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4fff00f40004000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff0ff0f04000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffff0f400040f0fffffffffffffffffffffffffffffffffffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffff0f4ff040f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffff000f4f0f0f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffff4fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffff44444fffffffffffffffffffffffffffffffffffff4444ffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffff4444444444f444f444ffffffffffffffffff444fff444444444ffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffff4444ff44444444444444444ffffff444ff44444444444ff444444fffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffff4444444fff44ff44ff44444444ff444444444444444444444ff444ffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4fffffffffffffffff4444f444ff444f44444fff4444444fff4444444444ff4444444f444ffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffff4444ff44fff44ff44f444ffffff4444ffffff44fff444f44ff44ff444fffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444fffffffffffffff44444f44fff44ff44ff44ffffff4f44ffffff4f44f4f44ff444f44f4440ffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffff4444f444ff444f444f44ffffffff44ffffffffff44fff44f44fff4444400ffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffff4444f44fff44ff44f444fffffff444ffffffffff44fff44f44fff44f44400fffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffff44444f44ff444ff44f44ffffff4f44ffffff4ffff44fff44ff4fff44f44400fffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffff4444f44fff44ff44f44ff4fffff44ff4fffffffff4ffff4ff4ffff4f44400fffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffff4444444fff44ff44f44ffffffff44ffffffffffff4ffff4ff44fff4f44400fffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4fffffffffffffff44444444fff44ff4444ffff4fff44ffff4fffffff44fff44f44fff4444400ffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffff444444444444444444444ffffffff44fffffffffff44fff44f44fff44444400fffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffff4fffff4444444444444444444444fffff44444fffff4ff444ff444444ff44444400fffffffffffffffffffff4444fffffffffff
f4ffffff4fff44fffffffffffffffff444444444444444444444444444f444444444ff444ff444444ff4444f4400ffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffff444444444444444444444444444444444444444444444444444444f44400ffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffff444444444400000000000444440000044444444440004444444444000ffffffffffffffffffffff444f44ffffffff
ffffffff4fff44fffffffffffffffffffffffff4444400000000000000000000000000000000000000044444000fffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000fffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000ffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000fffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffff00000fffff0000000000fff00000ffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffddffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffd22dffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffd22dffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444fffffffffffffffffffffffffffffffffffffffffffffffffd5225dfffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffdd22ddffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44fffffffffffffffffffffffffffffffffffffffffffffffffd9d22d9d00fffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffffffffffffffffffffffffffffffffdad22dad000ffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffd9ad11da9d00ffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffdad1111dad000fffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffd9ad2222da9d00ffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffda9d2222d9ad000fffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444fffffffffffffffffffffffffffffffffffffffffffffd9a9d2222d9a9d00fffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffd992d2222d299d000fffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44fffffffffffffffffffffffffffffffffffffffffffffd922fd2222d0229d00fffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffffffffffffffffffffffffffffd2ffffd22d00002d000ffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffff550000000000ffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4fffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000fffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000ffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44fffffffffffffffffffffffffffffffffffffffffffffffff0000f000000f0000fffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444fffffffffffffffffffffffffffffffffffffffffffffffff00ffff0000ffff00fffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44fffffffffffffffffffffffffffffffffffffffffffffffffffffffff00fffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff
ffffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffffff
fffffffff4fff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fff4fffffffff
ff4ffffff4ffff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4ffff4fff4fffff
fffff4fff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4ffffff4ff
fffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444fffffffffff
f4ffffff4fff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44fff4f4ffffff
ffffff4ff4ff44ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44ff4fffffff4f
ffffffff44f444ffffff444fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff444f44ffffffff

__map__
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040004200000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000420000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000042000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000004200000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000000000416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6040000000000000000000004200416152525051525200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002e4201e6003e40000000000000000000000000000000000000000001d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002666026660266602666026650256502465023650216501e6501c64019640176401464012640106300e6300c6300a63008620046200262003610026100161004610026100460003600006000000000000
001000000762003610016100960008600086000760007600076000760007600230000760007600076000760007600086000960009600086000860008600086000860008600066000660006600066000660006600
0003000028650286501c750174502664026640167401f6401f6301043019630196300f7201162011620074200c6100c6100761005610016100061000610282002120023200044000440004400133002320023200
000100001572017130182401a1401c7401f1502225024750207501a2401804016240120300f0300d2300a2200a020090200722006010052100321000000000000000000000000000000000000000000000000000
__music__
03 43424344
00 43424344

