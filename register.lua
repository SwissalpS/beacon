local colors = {
	white	= { desc = "White", 	color = "#ffffffff" },
    black	= { desc = "Black", 	color = "#0f0f0fff" },
    blue	= { desc = "Blue", 		color = "#0000ffff" },
    cyan	= { desc = "Cyan", 		color = "#00ffffff" },
    green	= { desc = "Green", 	color = "#00ff00ff" },
    magenta	= { desc = "Magenta", 	color = "#ff00ffff" },
    orange	= { desc = "Orange", 	color = "#ff8000ff" },
    red		= { desc = "Red", 		color = "#ff0000ff" },
    violet	= { desc = "Violet", 	color = "#8f00ffff" },
    yellow	= { desc = "Yellow", 	color = "#ffff00ff" },
}

local facedir_under = {
	[4] = {x= 1,y=0,z=0},
	[3] = {x=-1,y=0,z=0},
	[5] = {x=0,y= 1,z=0},
	[0] = {x=0,y=-1,z=0},
	[2] = {x=0,y=0,z= 1},
	[1] = {x=0,y=0,z=-1},
}

for name,data in pairs(colors) do
	-- beam
	minetest.register_node("beacon:"..name.."beam", {
		description = data.desc.." Beacon Beam",
		tiles = {"beacon_beam.png^[multiply:"..data.color},
		inventory_image = "beacon_beam.png^[multiply:"..data.color,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beam.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		pointable = false,
		climbable = beacon.config.beam_climbable,
	})

	-- beam base
	minetest.register_node("beacon:"..name.."base", {
		description = data.desc.." Beacon Beam Base",
		tiles = {"beacon_beambase.png^[multiply:"..data.color},
		inventory_image = "beacon_beambase.png^[multiply:"..data.color,
		groups = {beacon_beam = 1, not_in_creative_inventory = 1},
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		mesh = "beambase.obj",
		light_source = minetest.LIGHT_MAX,
		walkable = false,
		diggable = false,
		pointable = false,
		climbable = beacon.config.beam_climbable,
	})

	-- beacon node
	minetest.register_node("beacon:"..name, {
		description = data.desc.." Beacon",
		tiles = {"(beacon_baseglow.png^[multiply:"..data.color..")^beacon_base.png"},
		groups = {cracky = 3, oddly_breakable_by_hand = 3, beacon = 1},
		drawtype = "normal",
		paramtype = "light",
		light_source = 13,
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			if not beacon.allow_change(pos, player)
					or not minetest.get_meta(pos):get_inventory():get_stack(to_list, to_index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if not beacon.allow_change(pos, player) or stack:get_name() ~= beacon.config.upgrade_item
					or not minetest.get_meta(pos):get_inventory():get_stack(listname, index):is_empty() then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if not beacon.allow_change(pos, player) then
				return 0
			end
			return 1
		end,
		on_place = beacon.place,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			beacon.place_beam(pos, placer, pointed_thing, name)
			beacon.set_default_meta(pos)
		end,
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			beacon.show_formspec(pos, player:get_player_name())
		end,
		on_timer = function(pos, elapsed)
			return beacon.update(pos, data.color)
		end,
		can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			return not beacon.showing_formspec(pos) and meta:get_inventory():is_empty("beacon_upgrades")
		end,
		on_destruct = beacon.remove_beam,
	})

	-- coloring recipe
	minetest.register_craft({
		type = "shapeless",
		output = "beacon:"..name,
		recipe = { "group:beacon", "dye:"..name },
	})
end

-- base beacon recipe
minetest.register_craft({
	output = "beacon:white",
	recipe = {
		{"default:steel_ingot", "default:glass", "default:steel_ingot"},
		{"default:mese_crystal_fragment", "default:torch", "default:mese_crystal_fragment"},
		{"default:obsidian", "default:obsidian", "default:obsidian"},
	}
})

-- floating beam cleanup
minetest.register_abm({
	nodenames = {"group:beacon_beam"},
	interval = 2,
	chance = 2,
	action = function(pos, node)
		local under_pos = vector.add(pos, facedir_under[(node.param2-(node.param2%4))/4])
		local under_node = minetest.get_node(under_pos)
		if under_node then
			local def = minetest.registered_nodes[under_node.name]
			if def and def.drawtype == "airlike" then
				minetest.set_node(pos, {name = "air"})
			end
		end
	end,
})

-- conversion for beacons from the original mod
minetest.register_lbm({
	label = "Old beacon conversion",
	name = "beacon:old_conversion",
	nodenames = {"group:beacon"},
	run_at_every_load = false,
	action = function(pos, node)
		if not minetest.get_meta(pos):get_inventory():get_lists().beacon_upgrades then
			beacon.set_default_meta(pos)
		end
	end
})