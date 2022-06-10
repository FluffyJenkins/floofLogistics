-- /c debug(game.player.selected.logistic_network == game.surfaces[1].find_logistic_network_by_position(game.player.position,game.player.force))

local floofLogistics = { ghostPorts = {}, gui = {} }

local minLevel = 1
local maxLevel = 4

local ghostPortButton = {
	type = "button",
	name = "floof:ghostPortButton",
	caption = "Open FloofLogistics Port",
	anchor = {
		gui = defines.relative_gui_type.container_gui,
		position = defines.relative_gui_position.right,
		name = "cargo-wagon",
	}
}
local player = {}
local gui = {}
local debugMode = false
local function debug(str)
	if not debugMode then return end
	if type(str) == "table" then
		game.print(serpent.block(str))
	else
		game.print(str)
	end
end

local function drop_inventory(ent, inventory)
	for i = 1, #inventory do
		if inventory[i].valid_for_read then
			game.surfaces[1].spill_item_stack(ent.position, inventory[i], true, ent.force)
			inventory[i].clear()
		end
	end
end

local function move_inventory(inventoryA, inventoryB)
	for i = 1, #inventoryB do
		if inventoryA[i].valid_for_read and inventoryB[i].valid then
			local result = inventoryB[i].transfer_stack(inventoryA[i])
			if not result then
				game.surfaces[1].spill_item_stack(inventoryA.entity_owner.position, inventoryA[i], true, inventoryA.entity_owner.force)
				inventoryA[i].clear()
			end
		end
	end
end

local function removeGhostPort(unit_number,removeEntry)
	
		local ghostPort = floofLogistics.ghostPorts[unit_number]
		if ghostPort then
			if ghostPort.ent and ghostPort.ent.valid then
				drop_inventory(ghostPort.ent, ghostPort.robot)
				drop_inventory(ghostPort.ent, ghostPort.material)
				ghostPort.ent.destroy()
			else
				debug("ghostPort ent not valid!")
			end
			if removeEntry then
				floofLogistics.ghostPorts[unit_number] = nil
			end
		else
			debug("Error couldn't find unit in thing! " .. unit_number)
		end
		debug("end of remove")
end

local function floofSpawn(command)
	if command.parameter and game.entity_prototypes[command.parameter] then
		game.surfaces[1].create_entity { name = command.parameter, position = { game.player.position.x, game.player.position.y - 3 }, force = game.player.force }
	elseif command.parameter then
		debug({ "", "Error " .. command.parameter .. "is not a valid entity prototype" })
	else
		debug({ "", "Error no parameter supplied!" })
	end
end

local function clamp(min,max,i)
	return math.min(max,math.max(min,i))
end


local function createAndSwapGhostPort(event,ent,level)
	if not floofLogistics then return end
	level = level or 1
	local newEnt = {}
	local ghostPortName = "floof:ghostRoboPort-5m-L"
	level = clamp(1,4,level)
	if level == 1 then
		ghostPortName = "floof:ghostRoboPort-5m-L"
	elseif level == 2 then
		ghostPortName = "floof:ghostRoboPort-10m-L"
	elseif level == 3 then
		ghostPortName = "floof:ghostRoboPort-15m-L"
	elseif level == 4 then
		ghostPortName = "floof:ghostRoboPort-20m-L"
	end
	
	newEnt = game.players[event.player_index].surface.create_entity { name = ghostPortName, position = { ent.position.x, ent.position.y }, force = ent.force }
	newEnt.destructible = false
	newEnt.minable = false
	local newGhostPort = {
		level = level,
		parent = ent, parentUnit = ent.unit_number,
		ent = newEnt, entUnit = newEnt.unit_number,
		robot = newEnt.get_inventory(defines.inventory.roboport_robot),
		material = newEnt.get_inventory(defines.inventory.roboport_material),
		equipment = event.equipment
	}
	if not floofLogistics.ghostPorts then floofLogistics.ghostPorts = {} end


	if floofLogistics.ghostPorts[ent.unit_number] then
		local oldGhostPort = floofLogistics.ghostPorts[ent.unit_number]
		move_inventory(oldGhostPort.robot,newGhostPort.robot)
		move_inventory(oldGhostPort.material,newGhostPort.material)
		newGhostPort.ent.energy = oldGhostPort.ent.energy

		removeGhostPort(ent.unit_number)
		floofLogistics.gui[event.player_index].lastOpened[ ent.unit_number ] = nil
	end

	floofLogistics.gui[event.player_index].lastOpened[ newEnt.unit_number ] = ent
	
	floofLogistics.ghostPorts[ent.unit_number] = newGhostPort
	event.player.gui.relative["floof:ghostPortButton"].visible = true
end

local function getCurrentLevel(unit_number)
	local gP = floofLogistics.ghostPorts
	local level = 0
	debug((gP and gP[unit_number] and gP[unit_number].level) or 0)
	if gP and gP[unit_number] and gP[unit_number].level then
		level = gP[unit_number].level
	end
	return level
end

local function getClampedCount(ent)
	local count = ent.grid.get_contents()["floof:logisticPort"]
	if count then
		count = clamp(minLevel,maxLevel,count)
	end
	return count
end

local function switchGhostPorts(event,ent)
	local gP = floofLogistics.ghostPorts[ent.unit_number]
	local level = getCurrentLevel(ent.unit_number)
	local count = getClampedCount(ent)
	if count then
		if count ~= level then 
			createAndSwapGhostPort(event,ent,count)
		end
	else
		removeGhostPort(ent.unit_number,true)
		event.player.gui.relative["floof:ghostPortButton"].visible = false
	end
end

local function on_player_placed_equipment(event)
	local player = game.players[event.player_index]
	event.player = player
	debug("aaaaaaaaa" .. event.player_index .. " bbbbbbb " .. player.name)
	if event.equipment.name == "floof:logisticPort" then
		local ent = player.opened

		if ent and ent.grid.get_contents()["floof:logisticPort"] and (player.opened_gui_type == defines.gui_type.entity or player.opened_gui_type == defines.gui_type.equipment) then
			debug("I found the grid! " .. ent.name)
			switchGhostPorts(event,ent)
		end

	end
end

local function on_player_removed_equipment(event)
	local player = game.players[event.player_index]
	event.player = player
	if not floofLogistics.ghostPorts or not floofLogistics.ghostPorts[player.opened.unit_number] then return end
	debug("aaaaaaaaa" .. event.player_index .. " bbbbbbb " .. player.name)
	if event.equipment == "floof:logisticPort" then
		local ent = player.opened

		if ent and (player.opened_gui_type == defines.gui_type.entity or player.opened_gui_type == defines.gui_type.equipment) then
			debug("I think found the grid? " .. ent.name)
			if ent.grid.get_contents()["floof:logisticPort"] then
				switchGhostPorts(event,ent)
				
			else
				removeGhostPort(ent.unit_number,true)
				player.gui.relative["floof:ghostPortButton"].visible = false
			end
		end

	end
end

local Energy_UpdateRate = 60
local Move_UpdateRate = 30


--[[
/c debug(game.player.gui.relative.children[1].visible)
/c debug(game.player.gui.center.children[1].add({type="label",caption="aaaaaaaaaaaaa",anchor = {gui=defines.relative_gui_type.equipment_grid_gui,position=defines.relative_gui_position.left}}))
/c debug(game.player.gui.center.children[1].children[1].anchor = {gui=defines.relative_gui_type.equipment_grid_gui,position=defines.relative_gui_position.left})
]]

local function moveEnergy(ghostPort)
	if not ghostPort.parent or not ghostPort.parent.valid or not ghostPort.parent.grid then return end

	local needed = ghostPort.ent.electric_buffer_size - ghostPort.ent.energy

	for _,equipment in pairs(ghostPort.parent.grid.equipment) do
		if equipment.name == "floof:logisticPort" then
			if needed > 0 then
				if needed > equipment.energy then
					ghostPort.ent.energy = ghostPort.ent.energy + equipment.energy
					equipment.energy = 0
				else
					local leftover = equipment.energy - needed
					equipment.energy = leftover
					ghostPort.ent.energy = ghostPort.ent.energy + needed
				end
			end
		end
	end
	--[[
	if not ghostPort.equipment or not ghostPort.equipment.valid then return end
	if needed > ghostPort.equipment.energy then
		ghostPort.ent.energy = ghostPort.ent.energy + ghostPort.equipment.energy
		ghostPort.equipment.energy = 0
	else
		local leftover = ghostPort.equipment.energy - needed
		ghostPort.equipment.energy = leftover
		ghostPort.ent.energy = ghostPort.ent.energy + needed

	end
	]]
end

local function on_tick(event)
	if not floofLogistics.ghostPorts then return end
	local tick = event.tick
	for unit_number, ghostPort in pairs(floofLogistics.ghostPorts) do
		if ghostPort.ent.valid and ghostPort.parent.valid then
			if unit_number % Move_UpdateRate == tick % Move_UpdateRate then
				if (ghostPort.parent.speed ~= 0 and not ghostPort.parent.enable_logistics_while_moving) then
					ghostPort.ent.active = false
				else
					ghostPort.ent.active = true
				end
				local parentPos = ghostPort.parent.position
				if (ghostPort.parent.speed ~= 0 or (parentPos.x ~= ghostPort.ent.position.x and parentPos.y ~= ghostPort.ent.position.y)) then
					ghostPort.ent.teleport(parentPos)
				end
			end
			if unit_number % Energy_UpdateRate == tick % Energy_UpdateRate then
				moveEnergy(ghostPort)
			end
		elseif not ghostPort.ent.valid or not ghostPort.parent.valid then
			debug("ERROR, ghostPort.ent or ghostPort.parent is not valid")
			removeGhostPort(ghostPort.parentUnit,true)
		end
	end
end

local function findMatchingEnt(event,train)
	local lastOpeneds = floofLogistics.ghostPorts[floofLogistics.gui[event.player_index]["lastOpened"]]
	for k,v in pairs(lastOpeneds) do
		if v.parentUnit == train.unit_number then
			return v
		end
	end
end

local function on_gui_click(event)
	if event.element.name == "floof:ghostPortButton" then
		local currOpened = game.players[event.player_index].opened
		if floofLogistics.ghostPorts[currOpened.unit_number] then
			game.players[event.player_index].opened = floofLogistics.ghostPorts[currOpened.unit_number].ent
		end
	end
end

local function newGUI(player_index, gui)
	if gui["floof:ghostPortButton"] then gui["floof:ghostPortButton"].destroy() end
	local new_gui = gui.add(ghostPortButton)
	if not floofLogistics.gui[player_index] then
		floofLogistics.gui[player_index] = {lastOpened={},ghostPortButton=new_gui}
	end
end

local function on_gui_opened(event)
	local player = game.players[event.player_index]
	local gui = player.gui.relative
	
	newGUI(event.player_index,gui)
	if event.entity and event.entity.name == "cargo-wagon" then
		local ent = event.entity
		if ent.grid.get_contents()["floof:logisticPort"] then
			gui["floof:ghostPortButton"].visible = true
			
		else
			gui["floof:ghostPortButton"].visible = false
		end
	end
end

local function on_gui_closed(event)
	local player = game.players[event.player_index]
	local gui = player.gui.relative
	if event.entity then
		local ent = event.entity
		if ent.name == "cargo-wagon" then
			gui["floof:ghostPortButton"].visible = false
		end
		if ent.name:find("floof:ghostRoboPort-",1,true) == 1 then
			player.opened = floofLogistics.gui[event.player_index].lastOpened[ent.unit_number]
		end
	end
end

local function on_init()
	global.floofLogistics = floofLogistics
end

local function on_load()
	floofLogistics = global.floofLogistics



	script.on_event(defines.events.on_tick, on_tick)

	script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
	script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)

	script.on_event(defines.events.on_gui_click, on_gui_click)
	script.on_event(defines.events.on_gui_opened, on_gui_opened)
	script.on_event(defines.events.on_gui_closed, on_gui_closed)

end

local function on_configuration_changed(ConfigurationChangedData)
	if not global.floofLogistics.ghostPorts then

		global.floofLogistics = { ghostPorts = global.floofLogistics, gui = {} }
	else
		global.floofLogistics = floofLogistics or { ghostPorts = {}, gui = {} }
	end
end

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_load(on_load)

commands.add_command("floofSpawn", nil, floofSpawn)
