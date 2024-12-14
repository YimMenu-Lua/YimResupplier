---@diagnostic disable: undefined-global, lowercase-global

SCRIPT_NAME = "YimResupplier"
local TAGET_BUILD <const> = "3411"
local CFG = require("includes/YimConfig")
require("includes/yr_utils")

if GetBuildNumber() == TAGET_BUILD then
  yim_resupplier = gui.add_tab("YimResupplier")
  DEFAULT_CONFIG = {
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
  local main_global     = 1667995
  local cashUpdgrade1   = CFG.read("cashUpdgrade1")
  local cashUpdgrade2   = CFG.read("cashUpdgrade2")
  local cokeUpdgrade1   = CFG.read("cokeUpdgrade1")
  local cokeUpdgrade2   = CFG.read("cokeUpdgrade2")
  local methUpdgrade1   = CFG.read("methUpdgrade1")
  local methUpdgrade2   = CFG.read("methUpdgrade2")
  local weedUpdgrade1   = CFG.read("weedUpdgrade1")
  local weedUpdgrade2   = CFG.read("weedUpdgrade2")
  local fdUpdgrade1     = CFG.read("fdUpdgrade1")
  local fdUpdgrade2     = CFG.read("fdUpdgrade2")
  local bunkerUpdgrade1 = CFG.read("bunkerUpdgrade1")
  local bunkerUpdgrade2 = CFG.read("bunkerUpdgrade2")
  local acidUpdgrade    = CFG.read("acidUpdgrade")

  yim_resupplier:add_imgui(function()
    if network.is_session_started() and not script.is_active("maintransition") then
      hangarOwned = stats.get_int("MPX_PROP_HANGAR") ~= 0
      fCashOwned  = stats.get_int("MPX_PROP_FAC_SLOT0") ~= 0
      cokeOwned   = stats.get_int("MPX_PROP_FAC_SLOT1") ~= 0
      methOwned   = stats.get_int("MPX_PROP_FAC_SLOT2") ~= 0
      weedOwned   = stats.get_int("MPX_PROP_FAC_SLOT3") ~= 0
      fdOwned     = stats.get_int("MPX_PROP_FAC_SLOT4") ~= 0
      bunkerOwned = stats.get_int("MPX_PROP_FAC_SLOT5") ~= 0
      acidOwned   = stats.get_int("MPX_PROP_FAC_SLOT6") ~= 0
      ImGui.BeginTabBar("YimResupplier", ImGuiTabBarFlags.None)
      if ImGui.BeginTabItem("Manage Supplies") then
        local wh1Supplies  = stats.get_int("MPX_CONTOTALFORWHOUSE0")
        local wh2Supplies  = stats.get_int("MPX_CONTOTALFORWHOUSE1")
        local wh3Supplies  = stats.get_int("MPX_CONTOTALFORWHOUSE2")
        local wh4Supplies  = stats.get_int("MPX_CONTOTALFORWHOUSE3")
        local wh5Supplies  = stats.get_int("MPX_CONTOTALFORWHOUSE4")
        local hangarSupply = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
        local cashSupply   = stats.get_int("MPX_MATTOTALFORFACTORY0")
        local dfSupply     = stats.get_int("MPX_MATTOTALFORFACTORY1")
        local methSupply   = stats.get_int("MPX_MATTOTALFORFACTORY2")
        local weedSupply   = stats.get_int("MPX_MATTOTALFORFACTORY3")
        local cokeSupply   = stats.get_int("MPX_MATTOTALFORFACTORY4")
        local bunkerSupply = stats.get_int("MPX_MATTOTALFORFACTORY5")
        local acidSupply   = stats.get_int("MPX_MATTOTALFORFACTORY6")
        local ceoSupply    = (wh1Supplies + wh2Supplies + wh3Supplies + wh4Supplies + wh5Supplies)
        ImGui.Spacing(); ImGui.Text("Hangar Cargo"); ImGui.Separator()
        if hangarOwned then
          ImGui.Text("Current Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (hangarSupply / 50), 140, 30)
          if hangarSupply < 50 then
            if ImGui.Button("Source Random Crate(s)") then
              script.run_in_fiber(function()
                stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
              end)
            end
            ImGui.SameLine(); hangarLoop, used = ImGui.Checkbox("Auto-Fill", hangarLoop)
            if hangarLoop then
              script.run_in_fiber(function(hangarSupp)
                repeat
                  stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
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
        ImGui.Spacing(); ImGui.Text("CEO Warehouses"); ImGui.Separator()
        ImGui.Text("Current Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.ProgressBar(
          (ceoSupply / 555), 140, 30)
        if ceoSupply < 555 then
          if ImGui.Button("Source Random Crate(s)##ceo") then
            script.run_in_fiber(function(fillceo)
              for i = 12, 16 do
                stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i)
                fillceo:sleep(500) -- half second delay between each warehouse
              end
            end)
          end
          ImGui.SameLine(); ceoLoop, used = ImGui.Checkbox("Auto-Fill##ceo", ceoLoop)
          if ceoLoop then
            script.run_in_fiber(function(ceoloop)
              repeat
                for i = 12, 16 do
                  stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i)
                  ceoloop:sleep(500) -- half second delay between each warehouse
                end
                ceoloop:sleep(969)   -- add a delay to prevent transaction error or infinite 'transaction pending'
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
        ImGui.Spacing(); ImGui.Text("MC Supplies"); ImGui.Separator()
        if fCashOwned then
          ImGui.Text("Fake Cash:"); ImGui.SameLine(); ImGui.Dummy(55, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (cashSupply / 100), 140, 30)
          if math.ceil(cashSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##FakeCash") then
              globals.set_int(main_global + 0 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Cocaine:"); ImGui.SameLine(); ImGui.Dummy(73, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (cokeSupply / 100), 140, 30)
          if math.ceil(cokeSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Cocaine") then
              globals.set_int(main_global + 4 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Meth:"); ImGui.SameLine(); ImGui.Dummy(95, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (methSupply / 100), 140, 30)
          if math.ceil(methSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Meth") then
              globals.set_int(main_global + 2 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Weed:"); ImGui.SameLine(); ImGui.Dummy(90, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (weedSupply / 100), 140, 30)
          if math.ceil(weedSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Weed") then
              globals.set_int(main_global + 3 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Document Forgery: "); ImGui.SameLine(); ImGui.ProgressBar((dfSupply / 100), 140, 30)
          if math.ceil(dfSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##DocumentForgery") then
              globals.set_int(main_global + 1 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Bunker:"); ImGui.SameLine(); ImGui.Dummy(80, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (bunkerSupply / 100), 140, 30)
          if math.ceil(bunkerSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##Bunker") then
              globals.set_int(main_global + 5 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
          ImGui.Text("Acid Lab:"); ImGui.SameLine(); ImGui.Dummy(70, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (acidSupply / 100), 140, 30)
          if math.ceil(acidSupply) < 100 then
            ImGui.SameLine()
            if ImGui.Button(" Fill ##AcidLab") then
              globals.set_int(main_global + 6 + 1, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1)
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
            ImGui.Dummy(1, 10); coloredText("WARNING!\10Teleport buttons might be broken in public sessions.", 40,
              { 255, 204, 0, 0.8 })
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
          local hangarCargo = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
          hangarTotal = hangarCargo * 30000
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (hangarCargo / 50), 160, 25, tostring(hangarCargo) ..
            " Crates (" .. tostring(math.floor(hangarCargo / 0.5)) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine()
          ImGui.Text(formatMoney(hangarTotal))
        end
        --------------------------------------- CEO ----------------------------------------------------------------------
        ImGui.Separator(); ImGui.Text("CEO:")
        local wh1Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE0")
        local wh2Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE1")
        local wh3Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE2")
        local wh4Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE3")
        local wh5Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE4")
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
        local ceoSupply = (wh1Supplies + wh2Supplies + wh3Supplies + wh4Supplies + wh5Supplies)
        ceoTotal        = ((wh1Value * wh1Supplies) + (wh2Value * wh2Supplies) + (wh3Value * wh3Supplies) + (wh4Value * wh4Supplies) + (wh5Value * wh5Supplies))
        ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
          (ceoSupply / 555),
          160, 25, tostring(ceoSupply) .. " Crates (" .. tostring(math.floor((ceoSupply / 555) * 100)) .. "%)")
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine()
        ImGui.Text(formatMoney(ceoTotal))
        --------------------------------------- Fake Cash -------------------------------------------------------------------
        if fCashOwned then
          ImGui.Separator(); ImGui.Text("Fake Cash:"); ImGui.SameLine()
          cashUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##cash", cashUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("cashUpdgrade1", cashUpdgrade1)
          end
          cashUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##cash", cashUpdgrade2)
          if used then
            CFG.save("cashUpdgrade2", cashUpdgrade2)
          end
          if cashUpdgrade1 then
            cashOffset1 = globals.get_int(262145 + 17326)
          else
            cashOffset1 = 0
          end
          if cashUpdgrade2 then
            cashOffset2 = globals.get_int(262145 + 17332)
          else
            cashOffset2 = 0
          end
          local cashProduct = stats.get_int("MPX_PRODTOTALFORFACTORY0")
          cashTotal = ((globals.get_int(262145 + 17320) + cashOffset1 + cashOffset2) * cashProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (cashProduct / 40), 160, 25, tostring(cashProduct) .. " Boxes (" ..
            tostring(math.floor(cashProduct * 2.5)) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine()
          ImGui.Text(formatMoney(cashTotal))
        end
        ---------------------------------------Coke----------------------------------------------------------------------
        if cokeOwned then
          ImGui.Separator(); ImGui.Text("Cocaine:    "); ImGui.SameLine()
          cokeUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##coke", cokeUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("cokeUpdgrade1", cokeUpdgrade1)
          end
          cokeUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##coke", cokeUpdgrade2)
          if used then
            CFG.save("cokeUpdgrade2", cokeUpdgrade2)
          end
          if cokeUpdgrade1 then
            cokeOffset1 = globals.get_int(262145 + 17327)
          else
            cokeOffset1 = 0
          end
          if cokeUpdgrade2 then
            cokeOffset2 = globals.get_int(262145 + 17333)
          else
            cokeOffset2 = 0
          end
          local cokeProduct = stats.get_int("MPX_PRODTOTALFORFACTORY1")
          cokeTotal = ((globals.get_int(262145 + 17321) + cokeOffset1 + cokeOffset2) * cokeProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (cokeProduct / 10), 160, 25, tostring(cokeProduct) .. " Kilos (" .. tostring(cokeProduct * 10) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:")
          ImGui.SameLine(); ImGui.Text(formatMoney(cokeTotal))
        end
        ---------------------------------------Meth-----------------------------------------------------------------------
        if methOwned then
          ImGui.Separator()
          ImGui.Text("Meth:        "); ImGui.SameLine()
          methUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##meth", methUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("methUpdgrade1", methUpdgrade1)
          end
          methUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##meth", methUpdgrade2)
          if used then
            CFG.save("methUpdgrade2", methUpdgrade2)
          end
          if methUpdgrade1 then
            methOffset1 = globals.get_int(262145 + 17328)
          else
            methOffset1 = 0
          end
          if methUpdgrade2 then
            methOffset2 = globals.get_int(262145 + 17334)
          else
            methOffset2 = 0
          end
          local methProduct = stats.get_int("MPX_PRODTOTALFORFACTORY2")
          methTotal = ((globals.get_int(262145 + 17322) + methOffset1 + methOffset2) * methProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (methProduct / 20), 160, 25, tostring(methProduct) .. " Pounds (" .. tostring(methProduct * 5) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine()
          ImGui.Text(formatMoney(methTotal))
        end
        ---------------------------------------Weed------------------------------------------------------------------------
        if weedOwned then
          ImGui.Separator()
          ImGui.Text("Weed:       "); ImGui.SameLine()
          weedUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##weed", weedUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("weedUpdgrade1", weedUpdgrade1)
          end
          weedUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##weed", weedUpdgrade2)
          if used then
            CFG.save("weedUpdgrade2", weedUpdgrade2)
          end
          if weedUpdgrade1 then
            weedOffset1 = globals.get_int(262145 + 17329)
          else
            weedOffset1 = 0
          end
          if weedUpdgrade2 then
            weedOffset2 = globals.get_int(262145 + 17335)
          else
            weedOffset2 = 0
          end
          local weedProduct = stats.get_int("MPX_PRODTOTALFORFACTORY3")
          weedTotal = ((globals.get_int(262145 + 17323) + weedOffset1 + weedOffset2) * weedProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (weedProduct / 80), 160, 25,
            tostring(weedProduct) .. " Pounds (" .. tostring(math.floor(weedProduct / 8 * 10)) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine(); ImGui.Text(
            formatMoney(weedTotal))
        end
        ---------------------------------------Document Forgery------------------------------------------------------------
        if fdOwned then
          ImGui.Separator()
          ImGui.Text("Fake ID:    "); ImGui.SameLine()
          fdUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##fd", fdUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("fdUpdgrade1", fdUpdgrade1)
          end
          fdUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##fd", fdUpdgrade2)
          if used then
            CFG.save("fdUpdgrade2", fdUpdgrade2)
          end
          if fdUpdgrade1 then
            fdOffset1 = globals.get_int(262145 + 17325)
          else
            fdOffset1 = 0
          end
          if fdUpdgrade2 then
            fdOffset2 = globals.get_int(262145 + 17331)
          else
            fdOffset2 = 0
          end
          local fdProduct = stats.get_int("MPX_PRODTOTALFORFACTORY4")
          fdTotal = ((globals.get_int(262145 + 17319) + fdOffset1 + fdOffset2) * fdProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (fdProduct / 60), 160, 25, tostring(fdProduct) .. " Boxes (" .. tostring(math.floor(fdProduct / 6 * 10)) ..
            "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine(); ImGui.Text(
            formatMoney(fdTotal))
        end
        ---------------------------------------Bunker-----------------------------------------------------------------------
        if bunkerOwned then
          ImGui.Separator(); ImGui.Text("Bunker:     "); ImGui.SameLine()
          bunkerUpdgrade1, used = ImGui.Checkbox("Equipment Upgrade##bunker", bunkerUpdgrade1); ImGui.SameLine()
          if used then
            CFG.save("bunkerUpdgrade1", bunkerUpdgrade1)
          end
          bunkerUpdgrade2, used = ImGui.Checkbox("Staff Upgrade##bunker", bunkerUpdgrade2)
          if used then
            CFG.save("bunkerUpdgrade2", bunkerUpdgrade2)
          end
          if bunkerUpdgrade1 then
            bunkerOffset1 = globals.get_int(262145 + 21256)
          else
            bunkerOffset1 = 0
          end
          if bunkerUpdgrade2 then
            bunkerOffset2 = globals.get_int(262145 + 21255)
          else
            bunkerOffset2 = 0
          end
          local bunkerProduct = stats.get_int("MPX_PRODTOTALFORFACTORY5")
          bunkerTotal = ((globals.get_int(262145 + 21254) + bunkerOffset1 + bunkerOffset2) * bunkerProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (bunkerProduct / 100), 160, 25, tostring(bunkerProduct) .. " Crates (" .. tostring(bunkerProduct) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine(); ImGui.Text(
            "BC: " .. formatMoney(bunkerTotal) .. "\nLS: " .. formatMoney(math.floor(bunkerTotal * 1.5)))
        end
        ---------------------------------------Acid Lab-------------------------------------------------------------------
        if acidOwned then
          ImGui.Separator(); ImGui.Text("Acid Lab:   "); ImGui.SameLine()
          acidUpdgrade, used = ImGui.Checkbox("Equipment Upgrade##acid", acidUpdgrade)
          if used then
            CFG.save("acidUpdgrade", acidUpdgrade)
          end
          if acidUpdgrade then
            acidOffset = globals.get_int(262145 + 17330)
          else
            acidOffset = 0
          end
          local acidProduct = stats.get_int("MPX_PRODTOTALFORFACTORY6")
          acidTotal = ((globals.get_int(262145 + 17324) + acidOffset) * acidProduct)
          ImGui.Text("Product:"); ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine(); ImGui.ProgressBar(
            (acidProduct / 100), 160, 25,
            tostring(acidProduct) .. " Sheets (" .. tostring(math.floor(acidProduct / 16 * 10)) .. "%)")
          ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine(); ImGui.Text(
            formatMoney(acidTotal))
        end
        ImGui.Spacing(); ImGui.Separator()
        local finalAmt = (hangarTotal + ceoTotal + cashTotal + cokeTotal + methTotal + weedTotal + fdTotal + bunkerTotal + acidTotal)
        ImGui.Spacing(); ImGui.Text("Total Profit = " .. formatMoney(finalAmt))
        ImGui.EndTabItem()
      end
      if ImGui.BeginTabItem("Business Safes") then
        if stats.get_int("MPX_PROP_NIGHTCLUB") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ Nightclub ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
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
          local currentNcPop = stats.get_int("MPX_CLUB_POPULARITY")
          local popDiff = 1000 - currentNcPop
          local currNcSafeMoney = stats.get_int("MPX_CLUB_SAFE_CASH_VALUE")
          ImGui.Text("Popularity: "); ImGui.SameLine(); ImGui.Dummy(35, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currentNcPop / 1000, 160, 25, tostring(currentNcPop))
          if currentNcPop < 1000 then
            ImGui.SameLine()
            if ImGui.Button("Max Popularity") then
              stats.set_int("MPX_CLUB_POPULARITY", currentNcPop + popDiff)
              gui.show_success("YimResupplier", "Nightclub popularity increased.")
            end
          end
          ImGui.Text("Safe: "); ImGui.SameLine(); ImGui.Dummy(75, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currNcSafeMoney / 250000, 160, 25, formatMoney(currNcSafeMoney)); ImGui.Separator()
        end
        if stats.get_int("MPX_PROP_ARCADE") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ Arcade ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
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
          local currArSafeMoney = stats.get_int("MPX_ARCADE_SAFE_CASH_VALUE")
          ImGui.Text("Safe: ")
          ImGui.SameLine(); ImGui.Dummy(75, 1); ImGui.SameLine(); ImGui.ProgressBar(currArSafeMoney / 100000, 160, 25,
            formatMoney(currArSafeMoney)); ImGui.Separator()
        end
        if stats.get_int("MPX_PROP_SECURITY_OFFICE") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ Agency ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
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
          local currAgSafeMoney = stats.get_int("MPX_FIXER_SAFE_CASH_VALUE")
          ImGui.Text("Safe: "); ImGui.SameLine(); ImGui.Dummy(75, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currAgSafeMoney / 250000, 160, 25, formatMoney(currAgSafeMoney)); ImGui.Separator()
        end
        if stats.get_int("MPX_PROP_CLUBHOUSE") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ MC Clubhouse ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
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
          local currClubHouseBarProfit = stats.get_int("MPX_BIKER_BAR_RESUPPLY_CASH")
          ImGui.Text("Bar Earnings: "); ImGui.SameLine(); ImGui.Dummy(15, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currClubHouseBarProfit / 100000, 160, 25, formatMoney(currClubHouseBarProfit)); ImGui.Separator()
        end
        if stats.get_int("MPX_PROP_BAIL_OFFICE") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ Bail Office ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine()
            if ImGui.Button("Teleport##bail") then
              script.run_in_fiber(function()
                local bailBlip = HUD.GET_FIRST_BLIP_INFO_ID(893)
                local bailLoc
                if HUD.DOES_BLIP_EXIST(bailBlip) then
                  bailLoc = HUD.GET_BLIP_COORDS(bailBlip)
                  bailLoc.y = bailLoc.y + 1.2
                  selfTP(false, false, bailLoc)
                end
              end)
            end
          end
          local currBailSafe = stats.get_int("MPX_BAIL_SAFE_CASH_VALUE")
          ImGui.Text("Safe: "); ImGui.SameLine(); ImGui.Dummy(75, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currBailSafe / 100000, 160, 25, formatMoney(currBailSafe)); ImGui.Separator()
        end
        if stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0 then
          ImGui.Spacing(); ImGui.Spacing(); ImGui.Text("¤ Salvage Yard ¤")
          if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
            ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
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
          local currSalvSafe = stats.get_int("MPX_SALVAGE_SAFE_CASH_VALUE")
          ImGui.Text("Safe: "); ImGui.SameLine(); ImGui.Dummy(75, 1); ImGui.SameLine(); ImGui.ProgressBar(
            currSalvSafe / 250000, 160, 25, formatMoney(currSalvSafe))
        end
        if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
          ImGui.Dummy(1, 10); coloredText("WARNING!\10Teleport buttons might be broken in public sessions.", 40,
            { 255, 204, 0, 0.8 })
        end
        ImGui.EndTabItem()
      end
    else
      ImGui.Text("\nUnavailable in Single Player.\n\n")
    end
  end)
else
  gui.show_warning("YimResupplier", "YimResupplier is outdated.\nPlease update the script!")
  yim_resupplier = gui.add_tab("YimResupplier")
  yim_resupplier:add_text("YimResupplier is outdated.\n\nPlease update the script.")
end
