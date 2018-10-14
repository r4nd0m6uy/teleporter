----
-- Teleporter 0.0
-- Copyright (C) 2015 R4nd0m6uy
--
-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
----

teleporter = {}
teleporter.version = 0.0
teleporter.db = nil
teleporter.db_filename = minetest.get_worldpath().."/teleporter_db"

-- Read configuration
dofile(minetest.get_modpath("teleporter").."/config.lua")


-- MCL2 compatibility
local moditems = {}

if core.get_modpath("mcl_core") and mcl_core then -- means MineClone 2 is loaded, this is its core mod
	moditems.GLAS_ITEM = "group:glass"  -- MCL glass
	moditems.MESE_ITEM = "mcl_core:goldblock" -- using goldblock as approximate equivalent
	moditems.BOXART = "bgcolor[#d0d0d0;false]listcolors[#9d9d9d;#9d9d9d;#5c5c5c;#000000;#ffffff]"
else         -- fallback, assume default (MineTest Game) is loaded, otherwise it will error anyway here.
	moditems.GLAS_ITEM = "default:glass" -- MTG glass
	moditems.MESE_ITEM = "default:mese"
	moditems.BOXART = ""
end

------------------------------------------------------------------------
-- Teleporters database
------------------------------------------------------------------------
-- fix database break on reload
local function build_hash(pos)
	if pos == nil then
		return
	end

  return ""..pos.x.."/"..pos.y.."/"..pos.z
end

local function get_teleporters_db()
  if teleporter.db == nil
  then
    local file = io.open(teleporter.db_filename, "r")
    teleporter.db = {}
    if file ~= nil then
      local file_content = file:read("*all")
      io.close(file)

      if file_content and file_content ~= "" then
        minetest.log("Teleporters database initialised from file")
        teleporter.db = minetest.deserialize(file_content)
      end
    end
  end

  return teleporter.db
end

local function save_teleporters_db()
  local file = io.open(teleporter.db_filename, "w")

  if file then
    file:write(minetest.serialize(get_teleporters_db()))
    io.close(file)
    minetest.log("Teleporters database saved in file")
  else
    error(file)
  end
end

local function get_teleporter_at(pos)
  local db = get_teleporters_db()

	if pos == nil then
		return
	end

	local hash = build_hash(pos)

  if db[hash] == nil then
     db[hash] = {}
	end

	return db[hash]
end

local function get_teleporter_hash_from_name(name)
  local db = get_teleporters_db()

  for hash, tp in pairs(db) do
    if db[hash].name == name then
      return hash
    end
  end
end

local function teleporter_name_exists(name)
  local db = get_teleporters_db()

  for hash, tp in pairs(db) do
    if db[hash].name == name then
      return true
    end
  end

  return false
end

------------------------------------------------------------------------
-- Update world
------------------------------------------------------------------------
local function build_destination_drop_list(source_hash)
  local destination_list = ""
  local destination_sel_idx = 1
  local crt_sel_idx = 2
  local db = get_teleporters_db()

  for dest_hash, dest_tp in pairs(db) do
    -- TODO Check if allowed to teleport to this destination
    if dest_hash ~= source_hash then
      if destination_list == "" then
        destination_list = ","..dest_tp.name
      else
        destination_list = destination_list..","..dest_tp.name
      end
      -- Preselected destination
      if db[source_hash].destination_hash == dest_hash then
        destination_sel_idx = crt_sel_idx
      end
      crt_sel_idx = crt_sel_idx  + 1
    end
  end

  return "dropdown[1,2;4,1;dest;"..destination_list..";"..destination_sel_idx.."]"
end

local function update_teleporters_meta()
  local meta
  local db = get_teleporters_db()

  for hash, tp in pairs(db) do
    meta = minetest.env:get_meta(tp.location)

    -- Check if got unlinked
    if tp.destination_hash ~= nil and db[tp.destination_hash] == nil then
      tp.destination_hash = nil
    end

    -- Info text
    if core.get_modpath("mcl_core") == nil or mcl_core == nil then 
      if  tp.destination_hash == nil then
        meta:set_string("infotext", tp.name..": unlinked")
      else
        meta:set_string("infotext", tp.name..": linked to "..db[tp.destination_hash].name)
      end
		end

    -- Build right click menu
    meta:set_string(
      "formspec",
      "size[5,4]"..
        "label[2,0;Configure teleporter]"..
        "field[1,1;4,1;ID;Teleporter name;"..
        tp.name.."]"..
        "label[0,2;Destination]"..
        build_destination_drop_list(hash)..
        "button_exit[2,3;2,1;save;Save]"..
				moditems.BOXART)
  end

  -- Make changes permanent
  save_teleporters_db()
end

------------------------------------------------------------------------
-- Configure teleporters
------------------------------------------------------------------------
local function teleporter_configured(pos, formname, fields, sender)
	if pos == nil then
		return
	end

  local teleporter = get_teleporter_at(pos)
  local db = get_teleporters_db()
  local newName = fields["ID"]
  local newDest = fields["dest"]
  local player_name = sender:get_player_name()

  -- TODO Check if allowed to configured this teleporter
  -- Name was changed
  if newName ~= nil and newName ~= "" and newName ~= teleporter.name then
    if teleporter_name_exists(newName) then
      minetest.chat_send_player(player_name, "A teleporter named '"..newName.."' already exists")
    else
      teleporter.name = newName
    end
  end

  -- destination was changed
  if newDest ~= nil and newDest ~= teleporter.destination_name then
    if newDest == "" then
      minetest.log("Teleporter deactivated by user")
      teleporter.destination_hash = nil
      -- TODO Lighting effect off
    else
      minetest.log("New "..teleporter.name.." teleports to "..newDest)
      teleporter.destination_hash = get_teleporter_hash_from_name(newDest)
      -- TODO Lighting effect on
    end
  end

  update_teleporters_meta()
end

------------------------------------------------------------------------
-- on delete
------------------------------------------------------------------------
local function teleporter_destructed(pos)

	if pos == nil then
		return
	end

  get_teleporters_db()[build_hash(pos)] = nil
  update_teleporters_meta()
end

------------------------------------------------------------------------
-- on_construct
------------------------------------------------------------------------
local function teleporter_pad_constructed(pos)
	if pos == nil then
		return
	end

	local db = get_teleporters_db()
  local hash = build_hash(pos)
  local teleporter = {
    name = hash,
    location = pos,
    public = isPublic,
    destination_hash = nil,
    owner = nil,
    last_spawned_player_time = minetest.get_gametime()
  }

  db[hash] = teleporter
  update_teleporters_meta()
end

------------------------------------------------------------------------
-- teleport abm callback
------------------------------------------------------------------------
local function teleport_event(pos, node, active_object_count, active_object_count_wider)
	if pos == nil then
		return
	end

	local objs = minetest.env:get_objects_inside_radius(pos, 1)
  local tp = get_teleporter_at(pos)
  local db = get_teleporters_db()
        
  -- Stop if unlinked
  if tp.destination_hash == nil then
    return
  end

  -- Stops if cooling down
  if minetest.get_gametime() - tp.last_spawned_player_time <= teleporter.cooldown_time then
    return
  end

  -- Teleport near player(s)
  for k, player in pairs(objs) do
    if player:get_player_name() ~= nil then
      player:moveto(db[tp.destination_hash].location, false)
			minetest.sound_play("teleporter_teleport", {pos = db[tp.destination_hash].location, gain = 1.0, max_hear_distance = 10,})
      db[tp.destination_hash].last_spawned_player_time = minetest.get_gametime()
    end
  end
end

------------------------------------------------------------------------
-- minetest.register_node
------------------------------------------------------------------------
minetest.register_node(
  "teleporter:teleporter_pad", {
    tiles = {"teleporter_teleporter_pad.png"},
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {
        ---{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        {-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
      },
    },
    paramtype = "light",
    paramtype2 = "wallmounted",
    walkable = false,
    description="Teleporter Pad",
--    inventory_image = "teleporter_teleporter_pad_16.png",
    metadata_name = "sign",
    groups = {
      cracky = 2,
      dig_immediate = 2
    },
    selection_box = {
      type = "wallmounted",
    },
    on_construct = teleporter_pad_constructed,
    on_receive_fields = teleporter_configured,
    on_destruct = teleporter_destructed
  }
)

------------------------------------------------------------------------
-- teleport effect
------------------------------------------------------------------------
minetest.register_abm(
  {
    nodenames = {"teleporter:teleporter_pad"},
    interval = 1.0,
    chance = 1,
    action = teleport_event
  }
)

------------------------------------------------------------------------
-- minetest.register_craft
------------------------------------------------------------------------
minetest.register_craft(
  {
    output = 'teleporter:teleporter_pad', -- since teleporters are paired anyway, produce a pair.
    recipe = {
      { moditems.GLAS_ITEM, moditems.GLAS_ITEM, moditems.GLAS_ITEM },
      {'', '', ''},
      { '', moditems.MESE_ITEM, '' }, -- balancing mese against rail costs.
    }
  }
)
