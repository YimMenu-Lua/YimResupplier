---@diagnostic disable: undefined-global, lowercase-global

--[[
  #### RXI JSON Library (Modified by [Harmless](https://github.com/harmless05)).

  <u>Credits:</u> [RXI's json.lua](https://github.com/rxi/json.lua) for the original library.

]]
local function json()
  local json = { _version = "0.1.2" }
  --encode
  local encode

  local escape_char_map = {
    [ "\\" ] = "\\",
    [ "\"" ] = "\"",
    [ "\b" ] = "b",
    [ "\f" ] = "f",
    [ "\n" ] = "n",
    [ "\r" ] = "r",
    [ "\t" ] = "t",
  }

  local escape_char_map_inv = { [ "/" ] = "/" }
  for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
  end

  local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
  end

  local function encode_nil(val)
    return "null"
  end

  local function encode_table(val, stack)
    local res = {}
    stack = stack or {}
    if stack[val] then error("circular reference") end

    stack[val] = true

    if rawget(val, 1) ~= nil or next(val) == nil then
      local n = 0
      for k in pairs(val) do
        if type(k) ~= "number" then
          error("invalid table: mixed or invalid key types")
        end
        n = n + 1
      end
      if n ~= #val then
        error("invalid table: sparse array")
      end
      for i, v in ipairs(val) do
        table.insert(res, encode(v, stack))
      end
      stack[val] = nil
      return "[" .. table.concat(res, ",") .. "]"
    else
      for k, v in pairs(val) do
        if type(k) ~= "string" then
          error("invalid table: mixed or invalid key types")
        end
        table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
      end
      stack[val] = nil
      return "{" .. table.concat(res, ",") .. "}"
    end
  end

  local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
  end

  local function encode_number(val)
    if val ~= val or val <= -math.huge or val >= math.huge then
      error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
  end

  local type_func_map = {
    [ "nil"     ] = encode_nil,
    [ "table"   ] = encode_table,
    [ "string"  ] = encode_string,
    [ "number"  ] = encode_number,
    [ "boolean" ] = tostring,
  }

  encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
      return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
  end

  function json.encode(val)
    return ( encode(val) )
  end


  --decode
  local parse

  local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
      res[ select(i, ...) ] = true
    end
    return res
  end

  local space_chars   = create_set(" ", "\t", "\r", "\n")
  local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
  local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
  local literals      = create_set("true", "false", "null")

  local literal_map = {
    [ "true"  ] = true,
    [ "false" ] = false,
    [ "null"  ] = nil,
  }

  local function next_char(str, idx, set, negate)
    for i = idx, #str do
      if set[str:sub(i, i)] ~= negate then
        return i
      end
    end
    return #str + 1
  end

  local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
      col_count = col_count + 1
      if str:sub(i, i) == "\n" then
        line_count = line_count + 1
        col_count = 1
      end
    end
    error( string.format("%s at line %d col %d", msg, line_count, col_count) )
  end

  local function codepoint_to_utf8(n)
    local f = math.floor
    if n <= 0x7f then
      return string.char(n)
    elseif n <= 0x7ff then
      return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
      return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
      return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                        f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error( string.format("invalid unicode codepoint '%x'", n) )
  end

  local function parse_unicode_escape(s)
    local n1 = tonumber( s:sub(1, 4),  16 )
    local n2 = tonumber( s:sub(7, 10), 16 )
    if n2 then
      return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
      return codepoint_to_utf8(n1)
    end
  end

  local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
      local x = str:byte(j)
      if x < 32 then
        decode_error(str, j, "control character in string")
      elseif x == 92 then -- `\`: Escape
        res = res .. str:sub(k, j - 1)
        j = j + 1
        local c = str:sub(j, j)
        if c == "u" then
          local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                  or str:match("^%x%x%x%x", j + 1)
                  or decode_error(str, j - 1, "invalid unicode escape in string")
          res = res .. parse_unicode_escape(hex)
          j = j + #hex
        else
          if not escape_chars[c] then
            decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
          end
          res = res .. escape_char_map_inv[c]
        end
        k = j + 1
      elseif x == 34 then -- `"`: End of string
        res = res .. str:sub(k, j - 1)
        return res, j + 1
      end
      j = j + 1
    end
    decode_error(str, i, "expected closing quote for string")
  end

  local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
      decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
  end

  local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
      decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
  end

  local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
      local x
      i = next_char(str, i, space_chars, true)
      -- Empty / end of array?
      if str:sub(i, i) == "]" then
        i = i + 1
        break
      end
      -- Read token
      x, i = parse(str, i)
      res[n] = x
      n = n + 1
      -- Next token
      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "]" then break end
      if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
    end
    return res, i
  end

  local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
      local key, val
      i = next_char(str, i, space_chars, true)
      -- Empty / end of object?
      if str:sub(i, i) == "}" then
        i = i + 1
        break
      end
      -- Read key
      if str:sub(i, i) ~= '"' then
        decode_error(str, i, "expected string for key")
      end
      key, i = parse(str, i)
      -- Read ':' delimiter
      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) ~= ":" then
        decode_error(str, i, "expected ':' after key")
      end
      i = next_char(str, i + 1, space_chars, true)
      -- Read value
      val, i = parse(str, i)
      -- Set
      res[key] = val
      -- Next token
      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "}" then break end
      if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
    end
    return res, i
  end

  local char_func_map = {
    [ '"' ] = parse_string,
    [ "0" ] = parse_number,
    [ "1" ] = parse_number,
    [ "2" ] = parse_number,
    [ "3" ] = parse_number,
    [ "4" ] = parse_number,
    [ "5" ] = parse_number,
    [ "6" ] = parse_number,
    [ "7" ] = parse_number,
    [ "8" ] = parse_number,
    [ "9" ] = parse_number,
    [ "-" ] = parse_number,
    [ "t" ] = parse_literal,
    [ "f" ] = parse_literal,
    [ "n" ] = parse_literal,
    [ "[" ] = parse_array,
    [ "{" ] = parse_object,
  }

  parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
      return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
  end

  function json.decode(str)
    if type(str) ~= "string" then
      error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
      decode_error(str, idx, "trailing garbage")
    end
    return res
  end
  return json
end

--[[ **Config System For Lua**

  - Written by [Harmless](https://github.com/harmless05).

  - Uses [RXI JSON Library](https://github.com/rxi/json.lua).
]]
local jsonConf = json()
local function writeToFile(filename, data)
  local file, _ = io.open(filename, "w")
  if file == nil then
    log.warning("Failed to write to " .. filename)
    gui.show_error("YimActions", "Failed to write to " .. filename)
    return false
  end
  file:write(jsonConf.encode(data))
  file:close()
  return true
end

local function readFromFile(filename)
  local file, _ = io.open(filename, "r")
  if file == nil then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return jsonConf.decode(content)
end

local function checkAndCreateConfig(default_config)
  local config = readFromFile("YimResupplier.json")
  if config == nil then
    log.warning("Config file not found, creating a default config")
    gui.show_warning("YimActions", "Config file not found, creating a default config")
    if not writeToFile("YimResupplier.json", default_config) then
      return false
    end
    config = default_config
  end

  for key, defaultValue in pairs(default_config) do
    if config[key] == nil then
      config[key] = defaultValue
    end
  end

  if not writeToFile("YimResupplier.json", config) then
    return false
  end
  return true
end

local function readAndDecodeConfig()
  while not checkAndCreateConfig(default_config) do
    -- Wait for the file to be created
    os.execute("sleep " .. tonumber(1))
    log.debug("Waiting for YimResupplier.json to be created")
  end
  return readFromFile("YimResupplier.json")
end

local function saveToConfig(item_tag, value)
  local t = readAndDecodeConfig()
  if t then
    t[item_tag] = value
    if not writeToFile("YimResupplier.json", t) then
      log.debug("Failed to encode JSON to YimResupplier.json")
    end
  end
end

local function readFromConfig(item_tag)
  local t = readAndDecodeConfig()
  if t then
    return t[item_tag]
  else
    log.debug("Failed to decode JSON from YimResupplier.json")
  end
end
-------------------------------------------------------------------------------

online_version = memory.scan_pattern("8B C3 33 D2 C6 44 24 20"):add(0x24):rip()
if tonumber(online_version:get_string()) == 3274 then
  yim_resupplier = gui.get_tab("YimResupplier")
  default_config = {
        cashUpdgrade1   = false,
        cashUpdgrade2   = false,
        cokeUpdgrade1   = false,
        cokeUpdgrade2   = false,
        methUpdgrade1   = false,
        methUpdgrade2   = false,
        weedUpdgrade1   = false,
        weedUpdgrade2   = false,
        fdUpdgrade1     = false,
        fdUpdgrade2     = false,
        bunkerUpdgrade1 = false,
        bunkerUpdgrade2 = false,
        acidUpdgrade    = false,
      }
  local hangarOwned     = false
  local fCashOwned      = false
  local cokeOwned       = false
  local methOwned       = false
  local weedOwned       = false
  local fdOwned         = false
  local bunkerOwned     = false
  local acidOwned       = false
  local hangarTotal     = 0
  local cashTotal       = 0
  local cokeTotal       = 0
  local methTotal       = 0
  local weedTotal       = 0
  local fdTotal         = 0
  local bunkerTotal     = 0
  local acidTotal       = 0
  local cashUpdgrade1   = readFromConfig("cashUpdgrade1")
  local cashUpdgrade2   = readFromConfig("cashUpdgrade2")
  local cokeUpdgrade1   = readFromConfig("cokeUpdgrade1")
  local cokeUpdgrade2   = readFromConfig("cokeUpdgrade2")
  local methUpdgrade1   = readFromConfig("methUpdgrade1")
  local methUpdgrade2   = readFromConfig("methUpdgrade2")
  local weedUpdgrade1   = readFromConfig("weedUpdgrade1")
  local weedUpdgrade2   = readFromConfig("weedUpdgrade2")
  local fdUpdgrade1     = readFromConfig("fdUpdgrade1")
  local fdUpdgrade2     = readFromConfig("fdUpdgrade2")
  local bunkerUpdgrade1 = readFromConfig("bunkerUpdgrade1")
  local bunkerUpdgrade2 = readFromConfig("bunkerUpdgrade2")
  local acidUpdgrade    = readFromConfig("acidUpdgrade")
  local function formatMoney(value)
    return "$"..tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
  end
  local function coloredText(text, wrap_size, color)
    ImGui.PushStyleColor(ImGuiCol.Text, color[1]/255, color[2]/255, color[3]/255, color[4])
    ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
    ImGui.TextWrapped(text)
    ImGui.PopTextWrapPos()
    ImGui.PopStyleColor(1)
  end
  ---@param keepVehicle boolean
  ---@param setHeading boolean
  ---@param coords any
  ---@param heading? integer
  local function selfTP(keepVehicle, setHeading, coords, heading)
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
        ENTITY.SET_ENTITY_COORDS(self.get_ped(), coords.x, coords.y, coords.z, false, false, true)
      end
    end)
  end

  --[[ 
      -- useless
  local function totalCEOsupplies()
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

  local function getCEOvalue_G(crates)
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

  yim_resupplier:add_imgui(function()
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
      local MPx = "MP"..stats.get_character_index()
      if stats.get_int(MPx.."_PROP_HANGAR") ~= 0 then
        hangarOwned = true
      else
        hangarOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT0") ~= 0 then
        fCashOwned = true
      else
        fCashOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT1") ~= 0 then
        cokeOwned = true
      else
        cokeOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT2") ~= 0 then
        methOwned = true
      else
        methOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT3") ~= 0 then
        weedOwned = true
      else
        weedOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT4") ~= 0 then
        fdOwned = true
      else
        fdOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT5") ~= 0 then
        bunkerOwned = true
      else
        bunkerOwned = false
      end
      if stats.get_int(MPx.."_PROP_FAC_SLOT6") ~= 0 then
        acidOwned = true
      else
        acidOwned = false
      end
      ImGui.BeginTabBar("YimResupplier", ImGuiTabBarFlags.None)
      if ImGui.BeginTabItem("Manage Supplies") then
        local wh1Supplies  = stats.get_int(MPx .. "_CONTOTALFORWHOUSE0")
        local wh2Supplies  = stats.get_int(MPx .. "_CONTOTALFORWHOUSE1")
        local wh3Supplies  = stats.get_int(MPx .. "_CONTOTALFORWHOUSE2")
        local wh4Supplies  = stats.get_int(MPx .. "_CONTOTALFORWHOUSE3")
        local wh5Supplies  = stats.get_int(MPx .. "_CONTOTALFORWHOUSE4")
        local hangarSupply = stats.get_int(MPx .. "_HANGAR_CONTRABAND_TOTAL")
        local cashSupply   = stats.get_int(MPx .. "_MATTOTALFORFACTORY0")
        local cokeSupply   = stats.get_int(MPx .. "_MATTOTALFORFACTORY1")
        local methSupply   = stats.get_int(MPx .. "_MATTOTALFORFACTORY2")
        local weedSupply   = stats.get_int(MPx .. "_MATTOTALFORFACTORY3")
        local dfSupply     = stats.get_int(MPx .. "_MATTOTALFORFACTORY4")
        local bunkerSupply = stats.get_int(MPx .. "_MATTOTALFORFACTORY5")
        local acidSupply   = stats.get_int(MPx .. "_MATTOTALFORFACTORY6")
        local ceoSupply    = (wh1Supplies + wh2Supplies + wh3Supplies + wh4Supplies + wh5Supplies)
        ImGui.Spacing();ImGui.Text("Hangar Cargo");ImGui.Separator()
        if hangarOwned then
          ImGui.Text("Current Supplies:");ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.ProgressBar((hangarSupply/50), 140, 30)
          if hangarSupply < 50 then
            if ImGui.Button("Source Random Crate(s)") then
              script.run_in_fiber(function()
                stats.set_bool_masked(MPx.."_DLC22022PSTAT_BOOL3", true, 9)
              end)
            end
            ImGui.SameLine();hangarLoop, used = ImGui.Checkbox("Auto-Fill", hangarLoop, true)
            if hangarLoop then
              script.run_in_fiber(function(hangarSupp)
                repeat
                  stats.set_bool_masked(MPx.."_DLC22022PSTAT_BOOL3", true, 9)
                  hangarSupp:sleep(969) -- add a delay to prevent transaction error or infinite 'transaction pending'
                until
                  hangarSupply == 50 or hangarLoop == false
              end)
            end
          else
            if hangarLoop then
              hangarLoop = false
            end
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            if ImGui.Button("Teleport##hangar") then
              script.run_in_fiber(function()
                local hangarBlip = HUD.GET_FIRST_BLIP_INFO_ID(569)
                local hangarLoc
                if HUD.DOES_BLIP_EXIST(hangarBlip) then
                  hangarLoc = HUD.GET_BLIP_COORDS(hangarBlip)
                  selfTP(true, false, hangarLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Hangar.")
        end
        ImGui.Spacing();ImGui.Text("CEO Warehouses");ImGui.Separator()
        ImGui.Text("Current Supplies:");ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.ProgressBar((ceoSupply/555), 140, 30)
        if ceoSupply < 555 then
          if ImGui.Button("Source Random Crate(s)##ceo") then
            script.run_in_fiber(function(fillceo)
              for i = 12, 16 do
                stats.set_bool_masked(MPx.."_FIXERPSTAT_BOOL1", true, i)
                fillceo:sleep(500) -- half second delay between each warehouse
              end
            end)
          end
          ImGui.SameLine();ceoLoop, used = ImGui.Checkbox("Auto-Fill##ceo", ceoLoop, true)
          if ceoLoop then
            script.run_in_fiber(function(ceoloop)
              repeat
                for i = 12, 16 do
                  stats.set_bool_masked(MPx.."_FIXERPSTAT_BOOL1", true, i)
                  ceoloop:sleep(500) -- half second delay between each warehouse
                end
                ceoloop:sleep(969) -- add a delay to prevent transaction error or infinite 'transaction pending'
              until
                ceoSupply == 555 or ceoLoop == false
            end)
          end
        else
          if ceoLoop then
            ceoLoop = false
          end
        end
        if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
          if ImGui.Button("Teleport To Office") then
            script.run_in_fiber(function()
              local ceoBlip = HUD.GET_FIRST_BLIP_INFO_ID(475)
              local ceoLoc
              if HUD.DOES_BLIP_EXIST(ceoBlip) then
                ceoLoc = HUD.GET_BLIP_COORDS(ceoBlip)
                selfTP(true, false, ceoLoc)
              end
            end)
          end
        end
        ImGui.Spacing();ImGui.Text("MC Supplies");ImGui.Separator()
        if fCashOwned then
          ImGui.Text("Fake Cash:");ImGui.SameLine();ImGui.Dummy(55, 1);ImGui.SameLine();ImGui.ProgressBar((cashSupply/100), 140, 30)
          if math.ceil(cashSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##FakeCash") then
              globals.set_int(1663174 + 0 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##fc") then
              script.run_in_fiber(function()
                local fcBlip = HUD.GET_FIRST_BLIP_INFO_ID(500)
                local fcLoc
                if HUD.DOES_BLIP_EXIST(fcBlip) then
                  fcLoc = HUD.GET_BLIP_COORDS(fcBlip)
                  selfTP(false, false, fcLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Fake Cash business.")
        end
        if cokeOwned then
          ImGui.Text("Cocaine:");ImGui.SameLine();ImGui.Dummy(73, 1);ImGui.SameLine();ImGui.ProgressBar((cokeSupply/100), 140, 30)
          if math.ceil(cokeSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Cocaine") then
              globals.set_int(1663174 + 1 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##coke") then
              script.run_in_fiber(function()
                local cokeBlip = HUD.GET_FIRST_BLIP_INFO_ID(497)
                local cokeLoc
                if HUD.DOES_BLIP_EXIST(cokeBlip) then
                  cokeLoc = HUD.GET_BLIP_COORDS(cokeBlip)
                  selfTP(false, false, cokeLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Cocaine business.")
        end
        if methOwned then
          ImGui.Text("Meth:");ImGui.SameLine();ImGui.Dummy(95, 1);ImGui.SameLine();ImGui.ProgressBar((methSupply/100), 140, 30)
          if math.ceil(methSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Meth") then
              globals.set_int(1663174 + 2 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##meth") then
              script.run_in_fiber(function()
                local methBlip = HUD.GET_FIRST_BLIP_INFO_ID(499)
                local methLoc
                if HUD.DOES_BLIP_EXIST(methBlip) then
                  methLoc = HUD.GET_BLIP_COORDS(methBlip)
                  selfTP(false, false, methLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Meth business.")
        end
        if weedOwned then
          ImGui.Text("Weed:");ImGui.SameLine();ImGui.Dummy(90, 1);ImGui.SameLine();ImGui.ProgressBar((weedSupply/100), 140, 30)
          if math.ceil(weedSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Weed") then
              globals.set_int(1663174 + 3 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##weed") then
              script.run_in_fiber(function()
                local weedBlip = HUD.GET_FIRST_BLIP_INFO_ID(496)
                local weedLoc
                if HUD.DOES_BLIP_EXIST(weedBlip) then
                  weedLoc = HUD.GET_BLIP_COORDS(weedBlip)
                  selfTP(false, false, weedLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Weed business.")
        end
        if fdOwned then
          ImGui.Text("Document Forgery: ");ImGui.SameLine();ImGui.ProgressBar((dfSupply/100), 140, 30)
          if math.ceil(dfSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##DocumentForgery") then
              globals.set_int(1663174 + 4 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##fd") then
              script.run_in_fiber(function()
                local fdBlip = HUD.GET_FIRST_BLIP_INFO_ID(498)
                local fdLoc
                if HUD.DOES_BLIP_EXIST(fdBlip) then
                  fdLoc = HUD.GET_BLIP_COORDS(fdBlip)
                  selfTP(false, false, fdLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Document Forgery office.")
        end
        if bunkerOwned then
          ImGui.Text("Bunker:");ImGui.SameLine();ImGui.Dummy(80, 1);ImGui.SameLine();ImGui.ProgressBar((bunkerSupply/100), 140, 30)
          if math.ceil(bunkerSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Bunker") then
              globals.set_int(1663174 + 5 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##bunker") then
              script.run_in_fiber(function()
                local bunkerBlip = HUD.GET_FIRST_BLIP_INFO_ID(557)
                local bunkerLoc
                if HUD.DOES_BLIP_EXIST(bunkerBlip) then
                  bunkerLoc = HUD.GET_BLIP_COORDS(bunkerBlip)
                  selfTP(true, false, bunkerLoc)
                end
              end)
            end
          end
        else
          ImGui.Text("You don't own a Bunker.")
        end
        if acidOwned then
          ImGui.Text("Acid Lab:");ImGui.SameLine();ImGui.Dummy(70, 1);ImGui.SameLine();ImGui.ProgressBar((acidSupply/100), 140, 30)
          if math.ceil(acidSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##AcidLab") then
              globals.set_int(1663174 + 6 + 1, 1)
            end
            ImGui.SameLine();ImGui.Dummy(5, 1)
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine()
            if ImGui.Button("Teleport##acid") then
              script.run_in_fiber(function()
                local acidBlip = HUD.GET_FIRST_BLIP_INFO_ID(848)
                local acidLoc
                if HUD.DOES_BLIP_EXIST(acidBlip) then
                  acidLoc = HUD.GET_BLIP_COORDS(acidBlip)
                  selfTP(true, false, acidLoc)
                end
              end)
            end
          end
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.Dummy(1, 10);coloredText("WARNING!\10Teleport buttons might be broken in public sessions.", 40, {255, 204, 0, 0.8})
          end
        else
          ImGui.Text("You don't own an Acid Lab.")
        end
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Production Overview") then
        --------------------------------------- Hangar ----------------------------------------------------------------------
        if hangarOwned then
          ImGui.Text("Hangar:")
          local hangarCargo = stats.get_int(MPx.."_HANGAR_CONTRABAND_TOTAL")
          hangarTotal = hangarCargo * 30000
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((hangarCargo/50), 160, 25, tostring(hangarCargo).." Crates ("..tostring(math.floor(hangarCargo / 0.5)).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(hangarTotal))
        end
        --------------------------------------- CEO ----------------------------------------------------------------------
        ImGui.Separator();ImGui.Text("CEO:")
        local wh1Supplies = stats.get_int(MPx .. "_CONTOTALFORWHOUSE0")
        local wh2Supplies = stats.get_int(MPx .. "_CONTOTALFORWHOUSE1")
        local wh3Supplies = stats.get_int(MPx .. "_CONTOTALFORWHOUSE2")
        local wh4Supplies = stats.get_int(MPx .. "_CONTOTALFORWHOUSE3")
        local wh5Supplies = stats.get_int(MPx .. "_CONTOTALFORWHOUSE4")
        if wh1Supplies ~= nil and wh1Supplies > 0 then
          wh1Value = (globals.get_int(262145 + (getCEOvalue_G(wh1Supplies))))
        else
          wh1Value = 0
        end
        if wh2Supplies ~= nil and wh2Supplies > 0 then
          wh2Value = (globals.get_int(262145 + (getCEOvalue_G(wh2Supplies))))
        else
          wh2Value = 0
        end
        if wh3Supplies ~= nil and wh3Supplies > 0 then
          wh3Value = (globals.get_int(262145 + (getCEOvalue_G(wh3Supplies))))
        else
          wh3Value = 0
        end
        if wh4Supplies ~= nil and wh4Supplies > 0 then
          wh4Value = (globals.get_int(262145 + (getCEOvalue_G(wh4Supplies))))
        else
          wh4Value = 0
        end
        if wh5Supplies ~= nil and wh5Supplies > 0 then
          wh5Value = (globals.get_int(262145 + (getCEOvalue_G(wh5Supplies))))
        else
          wh5Value = 0
        end
        local ceoSupply   = (wh1Supplies + wh2Supplies + wh3Supplies + wh4Supplies + wh5Supplies)
        ceoTotal          = ((wh1Value * wh1Supplies) + (wh2Value * wh2Supplies) + (wh3Value * wh3Supplies) + (wh4Value * wh4Supplies) + (wh5Value * wh5Supplies))
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((ceoSupply/555), 160, 25, tostring(ceoSupply).." Crates ("..tostring(math.floor((ceoSupply / 555) * 100)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(ceoTotal))
        --------------------------------------- Fake Cash -------------------------------------------------------------------
        if fCashOwned then
          ImGui.Separator();ImGui.Text("Fake Cash:");ImGui.SameLine()
          cashUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##cash", cashUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("cashUpdgrade1", cashUpdgrade1)
          end
          cashUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##cash", cashUpdgrade2, true)
          if used then
            saveToConfig("cashUpdgrade2", cashUpdgrade2)
          end
          if cashUpdgrade1 then
            cashOffset1  = globals.get_int(262145 + 17326)
          else
            cashOffset1 = 0
          end
          if cashUpdgrade2 then
            cashOffset2  = globals.get_int(262145 + 17332)
          else
            cashOffset2 = 0
          end
          local cashProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY0")
          cashTotal = ((globals.get_int(262145 + 17320) + cashOffset1 + cashOffset2) * cashProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((cashProduct/40), 160, 25, tostring(cashProduct).." Boxes ("..tostring(math.floor(cashProduct * 2.5)).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(cashTotal))
        end
        ---------------------------------------Coke----------------------------------------------------------------------
        if cokeOwned then
          ImGui.Separator();ImGui.Text("Cocaine:    ");ImGui.SameLine()
          cokeUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##coke", cokeUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("cokeUpdgrade1", cokeUpdgrade1)
          end
          cokeUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##coke", cokeUpdgrade2, true)
          if used then
            saveToConfig("cokeUpdgrade2", cokeUpdgrade2)
          end
          if cokeUpdgrade1 then
            cokeOffset1  = globals.get_int(262145 + 17327)
          else
            cokeOffset1 = 0
          end
          if cokeUpdgrade2 then
            cokeOffset2  = globals.get_int(262145 + 17333)
          else
            cokeOffset2 = 0
          end
          local cokeProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY1")
          cokeTotal = ((globals.get_int(262145 + 17321) + cokeOffset1 + cokeOffset2) * cokeProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((cokeProduct/10), 160, 25, tostring(cokeProduct).." Kilos ("..tostring(cokeProduct * 10).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:")ImGui.SameLine();ImGui.Text(formatMoney(cokeTotal))
        end
        ---------------------------------------Meth-----------------------------------------------------------------------
        if methOwned then
          ImGui.Separator()ImGui.Text("Meth:        ");ImGui.SameLine()
          methUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##meth", methUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("methUpdgrade1", methUpdgrade1)
          end
          methUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##meth", methUpdgrade2, true)
          if used then
            saveToConfig("methUpdgrade2", methUpdgrade2)
          end
          if methUpdgrade1 then
            methOffset1  = globals.get_int(262145 + 17328)
          else
            methOffset1 = 0
          end
          if methUpdgrade2 then
            methOffset2  = globals.get_int(262145 + 17334)
          else
            methOffset2 = 0
          end
          local methProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY2")
          methTotal = ((globals.get_int(262145 + 17322)+ methOffset1 + methOffset2) * methProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((methProduct/20), 160, 25, tostring(methProduct).." Pounds ("..tostring(methProduct * 5).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(methTotal))
        end
        ---------------------------------------Weed------------------------------------------------------------------------
        if weedOwned then
          ImGui.Separator()ImGui.Text("Weed:       ");ImGui.SameLine()
          weedUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##weed", weedUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("weedUpdgrade1", weedUpdgrade1)
          end
          weedUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##weed", weedUpdgrade2, true)
          if used then
            saveToConfig("weedUpdgrade2", weedUpdgrade2)
          end
          if weedUpdgrade1 then
            weedOffset1  = globals.get_int(262145 + 17329)
          else
            weedOffset1 = 0
          end
          if weedUpdgrade2 then
            weedOffset2  = globals.get_int(262145 + 17335)
          else
            weedOffset2 = 0
          end
          local weedProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY3")
          weedTotal = ((globals.get_int(262145 + 17323) + weedOffset1 + weedOffset2) * weedProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((weedProduct/80), 160, 25, tostring(weedProduct).." Pounds ("..tostring(math.floor(weedProduct / 8 * 10)).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(weedTotal))
        end
        ---------------------------------------Document Forgery------------------------------------------------------------
        if fdOwned then
          ImGui.Separator()ImGui.Text("Fake ID:    ");ImGui.SameLine()
          fdUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##fd", fdUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("fdUpdgrade1", fdUpdgrade1)
          end
          fdUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##fd", fdUpdgrade2, true)
          if used then
            saveToConfig("fdUpdgrade2", fdUpdgrade2)
          end
          if fdUpdgrade1 then
            fdOffset1  = globals.get_int(262145 + 17325)
          else
            fdOffset1 = 0
          end
          if fdUpdgrade2 then
            fdOffset2  = globals.get_int(262145 + 17331)
          else
            fdOffset2 = 0
          end
          local fdProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY4")
          fdTotal = ((globals.get_int(262145 + 17319) + fdOffset1 + fdOffset2) * fdProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((fdProduct/60), 160, 25, tostring(fdProduct).." Boxes ("..tostring(math.floor(fdProduct / 6 * 10)).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(fdTotal))
        end
        ---------------------------------------Bunker-----------------------------------------------------------------------
        if bunkerOwned then
          ImGui.Separator();ImGui.Text("Bunker:     ");ImGui.SameLine()
          bunkerUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##bunker", bunkerUpdgrade1, true);ImGui.SameLine()
          if used then
            saveToConfig("bunkerUpdgrade1", bunkerUpdgrade1)
          end
          bunkerUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##bunker", bunkerUpdgrade2, true)
          if used then
            saveToConfig("bunkerUpdgrade2", bunkerUpdgrade2)
          end
          if bunkerUpdgrade1 then
            bunkerOffset1  = globals.get_int(262145 + 21256)
          else
            bunkerOffset1 = 0
          end
          if bunkerUpdgrade2 then
            bunkerOffset2  = globals.get_int(262145 + 21255)
          else
            bunkerOffset2 = 0
          end
          local bunkerProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY5")
          bunkerTotal = ((globals.get_int(262145 + 21254) + bunkerOffset1 + bunkerOffset2) * bunkerProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((bunkerProduct/100), 160, 25, tostring(bunkerProduct).." Crates ("..tostring(bunkerProduct).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text("BC: "..formatMoney(bunkerTotal).."\nLS: "..formatMoney(math.floor(bunkerTotal * 1.5)))
        end
        ---------------------------------------Acid Lab-------------------------------------------------------------------
        if acidOwned then
          ImGui.Separator();ImGui.Text("Acid Lab:   ");ImGui.SameLine()
          acidUpdgrade, used = ImGui.Checkbox("Equipment Upgrade##acid", acidUpdgrade, true)
          if used then
            saveToConfig("acidUpdgrade", acidUpdgrade)
          end
          if acidUpdgrade then
            acidOffset  = globals.get_int(262145 + 17330)
          else
            acidOffset = 0
          end
          local acidProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY6")
          acidTotal = ((globals.get_int(262145 + 17324) + acidOffset) * acidProduct)
          ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((acidProduct/100), 160, 25, tostring(acidProduct).." Sheets ("..tostring(math.floor(acidProduct / 16 * 10)).."%)")
          ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(acidTotal))
        end
        ImGui.Spacing();ImGui.Separator()
        local finalAmt = (hangarTotal + ceoTotal + cashTotal + cokeTotal + methTotal + weedTotal + fdTotal + bunkerTotal + acidTotal)
        ImGui.Spacing();ImGui.Text("Total Profit = "..formatMoney(finalAmt))
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Business Safes") then
        ImGui.Spacing();coloredText("-- README --", 10, readmeColor)
        if ImGui.IsItemHovered() then
          ImGui.BeginTooltip()
            coloredText("This is still a work in progress. Not all intended functionalities have been implemented.", 23.5, {255, 99, 71, 0.8})ImGui.Spacing()
            coloredText("R* added the ability to collect income from all your safes using a mobile app but they locked it behind a paywall (only available for GTA+ members). This paywall also makes it impossible for us PC players to have this feature. Therefore, I'm still looking for a way to replicate it here but hopefully there will be buttons allowing you to collect your safe income.", 23.5, {255, 255, 255, 0.8})
          ImGui.EndTooltip()
        end
        if stats.get_int(MPx.."_PROP_NIGHTCLUB") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ Nightclub ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(50, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##nc") then
              script.run_in_fiber(function()
                local ncBlip = HUD.GET_FIRST_BLIP_INFO_ID(614)
                local ncLoc
                if HUD.DOES_BLIP_EXIST(ncBlip) then
                  ncLoc = HUD.GET_BLIP_COORDS(ncBlip)
                  selfTP(false, false, ncLoc)
                end
              end)
            end
          end
          local currentNcPop = stats.get_int(MPx.."_CLUB_POPULARITY")
          local popDiff = 1000 - currentNcPop
          local currNcSafeMoney = stats.get_int(MPx.."_CLUB_SAFE_CASH_VALUE")
          ImGui.Text("Popularity: ");ImGui.SameLine();ImGui.Dummy(35, 1);ImGui.SameLine();ImGui.ProgressBar(currentNcPop/1000, 160, 25, tostring(currentNcPop))
          if currentNcPop < 1000 then
            ImGui.SameLine()
            if ImGui.Button("Max Popularity") then
              stats.set_int(MPx.."_CLUB_POPULARITY", currentNcPop + popDiff)
              gui.show_success("YimResupplier", "Nightclub popularity increased.")
            end
          end
          ImGui.Text("Safe: ");ImGui.SameLine();ImGui.Dummy(75, 1);ImGui.SameLine();ImGui.ProgressBar(currNcSafeMoney/250000, 160, 25, formatMoney(currNcSafeMoney));ImGui.Separator()
        end
        if stats.get_int(MPx.."_PROP_ARCADE") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ Arcade ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(60, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##arcade") then
              script.run_in_fiber(function()
                local arBlip = HUD.GET_FIRST_BLIP_INFO_ID(740)
                local arLoc
                if HUD.DOES_BLIP_EXIST(arBlip) then
                  arLoc = HUD.GET_BLIP_COORDS(arBlip)
                  selfTP(false, false, arLoc)
                end
              end)
            end
          end
          local currArSafeMoney = stats.get_int(MPx.."_ARCADE_SAFE_CASH_VALUE")
          ImGui.Text("Safe: ")ImGui.SameLine();ImGui.Dummy(75, 1);ImGui.SameLine();ImGui.ProgressBar(currArSafeMoney/100000, 160, 25, formatMoney(currArSafeMoney));ImGui.Separator()
        end
        if stats.get_int(MPx.."_PROP_SECURITY_OFFICE") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ Agency ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(60, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##agnc") then
              script.run_in_fiber(function()
                local agncBlip = HUD.GET_FIRST_BLIP_INFO_ID(826)
                local agncLoc
                if HUD.DOES_BLIP_EXIST(agncBlip) then
                  agncLoc = HUD.GET_BLIP_COORDS(agncBlip)
                  selfTP(false, false, agncLoc)
                end
              end)
            end
          end
          local currAgSafeMoney = stats.get_int(MPx.."_FIXER_SAFE_CASH_VALUE")
          ImGui.Text("Safe: ");ImGui.SameLine();ImGui.Dummy(75, 1);ImGui.SameLine();ImGui.ProgressBar(currAgSafeMoney/250000, 160, 25, formatMoney(currAgSafeMoney));ImGui.Separator()
        end
        if stats.get_int(MPx.."_PROP_CLUBHOUSE") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ MC Clubhouse ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(10, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##mc") then
              script.run_in_fiber(function()
                local mcBlip = HUD.GET_FIRST_BLIP_INFO_ID(492)
                local mcLoc
                if HUD.DOES_BLIP_EXIST(mcBlip) then
                  mcLoc = HUD.GET_BLIP_COORDS(mcBlip)
                  selfTP(false, false, mcLoc)
                end
              end)
            end
          end
          local currClubHouseBarProfit = stats.get_int(MPx.."_BIKER_BAR_RESUPPLY_CASH")
          ImGui.Text("Bar Earnings: ");ImGui.SameLine();ImGui.Dummy(15, 1);ImGui.SameLine();ImGui.ProgressBar(currClubHouseBarProfit/100000, 160, 25, formatMoney(currClubHouseBarProfit));ImGui.Separator()
        end
        if stats.get_int(MPx.."_PROP_BAIL_OFFICE") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ Bail Office ¤")
          --[[
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(40, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##bail") then
              script.run_in_fiber(function()
                local bailBlip = HUD.GET_FIRST_BLIP_INFO_ID(???)
                local bailLoc
                if HUD.DOES_BLIP_EXIST(bailBlip) then
                  bailLoc = HUD.GET_BLIP_COORDS(bailBlip)
                  selfTP(false, bailLoc)
                end
              end)
            end
          end
          ]]

          local currBailSafe = stats.get_int(MPx.."_BAIL_SAFE_CASH_VALUE")
          ImGui.Text("Safe: ");ImGui.SameLine();ImGui.Dummy(75, 1);ImGui.SameLine();ImGui.ProgressBar(currBailSafe/100000, 160, 25, formatMoney(currBailSafe));ImGui.Separator()
        end
        if stats.get_int(MPx.."_SALVAGE_YARD_OWNED") ~= 0 then
          ImGui.Spacing();ImGui.Spacing();ImGui.Text("¤ Salvage Yard ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine();ImGui.Dummy(20, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##salvage") then
              script.run_in_fiber(function()
                local slvgBlip = HUD.GET_FIRST_BLIP_INFO_ID(867)
                local slvgLoc
                if HUD.DOES_BLIP_EXIST(slvgBlip) then
                  slvgLoc = HUD.GET_BLIP_COORDS(slvgBlip)
                  selfTP(false, true, slvgLoc, 180)
                end
              end)
            end
          end
          local currSalvSafe = stats.get_int(MPx.."_SALVAGE_SAFE_CASH_VALUE")
          ImGui.Text("Safe: ");ImGui.SameLine();ImGui.Dummy(75, 1);ImGui.SameLine();ImGui.ProgressBar(currSalvSafe/250000, 160, 25, formatMoney(currSalvSafe))
        end
        if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
          ImGui.Dummy(1, 10);coloredText("WARNING!\10Teleport buttons might be broken in public sessions.", 40, {255, 204, 0, 0.8})
        end
        ImGui.EndTabItem()
      end
    else
      ImGui.Text("\nUnavailable in Single Player.\n\n")
    end
  end)
elseif tonumber(online_version:get_string()) > 3179 then
  gui.show_warning("YimResupplier", "YimResupplier is not up-to-date.\nPlease update the script!")
  yim_resupplier = gui.get_tab("YimResupplier")
  yim_resupplier:add_text("YimResupplier is not up-to-date.\n\nPlease update the script.")
else
  gui.show_error("YimResupplier", "Failed to load!")
end

script.register_looped("shitty rgb text", function(rgbtxt)
  if gui.is_open() then
   rgbtxt:sleep(150)
    readmeColor = {0, 255, 255, 1}
   rgbtxt:sleep(150)
    readmeColor = {0, 127, 255, 1}
   rgbtxt:sleep(150)
    readmeColor = {0, 0, 255, 1}
   rgbtxt:sleep(150)
    readmeColor = {127, 0, 255, 1}
   rgbtxt:sleep(150)
    readmeColor = {255, 0, 255, 1}
   rgbtxt:sleep(150)
    readmeColor = {255, 0, 127, 1}
   rgbtxt:sleep(150)
    readmeColor = {255, 0, 0, 1}
   rgbtxt:sleep(150)
    readmeColor = {255, 127, 0, 1}
   rgbtxt:sleep(150)
    readmeColor = {255, 255, 0, 1}
   rgbtxt:sleep(150)
    readmeColor = {127, 255, 0, 1}
   rgbtxt:sleep(150)
    readmeColor = {0, 255, 0, 1}
   rgbtxt:sleep(150)
    readmeColor = {0, 255, 127, 1}
  end
end)