---@diagnostic disable: undefined-global, lowercase-global

function GetBuildNumber()
  local pBuildNum = memory.scan_pattern("8B C3 33 D2 C6 44 24 20"):add(0x24):rip()
  return pBuildNum:get_string()
end

function formatMoney(value)
  return "$" .. tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function coloredText(text, wrap_size, color)
  ImGui.PushStyleColor(ImGuiCol.Text, color[1] / 255, color[2] / 255, color[3] / 255, color[4])
  ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
  ImGui.TextWrapped(text)
  ImGui.PopTextWrapPos()
  ImGui.PopStyleColor(1)
end

---@param keepVehicle boolean
---@param setHeading boolean
---@param coords vec3
---@param heading? integer
function selfTP(keepVehicle, setHeading, coords, heading)
  script.run_in_fiber(function(selftp)
    STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)
    selftp:sleep(300)
    if setHeading then
      if heading == nil then
        heading = 0
      end
      ENTITY.SET_ENTITY_HEADING(self.get_ped(), heading)
    end
    if keepVehicle then
      PED.SET_PED_COORDS_KEEP_VEHICLE(self.get_ped(), coords.x, coords.y, coords.z)
    else
      TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
      ENTITY.SET_ENTITY_COORDS(self.get_ped(), coords.x, coords.y, coords.z, false, false, false, true)
    end
  end)
end

--[[
      -- useless
  function totalCEOsupplies()
    local s_T = {}
    local n   = 0
    local t_s = 0
    while n < 5 do
      local value = stats.get_int("MP" .. stats.get_character_index() .. "_CONTOTALFORWHOUSE" .. tostring(n))
      n = n + 1
      table.insert(s_T, value)
    end
    for _, v in pairs(s_T) do
      t_s = t_s + v
    end
    return t_s
  end
  ]]

function getCEOvalue_G(crates)
  local G
  if crates ~= nil then
    if crates == 1 then
      G = 15732
    end
    if crates == 2 then
      G = 15733
    end
    if crates == 3 then
      G = 15734
    end
    if crates == 4 or crates == 5 then
      G = 15735
    end
    if crates == 6 or crates == 7 then
      G = 15736
    end
    if crates == 8 or crates == 9 then
      G = 15737
    end
    if crates >= 10 and crates <= 14 then
      G = 15738
    end
    if crates >= 15 and crates <= 19 then
      G = 15739
    end
    if crates >= 20 and crates <= 24 then
      G = 15740
    end
    if crates >= 25 and crates <= 29 then
      G = 15741
    end
    if crates >= 30 and crates <= 34 then
      G = 15742
    end
    if crates >= 35 and crates <= 39 then
      G = 15743
    end
    if crates >= 40 and crates <= 44 then
      G = 15744
    end
    if crates >= 45 and crates <= 49 then
      G = 15745
    end
    if crates >= 50 and crates <= 59 then
      G = 15746
    end
    if crates >= 60 and crates <= 69 then
      G = 15747
    end
    if crates >= 70 and crates <= 79 then
      G = 15748
    end
    if crates >= 80 and crates <= 89 then
      G = 15749
    end
    if crates >= 90 and crates <= 99 then
      G = 15750
    end
    if crates >= 100 and crates <= 110 then
      G = 15751
    end
    if crates == 111 then
      G = 15752
    end
  else
    G = 0
  end
  return G
end
