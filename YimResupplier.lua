---@diagnostic disable: undefined-global, lowercase-global

--------------------------------------------------------------------------------------------
--[[
  RXI JSON Library (Modified by Harmless)
  Credits: RXI (json.lua (https://github.com/rxi/json.lua) - for the original library)
]]--
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
if tonumber(online_version:get_string()) == 3179 then
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
  yim_resupplier:add_imgui(function()
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
      local MPx = "MP"..stats.get_character_index()
      ImGui.BeginTabBar("YimResupplier", ImGuiTabBarFlags.None)
      if ImGui.BeginTabItem("Manage Supplies") then
        local hangarSupply = stats.get_int(MPx.."_HANGAR_CONTRABAND_TOTAL")
        local cashSupply   = stats.get_int(MPx.."_MATTOTALFORFACTORY0")
        local cokeSupply   = stats.get_int(MPx.."_MATTOTALFORFACTORY1")
        local methSupply   = stats.get_int(MPx.."_MATTOTALFORFACTORY2")
        local weedSupply   = stats.get_int(MPx.."_MATTOTALFORFACTORY3")
        local dfSupply     = stats.get_int(MPx.."_MATTOTALFORFACTORY4")
        local bunkerSupply = stats.get_int(MPx.."_MATTOTALFORFACTORY5")
        local acidSupply   = stats.get_int(MPx.."_MATTOTALFORFACTORY6")
        ImGui.Text("Hangar Cargo");ImGui.Separator()
        -- if stats.get_int(MPx.."_HANGAR_OWNED") ~= 0 then
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
        -- else
        --   ImGui.Text("You don't own a Hangar.")
        -- end
        ImGui.Spacing();ImGui.Text("MC Supplies");ImGui.Separator()
        -- if stats.get_int(MPx.."_FACTORYSLOT0") ~= 0 then
          ImGui.Text("Fake Cash:");ImGui.SameLine();ImGui.Dummy(55, 1);ImGui.SameLine();ImGui.ProgressBar((cashSupply/100), 140, 30)
          if math.ceil(cashSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##FakeCash") then
              globals.set_int(1662873 + 0 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Fake Cash business.")
        -- end
        -- if stats.get_int(MPx.."_FACTORYSLOT1") ~= 0 then
          ImGui.Text("Cocaine:");ImGui.SameLine();ImGui.Dummy(73, 1);ImGui.SameLine();ImGui.ProgressBar((cokeSupply/100), 140, 30)
          if math.ceil(cokeSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Cocaine") then
              globals.set_int(1662873 + 1 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Cocaine business.")
        -- end
        -- if stats.get_int(MPx.."_FACTORYSLOT2") ~= 0 then
          ImGui.Text("Meth:");ImGui.SameLine();ImGui.Dummy(95, 1);ImGui.SameLine();ImGui.ProgressBar((methSupply/100), 140, 30)
          if math.ceil(methSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Meth") then
              globals.set_int(1662873 + 2 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Meth business.")
        -- end
        -- if stats.get_int(MPx.."_FACTORYSLOT3") ~= 0 then
          ImGui.Text("Weed:");ImGui.SameLine();ImGui.Dummy(90, 1);ImGui.SameLine();ImGui.ProgressBar((weedSupply/100), 140, 30)
          if math.ceil(weedSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Weed") then
              globals.set_int(1662873 + 3 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Weed business.")
        -- end
        -- if stats.get_int(MPx.."_FACTORYSLOT4") ~= 0 then
          ImGui.Text("Document Forgery: ");ImGui.SameLine();ImGui.ProgressBar((dfSupply/100), 140, 30)
          if math.ceil(dfSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##DocumentForgery") then
              globals.set_int(1662873 + 4 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Document Forgery office.")
        -- end
        -- if stats.get_int(MPx.."_FACTORYSLOT5") ~= 0 then
          ImGui.Text("Bunker:");ImGui.SameLine();ImGui.Dummy(80, 1);ImGui.SameLine();ImGui.ProgressBar((bunkerSupply/100), 140, 30)
          if math.ceil(bunkerSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Bunker") then
              globals.set_int(1662873 + 5 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own a Bunker.")
        -- end
        -- if stats.get_int(MPx.."_MP_STAT_XM22_LAB_OWNED_v0") ~= 0 then
          ImGui.Text("Acid Lab:");ImGui.SameLine();ImGui.Dummy(70, 1);ImGui.SameLine();ImGui.ProgressBar((acidSupply/100), 140, 30)
          if math.ceil(acidSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##AcidLab") then
              globals.set_int(1662873 + 6 + 1, 1)
            end
          end
        -- else
        --   ImGui.Text("You don't own an Acid Lab.")
        -- end
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Production Overview") then
        local function formatMoney(value)
          return "$"..tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
        end

        ImGui.Text("Hangar:")
        local hangarCargo = stats.get_int(MPx.."_HANGAR_CONTRABAND_TOTAL")
        local hangarTotal = hangarCargo * 30000
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((hangarCargo/50), 160, 25, tostring(hangarCargo).." Crates ("..tostring(math.floor(hangarCargo / 0.5)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(hangarTotal))
        ---------------------------------------Fake Cash-------------------------------------------------------------------
        ImGui.Separator()ImGui.Text("Fake Cash:");ImGui.SameLine()
        cashUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##cash", cashUpdgrade1, true);ImGui.SameLine()
        if used then
          saveToConfig("cashUpdgrade1", cashUpdgrade1)
        end
        cashUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##cash", cashUpdgrade2, true)
        if used then
          saveToConfig("cashUpdgrade2", cashUpdgrade2)
        end
        if cashUpdgrade1 then
          cashOffset1  = globals.get_int(262145 + 17635)
        else
          cashOffset1 = 0
        end
        if cashUpdgrade2 then
          cashOffset2  = globals.get_int(262145 + 17641)
        else
          cashOffset2 = 0
        end
        local cashProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY0")
        local cashTotal   = ((globals.get_int(262145 + 17629) + cashOffset1 + cashOffset2) * cashProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((cashProduct/40), 160, 25, tostring(cashProduct).." Boxes ("..tostring(math.floor(cashProduct * 2.5)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(cashTotal))
        ---------------------------------------Coke----------------------------------------------------------------------
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
          cokeOffset1  = globals.get_int(262145 + 17636)
        else
          cokeOffset1 = 0
        end
        if cokeUpdgrade2 then
          cokeOffset2  = globals.get_int(262145 + 17642)
        else
          cokeOffset2 = 0
        end
        local cokeProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY1")
        local cokeTotal   = ((globals.get_int(262145 + 17630) + cokeOffset1 + cokeOffset2) * cokeProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((cokeProduct/10), 160, 25, tostring(cokeProduct).." Kilos ("..tostring(cokeProduct * 10).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:")ImGui.SameLine();ImGui.Text(formatMoney(cokeTotal))
        ---------------------------------------Meth-----------------------------------------------------------------------
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
          methOffset1  = globals.get_int(262145 + 17637)
        else
          methOffset1 = 0
        end
        if methUpdgrade2 then
          methOffset2  = globals.get_int(262145 + 17643)
        else
          methOffset2 = 0
        end
        local methProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY2")
        local methTotal   = ((globals.get_int(262145 + 17631)+ methOffset1 + methOffset2) * methProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((methProduct/20), 160, 25, tostring(methProduct).." Pounds ("..tostring(methProduct * 5).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine()ImGui.Text(formatMoney(methTotal))
        ---------------------------------------Weed------------------------------------------------------------------------
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
          weedOffset1  = globals.get_int(262145 + 17638)
        else
          weedOffset1 = 0
        end
        if weedUpdgrade2 then
          weedOffset2  = globals.get_int(262145 + 17644)
        else
          weedOffset2 = 0
        end
        local weedProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY3")
        local weedTotal   = ((globals.get_int(262145 + 17632) + weedOffset1 + weedOffset2) * weedProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((weedProduct/80), 160, 25, tostring(weedProduct).." Pounds ("..tostring(math.floor(weedProduct / 8 * 10)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(weedTotal))
        ---------------------------------------Document Forgery------------------------------------------------------------
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
          fdOffset1  = globals.get_int(262145 + 17634)
        else
          fdOffset1 = 0
        end
        if fdUpdgrade2 then
          fdOffset2  = globals.get_int(262145 + 17640)
        else
          fdOffset2 = 0
        end
        local fdProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY4")
        local fdTotal   = ((globals.get_int(262145 + 17628) + fdOffset1 + fdOffset2) * fdProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((fdProduct/60), 160, 25, tostring(fdProduct).." Boxes ("..tostring(math.floor(fdProduct / 6 * 10)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(fdTotal))
        ---------------------------------------Bunker-----------------------------------------------------------------------
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
          bunkerOffset1  = globals.get_int(262145 + 21749)
        else
          bunkerOffset1 = 0
        end
        if bunkerUpdgrade2 then
          bunkerOffset2  = globals.get_int(262145 + 21748)
        else
          bunkerOffset2 = 0
        end
        local bunkerProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY5")
        local bunkerTotal   = ((globals.get_int(262145 + 21747) + bunkerOffset1 + bunkerOffset2) * bunkerProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((bunkerProduct/100), 160, 25, tostring(bunkerProduct).." Crates ("..tostring(bunkerProduct).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text("BC: "..formatMoney(bunkerTotal).."\nLS: "..formatMoney(math.floor(bunkerTotal * 1.5)))
        ---------------------------------------Acid Lab-------------------------------------------------------------------
        ImGui.Separator();ImGui.Text("Acid Lab:   ");ImGui.SameLine()
        acidUpdgrade, used = ImGui.Checkbox("Equipment Upgrade##acid", acidUpdgrade, true)
        if used then
          saveToConfig("acidUpdgrade", acidUpdgrade)
        end
        if acidUpdgrade then
          acidOffset  = globals.get_int(262145 + 17639)
        else
          acidOffset = 0
        end
        local acidProduct = stats.get_int(MPx.."_PRODTOTALFORFACTORY6")
        local acidTotal   = ((globals.get_int(262145 + 17633) + acidOffset) * acidProduct)
        ImGui.Text("Product:");ImGui.SameLine();ImGui.Dummy(5, 1);ImGui.SameLine();ImGui.ProgressBar((acidProduct/100), 160, 25, tostring(acidProduct).." Sheets ("..tostring(math.floor(acidProduct / 16 * 10)).."%)")
        ImGui.SameLine();ImGui.Dummy(10, 1);ImGui.SameLine();ImGui.Text("Value:");ImGui.SameLine();ImGui.Text(formatMoney(acidTotal))
        ImGui.Spacing();ImGui.Separator()
        local finalAmt = (hangarTotal + cashTotal + cokeTotal + methTotal + weedTotal + fdTotal + bunkerTotal + acidTotal)
        ImGui.Spacing();ImGui.Text("Total Profit = "..formatMoney(finalAmt))
        ImGui.EndTabItem()
      end
    else
      ImGui.Text("YimResupplier doesn't work in Single Player.")
    end
  end)
elseif tonumber(online_version:get_string()) > 3179 then
  gui.show_message("YimResupplier", "YimResupplier is not up-to-date.\nPlease update the script!")
  yim_resupplier = gui.get_tab("YimResupplier")
  yim_resupplier:add_text("YimResupplier is not up-to-date.\n\nPlease update the script.")
else
  gui.show_message("YimResupplier", "Failed to load!")
end