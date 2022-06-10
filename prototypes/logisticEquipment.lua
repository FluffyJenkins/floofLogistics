local defaultRoboPort = table.deepcopy(data.raw["roboport"]["roboport"]);
defaultRoboPort.open_sound = nil
defaultRoboPort.close_sound = nil
defaultRoboPort.working_sound = nil
defaultRoboPort.open_door_trigger_effect = nil
defaultRoboPort.close_door_trigger_effect = nil

local baseGhostRoboPort = {
	name = "floof:ghostRoboPort",
	localised_name = {"","ghostRoboPort"},
	localised_description = {"",":3"},
	flags = {
			'no-automated-item-insertion',
			'no-automated-item-removal',
			'hidden',
            'hide-alt-info',
            'not-upgradable',
            'not-in-kill-statistics',
            'not-blueprintable',
            'not-deconstructable',
            'not-on-map',
            'placeable-off-grid'
    },
	max_health = 1,
	selectable = true,
	destructible = false,
    selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
	collision_box = {{0,0},{0,0}},
	collision_mask = {},
    stationing_offset = {0, -1},
	spawn_and_station_height=-1,
	energy_source =
		{
		  type = "electric",
		  usage_priority = "secondary-input",
		  buffer_capacity = "500MJ",
		  render_no_network_icon = false,
		  render_no_power_icon = false,
		},
    logistics_radius = 10,
    construction_radius = 10,
	
}

local function debug(str)
	local debugMode = false
	if debugMode then
	game.print("floofLogi:"..str)
	end
end

local function rescaleSprites(sprites,maxW,maxH,deep)
	maxW = maxW or 69
	maxH = maxH or maxW
	local tempSprites
	if deep then
		tempSprites = table.deepcopy(sprites)
	else
		tempSprites = sprites
	end
	local maxWH = {width = 0, height = 0}
	local maxSpriteHeight = 0
	local maxSpriteWidth = 0
	local function worker(maxWH,job)
		debug("W1A "..maxWH.width.." "..maxWH.height.."    "..job.width.." "..job.height)
		maxWH.height = math.max(maxWH.height or 0,job.height)
		maxWH.width = math.max(maxWH.width or 0,job.width)
		--[[if job.hr_version then
			worker(maxWH,job.hr_version)
		end]]
		debug("W1B "..maxWH.width.." "..maxWH.height.."    "..job.width.." "..job.height)
	end
	local function worker2(maxW,maxH,maxWH,job)
		debug("W2A "..maxW.." "..maxH.."    "..job.width.." "..job.height)
		local ratio = math.min(maxW/maxWH.width,maxH/maxWH.height)
		local oldHeight = job.height
		--job.height = job.height*ratio
		--job.width = job.width*ratio
		if job.shift then
			job.shift[1] = job.shift[1]*ratio
			job.shift[2] = job.shift[2]*ratio
		end
		if job.scale then
			job.scale = job.scale*ratio
		else
			job.scale = ratio
		end
		debug("W2B "..maxW.." "..maxH.."    "..job.width.." "..job.height)
		if job.hr_version then
			worker2(maxW,maxH,maxWH,job.hr_version)
		end
	end
		
	for _, sprite in pairs(tempSprites) do
		debug("L1 ".._)
		if sprite.layers then
			for _, layer in pairs(sprite.layers) do
				debug("L1_1 ".._)
				worker(maxWH,layer)
				if layer.hr_version then
					worker(maxWH,layer.hr_version)
				end
			end
		else
			worker(maxWH,sprite)
		end
	end
	
	
	for _, sprite in pairs(tempSprites) do
		debug("L2 ".._)
		if sprite.layers then
			for _, layer in pairs(sprite.layers) do
				worker2(maxW,maxH,maxWH,layer)
				--[[if layer.hr_version then
					worker2(maxSpriteWidth,maxSpriteHeight,layer.hr_version)
				end]]
			end
		else
			worker2(maxW,maxH,maxWH,sprite)
		end
	end
end


local function genGhostPort(name,props)
	props = props or {}
	name = name or math.floor(math.random()*100000)
	local newProps = {
		name = "floof:ghostRoboPort-" .. name,
		localised_name = {"","ghostRoboPort-" .. name},
	}
	return util.merge{defaultRoboPort,baseGhostRoboPort,newProps,props}
end

local test = util.merge{defaultRoboPort,baseGhostRoboPort,{}}


rescaleSprites({defaultRoboPort.base,defaultRoboPort.base_patch,defaultRoboPort.base_animation,defaultRoboPort.door_animation_up,defaultRoboPort.door_animation_down},0,0)


local recipe = {
	{
		type = "recipe",
		name = "floof:logisticPort",
		localised_name = {"","Logistic Port"},
		localised_description = {"","Logistic port for mobile logisitical requests!"},
		enabled = true,
		energy_required = 10,
		ingredients =
		{
			{"advanced-circuit", 10},
			{"iron-gear-wheel", 40},
			{"steel-plate", 20},
			{"battery", 20},
		},
		result = "floof:logisticPort"
	}
}

local equipment = {
	{
		type = "battery-equipment",
		name = "floof:logisticPort",
		localised_name = {"","Logistic Port"},
		localised_description = {"","Logistic port for mobile logisitical requests!"},
		take_result = "floof:logisticPort",
		sprite = {
			filename = "__floofLogistics__/graphics/icon.png",
			width = 64,
			height = 64,
			mipmap_count = 4,
			priority = "medium",
		},
		shape = {
			width = 1,
			height = 1,
			type = 'full',
		},
		energy_source =
		{
			type = "electric",
			buffer_capacity = "75MJ",
			input_flow_limit = "7500KW",
			usage_priority = "secondary-input"
		},
		categories = {"armor"},
	}
}

local item = {
	{
		type = "item",
		name = "floof:logisticPort",
		localised_name = {"","Logistic Port"},
		localised_description = {"","Logistic port for mobile logisitical requests!"},
		icon =  "__floofLogistics__/graphics/icon.png",
		icon_size =  64,
		subgroup = "equipment",
		order = "z",

		placed_as_equipment_result = "floof:logisticPort",
		stack_size   =  50,
	},
}

local grid = 
{
	type = "equipment-grid",
	name = "floof:grid",
	width = 8,
	height = 5,
	equipment_categories = {"armor"}
}

data:extend(recipe)
data:extend(item)
data:extend(equipment)
data:extend(
{
	grid,
	util.merge{defaultRoboPort,baseGhostRoboPort},
	genGhostPort("5m-L",{logistics_radius=5,construction_radius=5,logistics_connection_distance=5}),
	genGhostPort("10m-L",{logistics_radius=10,construction_radius=10,logistics_connection_distance=10}),
	genGhostPort("15m-L",{logistics_radius=15,construction_radius=15,logistics_connection_distance=15}),
	genGhostPort("20m-L",{logistics_radius=20,construction_radius=20,logistics_connection_distance=20}),
})