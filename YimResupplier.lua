---@diagnostic disable: undefined-global, lowercase-global

online_version = memory.scan_pattern("8B C3 33 D2 C6 44 24 20"):add(0x24):rip()
if tonumber(online_version:get_string()) == 3179 then
  yim_resupplier = gui.get_tab("YimResupplier")
  yim_resupplier:add_imgui(function()
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
      local MPx          = "MP"..stats.get_character_index()
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
          ImGui.SameLine();hangarLoop, _ = ImGui.Checkbox("Auto-Fill", hangarLoop, true)
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