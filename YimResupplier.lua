---@diagnostic disable: undefined-global, lowercase-global

online_version = memory.scan_pattern("8B C3 33 D2 C6 44 24 20"):add(0x24):rip()
if tonumber(online_version:get_string()) == 3179 then
  yim_resupplier = gui.get_tab("YimResupplier")
  yim_resupplier:add_imgui(function()
  ImGui.Text("Hangar Cargo")
    if ImGui.Button("Source Random Crate(s)") then
      script.run_in_fiber(function()
      stats.set_bool_masked("MP"..stats.get_int("MPPLY_LAST_MP_CHAR").."_DLC22022PSTAT_BOOL3", true, 9)
      end)
    end
  ImGui.Text("MC Supplies")
    if ImGui.Button("Fill Fake Cash Supplies") then
      globals.set_int(1662873 + 1, 1)
    end
    if ImGui.Button("Fill Cocaine Supplies") then
      globals.set_int(1662873 + 2, 1)
    end
    if ImGui.Button("Fill Meth Supplies") then
      globals.set_int(1662873 + 3, 1)  
    end
    if ImGui.Button("Fill Weed Supplies") then
      globals.set_int(1662873 + 4, 1)
    end
    if ImGui.Button("Fill Document Forgery Supplies") then
      globals.set_int(1662873 + 5, 1)
    end
    if ImGui.Button("Fill Bunker Supplies") then
      globals.set_int(1662873 + 6, 1)
    end
    if ImGui.Button("Fill Acid Lab Supplies") then
      globals.set_int(1662873 + 7, 1)
    end
  end)
elseif tonumber(online_version:get_string()) > 3179 then
  gui.show_message("YimResupplier", "YimResupplier is not up-to-date.\nPlease update the script!")
  yim_resupplier = gui.get_tab("YimResupplier")
  yim_resupplier:add_text("YimResupplier is not up-to-date.\n\nPlease update the script.")
else
  gui.show_message("YimResupplier", "Failed to load!")
end