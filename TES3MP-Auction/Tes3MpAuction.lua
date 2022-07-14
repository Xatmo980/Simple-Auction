local GuI = 44332215
local SGuI = 44332220
local IGuI = 44332225
local PostItemLimit = 50         -- (Working) max amount of items posted allowed
local BotOn = true               -- (Working) turn bot on or off (true = on, false = off)
local RandomizeBotItems = true   -- (Working) Post Random items in the list (Requires BotPostLimit to be Set as well)
local BotPostLimit = 10          -- (Working) How Many Random Items to post from the list
local BaseItemName = {}
local Auction = {}
local config = {}
local SellValue = ""
local IName = ""
local INum = ""
Selling = {}
Buying = {}
local getFiles = function(directory)

    local i, t, popen = 0, {}, io.popen
    local pfile = nil

    pfile = popen('dir "' .. directory .. '" /b')

    for filename in pfile:lines() do
        i = i + 1
	t[i] = filename
    end
	pfile:close()

   return t
end

Auction.Option = function(pid)
      if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
         if BotOn == true then
            Auction.Bot(pid)
         end
	 Players[pid].currentCustomMenu = "Select"
         menuHelper.DisplayMenu(pid, Players[pid].currentCustomMenu)
      end
end

Auction.Buy = function(pid)
   if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
      local directory = tes3mp.GetDataPath() .. "/Auction/"
      local Files = getFiles(directory)
      local items = ""
      local data = {}
      Selling = {}
      Buying = {}

        for _,fileName in pairs(Files) do
            local NoFileExtension = fileName:split(".")
            local fileName = NoFileExtension[1]

          if (fileName == "BotItems") then
             -- tes3mp.LogMessage(3, "Gandalf: You Shall Not Pass!!!")
          else
            data = jsonInterface.load("Auction/" .. fileName .. ".json")
            if data ~= nil then
              for index, Items in pairs(data) do
                  for k,v in pairs(Items) do
                      table.insert(Buying, {Player = fileName, Name = v.Name, Price = v['2']})
                      table.insert(Selling, {Player = fileName, Name = Auction.GetName(v.Name), Price = v['2']}) 
                  end
              end
          end
        end
     end
       for i=1,#Selling do
           items = items .. "(" .. Selling[i].Player .. ")" ..  "[" .. Selling[i].Name .. "]".. " G" .. Selling[i].Price.."\n"
       end
   tes3mp.ListBox(pid, GuI, "Auction House", items)          
  end
end

Auction.Sell = function(pid)
      if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
         local CheckLimit = Auction.CheckLimit(pid)
         if CheckLimit == true then
            return tes3mp.MessageBox(pid, -1,"The Auction is Full at the moment!!")
         end
         local Pi = Players[pid]
         local Full = ""
         BaseItemName = {}
         local ItemList = ""
         Auction.Check(pid)
               for index, currentItem in pairs(Pi.data.inventory) do
                   for k,v in pairs(currentItem) do
                       if k == "refId" then
                          Full = Auction.GetName(v)
                             if Full ~= nil then
                                table.insert(BaseItemName, {Name = v})
                                ItemList = ItemList .. Full .. "\n"
                             end
                       end
                   end
               end 
              tes3mp.ListBox(pid, SGuI, "Inventory", ItemList)
       end
end


customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
    local isValid = eventStatus.validDefaultHandler
    if isValid ~= false then
        if idGui == SGuI then
           if data ~= nil then
             if tonumber(data) >= 0 then
                if tonumber(data) <= 1000 then
                   INum = tonumber(data)
                   return Auction.ShowInp(pid)
                end
             end
           end
        end
        if idGui == IGuI then
           if data ~= nil then
              SellValue = tonumber(data)
              if SellValue == nil then
                 tes3mp.MessageBox(pid, -1, "You can only post numbers!")
                 return
              else
                 return Auction.SaveItem(pid)
              end
           end
        end
        if idGui == GuI then
             if data ~= nil then
                if tonumber(data) <= 500 then
                   Iname = tonumber(data)
                   return Auction.BuyItem(pid)
                end
             end
        end
    end
end)

Auction.ShowInp = function(pid)
     tes3mp.InputDialog(pid, IGuI, "How Much Gold?","Enter the amount of gold")
end

Auction.BuyItem = function(pid)
      if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
         local In = 1
         local LoadItem
         local Iname = Iname + 1
               for i=1,#Buying do
                   if In == Iname then
                      local BP = Buying[In].Player
                      local P = tonumber(Buying[In].Price)
                      local ReF = Buying[In].Name
                      local G = Auction.GoldGetAmount(pid)
                      if G >= P then
                         G = G - P
                         Auction.GoldSetAmount(pid, G)
                         inventoryHelper.addItem(Players[pid].data.inventory, ReF, 1)
                         tes3mp.MessageBox(pid, -1, "You have purchased item!")
                         LoadItem = jsonInterface.load("Auction/" .. BP .. ".json")
                         table.remove(LoadItem.Items, In)
                         jsonInterface.save("Auction/" .. BP .. ".json", LoadItem)
                         Players[pid]:LoadInventory()
                         Players[pid]:LoadEquipment()
                         Players[pid]:LoadQuickKeys()
                         Players[pid]:LoadSpellbook()
                         Auction.addGold(BP, P)
                         tes3mp.LogMessage(3, Players[pid].name .. " Bought Item " .. ReF .. " for " .. "(" .. P .. ")" .. "Gold")
                         return
                      else
                         tes3mp.MessageBox(pid, -1, "You Lack the Needed Gold for that item!")
                         return
                      end          
                   end
                 In = In + 1
               end
     end
end

Auction.SaveItem = function(pid)
      if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
         local playerName = Players[pid].name
         local Play = Players[pid]
         local Ind = 0

         iList = jsonInterface.load("Auction/" .. playerName .. ".json")
         if iList.Items == nil then
            iList.Items = {}
         end    
             for k,v in pairs(BaseItemName) do
                 if Ind == INum then
                    table.insert(iList.Items, v)
                    tableHelper.insertValues(v, {Player = playerName}, true)
                    tableHelper.insertValues(v, {Price = SellValue}, true)
                    inventoryHelper.removeExactItem(Play.data.inventory, v.Name, 1)
                    local MsgName = v.Name
                    tes3mp.MessageBox(pid, -1, MsgName .. " Has been posted and taken")
                    Play:LoadInventory()
                    Play:LoadEquipment()
                    Play:LoadQuickKeys()
                    Play:LoadSpellbook()
                    tes3mp.LogMessage(3, playerName .. " Posted Item " .. MsgName .. " for " .. "(" .. SellValue .. ")" .. "Gold")
                 end
                Ind = Ind + 1
              end
           jsonInterface.save("Auction/" .. playerName .. ".json", iList)
      end
end

Auction.Bot = function(pid)
     if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        local BotI = {}
        local ANumber
        local rand
         if (Auction.CheckLimit() == nil) or (Auction.CheckLimit() == 0) then
           BotItems = jsonInterface.load("Auction/BotItems.json")
           if BotI.Items == nil then
              BotI.Items = {}
           end 
             if BotItems ~= nil then
                if RandomizeBotItems == true then
                   for index, B in pairs(BotItems.Items) do
                       ANumber = index
                   end
                       for i=1, BotPostLimit do
                           rand = math.random(ANumber)
                           table.insert(BotI.Items, BotItems.Items[rand])
                      end
                      jsonInterface.save("Auction/Bot.json", BotI)
                      return
                else
                   for index, Bot in pairs(BotItems.Items) do
                       for k,v in pairs(Bot) do
                           print(k, v)
                           if k ~= nil then
                              tableHelper.insertValues(BotItems.Items, {Price = v['2'], Player = v['1'], Player = v.Name}, true)
                           end
                       end
                   end 
                 jsonInterface.save("Auction/Bot.json", BotItems)
                 return
               end
            end
         end
      end
end


Auction.Check = function(pid)
         local dir = tes3mp.GetDataPath() .. "/Auction/"
         local playerName = Players[pid].name
         if tes3mp.DoesFilePathExist(dir .. playerName .. ".json") == true then
            return
         else
            local save = {}
            jsonInterface.save("Auction/" .. playerName .. ".json", save)
            return
         end
end

Auction.CheckLimit = function(pid)
         local directory = tes3mp.GetDataPath() .. "/Auction/"
         local Files = getFiles(directory)
         local Iter = 0
         local Itm
         

        for _,fileName in pairs(Files) do
            local NoFileExtension = fileName:split(".")
            local fileName = NoFileExtension[1]

          if (fileName == "BotItems") then
             -- tes3mp.LogMessage(3, "Gandalf: You Shall Not Pass!!!")
          else
            dat = jsonInterface.load("Auction/" .. fileName .. ".json")
            if dat ~= nil then
              for index, Itm in pairs(dat) do
                  for k,v in pairs(Itm) do
                      for k,v in pairs(v) do
                          if k == "Name" then
                             Iter = Iter + 1
                             if Iter >= PostItemLimit then
                                return true
                             end
                          end          
                      end
                  end
              end
           end
        end
     end
   return Iter
end

Auction.GoldGetAmount = function(pid)
    local goldIndex

    if tableHelper.containsKeyValue(Players[pid].data.inventory, "refId", "gold_001", true) then
        goldIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.inventory, "refId", "gold_001")

        return Players[pid].data.inventory[goldIndex].count
    end

    return 0
end

Auction.GoldSetAmount = function(pid, gold)
    local goldIndex

    if tableHelper.containsKeyValue(Players[pid].data.inventory, "refId", "gold_001", true) then
        goldIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.inventory, "refId", "gold_001")

        Players[pid].data.inventory[goldIndex].count = gold
        Players[pid]:Save()
        Players[pid]:LoadInventory()
        Players[pid]:LoadEquipment()
    end
end

Auction.name2pid = function(name)
	local name = name:lower()
	for pid,_ in pairs(Players) do
		if string.lower(Players[pid].accountName) == name then
			return pid
		end
	end
	return nil
end

Auction.addGold = function(name, amount)
    if name == "Bot" then
       return
    end
    local pid = Auction.name2pid(name)
    local accountFile = ""
    local player = {}
    if pid == nil then -- if the player isn't logged in 
        player = Auction.fakePlayer(name)
    else
        player = logicHandler.GetPlayerByName(name) --tecnicaly you can use this for offline players aswell but the save function doesn't work see: https://github.com/TES3MP/CoreScripts/pull/73
    end
    

	local goldLoc = inventoryHelper.getItemIndex(player.data.inventory, "gold_001", -1) --get the location of gold in the players inventory
	
	if goldLoc then --if the player already has gold in there inventory
		player.data.inventory[goldLoc].count = player.data.inventory[goldLoc].count + amount --add the new gold onto his already existing stack
	else
		table.insert(player.data.inventory, {refId = "gold_001", count = amount, charge = -1}) --create a new stack of gold
    end
    
    
    player:Save()
    if pid ~= nil then --if the player is online
        player:LoadInventory()
        player:LoadEquipment()
        player:LoadQuickKeys()
        tes3mp.MessageBox(pid, -1, "You have sold an item for " .. amount .. "Gold")
    end
end

Auction.fakePlayer = function(name)
    local player = {}
    local accountName = fileHelper.fixFilename(name)
    player.accountFile = tes3mp.GetCaseInsensitiveFilename(tes3mp.GetModDir() .. "/player/", accountName .. ".json")

    if player.accountFile == "invalid" then
        tes3mp.LogMessage(enumerations.log.WARNING, "[Marketplace] WARNING fakePlayer called with invalid name!")
        return
    end

    player.data = jsonInterface.load("player/" .. player.accountFile)

    function player:Save()
        local config = require("config")
        jsonInterface.save("player/" .. self.accountFile, self.data, config.playerKeyOrder)
    end

    return player
end



Auction.GetName = function(v)
if (v == "potion_ancient_brandy")
 then v = "Ancient Dagoth Brandy" return v 
elseif (v == "p_disease_resistance_b")
 then v = "Bargain Disease Resistance" return v 
elseif (v == "p_fire_resistance_b")
 then v = "Bargain Fire Resistance" return v 
elseif (v == "p_fortify_agility_b")
 then v = "Bargain Fortify Agility" return v 
elseif (v == "p_fortify_endurance_b")
 then v = "Bargain Fortify Endurance" return v 
elseif (v == "p_fortify_fatigue_b")
 then v = "Bargain Fortify Fatigue" return v 
elseif (v == "p_fortify_health_b")
 then v = "Bargain Fortify Health Potion" return v 
elseif (v == "p_fortify_intelligence_b")
 then v = "Bargain Fortify Intelligence" return v 
elseif (v == "p_fortify_magicka_b")
 then v = "Bargain Fortify Magicka" return v 
elseif (v == "p_fortify_personality_b")
 then v = "Bargain Fortify Personality" return v 
elseif (v == "p_fortify_strength_b")
 then v = "Bargain Fortify Strength" return v 
elseif (v == "p_fortify_willpower_b")
 then v = "Bargain Fortify Willpower" return v 
elseif (v == "p_frost_resistance_b")
 then v = "Bargain Frost Resistance" return v 
elseif (v == "p_lightning shield_b")
 then v = "Bargain Lightning Shield" return v 
elseif (v == "p_magicka_resistance_b")
 then v = "Bargain Magicka Resistance" return v 
elseif (v == "p_poison_resistance_b")
 then v = "Bargain Poison Resistance" return v 
elseif (v == "p_burden_b")
 then v = "Bargain Potion of Burden" return v 
elseif (v == "p_feather_b")
 then v = "Bargain Potion of Feather" return v 
elseif (v == "p_fire_shield_b")
 then v = "Bargain Potion of Fire Shield" return v 
elseif (v == "p_fortify_luck_b")
 then v = "Bargain Potion of Fortify Luck" return v 
elseif (v == "p_fortify_speed_b")
 then v = "Bargain Potion of Fortify Speed" return v 
elseif (v == "p_frost_shield_b")
 then v = "Bargain Potion of Frost Shield" return v 
elseif (v == "p_invisibility_b")
 then v = "Bargain Potion of Invisibility" return v 
elseif (v == "p_jump_b")
 then v = "Bargain Potion of Jump" return v 
elseif (v == "p_light_b")
 then v = "Bargain Potion of Light" return v 
elseif (v == "p_night-eye_b")
 then v = "Bargain Potion of Night-Eye" return v 
elseif (v == "p_paralyze_b")
 then v = "Bargain Potion of Paralyze" return v 
elseif (v == "p_reflection_b")
 then v = "Bargain Potion of Reflection" return v 
elseif (v == "p_chameleon_b")
 then v = "Bargain Potion of Shadow" return v 
elseif (v == "p_silence_b")
 then v = "Bargain Potion of Silence" return v 
elseif (v == "p_swift_swim_b")
 then v = "Bargain Potion of Swift Swim" return v 
elseif (v == "p_restore_agility_b")
 then v = "Bargain Restore Agility" return v 
elseif (v == "p_restore_endurance_b")
 then v = "Bargain Restore Endurance" return v 
elseif (v == "p_restore_fatigue_b")
 then v = "Bargain Restore Fatigue" return v 
elseif (v == "p_restore_health_b")
 then v = "Bargain Restore Health" return v 
elseif (v == "p_restore_intelligence_b")
 then v = "Bargain Restore Intelligence" return v 
elseif (v == "p_restore_luck_b")
 then v = "Bargain Restore Luck" return v 
elseif (v == "p_restore_magicka_b")
 then v = "Bargain Restore Magicka" return v 
elseif (v == "p_restore_personality_b")
 then v = "Bargain Restore Personality" return v 
elseif (v == "p_restore_speed_b")
 then v = "Bargain Restore Speed" return v 
elseif (v == "p_restore_strength_b")
 then v = "Bargain Restore Strength" return v 
elseif (v == "p_restore_willpower_b")
 then v = "Bargain Restore Willpower" return v 
elseif (v == "p_levitation_b")
 then v = "Bargain Rising Force Potion" return v 
elseif (v == "p_shock_resistance_b")
 then v = "Bargain Shock Resistance" return v 
elseif (v == "p_spell_absorption_b")
 then v = "Bargain Spell Absorption" return v 
elseif (v == "p_quarrablood_UNIQUE")
 then v = "Blood of the Quarra Masters" return v 
elseif (v == "p_disease_resistance_c")
 then v = "Cheap Disease Resistance" return v 
elseif (v == "p_fire_resistance_c")
 then v = "Cheap Fire Resistance" return v 
elseif (v == "p_fortify_agility_c")
 then v = "Cheap Fortify Agility" return v 
elseif (v == "p_fortify_endurance_c")
 then v = "Cheap Fortify Endurance" return v 
elseif (v == "p_fortify_fatigue_c")
 then v = "Cheap Fortify Fatigue" return v 
elseif (v == "p_fortify_intelligence_c")
 then v = "Cheap Fortify Intelligence" return v 
elseif (v == "p_fortify_personality_c")
 then v = "Cheap Fortify Personality" return v 
elseif (v == "p_fortify_strength_c")
 then v = "Cheap Fortify Strength" return v 
elseif (v == "p_fortify_willpower_c")
 then v = "Cheap Fortify Willpower" return v 
elseif (v == "p_frost_resistance_c")
 then v = "Cheap Frost Resistance" return v 
elseif (v == "p_lightning shield_c")
 then v = "Cheap Lightning Shield" return v 
elseif (v == "p_magicka_resistance_c")
 then v = "Cheap Magicka Resistance" return v 
elseif (v == "p_poison_resistance_c")
 then v = "Cheap Poison Resistance" return v 
elseif (v == "p_burden_c")
 then v = "Cheap Potion of Burden" return v 
elseif (v == "p_feather_c")
 then v = "Cheap Potion of Feather" return v 
elseif (v == "p_fire_shield_c")
 then v = "Cheap Potion of Fire Shield" return v 
elseif (v == "p_fortify_health_c")
 then v = "Cheap Potion of Fortify Health" return v 
elseif (v == "p_fortify_luck_c")
 then v = "Cheap Potion of Fortify Luck" return v 
elseif (v == "p_fortify_magicka_c")
 then v = "Cheap Potion of Fortify Magicka" return v 
elseif (v == "p_fortify_speed_c")
 then v = "Cheap Potion of Fortify Speed" return v 
elseif (v == "p_frost_shield_c")
 then v = "Cheap Potion of Frost Shield" return v 
elseif (v == "p_invisibility_c")
 then v = "Cheap Potion of Invisibility" return v 
elseif (v == "p_jump_c")
 then v = "Cheap Potion of Jump" return v 
elseif (v == "p_light_c")
 then v = "Cheap Potion of Light" return v 
elseif (v == "p_night-eye_c")
 then v = "Cheap Potion of Night-Eye" return v 
elseif (v == "p_paralyze_c")
 then v = "Cheap Potion of Paralyze" return v 
elseif (v == "p_reflection_c")
 then v = "Cheap Potion of Reflection" return v 
elseif (v == "p_chameleon_c")
 then v = "Cheap Potion of Shadow" return v 
elseif (v == "p_silence_c")
 then v = "Cheap Potion of Silence" return v 
elseif (v == "p_swift_swim_c")
 then v = "Cheap Potion of Swift Swim" return v 
elseif (v == "p_restore_agility_c")
 then v = "Cheap Restore Agility" return v 
elseif (v == "p_restore_endurance_c")
 then v = "Cheap Restore Endurance" return v 
elseif (v == "p_restore_fatigue_c")
 then v = "Cheap Restore Fatigue" return v 
elseif (v == "p_restore_health_c")
 then v = "Cheap Restore Health" return v 
elseif (v == "p_restore_intelligence_c")
 then v = "Cheap Restore Intelligence" return v 
elseif (v == "p_restore_luck_c")
 then v = "Cheap Restore Luck" return v 
elseif (v == "p_restore_magicka_c")
 then v = "Cheap Restore Magicka" return v 
elseif (v == "p_restore_personality_c")
 then v = "Cheap Restore Personality" return v 
elseif (v == "p_restore_speed_c")
 then v = "Cheap Restore Speed" return v 
elseif (v == "p_restore_strength_c")
 then v = "Cheap Restore Strength" return v 
elseif (v == "p_restore_willpower_c")
 then v = "Cheap Restore Willpower" return v 
elseif (v == "p_levitation_c")
 then v = "Cheap Rising Force Potion" return v 
elseif (v == "p_shock_resistance_c")
 then v = "Cheap Shock Resistance" return v 
elseif (v == "p_spell_absorption_c")
 then v = "Cheap Spell Absorption" return v 
elseif (v == "potion_cyro_brandy_01")
 then v = "Cyrodiilic Brandy" return v 
elseif (v == "p_disease_resistance_e")
 then v = "Exclusive Disease Resistance" return v 
elseif (v == "p_fire_resistance_e")
 then v = "Exclusive Fire Resistance" return v 
elseif (v == "p_fortify_agility_e")
 then v = "Exclusive Fortify Agility" return v 
elseif (v == "p_fortify_attack_e")
 then v = "Exclusive Fortify Attack" return v 
elseif (v == "p_fortify_endurance_e")
 then v = "Exclusive Fortify Endurance" return v 
elseif (v == "p_fortify_fatigue_e")
 then v = "Exclusive Fortify Fatigue" return v 
elseif (v == "p_fortify_health_e")
 then v = "Exclusive Fortify Health" return v 
elseif (v == "p_fortify_intelligence_e")
 then v = "Exclusive Fortify Intelligence" return v 
elseif (v == "p_fortify_luck_e")
 then v = "Exclusive Fortify Luck" return v 
elseif (v == "p_fortify_magicka_e")
 then v = "Exclusive Fortify Magicka" return v 
elseif (v == "p_fortify_personality_e")
 then v = "Exclusive Fortify Personality" return v 
elseif (v == "p_fortify_speed_e")
 then v = "Exclusive Fortify Speed" return v 
elseif (v == "p_fortify_strength_e")
 then v = "Exclusive Fortify Strength" return v 
elseif (v == "p_fortify_willpower_e")
 then v = "Exclusive Fortify Willpower" return v 
elseif (v == "p_frost_resistance_e")
 then v = "Exclusive Frost Resistance" return v 
elseif (v == "p_frost_shield_e")
 then v = "Exclusive Frost Shield" return v 
elseif (v == "p_invisibility_e")
 then v = "Exclusive Invisibility" return v 
elseif (v == "p_lightning shield_e")
 then v = "Exclusive Lightning Shield" return v 
elseif (v == "p_magicka_resistance_e")
 then v = "Exclusive Magicka Resistance" return v 
elseif (v == "p_poison_resistance_e")
 then v = "Exclusive Poison Resistance" return v 
elseif (v == "p_burden_e")
 then v = "Exclusive Potion of Burden" return v 
elseif (v == "p_feather_e")
 then v = "Exclusive Potion of Feather" return v 
elseif (v == "p_fire_shield_e")
 then v = "Exclusive Potion of Fire Shield" return v 
elseif (v == "p_jump_e")
 then v = "Exclusive Potion of Jump" return v 
elseif (v == "p_light_e")
 then v = "Exclusive Potion of Light" return v 
elseif (v == "p_night-eye_e")
 then v = "Exclusive Potion of Night-Eye" return v 
elseif (v == "p_paralyze_e")
 then v = "Exclusive Potion of Paralyze" return v 
elseif (v == "p_reflection_e")
 then v = "Exclusive Potion of Reflection" return v 
elseif (v == "p_chameleon_e")
 then v = "Exclusive Potion of Shadow" return v 
elseif (v == "p_silence_e")
 then v = "Exclusive Potion of Silence" return v 
elseif (v == "p_swift_swim_e")
 then v = "Exclusive Potion of Swift Swim" return v 
elseif (v == "p_restore_agility_e")
 then v = "Exclusive Restore Agility" return v 
elseif (v == "p_restore_endurance_e")
 then v = "Exclusive Restore Endurance" return v 
elseif (v == "p_restore_fatigue_e")
 then v = "Exclusive Restore Fatigue" return v 
elseif (v == "p_restore_health_e")
 then v = "Exclusive Restore Health" return v 
elseif (v == "p_restore_intelligence_e")
 then v = "Exclusive Restore Intelligence" return v 
elseif (v == "p_restore_luck_e")
 then v = "Exclusive Restore Luck" return v 
elseif (v == "p_restore_magicka_e")
 then v = "Exclusive Restore Magicka" return v 
elseif (v == "p_restore_personality_e")
 then v = "Exclusive Restore Personality" return v 
elseif (v == "p_restore_speed_e")
 then v = "Exclusive Restore Speed" return v 
elseif (v == "p_restore_strength_e")
 then v = "Exclusive Restore Strength" return v 
elseif (v == "p_restore_willpower_e")
 then v = "Exclusive Restore Willpower" return v 
elseif (v == "p_levitation_e")
 then v = "Exclusive Rising Force Potion" return v 
elseif (v == "p_shock_resistance_e")
 then v = "Exclusive Shock Resistance" return v 
elseif (v == "p_spell_absorption_e")
 then v = "Exclusive Spell Absorption" return v 
elseif (v == "Potion_Cyro_Whiskey_01")
 then v = "Flin" return v 
elseif (v == "potion_comberry_brandy_01")
 then v = "Greef" return v 
elseif (v == "p_lovepotion_unique")
 then v = "Love Potion" return v 
elseif (v == "Potion_Local_Brew_01")
 then v = "Mazte" return v 
elseif (v == "p_cure_blight_s")
 then v = "Potion of Cure Blight Disease" return v 
elseif (v == "p_cure_common_s")
 then v = "Potion of Cure Common Disease" return v 
elseif (v == "p_cure_paralyzation_s")
 then v = "Potion of Cure Paralyzation" return v 
elseif (v == "p_cure_poison_s")
 then v = "Potion of Cure Poison" return v 
elseif (v == "p_detect_creatures_s")
 then v = "Potion of Detect Creatures" return v 
elseif (v == "p_detect_enchantment_s")
 then v = "Potion of Detect Enchantments" return v 
elseif (v == "p_detect_key_s")
 then v = "Potion of Detect Key" return v 
elseif (v == "p_dispel_s")
 then v = "Potion of Dispel" return v 
elseif (v == "p_almsivi_intervention_s")
 then v = "Potion of Fool's Luck" return v 
elseif (v == "p_heroism_s")
 then v = "Potion of Heroism" return v 
elseif (v == "p_mark_s")
 then v = "Potion of Marking" return v 
elseif (v == "p_recall_s")
 then v = "Potion of Recall" return v 
elseif (v == "p_slowfall_s")
 then v = "Potion of Slowfalling" return v 
elseif (v == "p_telekinesis_s")
 then v = "Potion of Telekinesis" return v 
elseif (v == "p_water_breathing_s")
 then v = "Potion of Water Breathing" return v 
elseif (v == "p_water_walking_s")
 then v = "Potion of Water Walking" return v 
elseif (v == "p_disease_resistance_q")
 then v = "Quality Disease Resistance" return v 
elseif (v == "p_fire_resistance_q")
 then v = "Quality Fire Resistance" return v 
elseif (v == "p_fortify_agility_q")
 then v = "Quality Fortify Agility" return v 
elseif (v == "p_fortify_endurance_q")
 then v = "Quality Fortify Endurance" return v 
elseif (v == "p_fortify_fatigue_q")
 then v = "Quality Fortify Fatigue" return v 
elseif (v == "p_fortify_health_q")
 then v = "Quality Fortify Health" return v 
elseif (v == "p_fortify_intelligence_q")
 then v = "Quality Fortify Intelligence" return v 
elseif (v == "p_fortify_magicka_q")
 then v = "Quality Fortify Magicka" return v 
elseif (v == "p_fortify_personality_q")
 then v = "Quality Fortify Personality" return v 
elseif (v == "p_fortify_strength_q")
 then v = "Quality Fortify Strength" return v 
elseif (v == "p_fortify_willpower_q")
 then v = "Quality Fortify Willpower" return v 
elseif (v == "p_frost_resistance_q")
 then v = "Quality Frost Resistance" return v 
elseif (v == "p_frost_shield_q")
 then v = "Quality Frost Shield" return v 
elseif (v == "p_lightning shield_q")
 then v = "Quality Lightning Shield" return v 
elseif (v == "p_magicka_resistance_q")
 then v = "Quality Magicka Resistance" return v 
elseif (v == "p_poison_resistance_q")
 then v = "Quality Poison Resistance" return v 
elseif (v == "p_burden_q")
 then v = "Quality Potion of Burden" return v 
elseif (v == "p_feather_q")
 then v = "Quality Potion of Feather" return v 
elseif (v == "p_fire_shield_q")
 then v = "Quality Potion of Fire Shield" return v 
elseif (v == "p_fortify_luck_q")
 then v = "Quality Potion of Fortify Luck" return v 
elseif (v == "p_fortify_speed_q")
 then v = "Quality Potion of Fortify Speed" return v 
elseif (v == "p_invisibility_q")
 then v = "Quality Potion of Invisibility" return v 
elseif (v == "p_jump_q")
 then v = "Quality Potion of Jump" return v 
elseif (v == "p_light_q")
 then v = "Quality Potion of Light" return v 
elseif (v == "p_night-eye_q")
 then v = "Quality Potion of Night-Eye" return v 
elseif (v == "p_paralyze_q")
 then v = "Quality Potion of Paralyze" return v 
elseif (v == "p_reflection_q")
 then v = "Quality Potion of Reflection" return v 
elseif (v == "p_chameleon_q")
 then v = "Quality Potion of Shadow" return v 
elseif (v == "p_silence_q")
 then v = "Quality Potion of Silence" return v 
elseif (v == "p_swift_swim_q")
 then v = "Quality Potion of Swift Swim" return v 
elseif (v == "p_restore_agility_q")
 then v = "Quality Restore Agility" return v 
elseif (v == "p_restore_endurance_q")
 then v = "Quality Restore Endurance" return v 
elseif (v == "p_restore_fatigue_q")
 then v = "Quality Restore Fatigue" return v 
elseif (v == "p_restore_health_q")
 then v = "Quality Restore Health" return v 
elseif (v == "p_restore_intelligence_q")
 then v = "Quality Restore Intelligence" return v 
elseif (v == "p_restore_luck_q")
 then v = "Quality Restore Luck" return v 
elseif (v == "p_restore_magicka_q")
 then v = "Quality Restore Magicka" return v 
elseif (v == "p_restore_personality_q")
 then v = "Quality Restore Personality" return v 
elseif (v == "p_restore_speed_q")
 then v = "Quality Restore Speed" return v 
elseif (v == "p_restore_strength_q")
 then v = "Quality Restore Strength" return v 
elseif (v == "p_restore_willpower_q")
 then v = "Quality Restore Willpower" return v 
elseif (v == "P_Levitation_Q")
 then v = "Quality Rising Force Potion" return v 
elseif (v == "p_shock_resistance_q")
 then v = "Quality Shock Resistance" return v 
elseif (v == "p_spell_absorption_q")
 then v = "Quality Spell Absorption" return v 
elseif (v == "potion_comberry_wine_01")
 then v = "Shein" return v 
elseif (v == "p_sinyaramen_UNIQUE")
 then v = "Sinyaramen's Potion" return v 
elseif (v == "potion_skooma_01")
 then v = "Skooma" return v 
elseif (v == "p_drain_luck_q")
 then v = "Spoiled Cure Disease Potion" return v 
elseif (v == "p_drain_strength_q")
 then v = "Spoiled Cure Disease Potion" return v 
elseif (v == "p_drain willpower_q")
 then v = "Spoiled Cure Disease Potion" return v 
elseif (v == "p_drain_magicka_q")
 then v = "Spoiled Cure Poison Potion" return v 
elseif (v == "p_drain_speed_q")
 then v = "Spoiled Cure Poison Potion" return v 
elseif (v == "p_drain_intelligence_q")
 then v = "Spoiled Potion of Swift Swim" return v 
elseif (v == "p_drain_personality_q")
 then v = "Spoiled Potion of Swift Swim" return v 
elseif (v == "p_drain_agility_q")
 then v = "Spoiled SlowFall Potion" return v 
elseif (v == "p_drain_endurance_q")
 then v = "Spoiled SlowFall Potion" return v 
elseif (v == "p_disease_resistance_s")
 then v = "Standard Disease Resistance" return v 
elseif (v == "p_fire resistance_s")
 then v = "Standard Fire Resistance" return v 
elseif (v == "p_fortify_agility_s")
 then v = "Standard Fortify Agility Potion" return v 
elseif (v == "p_fortify_endurance_s")
 then v = "Standard Fortify Endurance" return v 
elseif (v == "p_fortify_fatigue_s")
 then v = "Standard Fortify Fatigue Potion" return v 
elseif (v == "p_fortify_health_s")
 then v = "Standard Fortify Health Potion" return v 
elseif (v == "p_fortify_intelligence_s")
 then v = "Standard Fortify Intelligence" return v 
elseif (v == "p_fortify_luck_s")
 then v = "Standard Fortify Luck Potion" return v 
elseif (v == "p_fortify_magicka_s")
 then v = "Standard Fortify Magicka Potion" return v 
elseif (v == "p_fortify_personality_s")
 then v = "Standard Fortify Personality" return v 
elseif (v == "p_fortify_speed_s")
 then v = "Standard Fortify Speed" return v 
elseif (v == "p_fortify_strength_s")
 then v = "Standard Fortify Strength" return v 
elseif (v == "p_fortify_willpower_s")
 then v = "Standard Fortify Willpower" return v 
elseif (v == "p_lightning shield_s")
 then v = "Standard Lightning Shield" return v 
elseif (v == "p_magicka_resistance_s")
 then v = "Standard Magicka Resistance" return v 
elseif (v == "p_poison_resistance_s")
 then v = "Standard Poison Resistance" return v 
elseif (v == "p_burden_s")
 then v = "Standard Potion of Burden" return v 
elseif (v == "p_fire_shield_s")
 then v = "Standard Potion of Fire Shield" return v 
elseif (v == "p_frost_shield_s")
 then v = "Standard Potion of Frost Shield" return v 
elseif (v == "p_invisibility_s")
 then v = "Standard Potion of Invisibility" return v 
elseif (v == "p_jump_s")
 then v = "Standard Potion of Jump" return v 
elseif (v == "p_light_s")
 then v = "Standard Potion of Light" return v 
elseif (v == "p_night-eye_s")
 then v = "Standard Potion of Night-Eye" return v 
elseif (v == "p_paralyze_s")
 then v = "Standard Potion of Paralyze" return v 
elseif (v == "p_reflection_s")
 then v = "Standard Potion of Reflection" return v 
elseif (v == "p_restore_luck_s")
 then v = "Standard Potion of Restore Luck" return v 
elseif (v == "p_chameleon_s")
 then v = "Standard Potion of Shadow" return v 
elseif (v == "p_silence_s")
 then v = "Standard Potion of Silence" return v 
elseif (v == "p_frost_resistance_s")
 then v = "Standard Resist Frost Potion" return v 
elseif (v == "p_restore_agility_s")
 then v = "Standard Restore Agility" return v 
elseif (v == "p_restore_endurance_s")
 then v = "Standard Restore Endurance" return v 
elseif (v == "p_restore_fatigue_s")
 then v = "Standard Restore Fatigue" return v 
elseif (v == "p_restore_health_s")
 then v = "Standard Restore Health Potion" return v 
elseif (v == "p_restore_intelligence_s")
 then v = "Standard Restore Intelligence" return v 
elseif (v == "p_restore_magicka_s")
 then v = "Standard Restore Magicka Potion" return v 
elseif (v == "p_restore_personality_s")
 then v = "Standard Restore Personality" return v 
elseif (v == "p_restore_speed_s")
 then v = "Standard Restore Speed" return v 
elseif (v == "p_restore_strength_s")
 then v = "Standard Restore Strength" return v 
elseif (v == "p_restore_willpower_s")
 then v = "Standard Restore Willpower" return v 
elseif (v == "p_levitation_s")
 then v = "Standard Rising Force Potion" return v 
elseif (v == "p_shock_resistance_s")
 then v = "Standard Shock Resistance" return v 
elseif (v == "p_spell_absorption_s")
 then v = "Standard Spell Absorption" return v 
elseif (v == "potion_local_liquor_01")
 then v = "Sujamma" return v 
elseif (v == "potion_t_bug_musk_01")
 then v = "Telvanni Bug Musk" return v 
elseif (v == "p_cure_common_unique")
 then v = "Trebonius' Potion of Curing" return v 
elseif (v == "p_vintagecomberrybrandy1")
 then v = "Vintage Brandy" return v 
elseif (v == "apparatus_a_alembic_01")
 then v = "Apprentice's Alembic" return v 
elseif (v == "apparatus_a_calcinator_01")
 then v = "Apprentice's Calcinator" return v 
elseif (v == "apparatus_a_mortar_01")
 then v = "Apprentice's Mortar and Pestle" return v 
elseif (v == "apparatus_a_retort_01")
 then v = "Apprentice's Retort" return v 
elseif (v == "apparatus_a_spipe_01")
 then v = "Good Skooma Pipe" return v 
elseif (v == "apparatus_g_alembic_01")
 then v = "Grandmaster's Alembic" return v 
elseif (v == "apparatus_g_calcinator_01")
 then v = "Grandmaster's Calcinator" return v 
elseif (v == "apparatus_g_mortar_01")
 then v = "Grandmaster's Mortar and Pestle" return v 
elseif (v == "apparatus_g_retort_01")
 then v = "Grandmaster's Retort" return v 
elseif (v == "apparatus_j_alembic_01")
 then v = "Journeyman's Alembic" return v 
elseif (v == "apparatus_j_calcinator_01")
 then v = "Journeyman's Calcinator" return v 
elseif (v == "apparatus_j_mortar_01")
 then v = "Journeyman's Mortar and Pestle" return v 
elseif (v == "apparatus_j_retort_01")
 then v = "Journeyman's Retort" return v 
elseif (v == "apparatus_m_alembic_01")
 then v = "Master's Alembic" return v 
elseif (v == "apparatus_m_calcinator_01")
 then v = "Master's Calcinator" return v 
elseif (v == "apparatus_m_mortar_01")
 then v = "Master's Mortar and Pestle" return v 
elseif (v == "apparatus_m_retort_01")
 then v = "Master's Retort" return v 
elseif (v == "apparatus_sm_alembic_01")
 then v = "SecretMaster's Alembic" return v 
elseif (v == "apparatus_sm_calcinator_01")
 then v = "SecretMaster's Calcinator" return v 
elseif (v == "apparatus_sm_mortar_01")
 then v = "SecretMaster's Mortar and Pestl" return v 
elseif (v == "apparatus_sm_retort_01")
 then v = "SecretMaster's Retort" return v 
elseif (v == "apparatus_a_spipe_tsiya")
 then v = "Tsiya's Skooma Pipe" return v 
elseif (v == "bonemold_armun-an_cuirass")
 then v = "Armun-An Bonemold Cuirass" return v 
elseif (v == "bonemold_armun-an_pauldron_l")
 then v = "Armun-An Bonemold L Pauldron" return v 
elseif (v == "bonemold_armun-an_pauldron_r")
 then v = "Armun-An Bonemold R Pauldron" return v 
elseif (v == "ebony_shield_auriel")
 then v = "Auriel's Shield" return v 
elseif (v == "azura's servant")
 then v = "Azura's Servant" return v 
elseif (v == "blessed_shield")
 then v = "Blessed Shield" return v 
elseif (v == "blessed_tower_shield")
 then v = "Blessed Tower Shield" return v 
elseif (v == "Blood_Feast_Shield")
 then v = "Blood Feat Shield" return v 
elseif (v == "bloodworm_helm_unique")
 then v = "Bloodworm Helm" return v 
elseif (v == "netch_leather_boiled_cuirass")
 then v = "Boiled Netch Leather Cuirass" return v 
elseif (v == "netch_leather_boiled_helm")
 then v = "Boiled Netch Leather Helm" return v 
elseif (v == "bonedancer gauntlet")
 then v = "Bonedancer Gauntlet" return v 
elseif (v == "bonemold_boots")
 then v = "Bonemold Boots" return v 
elseif (v == "lbonemold brace of horny fist")
 then v = "Bonemold Brace of Horny Fist" return v 
elseif (v == "rbonemold bracer of horny fist")
 then v = "Bonemold Bracer of Horny Fist" return v 
elseif (v == "bonemold_cuirass")
 then v = "Bonemold Cuirass" return v 
elseif (v == "bonemold_greaves")
 then v = "Bonemold Greaves" return v 
elseif (v == "bonemold_helm")
 then v = "Bonemold Helm" return v 
elseif (v == "bonemold_bracer_left")
 then v = "Bonemold Left Bracer" return v 
elseif (v == "bonemold_pauldron_l")
 then v = "Bonemold L Pauldron" return v 
elseif (v == "bonemold_bracer_right")
 then v = "Bonemold Right Bracer" return v 
elseif (v == "bonemold_pauldron_r")
 then v = "Bonemold R Pauldron" return v 
elseif (v == "bonemold_shield")
 then v = "Bonemold Shield" return v 
elseif (v == "bonemold_towershield")
 then v = "Bonemold Tower Shield" return v 
elseif (v == "boneweave gauntlet")
 then v = "Boneweave Gauntlet" return v 
elseif (v == "boots of blinding speed[unique]")
 then v = "Boots of Blinding Speed" return v 
elseif (v == "boots_apostle_unique")
 then v = "Boots of the Apostle" return v 
elseif (v == "bound_helm")
 then v = "Bound_Helm" return v 
elseif (v == "bound_boots")
 then v = "Bound Boots" return v 
elseif (v == "bound_cuirass")
 then v = "Bound Cuirass" return v 
elseif (v == "bound_gauntlet_left")
 then v = "Bound Left Gauntlet" return v 
elseif (v == "bound_gauntlet_right")
 then v = "Bound Right Gauntlet" return v 
elseif (v == "bound_shield")
 then v = "Bound Shield" return v 
elseif (v == "chest of fire")
 then v = "Chest of Fire" return v 
elseif (v == "chitin boots")
 then v = "Chitin Boots" return v 
elseif (v == "chitin cuirass")
 then v = "Chitin Cuirass" return v 
elseif (v == "chitin greaves")
 then v = "Chitin Greaves" return v 
elseif (v == "chitin helm")
 then v = "Chitin Helm" return v 
elseif (v == "chitin guantlet - left")
 then v = "Chitin Left Gauntlet" return v 
elseif (v == "chitin pauldron - left")
 then v = "Chitin Left Pauldron" return v 
elseif (v == "chitin_mask_helm")
 then v = "Chitin Mask Helm" return v 
elseif (v == "chitin guantlet - right")
 then v = "Chitin Right Gauntlet" return v 
elseif (v == "chitin pauldron - right")
 then v = "Chitin Right Pauldron" return v 
elseif (v == "chitin_shield")
 then v = "Chitin Shield" return v 
elseif (v == "chitin_towershield")
 then v = "Chitin Tower Shield" return v 
elseif (v == "cloth bracer left")
 then v = "Cloth Left Bracer" return v 
elseif (v == "cloth bracer right")
 then v = "Cloth Right Bracer" return v 
elseif (v == "fur_colovian_helm")
 then v = "Colovian Fur Helm" return v 
elseif (v == "conoon_chodala_boots_unique")
 then v = "Conoon Chodala's Boots" return v 
elseif (v == "cuirass_savior_unique")
 then v = "Cuirass of the Savior's Hide" return v 
elseif (v == "daedric_boots")
 then v = "Daedric Boots" return v 
elseif (v == "daedric_cuirass")
 then v = "Daedric Cuirass" return v 
elseif (v == "daedric_cuirass_htab")
 then v = "Daedric Cuirass" return v 
elseif (v == "daedric_god_helm")
 then v = "Daedric Face of God" return v 
elseif (v == "daedric_fountain_helm")
 then v = "Daedric Face of Inspiration" return v 
elseif (v == "daedric_terrifying_helm")
 then v = "Daedric Face of Terror" return v 
elseif (v == "daedric_greaves")
 then v = "Daedric Greaves" return v 
elseif (v == "daedric_greaves_htab")
 then v = "Daedric Greaves" return v 
elseif (v == "daedric_gauntlet_left")
 then v = "Daedric Left Gauntlet" return v 
elseif (v == "daedric_pauldron_left")
 then v = "Daedric Left Pauldron" return v 
elseif (v == "daedric_gauntlet_right")
 then v = "Daedric Right Gauntlet" return v 
elseif (v == "daedric_pauldron_right")
 then v = "Daedric Right Pauldron" return v 
elseif (v == "daedric_shield")
 then v = "Daedric Shield" return v 
elseif (v == "daedric_towershield")
 then v = "Daedric Tower Shield" return v 
elseif (v == "darksun_shield_unique")
 then v = "Darksun Shield" return v 
elseif (v == "demon cephalopod")
 then v = "Demon Cephalopod" return v 
elseif (v == "demon helm")
 then v = "Demon Helm" return v 
elseif (v == "demon mole crab")
 then v = "Demon Mole Crab" return v 
elseif (v == "devil cephalopod helm")
 then v = "Devil Cephalopod Helm" return v 
elseif (v == "devil helm")
 then v = "Devil Helm" return v 
elseif (v == "devil mole crab helm")
 then v = "Devil Mole Crab Helm" return v 
elseif (v == "dragonbone_cuirass_unique")
 then v = "Dragonbone cuirass" return v 
elseif (v == "dragonscale_towershield")
 then v = "Dragonscale Tower Shield" return v 
elseif (v == "dreugh_cuirass")
 then v = "Dreugh Cuirass" return v 
elseif (v == "dreugh_cuirass_ttrm")
 then v = "Dreugh Cuirass" return v 
elseif (v == "dreugh_helm")
 then v = "Dreugh Helm" return v 
elseif (v == "dreugh_shield")
 then v = "Dreugh Shield" return v 
elseif (v == "silver_dukesguard_cuirass")
 then v = "Duke's Guard Silver Cuirass" return v 
elseif (v == "dwemer_boots")
 then v = "Dwemer Boots" return v 
elseif (v == "dwemer_boots of flying")
 then v = "Dwemer Boots of Flying" return v 
elseif (v == "dwemer_cuirass")
 then v = "Dwemer Cuirass" return v 
elseif (v == "dwemer_greaves")
 then v = "Dwemer Greaves" return v 
elseif (v == "dwemer_helm")
 then v = "Dwemer Helm" return v 
elseif (v == "dwemer_bracer_left")
 then v = "Dwemer Left Bracer" return v 
elseif (v == "dwemer_pauldron_left")
 then v = "Dwemer Left Pauldron" return v 
elseif (v == "dwemer_bracer_right")
 then v = "Dwemer Right Bracer" return v 
elseif (v == "dwemer_pauldron_right")
 then v = "Dwemer Right Pauldron" return v 
elseif (v == "dwemer_shield")
 then v = "Dwemer Shield" return v 
elseif (v == "ebony_boots")
 then v = "Ebony Boots" return v 
elseif (v == "ebony_closed_helm")
 then v = "Ebony Closed Helm" return v 
elseif (v == "ebony_cuirass")
 then v = "Ebony Cuirass" return v 
elseif (v == "ebony_greaves")
 then v = "Ebony Greaves" return v 
elseif (v == "ebony_bracer_left")
 then v = "Ebony Left Bracer" return v 
elseif (v == "ebony_bracer_left_tgeb")
 then v = "Ebony Left Bracer" return v 
elseif (v == "ebony_pauldron_left")
 then v = "Ebony Left Pauldron" return v 
elseif (v == "ebon_plate_cuirass_unique")
 then v = "Ebony Mail" return v 
elseif (v == "ebony_bracer_right")
 then v = "Ebony Right Bracer" return v 
elseif (v == "ebony_bracer_right_tgeb")
 then v = "Ebony Right Bracer" return v 
elseif (v == "ebony_pauldron_right")
 then v = "Ebony Right Pauldron" return v 
elseif (v == "ebony_shield")
 then v = "Ebony Shield" return v 
elseif (v == "ebony_towershield")
 then v = "Ebony Tower Shield" return v 
elseif (v == "towershield_eleidon_unique")
 then v = "Eleidon's Ward" return v 
elseif (v == "erur_dan_cuirass_unique")
 then v = "Erur-Dan's Cuirass" return v 
elseif (v == "feather_shield")
 then v = "Feather Shield" return v 
elseif (v == "fiend helm")
 then v = "Fiend Helm" return v 
elseif (v == "gauntlet_fists_l_unique")
 then v = "Fist of Randagulf Left Gauntlet" return v 
elseif (v == "gauntlet_fists_r_unique")
 then v = "Fist of Randagulf Rt Gauntlet" return v 
elseif (v == "bonemold_gah-julan_cuirass")
 then v = "Gah-Julan Bonemold Cuirass" return v 
elseif (v == "bonemold_gah-julan_pauldron_l")
 then v = "Gah-Julan Bonemold L Pauldron" return v 
elseif (v == "bonemold_gah-julan_pauldron_r")
 then v = "Gah-Julan Bonemold R Pauldron" return v 
elseif (v == "glass_boots")
 then v = "Glass Boots" return v 
elseif (v == "glass_cuirass")
 then v = "Glass Cuirass" return v 
elseif (v == "glass_greaves")
 then v = "Glass Greaves" return v 
elseif (v == "glass_helm")
 then v = "Glass Helm" return v 
elseif (v == "glass_pauldron_left")
 then v = "Glass Left Pauldron" return v 
elseif (v == "glass_pauldron_right")
 then v = "Glass Right Pauldron" return v 
elseif (v == "glass_shield")
 then v = "Glass Shield" return v 
elseif (v == "glass_towershield")
 then v = "Glass Tower Shield" return v 
elseif (v == "gondolier_helm")
 then v = "Gondolier's Helm" return v 
elseif (v == "cephalopod_helm_HTNK")
 then v = "Gothren's Cephalopod Helm" return v 
elseif (v == "heart wall")
 then v = "Heart Wall" return v 
elseif (v == "heavy_leather_boots")
 then v = "Heavy Leather Boots" return v 
elseif (v == "imperial_helm_frald_uniq")
 then v = "Helm of Graff the White" return v 
elseif (v == "helm of holy fire")
 then v = "Helm of Holy Fire" return v 
elseif (v == "helm_bearclaw_unique")
 then v = "Helm of Oreyn Bearclaw" return v 
elseif (v == "helm of wounding")
 then v = "Helm of Wounding" return v 
elseif (v == "bonemold_tshield_hlaaluguard")
 then v = "Hlaalu Guard Shield" return v 
elseif (v == "holy_shield")
 then v = "Holy Shield" return v 
elseif (v == "holy_tower_shield")
 then v = "Holy Tower Shield" return v 
elseif (v == "imperial_chain_coif_helm")
 then v = "Imperial Chain Coif" return v 
elseif (v == "imperial_chain_cuirass")
 then v = "Imperial Chain Cuirass" return v 
elseif (v == "imperial_chain_greaves")
 then v = "Imperial Chain Greaves" return v 
elseif (v == "imperial_chain_pauldron_left")
 then v = "Imperial Chain Left Pauldron" return v 
elseif (v == "imperial_chain_pauldron_right")
 then v = "Imperial Chain Right Pauldron" return v 
elseif (v == "dragonscale_cuirass")
 then v = "Imperial Dragonscale Cuirass" return v 
elseif (v == "dragonscale_helm")
 then v = "Imperial Dragonscale Helm" return v 
elseif (v == "newtscale_cuirass")
 then v = "Imperial Newtscale Cuirass" return v 
elseif (v == "imperial shield")
 then v = "Imperial Shield" return v 
elseif (v == "silver_cuirass")
 then v = "Imperial Silver Cuirass" return v 
elseif (v == "silver_helm")
 then v = "Imperial Silver Helm" return v 
elseif (v == "imperial boots")
 then v = "Imperial Steel Boots" return v 
elseif (v == "imperial cuirass_armor")
 then v = "Imperial Steel Cuirass" return v 
elseif (v == "imperial_greaves")
 then v = "Imperial Steel Greaves" return v 
elseif (v == "imperial helmet armor")
 then v = "Imperial Steel Helmet" return v 
elseif (v == "imperial helmet armor_Dae_curse")
 then v = "Imperial Steel Helmet" return v 
elseif (v == "imperial left gauntlet")
 then v = "Imperial Steel Left Gauntlet" return v 
elseif (v == "imperial left pauldron")
 then v = "Imperial Steel Left Pauldron" return v 
elseif (v == "imperial right gauntlet")
 then v = "Imperial Steel Right Gauntlet" return v 
elseif (v == "imperial right pauldron")
 then v = "Imperial Steel Right Pauldron" return v 
elseif (v == "imperial_studded_cuirass")
 then v = "Imperial Studded Leather Cuiras" return v 
elseif (v == "templar boots")
 then v = "Imperial Templar Boots" return v 
elseif (v == "templar_greaves")
 then v = "Imperial Templar Greaves" return v 
elseif (v == "templar_helmet_armor")
 then v = "Imperial Templar Helmet" return v 
elseif (v == "templar_cuirass")
 then v = "Imperial Templar Knight Cuirass" return v 
elseif (v == "templar bracer left")
 then v = "Imperial Templar Left Bracer" return v 
elseif (v == "templar_pauldron_left")
 then v = "Imperial Templar Left Pauldron" return v 
elseif (v == "templar bracer right")
 then v = "Imperial Templar Right Bracer" return v 
elseif (v == "templar_pauldron_right")
 then v = "Imperial Templar Right Pauldron" return v 
elseif (v == "indoril boots")
 then v = "Indoril Boots" return v 
elseif (v == "indoril cuirass")
 then v = "Indoril Cuirass" return v 
elseif (v == "indoril helmet")
 then v = "Indoril Helmet" return v 
elseif (v == "indoril left gauntlet")
 then v = "Indoril Left Gauntlet" return v 
elseif (v == "indoril pauldron left")
 then v = "Indoril Left Pauldron" return v 
elseif (v == "indoril right gauntlet")
 then v = "Indoril Right Gauntlet" return v 
elseif (v == "indoril pauldron right")
 then v = "Indoril Right Pauldron" return v 
elseif (v == "indoril shield")
 then v = "Indoril Shield" return v 
elseif (v == "iron boots")
 then v = "Iron Boots" return v 
elseif (v == "iron_cuirass")
 then v = "Iron Cuirass" return v 
elseif (v == "iron_greaves")
 then v = "Iron Greaves" return v 
elseif (v == "iron_helmet")
 then v = "Iron Helmet" return v 
elseif (v == "iron_bracer_left")
 then v = "Iron Left Bracer" return v 
elseif (v == "iron_gauntlet_left")
 then v = "Iron Left Gauntlet" return v 
elseif (v == "iron_pauldron_left")
 then v = "Iron Left Pauldron" return v 
elseif (v == "iron_bracer_right")
 then v = "Iron Right Bracer" return v 
elseif (v == "iron_gauntlet_right")
 then v = "Iron Right Gauntlet" return v 
elseif (v == "iron_pauldron_right")
 then v = "Iron Right Pauldron" return v 
elseif (v == "iron_shield")
 then v = "Iron Shield" return v 
elseif (v == "iron_towershield")
 then v = "Iron Tower Shield" return v 
elseif (v == "left cloth horny fist bracer")
 then v = "Left Cloth Horny Fist Bracer" return v 
elseif (v == "Gauntlet_of_Glory_left")
 then v = "Left Gauntlet of Glory" return v 
elseif (v == "gauntlet _horny_fist_l")
 then v = "Left Gauntlet of the Horny Fist" return v 
elseif (v == "left gauntlet of the horny fist")
 then v = "Left Gauntlet of the Horny Fist" return v 
elseif (v == "glass_bracer_left")
 then v = "Left Glass Bracer" return v 
elseif (v == "left_horny_fist_gauntlet")
 then v = "Left Glove of the Horny Fist" return v 
elseif (v == "left leather bracer")
 then v = "Left Leather Bracer" return v 
elseif (v == "lords_cuirass_unique")
 then v = "Lord's Mail" return v 
elseif (v == "daedric_helm_clavicusvile")
 then v = "Masque of Clavicus Vile" return v 
elseif (v == "merisan_cuirass")
 then v = "Merisan Cuirass" return v 
elseif (v == "merisan helm")
 then v = "Merisan Helm" return v 
elseif (v == "morag_tong_helm")
 then v = "Morag Tong Helm" return v 
elseif (v == "Mountain Spirit")
 then v = "Mountain Spirit" return v 
elseif (v == "bonemold_armun-an_helm")
 then v = "Native Armun-An Bonemold Helm" return v 
elseif (v == "bonemold_chuzei_helm")
 then v = "Native Chuzei Bonemold Helm" return v 
elseif (v == "bonemold_gah-julan_helm")
 then v = "Native Gah-Julan Bonemold Helm" return v 
elseif (v == "bonemold_gah-julan_hhda")
 then v = "Native Gah-Julan Bonemold Helm" return v 
elseif (v == "netch_leather_boots")
 then v = "Netch Leather Boots" return v 
elseif (v == "netch_leather_cuirass")
 then v = "Netch Leather Cuirass" return v 
elseif (v == "netch_leather_greaves")
 then v = "Netch Leather Greaves" return v 
elseif (v == "netch_leather_helm")
 then v = "Netch Leather Helm" return v 
elseif (v == "netch_leather_gauntlet_left")
 then v = "Netch Leather Left Gauntlet" return v 
elseif (v == "netch_leather_pauldron_left")
 then v = "Netch Leather Left Pauldron" return v 
elseif (v == "netch_leather_gauntlet_right")
 then v = "Netch Leather Right Gauntlet" return v 
elseif (v == "netch_leather_pauldron_right")
 then v = "Netch Leather Right Pauldron" return v 
elseif (v == "netch_leather_shield")
 then v = "Netch Leather Shield" return v 
elseif (v == "netch_leather_towershield")
 then v = "Netch Leather Tower Shield" return v 
elseif (v == "fur_bearskin_cuirass")
 then v = "Nordic Bearskin Cuirass" return v 
elseif (v == "fur_boots")
 then v = "Nordic Fur Boots" return v 
elseif (v == "fur_cuirass")
 then v = "Nordic Fur Cuirass" return v 
elseif (v == "fur_greaves")
 then v = "Nordic Fur Greaves" return v 
elseif (v == "fur_helm")
 then v = "Nordic Fur Helm" return v 
elseif (v == "fur_bracer_left")
 then v = "Nordic Fur Left Bracer" return v 
elseif (v == "fur_gauntlet_left")
 then v = "Nordic Fur Left Gauntlet" return v 
elseif (v == "fur_pauldron_left")
 then v = "Nordic Fur Left Pauldron" return v 
elseif (v == "fur_bracer_right")
 then v = "Nordic Fur Right Bracer" return v 
elseif (v == "fur_gauntlet_right")
 then v = "Nordic Fur Right Gauntlet" return v 
elseif (v == "fur_pauldron_right")
 then v = "Nordic Fur Right Pauldron" return v 
elseif (v == "nordic_iron_cuirass")
 then v = "Nordic Iron Cuirass" return v 
elseif (v == "nordic_iron_helm")
 then v = "Nordic Iron Helm" return v 
elseif (v == "nordic_leather_shield")
 then v = "Nordic Leather Shield" return v 
elseif (v == "nordic_ringmail_cuirass")
 then v = "Nordic Ringmail Cuirass" return v 
elseif (v == "trollbone_cuirass")
 then v = "Nordic Trollbone Cuirass" return v 
elseif (v == "trollbone_helm")
 then v = "Nordic Trollbone Helm" return v 
elseif (v == "trollbone_shield")
 then v = "Nordic Trollbone Shield" return v 
elseif (v == "orcish_boots")
 then v = "Orcish Boots" return v 
elseif (v == "orcish_cuirass")
 then v = "Orcish Cuirass" return v 
elseif (v == "orcish_greaves")
 then v = "Orcish Greaves" return v 
elseif (v == "orcish_helm")
 then v = "Orcish Helm" return v 
elseif (v == "orcish_bracer_left")
 then v = "Orcish Left Bracer" return v 
elseif (v == "orcish_pauldron_left")
 then v = "Orcish Left Pauldron" return v 
elseif (v == "orcish_bracer_right")
 then v = "Orcish Right Bracer" return v 
elseif (v == "orcish_pauldron_right")
 then v = "Orcish Right Pauldron" return v 
elseif (v == "orcish_towershield")
 then v = "Orcish Tower Shield" return v 
elseif (v == "bonemold_tshield_hrlb")
 then v = "Redoran Banner Shield" return v 
elseif (v == "bonemold_founders_helm")
 then v = "Redoran Founder's Helm" return v 
elseif (v == "bonemold_tshield_redoranguard")
 then v = "Redoran Guard Shield" return v 
elseif (v == "redoran_master_helm")
 then v = "Redoran Master Helm" return v 
elseif (v == "chitin_watchman_helm")
 then v = "Redoran Watchman's Helm" return v 
elseif (v == "right cloth horny fist bracer")
 then v = "Right Cloth Horny Fist Bracer" return v 
elseif (v == "gauntlet_of_glory_right")
 then v = "Right Gauntlet of Glory" return v 
elseif (v == "gauntlet_horny_fist_r")
 then v = "Right Gauntlet of Horny Fist" return v 
elseif (v == "right gauntlet of horny fist")
 then v = "Right Gauntlet of Horny Fist" return v 
elseif (v == "glass_bracer_right")
 then v = "Right Glass Bracer" return v 
elseif (v == "right horny fist gauntlet")
 then v = "Right Glove of the Horny Fist" return v 
elseif (v == "right leather bracer")
 then v = "Right Leather Bracer" return v 
elseif (v == "saint's shield")
 then v = "Saint's Shield" return v 
elseif (v == "ebony_closed_helm_fghl")
 then v = "Sarano Ebony Helm" return v 
elseif (v == "shadow_shield")
 then v = "Shadow Shield" return v 
elseif (v == "shield_of_light")
 then v = "Shield of Light" return v 
elseif (v == "shield of the undaunted")
 then v = "Shield of the Undaunted" return v 
elseif (v == "shield of wounds")
 then v = "Shield of Wounds" return v 
elseif (v == "slave_bracer_left")
 then v = "Slave's Left Bracer" return v 
elseif (v == "slave_bracer_right")
 then v = "Slave's Right Bracer" return v 
elseif (v == "spell_breaker_unique")
 then v = "Spell Breaker" return v 
elseif (v == "spirit of indoril")
 then v = "Spirit of Indoril" return v 
elseif (v == "steel_boots")
 then v = "Steel Boots" return v 
elseif (v == "steel_cuirass")
 then v = "Steel Cuirass" return v 
elseif (v == "steel_greaves")
 then v = "Steel Greaves" return v 
elseif (v == "steel_helm")
 then v = "Steel Helm" return v 
elseif (v == "steel_gauntlet_left")
 then v = "Steel Left Gauntlet" return v 
elseif (v == "steel_pauldron_left")
 then v = "Steel Left Pauldron" return v 
elseif (v == "steel_gauntlet_right")
 then v = "Steel Right Gauntlet" return v 
elseif (v == "steel_pauldron_right")
 then v = "Steel Right Pauldron" return v 
elseif (v == "steel_shield")
 then v = "Steel Shield" return v 
elseif (v == "steel_towershield")
 then v = "Steel Tower Shield" return v 
elseif (v == "storm helm")
 then v = "Storm Helm" return v 
elseif (v == "succour of indoril")
 then v = "Succour of Indoril" return v 
elseif (v == "cephalopod_helm")
 then v = "Telvanni Cephalopod Helm" return v 
elseif (v == "dust_adept_helm")
 then v = "Telvanni Dust Adept Helm" return v 
elseif (v == "bonemold_tshield_telvanniguard")
 then v = "Telvanni Guard Shield" return v 
elseif (v == "mole_crab_helm")
 then v = "Telvanni Mole Crab Helm" return v 
elseif (v == "tenpaceboots")
 then v = "Ten Pace Boots" return v 
elseif (v == "the_chiding_cuirass")
 then v = "The Chiding Cuirass" return v 
elseif (v == "icecap_unique")
 then v = "The Icecap" return v 
elseif (v == "velothian_helm")
 then v = "Velothian Helm" return v 
elseif (v == "velothian shield")
 then v = "Velothian Shield" return v 
elseif (v == "velothis_shield")
 then v = "Velothi's Shield" return v 
elseif (v == "veloths_shield")
 then v = "Veloth's Shield" return v 
elseif (v == "veloths_tower_shield")
 then v = "Veloth's Tower Shield" return v 
elseif (v == "wraithguard")
 then v = "Wraithguard" return v 
elseif (v == "wraithguard_jury_rig")
 then v = "Wraithguard" return v 
elseif (v == "BookSkill_Short Blade3")
 then v = "2920, Evening Star" return v 
elseif (v == "BookSkill_Spear2")
 then v = "2920, First Seed" return v 
elseif (v == "BookSkill_Conjuration4")
 then v = "2920, FrostFall" return v 
elseif (v == "BookSkill_Conjuration3")
 then v = "2920, Hearth Fire" return v 
elseif (v == "BookSkill_Sneak2")
 then v = "2920, Last Seed" return v 
elseif (v == "BookSkill_Heavy Armor2")
 then v = "2920, MidYear" return v 
elseif (v == "BookSkill_Long Blade2")
 then v = "2920, Morning Star" return v 
elseif (v == "BookSkill_Restoration4")
 then v = "2920, Rain's Hand" return v 
elseif (v == "BookSkill_Speechcraft3")
 then v = "2920, Second Seed" return v 
elseif (v == "BookSkill_Mysticism2")
 then v = "2920, Sun's Dawn" return v 
elseif (v == "BookSkill_Short Blade2")
 then v = "2920, Sun's Dusk" return v 
elseif (v == "BookSkill_Mercantile3")
 then v = "2920, Sun's Height" return v 
elseif (v == "BookSkill_Athletics3")
 then v = "36 Lessons of Vivec, Sermon 1" return v 
elseif (v == "BookSkill_Short Blade4")
 then v = "36 Lessons of Vivec, Sermon 10" return v 
elseif (v == "bookskill_unarmored3")
 then v = "36 Lessons of Vivec, Sermon 11" return v 
elseif (v == "bookskill_heavy armor5")
 then v = "36 Lessons of Vivec, Sermon 12" return v 
elseif (v == "BookSkill_Alteration4")
 then v = "36 Lessons of Vivec, Sermon 13" return v 
elseif (v == "bookskill_spear3")
 then v = "36 Lessons of Vivec, Sermon 14" return v 
elseif (v == "bookskill_unarmored4")
 then v = "36 Lessons of Vivec, Sermon 15" return v 
elseif (v == "BookSkill_Axe5")
 then v = "36 Lessons of Vivec, Sermon 16" return v 
elseif (v == "BookSkill_Axe5_open")
 then v = "36 Lessons of Vivec, Sermon 16" return v 
elseif (v == "bookskill_long blade3")
 then v = "36 Lessons of Vivec, Sermon 17" return v 
elseif (v == "BookSkill_Alchemy5")
 then v = "36 Lessons of Vivec, Sermon 18" return v 
elseif (v == "bookskill_enchant4")
 then v = "36 Lessons of Vivec, Sermon 19" return v 
elseif (v == "BookSkill_Alchemy4")
 then v = "36 Lessons of Vivec, Sermon 2" return v 
elseif (v == "bookskill_long blade4")
 then v = "36 Lessons of Vivec, Sermon 20" return v 
elseif (v == "bookskill_light armor4")
 then v = "36 Lessons of Vivec, Sermon 21" return v 
elseif (v == "bookskill_medium armor4")
 then v = "36 Lessons of Vivec, Sermon 22" return v 
elseif (v == "bookskill_long blade5")
 then v = "36 Lessons of Vivec, Sermon 23" return v 
elseif (v == "bookskill_spear4")
 then v = "36 Lessons of Vivec, Sermon 24" return v 
elseif (v == "BookSkill_Armorer4")
 then v = "36 Lessons of Vivec, Sermon 25" return v 
elseif (v == "bookskill_sneak5")
 then v = "36 Lessons of Vivec, Sermon 26" return v 
elseif (v == "bookskill_speechcraft5")
 then v = "36 Lessons of Vivec, Sermon 27" return v 
elseif (v == "bookskill_light armor5")
 then v = "36 Lessons of Vivec, Sermon 28" return v 
elseif (v == "BookSkill_Armorer5")
 then v = "36 Lessons of Vivec, Sermon 29" return v 
elseif (v == "BookSkill_Blunt Weapon4")
 then v = "36 Lessons of Vivec, Sermon 3" return v 
elseif (v == "BookSkill_Short Blade5")
 then v = "36 Lessons of Vivec, Sermon 30" return v 
elseif (v == "BookSkill_Athletics5")
 then v = "36 Lessons of Vivec, Sermon 31" return v 
elseif (v == "BookSkill_Block5")
 then v = "36 Lessons of Vivec, Sermon 32" return v 
elseif (v == "bookskill_medium armor5")
 then v = "36 Lessons of Vivec, Sermon 33" return v 
elseif (v == "bookskill_unarmored5")
 then v = "36 Lessons of Vivec, Sermon 34" return v 
elseif (v == "bookskill_spear5")
 then v = "36 Lessons of Vivec, Sermon 35" return v 
elseif (v == "BookSkill_Mysticism4")
 then v = "36 Lessons of Vivec, Sermon 36" return v 
elseif (v == "BookSkill_Mysticism3")
 then v = "36 Lessons of Vivec, Sermon 4" return v 
elseif (v == "BookSkill_Axe4")
 then v = "36 Lessons of Vivec, Sermon 5" return v 
elseif (v == "BookSkill_Armorer3")
 then v = "36 Lessons of Vivec, Sermon 6" return v 
elseif (v == "BookSkill_Block4")
 then v = "36 Lessons of Vivec, Sermon 7" return v 
elseif (v == "BookSkill_Athletics4")
 then v = "36 Lessons of Vivec, Sermon 8" return v 
elseif (v == "BookSkill_Blunt Weapon5")
 then v = "36 Lessons of Vivec, Sermon 9" return v 
elseif (v == "bk_ABCs")
 then v = "ABCs for Barbarians" return v 
elseif (v == "BookSkill_Acrobatics2")
 then v = "A Dance in Fire, Chapter 1" return v 
elseif (v == "BookSkill_Block3")
 then v = "A Dance in Fire, Chapter 2" return v 
elseif (v == "BookSkill_Athletics2")
 then v = "A Dance in Fire, Chapter 3" return v 
elseif (v == "BookSkill_Acrobatics3")
 then v = "A Dance in Fire, Chapter 4" return v 
elseif (v == "BookSkill_Marksman2")
 then v = "A Dance in Fire, Chapter 5" return v 
elseif (v == "bookskill_mercantile4")
 then v = "A Dance in Fire, Chapter 6" return v 
elseif (v == "bookskill_mercantile5")
 then v = "A Dance in Fire, Chapter 7" return v 
elseif (v == "sc_Indie")
 then v = "A dying man's last words" return v 
elseif (v == "bk_AedraAndDaedra")
 then v = "Aedra and Daedra" return v 
elseif (v == "Cumanya's Notes")
 then v = "A Fair Warning" return v 
elseif (v == "BookSkill_Alchemy1")
 then v = "A Game at Dinner" return v 
elseif (v == "bk_joldanote")
 then v = "A hastily scrawled note" return v 
elseif (v == "bookskill_destruction3")
 then v = "A Hypothetical Treachery" return v 
elseif (v == "bk_Ajira2")
 then v = "Ajira's Flower Report" return v 
elseif (v == "bk_Ajira1")
 then v = "Ajira's Mushroom Report" return v 
elseif (v == "bk_leaflet_false")
 then v = "A Leaflet" return v 
elseif (v == "bk_istunondescosmology")
 then v = "A Less Rude Song" return v 
elseif (v == "bk_AncestorsAndTheDunmer")
 then v = "Ancestors and the Dunmer" return v 
elseif (v == "bk_AntecedantsDwemerLaw")
 then v = "Antecedants of Dwemer Law" return v 
elseif (v == "bk_ArcanaRestored")
 then v = "Arcana Restored" return v 
elseif (v == "bk_ArkayTheEnemy")
 then v = "Arkay the Enemy" return v 
elseif (v == "bk_landdeed_hhrd")
 then v = "Ascadian Isles Land Deed" return v 
elseif (v == "sc_Vulpriss")
 then v = "A scrawled note" return v 
elseif (v == "sc_Malaki")
 then v = "A scroll written in blood" return v 
elseif (v == "bk_Ashland_Hymns")
 then v = "Ashland Hymns" return v 
elseif (v == "bk_ShortHistoryMorrowind")
 then v = "A Short History of Morrowind" return v 
elseif (v == "bk_AuraneFrernis1")
 then v = "Aurane Frernis' Recipies" return v 
elseif (v == "bk_auranefrernis2")
 then v = "Aurane Frernis' Recipies" return v 
elseif (v == "bk_auranefrernis3")
 then v = "Aurane Frernis' Recipies" return v 
elseif (v == "bk_note")
 then v = "A worn and weathered note" return v 
elseif (v == "BookSkill_Sneak3")
 then v = "Azura and the Box" return v 
elseif (v == "bk_BeramJournal1")
 then v = "Beram Journal Entry 1" return v 
elseif (v == "bk_BeramJournal2")
 then v = "Beram Journal Entry 2" return v 
elseif (v == "bk_BeramJournal3")
 then v = "Beram Journal Entry 3" return v 
elseif (v == "bk_BeramJournal4")
 then v = "Beram Journal Entry 4" return v 
elseif (v == "bk_BeramJournal5")
 then v = "Beram Journal Entry 5" return v 
elseif (v == "bk_BiographyBarenziah1")
 then v = "Biography of Barenziah v I" return v 
elseif (v == "bk_BiographyBarenziah2")
 then v = "Biography of Barenziah v II" return v 
elseif (v == "bk_BiographyBarenziah3")
 then v = "Biography of Barenziah v III" return v 
elseif (v == "BookSkill_Speechcraft1")
 then v = "Biography of the Wolf Queen" return v 
elseif (v == "bk_BlasphemousRevenants")
 then v = "Blasphemous Revenants" return v 
elseif (v == "bk_Boethiah's Glory_unique")
 then v = "Boethiah's Glory" return v 
elseif (v == "bk_BoethiahPillowBook")
 then v = "Boethiah's Pillow Book" return v 
elseif (v == "BookSkill_Medium Armor2")
 then v = "Bone, Part One" return v 
elseif (v == "BookSkill_Medium Armor3")
 then v = "Bone, Part Two" return v 
elseif (v == "bk_BookOfLifeAndService")
 then v = "Book of Life and Service" return v 
elseif (v == "bk_BookOfRestAndEndings")
 then v = "Book of Rest and Endings" return v 
elseif (v == "BookSkill_Alteration1")
 then v = "Breathing Water" return v 
elseif (v == "bk_BriefHistoryEmpire1")
 then v = "Brief History of the Empire v 1" return v 
elseif (v == "bk_BriefHistoryEmpire2")
 then v = "Brief History of the Empire v 2" return v 
elseif (v == "bk_BriefHistoryEmpire3")
 then v = "Brief History of the Empire v 3" return v 
elseif (v == "bk_BriefHistoryEmpire4")
 then v = "Brief History of the Empire v 4" return v 
elseif (v == "bk_BrownBook426")
 then v = "Brown Book of 3E 426" return v 
elseif (v == "bk_CalderaRecordBook1")
 then v = "Caldera Ledger" return v 
elseif (v == "bk_CalderaMiningContract")
 then v = "Caldera Mining Contract" return v 
elseif (v == "bk_fishystick")
 then v = "Capn's Guide to the Fishy Stick" return v 
elseif (v == "bookskill_security4")
 then v = "Chance's Folly" return v 
elseif (v == "bookskill_unarmored2")
 then v = "Charwich-Koniinge, Volume 1" return v 
elseif (v == "bookskill_hand to hand3")
 then v = "Charwich-Koniinge, Volume 2" return v 
elseif (v == "BookSkill_Mysticism5")
 then v = "Charwich-Koniinge, Volume 3" return v 
elseif (v == "bookskill_hand to hand4")
 then v = "Charwich-Koniinge, Volume 4" return v 
elseif (v == "bookskill_medium armor1")
 then v = "Cherim's Heart of Anequina" return v 
elseif (v == "bk_ChildrenOfTheSky")
 then v = "Children of the Sky" return v 
elseif (v == "BookSkill_Heavy Armor3")
 then v = "Chimarvamidium" return v 
elseif (v == "bk_ChroniclesNchuleft")
 then v = "Chronicles of Nchuleft" return v 
elseif (v == "bk_clientlist")
 then v = "Client List" return v 
elseif (v == "bk_Confessions")
 then v = "Confessions of a Skooma-Eater" return v 
elseif (v == "bk_stronghold_c_hlaalu")
 then v = "Construction Contract" return v 
elseif (v == "bk_corpsepreperation1_c")
 then v = "Corpse Preparation v I" return v 
elseif (v == "bk_corpsepreperation1_o")
 then v = "Corpse Preparation v I" return v 
elseif (v == "bk_corpsepreperation2_c")
 then v = "Corpse Preparation v II" return v 
elseif (v == "bk_corpsepreperation3_c")
 then v = "Corpse Preparation v III" return v 
elseif (v == "bk_BlightPotionNotice")
 then v = "Cure Blight Potion Notice" return v 
elseif (v == "bk_Dagoth_Urs_Plans")
 then v = "Dagoth Ur's Plans" return v 
elseif (v == "bk_darkestdarkness")
 then v = "Darkest Darkness" return v 
elseif (v == "BookSkill_Block1")
 then v = "Death Blow of Abernanit" return v 
elseif (v == "bk_a1_1_packagedecoded")
 then v = "decoded package" return v 
elseif (v == "bk_indreledeed")
 then v = "Deed to Indrele's House" return v 
elseif (v == "bk_a1_1_directionscaiuscosades")
 then v = "Directions to Caius Cosades" return v 
elseif (v == "bk_dispelrecipe_tgca")
 then v = "Dispel Potion Formula" return v 
elseif (v == "bk_DivineMetaphysics")
 then v = "Divine Metaphysics..." return v 
elseif (v == "bk_drenblackmail")
 then v = "Dren's Note" return v 
elseif (v == "bk_Dren_shipping_log")
 then v = "Dren's shipping log" return v 
elseif (v == "bk_dwemermuseumwelcome")
 then v = "Dwemer Museum Welcome" return v 
elseif (v == "bk_eastempirecompanyledger")
 then v = "East Empire Company Ledger" return v 
elseif (v == "bk_Ibardad_Elante_notes")
 then v = "Elante's Notes" return v 
elseif (v == "bk_a1_1_elone_to_Balmora")
 then v = "Elone's Directions to Balmora" return v 
elseif (v == "bk_fellowshiptemple")
 then v = "Fellowship of the Temple" return v 
elseif (v == "BookSkill_Enchant1")
 then v = "Feyfolken I" return v 
elseif (v == "BookSkill_Conjuration1")
 then v = "Feyfolken II" return v 
elseif (v == "BookSkill_Conjuration2")
 then v = "Feyfolken III" return v 
elseif (v == "bk_charterFG")
 then v = "Fighters Guild Charter" return v 
elseif (v == "bk_fivesongsofkingwulfharth")
 then v = "Five Songs of King Wulfharth" return v 
elseif (v == "bk_formygodsandemperor")
 then v = "For my Gods and Emperor" return v 
elseif (v == "bk_fortpelagiadprisonerlog")
 then v = "Fort Pelagiad Prisoner Log" return v 
elseif (v == "bk_fragmentonartaeum")
 then v = "Fragment: On Artaeum" return v 
elseif (v == "bk_frontierconquestaccommodat")
 then v = "Frontier, Conquest..." return v 
elseif (v == "bk_galerionthemystic")
 then v = "Galerion The Mystic" return v 
elseif (v == "bk_galtisguvronsnote")
 then v = "Galtis Guvron's Note" return v 
elseif (v == "bk_galur_rithari's_papers")
 then v = "Galur Rithari's Papers" return v 
elseif (v == "bk_uleni's_papers")
 then v = "Ghost-Free Papers" return v 
elseif (v == "bk_gnisiseggmineledger")
 then v = "Gnisis Eggmine Ledger" return v 
elseif (v == "bk_gnisiseggminepass")
 then v = "Gnisis Eggmine Pass" return v 
elseif (v == "bk_graspingfortune")
 then v = "Grasping Fortune" return v 
elseif (v == "bk_great_houses")
 then v = "Great Houses of Morrowind" return v 
elseif (v == "bk_guide_to_ald_ruhn")
 then v = "Guide to Ald'ruhn" return v 
elseif (v == "bk_guide_to_balmora")
 then v = "Guide to Balmora" return v 
elseif (v == "bk_guide_to_sadrithmora")
 then v = "Guide to Sadrith Mora" return v 
elseif (v == "bk_guide_to_vivec")
 then v = "Guide to Vivec" return v 
elseif (v == "bk_guide_to_vvardenfell")
 then v = "Guide to Vvardenfell" return v 
elseif (v == "bk_guylainesarchitecture")
 then v = "Guylaine's Architecture" return v 
elseif (v == "bookskill_heavy armor1")
 then v = "Hallgerd's Tale" return v 
elseif (v == "bk_hanginggardenswasten")
 then v = "Hanging Gardens..." return v 
elseif (v == "bk_bartendersguide")
 then v = "Hanin's Wake" return v 
elseif (v == "bk_bartendersguide_01")
 then v = "Hanin's Wake" return v 
elseif (v == "bk_a1_2_antabolistocosades")
 then v = "Hasphat's notes for Cosades" return v 
elseif (v == "bk_Hlaalu_Vaults_Ledger")
 then v = "Hlaalu Vaults Ledger" return v 
elseif (v == "bk_HomiliesOfBlessedAlmalexia")
 then v = "Homilies of Blessed Almalexia" return v 
elseif (v == "writ_baladas")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_belvayn")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_bemis")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_bero")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_brilnosu")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_galasa")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_guril")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_mavon")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_navil")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_oran")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_sadus")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_saren")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_therana")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_varro")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_vendu")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "writ_yasalmibaal")
 then v = "Honorable Writ of Execution" return v 
elseif (v == "bk_honorthieves")
 then v = "Honor Among Thieves" return v 
elseif (v == "bk_hospitality_papers")
 then v = "Hospitality Papers" return v 
elseif (v == "bookskill_heavy armor4")
 then v = "How Orsinium Passed to the Orcs" return v 
elseif (v == "BookSkill_Light Armor2")
 then v = "Ice and Chiton" return v 
elseif (v == "bk_impmuseumwelcome")
 then v = "Imperial Museum Welcome" return v 
elseif (v == "bookskill_illusion3")
 then v = "Incident in Necrom" return v 
elseif (v == "bk_InvocationOfAzura")
 then v = "Invocation of Azura" return v 
elseif (v == "bk_pillowinvoice")
 then v = "Invoice" return v 
elseif (v == "bk_itermerelsnotes")
 then v = "Itermerel's Notes" return v 
elseif (v == "bk_falljournal_unique")
 then v = "Journal of Tarhiel" return v 
elseif (v == "bk_notes-kagouti mating habits")
 then v = "Kagouti Mating Habits" return v 
elseif (v == "bk_kagrenac'sjournal_excl")
 then v = "Kagrenac's Journal" return v 
elseif (v == "bk_kagrenac'splans_excl")
 then v = "Kagrenac's Planbook" return v 
elseif (v == "bk_kagrenac'stools")
 then v = "Kagrenac's Tools" return v 
elseif (v == "BookSkill_Armorer2")
 then v = "Last Scabbard of Akrash" return v 
elseif (v == "bk_legionsofthedead")
 then v = "Legions of the Dead" return v 
elseif (v == "bk_letterfromgadayn")
 then v = "Letter from Gadayn" return v 
elseif (v == "bk_letterfromjzhirr")
 then v = "Letter From J'Zhirr" return v 
elseif (v == "bk_letterfromllaalam")
 then v = "Letter From Llaalam Dredil" return v 
elseif (v == "bk_letterfromllaalam2")
 then v = "Letter From Llaalam Dredil" return v 
elseif (v == "bk_ocato_recommendation")
 then v = "Letter from Ocato" return v 
elseif (v == "bk_miungei")
 then v = "Letter from Tsrazami" return v 
elseif (v == "bk_a1_2_introtocadiusus")
 then v = "Letter to Senilias Cadiusus" return v 
elseif (v == "bk_LivesOfTheSaints")
 then v = "Lives of the Saints" return v 
elseif (v == "bookskill_light armor3")
 then v = "Lord Jornibret's Last Dance" return v 
elseif (v == "bk_charterMG")
 then v = "Mages Guild Charter" return v 
elseif (v == "bk_red_mountain_map")
 then v = "Map of Red Mountain" return v 
elseif (v == "bookskill_hand to hand5")
 then v = "Master Zoaraym's Tale" return v 
elseif (v == "bk_a2_2_dagoth_message")
 then v = "Message from Dagoth Ur" return v 
elseif (v == "bk_messagefrommasteraryon")
 then v = "Message from Master Aryon" return v 
elseif (v == "sc_messengerscroll")
 then v = "Messenger Scroll" return v 
elseif (v == "sc_summondaedroth_hto")
 then v = "Milyn Faram's Scroll" return v 
elseif (v == "bk_a1_v_vivecinformants")
 then v = "Mission to Vivec -- from Caius" return v 
elseif (v == "bk_MixedUnitTactics")
 then v = "Mixed Unit Tactics v1" return v 
elseif (v == "bk_MysteriousAkavir")
 then v = "Mysterious Akavir" return v 
elseif (v == "BookSkill_Acrobatics5")
 then v = "Mystery of Talara, Part 1" return v 
elseif (v == "BookSkill_Restoration5")
 then v = "Mystery of Talara, Part 2" return v 
elseif (v == "BookSkill_Destruction5")
 then v = "Mystery of Talara, Part 3" return v 
elseif (v == "BookSkill_Destruction5_open")
 then v = "Mystery of Talara, Part 3" return v 
elseif (v == "bookskill_illusion5")
 then v = "Mystery of Talara, Part 4" return v 
elseif (v == "bookskill_mystery5")
 then v = "Mystery of Talara, Part 5" return v 
elseif (v == "bk_Mysticism")
 then v = "Mysticism" return v 
elseif (v == "bk_nchunaksfireandfaith")
 then v = "Nchunak's Fire and Faith" return v 
elseif (v == "bk_nemindasorders")
 then v = "Neminda's Orders" return v 
elseif (v == "bk_vivec_murders")
 then v = "Nerevar at Red Mountain" return v 
elseif (v == "bk_a1_4_sharnsnotes")
 then v = "Nerevarine cult notes" return v 
elseif (v == "bk_NerevarMoonandStar")
 then v = "Nerevar Moon-and-Star" return v 
elseif (v == "bk_NGastaKvataKvakis_c")
 then v = "N'Gasta! Kvata! Kvakis!" return v 
elseif (v == "bk_NGastaKvataKvakis_o")
 then v = "N'Gasta! Kvata! Kvakis!" return v 
elseif (v == "bookskill_blunt weapon3")
 then v = "Night Falls On Sentinel" return v 
elseif (v == "bk_BriefHistoryofWood")
 then v = "No-h's Picture Book of Wood" return v 
elseif (v == "bk_BriefHistoryofWood_01")
 then v = "No-h's Picture Book of Wood" return v 
elseif (v == "bk_Nerano")
 then v = "Note from Bakarak" return v 
elseif (v == "bk_notefrombashuk")
 then v = "Note from Bashuk" return v 
elseif (v == "bk_notefromberwen")
 then v = "Note from Berwen" return v 
elseif (v == "bk_notefrombildren")
 then v = "Note From Bildren" return v 
elseif (v == "bk_notefrombugrol")
 then v = "Note from Bugrol" return v 
elseif (v == "bk_notefromernil")
 then v = "Note From Ernil" return v 
elseif (v == "bk_notefromferele")
 then v = "Note from Ferele" return v 
elseif (v == "bk_notefromirgola")
 then v = "Note from Irgola" return v 
elseif (v == "bk_NoteFromJ'Zhirr")
 then v = "Note from J'zhirr" return v 
elseif (v == "bk_notefromnelos")
 then v = "Note from Nelos" return v 
elseif (v == "bk_talostreason")
 then v = "Note from Oritius Maro" return v 
elseif (v == "bk_notefromradras")
 then v = "Note From Radras" return v 
elseif (v == "bk_notefromsondaale")
 then v = "Note from Sondaale" return v 
elseif (v == "bk_saryoni_note")
 then v = "note from the Archcanon" return v 
elseif (v == "bk_notebyaryon")
 then v = "Notes by Aryon" return v 
elseif (v == "bk_A1_7_HuleeyaInformant")
 then v = "Notes from Huleeya" return v 
elseif (v == "bookskill_restoration2")
 then v = "Notes on Racial Phylogeny" return v 
elseif (v == "bk_NoteToAmaya")
 then v = "Note to Amaya" return v 
elseif (v == "bk_notetocalderaguard")
 then v = "NoteToCalderaGuard" return v 
elseif (v == "bk_falanaamonote")
 then v = "Note to Falanaamo" return v 
elseif (v == "bk_shalit_note")
 then v = "Note to Giden" return v 
elseif (v == "bk_Dren_Hlevala_note")
 then v = "Note to Hlevala" return v 
elseif (v == "note to hrisskar")
 then v = "Note to Hrisskar" return v 
elseif (v == "bk_notetoinorra")
 then v = "Note to Inorra" return v 
elseif (v == "bk_notetocalderamages")
 then v = "Note to Mages" return v 
elseif (v == "bk_notetomalsa")
 then v = "Note to Malsa Ules" return v 
elseif (v == "bk_notetomenus")
 then v = "Note to Menus" return v 
elseif (v == "bk_enamor")
 then v = "Note to Salyn Sarethi" return v 
elseif (v == "bk_notetocalderaslaves")
 then v = "Note to Slaves" return v 
elseif (v == "bk_notetotelvon")
 then v = "Note to Telvon" return v 
elseif (v == "bk_notetovalvius")
 then v = "Note to Valvius" return v 
elseif (v == "bk_storagenotice")
 then v = "Notice" return v 
elseif (v == "bk_BriefHistoryEmpire1_oh")
 then v = "Odral's History of the Empire 1" return v 
elseif (v == "bk_BriefHistoryEmpire2_oh")
 then v = "Odral's History of the Empire 2" return v 
elseif (v == "bk_BriefHistoryEmpire3_oh")
 then v = "Odral's History of the Empire 3" return v 
elseif (v == "bk_BriefHistoryEmpire4_oh")
 then v = "Odral's History of the Empire 4" return v 
elseif (v == "bk_landdeedfake_hhrd")
 then v = "Odral's Land Deed" return v 
elseif (v == "bk_OnMorrowind")
 then v = "On Morrowind" return v 
elseif (v == "bk_onoblivion")
 then v = "On Oblivion" return v 
elseif (v == "bk_orderfrommollismo")
 then v = "Order From Mollismo" return v 
elseif (v == "bk_eggorders")
 then v = "Order Manifest" return v 
elseif (v == "bk_ordersforbivaleteneran")
 then v = "Orders for Bivale Teneran" return v 
elseif (v == "bk_ordolegionis")
 then v = "Ordo Legionis" return v 
elseif (v == "bk_OriginOfTheMagesGuild")
 then v = "Origin of the Mages Guild" return v 
elseif (v == "bk_OverviewOfGodsAndWorship")
 then v = "Overview of Gods and Worship" return v 
elseif (v == "bk_a1_1_caiuspackage")
 then v = "Package for Caius Cosades" return v 
elseif (v == "bk_ILHermit_Page")
 then v = "Page from History of the Empire" return v 
elseif (v == "bookskill_illusion4")
 then v = "Palla, Book I" return v 
elseif (v == "bookskill_enchant3")
 then v = "Palla, Book II" return v 
elseif (v == "sc_paper_plain_01_canodia")
 then v = "paper" return v 
elseif (v == "sc_paper plain")
 then v = "paper" return v 
elseif (v == "bk_6thhouseravings")
 then v = "Parchment with Scrawlings" return v 
elseif (v == "note_Peke_Utchoo")
 then v = "Peke Utchoo's last words" return v 
elseif (v == "bk_vivecs_plan")
 then v = "Plan to Defeat Dagoth Ur" return v 
elseif (v == "bk_poisonsong1")
 then v = "Poison Song I" return v 
elseif (v == "bk_poisonsong2")
 then v = "Poison Song II" return v 
elseif (v == "bk_poisonsong3")
 then v = "Poison Song III" return v 
elseif (v == "bk_poisonsong4")
 then v = "Poison Song IV" return v 
elseif (v == "bk_poisonsong5")
 then v = "Poison Song V" return v 
elseif (v == "bk_poisonsong6")
 then v = "Poison Song VI" return v 
elseif (v == "bk_poisonsong7")
 then v = "Poison Song VII" return v 
elseif (v == "bk_V_hlaaluprison")
 then v = "Prisoner Checklist" return v 
elseif (v == "bk_progressoftruth")
 then v = "Progress of Truth" return v 
elseif (v == "bk_propertyofjolda")
 then v = "Property of Jolda" return v 
elseif (v == "bk_provinces_of_tamriel")
 then v = "Provinces of Tamriel" return v 
elseif (v == "bk_NerevarineNotice")
 then v = "Public notice" return v 
elseif (v == "bk_ravilamemorial")
 then v = "Ravila Memorial" return v 
elseif (v == "bookskill_acrobatics1")
 then v = "Realizations of Acrobacy" return v 
elseif (v == "bk_redbook426")
 then v = "Red Book of 3E 426" return v 
elseif (v == "bk_redorancookingsecrets")
 then v = "Redoran Cooking Secrets" return v 
elseif (v == "bk_Redoran_Vaults_Ledger")
 then v = "Redoran Vaults Ledger" return v 
elseif (v == "bk_reflectionsoncultworship...")
 then v = "Reflections on Cult Worship" return v 
elseif (v == "chargen statssheet")
 then v = "Release Identification" return v 
elseif (v == "bk_shalitjournal_deal")
 then v = "Rels Tenim Journal Page" return v 
elseif (v == "bk_responsefromdivaythfyr")
 then v = "Response from Divayth Fyr" return v 
elseif (v == "bookskill_destruction2")
 then v = "Response to Bero's Speech" return v 
elseif (v == "bk_stronghold_ld_hlaalu")
 then v = "Rethan Manor Land Deed" return v 
elseif (v == "text_paper_roll_01")
 then v = "Rolled Paper" return v 
elseif (v == "bk_SaintNerevar")
 then v = "Saint Nerevar" return v 
elseif (v == "bk_SaryonisSermons")
 then v = "Saryoni's Sermons" return v 
elseif (v == "bk_saryonisermonsmanuscript")
 then v = "Saryoni's Sermons Manuscript" return v 
elseif (v == "sc_almsiviintervention")
 then v = "Scroll of Almsivi Intervention" return v 
elseif (v == "sc_alvusiaswarping")
 then v = "Scroll of Alvusia's Warping" return v 
elseif (v == "sc_balefulsuffering")
 then v = "Scroll of Baleful Suffering" return v 
elseif (v == "sc_blackdeath")
 then v = "Scroll of Black Death" return v 
elseif (v == "sc_blackdespair")
 then v = "Scroll of Black Despair" return v 
elseif (v == "sc_blackfate")
 then v = "Scroll of Black Fate" return v 
elseif (v == "sc_blackmind")
 then v = "Scroll of Black Mind" return v 
elseif (v == "sc_blackscorn")
 then v = "Scroll of Black Scorn" return v 
elseif (v == "sc_blacksloth")
 then v = "Scroll of Black Sloth" return v 
elseif (v == "sc_blackweakness")
 then v = "Scroll of Black Weakness" return v 
elseif (v == "sc_bloodfire")
 then v = "Scroll of Bloodfire" return v 
elseif (v == "sc_brevasavertedeyes")
 then v = "Scroll of Breva's Averted Eyes" return v 
elseif (v == "sc_celerity")
 then v = "Scroll of Celerity" return v 
elseif (v == "sc_corruptarcanix")
 then v = "Scroll of Corrupt Arcanix" return v 
elseif (v == "sc_cureblight_ranged")
 then v = "Scroll of Daerir's Blessing" return v 
elseif (v == "sc_daerirsmiracle")
 then v = "Scroll of Daerir's Miracle" return v 
elseif (v == "sc_daydenespanacea")
 then v = "Scroll of Daydene's Panacea" return v 
elseif (v == "sc_daynarsairybubble")
 then v = "Scroll of Daynar's Airy Bubble" return v 
elseif (v == "sc_dedresmasterfuleye")
 then v = "Scroll of Dedres' Masterful Eye" return v 
elseif (v == "sc_didalasknack")
 then v = "Scroll of Didala's Knack" return v 
elseif (v == "sc_divineintervention")
 then v = "Scroll of Divine Intervention" return v 
elseif (v == "sc_drathissoulrot")
 then v = "Scroll of Drathis' Soulrot" return v 
elseif (v == "sc_drathiswinterguest")
 then v = "Scroll of Drathis' Winter Guest" return v 
elseif (v == "sc_ekashslocksplitter")
 then v = "Scroll of Ekash's Lock Splitter" return v 
elseif (v == "sc_elementalburstfire")
 then v = "Scroll of Elemental Burst:Fire" return v 
elseif (v == "sc_elementalburstfrost")
 then v = "Scroll of Elemental Burst:Frost" return v 
elseif (v == "sc_elementalburstshock")
 then v = "Scroll of Elemental Burst:Shock" return v 
elseif (v == "sc_elevramssty")
 then v = "Scroll of Elevram's Sty" return v 
elseif (v == "sc_fadersleadenflesh")
 then v = "Scroll of Fader's Leaden Flesh" return v 
elseif (v == "sc_feldramstrepidation")
 then v = "Scroll of Feldram's Trepidation" return v 
elseif (v == "sc_FiercelyRoastThyEnemy_unique")
 then v = "Scroll of Fiercely Roasting" return v 
elseif (v == "sc_flamebane")
 then v = "Scroll of Flamebane" return v 
elseif (v == "sc_flameguard")
 then v = "Scroll of Flameguard" return v 
elseif (v == "sc_fphyggisgemfeeder")
 then v = "Scroll of Fphyggi's Gem-Feeder" return v 
elseif (v == "sc_frostbane")
 then v = "Scroll of Frostbane" return v 
elseif (v == "sc_frostguard")
 then v = "Scroll of Frostguard" return v 
elseif (v == "sc_galmsesseal")
 then v = "Scroll of Galmes' Seal" return v 
elseif (v == "sc_golnaraseyemaze")
 then v = "Scroll of Golnara's Eye-Maze" return v 
elseif (v == "sc_gonarsgoad")
 then v = "Scroll of Gonar's Goad" return v 
elseif (v == "sc_greaterdomination")
 then v = "Scroll of Greater Domination" return v 
elseif (v == "sc_greydeath")
 then v = "Scroll of Grey Death" return v 
elseif (v == "sc_greydespair")
 then v = "Scroll of Grey Despair" return v 
elseif (v == "sc_greyfate")
 then v = "Scroll of Grey Fate" return v 
elseif (v == "sc_greymind")
 then v = "Scroll of Grey Mind" return v 
elseif (v == "sc_greyscorn")
 then v = "Scroll of Grey Scorn" return v 
elseif (v == "sc_greysloth")
 then v = "Scroll of Grey Sloth" return v 
elseif (v == "sc_greyweakness")
 then v = "Scroll of Grey Weakness" return v 
elseif (v == "sc_healing")
 then v = "Scroll of Healing" return v 
elseif (v == "sc_heartwise")
 then v = "Scroll of Heartwise" return v 
elseif (v == "sc_hellfire")
 then v = "Scroll of Hellfire" return v 
elseif (v == "sc_icarianflight")
 then v = "Scroll of Icarian Flight" return v 
elseif (v == "sc_illneasbreath")
 then v = "Scroll of Illnea's Breath" return v 
elseif (v == "sc_inaschastening")
 then v = "Scroll of Inas' Chastening" return v 
elseif (v == "sc_inasismysticfinger")
 then v = "Scroll of Inasi's Mystic Finger" return v 
elseif (v == "sc_insight")
 then v = "Scroll of Insight" return v 
elseif (v == "sc_invisibility")
 then v = "Scroll of Invisibility" return v 
elseif (v == "sc_leaguestep")
 then v = "Scroll of Leaguestep" return v 
elseif (v == "sc_lesserdomination")
 then v = "Scroll of Lesser Domination" return v 
elseif (v == "sc_llirosglowingeye")
 then v = "Scroll of Lliros' Glowing Eye" return v 
elseif (v == "sc_lordmhasvengeance")
 then v = "Scroll of Lord Mhas' Vengeance" return v 
elseif (v == "sc_mageweal")
 then v = "Scroll of Mageweal" return v 
elseif (v == "sc_manarape")
 then v = "Scroll of Manarape" return v 
elseif (v == "sc_mark")
 then v = "Scroll of Mark" return v 
elseif (v == "sc_mondensinstigator")
 then v = "Scroll of Monden's Instigator" return v 
elseif (v == "sc_nerusislockjaw")
 then v = "Scroll of Nerusi's Lockjaw" return v 
elseif (v == "sc_ondusisunhinging")
 then v = "Scroll of Ondusi's Unhinging" return v 
elseif (v == "sc_princeovsbrightball")
 then v = "Scroll of Prince Ov's Brightbal" return v 
elseif (v == "sc_psychicprison")
 then v = "Scroll of Psychic Prison" return v 
elseif (v == "sc_purityofbody")
 then v = "Scroll of Purity of Body" return v 
elseif (v == "sc_radiyasicymask")
 then v = "Scroll of Radiya's Icy Mask" return v 
elseif (v == "sc_radrenesspellbreaker")
 then v = "Scroll of Radrene'sSpellBreaker" return v 
elseif (v == "sc_reddeath")
 then v = "Scroll of Red Death" return v 
elseif (v == "sc_reddespair")
 then v = "Scroll of Red Despair" return v 
elseif (v == "sc_redfate")
 then v = "Scroll of Red Fate" return v 
elseif (v == "sc_redmind")
 then v = "Scroll of Red Mind" return v 
elseif (v == "sc_redscorn")
 then v = "Scroll of Red Scorn" return v 
elseif (v == "sc_redsloth")
 then v = "Scroll of Red Sloth" return v 
elseif (v == "sc_redweakness")
 then v = "Scroll of Red Weakness" return v 
elseif (v == "sc_restoration")
 then v = "Scroll of Restoration" return v 
elseif (v == "sc_reynosbeastfinder")
 then v = "Scroll of Reynos' Beast Finder" return v 
elseif (v == "sc_reynosfins")
 then v = "Scroll of Reynos' Fins" return v 
elseif (v == "sc_salensvivication")
 then v = "Scroll of Salen's Vivication" return v 
elseif (v == "sc_savagemight")
 then v = "Scroll of Savage Might" return v 
elseif (v == "sc_selisfieryward")
 then v = "Scroll of Selis' Fiery Ward" return v 
elseif (v == "sc_selynsmistslippers")
 then v = "Scroll of Selyn's Mist Slippers" return v 
elseif (v == "sc_sertisesporphyry")
 then v = "Scroll of Sertises' Porphyry" return v 
elseif (v == "sc_shockbane")
 then v = "Scroll of Shockbane" return v 
elseif (v == "sc_shockguard")
 then v = "Scroll of Shockguard" return v 
elseif (v == "sc_stormward")
 then v = "Scroll of Stormward" return v 
elseif (v == "sc_summonflameatronach")
 then v = "Scroll of Summon Flame Atronach" return v 
elseif (v == "sc_summonfrostatronach")
 then v = "Scroll of Summon Frost Atronach" return v 
elseif (v == "sc_summongoldensaint")
 then v = "Scroll of Summon Golden Saint" return v 
elseif (v == "sc_summonskeletalservant")
 then v = "Scroll of Summon Skeleton" return v 
elseif (v == "sc_supremedomination")
 then v = "Scroll of Supreme Domination" return v 
elseif (v == "sc_taldamsscorcher")
 then v = "Scroll of Taldam's Scorcher" return v 
elseif (v == "sc_telvinscourage")
 then v = "Scroll of Telvin's Courage" return v 
elseif (v == "sc_tendilstrembling")
 then v = "Scroll of Tendil's Trembling" return v 
elseif (v == "sc_tevilspeace")
 then v = "Scroll of Tevil's Peace" return v 
elseif (v == "sc_tevralshawkshaw")
 then v = "Scroll of Tevral's Hawkshaw" return v 
elseif (v == "sc_argentglow")
 then v = "Scroll of The Argent Glow" return v 
elseif (v == "sc_blackstorm")
 then v = "Scroll of The Black Storm" return v 
elseif (v == "sc_bloodthief")
 then v = "Scroll of The Blood Thief" return v 
elseif (v == "sc_dawnsprite")
 then v = "Scroll of The Dawn Sprite" return v 
elseif (v == "sc_fifthbarrier")
 then v = "Scroll of The Fifth Barrier" return v 
elseif (v == "sc_firstbarrier")
 then v = "Scroll of The First Barrier" return v 
elseif (v == "sc_fourthbarrier")
 then v = "Scroll of The Fourth Barrier" return v 
elseif (v == "sc_gamblersprayer")
 then v = "Scroll of The Gambler's Prayer" return v 
elseif (v == "sc_mageseye")
 then v = "Scroll of The Mage's Eye" return v 
elseif (v == "sc_mindfeeder")
 then v = "Scroll of The Mind Feeder" return v 
elseif (v == "sc_ninthbarrier")
 then v = "Scroll of The Ninth Barrier" return v 
elseif (v == "sc_oathfast")
 then v = "Scroll of The Oathfast" return v 
elseif (v == "sc_secondbarrier")
 then v = "Scroll of The Second Barrier" return v 
elseif (v == "sc_sixthbarrier")
 then v = "Scroll of The Sixth Barrier" return v 
elseif (v == "sc_thirdbarrier")
 then v = "Scroll of The Third Barrier" return v 
elseif (v == "sc_tinurshoptoad")
 then v = "Scroll of Tinur's Hoptoad" return v 
elseif (v == "sc_toususabidingbeast")
 then v = "Scroll of Tousu's Abiding Beast" return v 
elseif (v == "sc_vaerminaspromise")
 then v = "Scroll of Vaermina's Promise" return v 
elseif (v == "sc_vigor")
 then v = "Scroll of Vigor" return v 
elseif (v == "sc_vitality")
 then v = "Scroll of Vitality" return v 
elseif (v == "sc_warriorsblessing")
 then v = "Scroll of Warrior's Blessing" return v 
elseif (v == "sc_windform")
 then v = "Scroll of Windform" return v 
elseif (v == "sc_windwalker")
 then v = "Scroll of Windwalker" return v 
elseif (v == "bk_CalderaRecordBook2")
 then v = "Secret Caldera Ledger" return v 
elseif (v == "bk_SecretsDwemerAnimunculi")
 then v = "Secrets of Dwemer Animunculi" return v 
elseif (v == "bk_seniliasreport")
 then v = "Senilius' Report" return v 
elseif (v == "bk_sharnslegionsofthedead")
 then v = "Sharn's Legions of the Dead" return v 
elseif (v == "bk_varoorders")
 then v = "Shipping Notice" return v 
elseif (v == "bk_shishireport")
 then v = "Shishi Report" return v 
elseif (v == "bookskill_illusion2")
 then v = "Silence" return v 
elseif (v == "BookSkill_Alteration3")
 then v = "Sithis" return v 
elseif (v == "bookskill_spear1")
 then v = "Smuggler's Island" return v 
elseif (v == "bk_notesoldout")
 then v = "Sold Out Notice" return v 
elseif (v == "BookSkill_Alchemy3")
 then v = "Song of the Alchemists" return v 
elseif (v == "bk_sottildescodebook")
 then v = "Sottilde's Code Book" return v 
elseif (v == "bk_specialfloraoftamriel")
 then v = "Special Flora of Tamriel" return v 
elseif (v == "bk_spiritofnirn")
 then v = "Spirit of Nirn, God of Mortals" return v 
elseif (v == "bk_SpiritOfTheDaedra")
 then v = "Spirit of the Daedra" return v 
elseif (v == "bk_SamarStarloversJournal")
 then v = "Starlover's Log" return v 
elseif (v == "bookskill_security5")
 then v = "Surfeit of Thieves" return v 
elseif (v == "bk_TalMarogKersResearches")
 then v = "Tal Marog Ker's Researches" return v 
elseif (v == "bk_Yagrum's_Book")
 then v = "Tamrielic Lore" return v 
elseif (v == "bk_Aedra_Tarer_Unique")
 then v = "Tarer's Aedra and Daedra" return v 
elseif (v == "bk_seydaneentaxrecord")
 then v = "Tax Record" return v 
elseif (v == "bk_Telvanni_Vault_Ledger")
 then v = "Telvanni Vault Ledger" return v 
elseif (v == "bk_AffairsOfWizards")
 then v = "The Affairs of Wizards" return v 
elseif (v == "bk_AlchemistsFormulary")
 then v = "The Alchemists Formulary" return v 
elseif (v == "bk_AnnotatedAnuad")
 then v = "The Annotated Anuad" return v 
elseif (v == "bk_ChildrensAnuad")
 then v = "The Annotated Anuad" return v 
elseif (v == "bk_Anticipations")
 then v = "The Anticipations" return v 
elseif (v == "bk_ArcturianHeresy")
 then v = "The Arcturian Heresy" return v 
elseif (v == "BookSkill_Armorer1")
 then v = "The Armorer's Challenge" return v 
elseif (v == "bookskill_destruction4")
 then v = "The Art of War Magic" return v 
elseif (v == "bookskill_axe2")
 then v = "The Axe Man" return v 
elseif (v == "bk_vivec_no_murder")
 then v = "The Battle of Red Mountain" return v 
elseif (v == "BookSkill_Acrobatics4")
 then v = "The Black Arrow, Volume 1" return v 
elseif (v == "bookskill_marksman5")
 then v = "The Black Arrow, Volume II" return v 
elseif (v == "bk_BlackGlove")
 then v = "The Black Glove" return v 
elseif (v == "bk_BlueBookOfRiddles")
 then v = "The Blue Book of Riddles" return v 
elseif (v == "bk_BookOfDaedra")
 then v = "The Book of Daedra" return v 
elseif (v == "bk_BookDawnAndDusk")
 then v = "The Book of Dawn and Dusk" return v 
elseif (v == "bk_BrothersOfDarkness")
 then v = "The Brothers of Darkness" return v 
elseif (v == "bookskill_mercantile1")
 then v = "The Buying Game" return v 
elseif (v == "BookSkill_Alchemy2")
 then v = "The Cake and the Diamond" return v 
elseif (v == "bk_CantatasOfVivec")
 then v = "The Cantatas of Vivec" return v 
elseif (v == "bk_ChangedOnes")
 then v = "The Changed Ones" return v 
elseif (v == "bk_ConsolationsOfPrayer")
 then v = "The Consolations of Prayer" return v 
elseif (v == "bk_DoorsOfTheSpirit")
 then v = "The Doors of the Spirit" return v 
elseif (v == "BookSkill_Security3")
 then v = "The Dowry" return v 
elseif (v == "BookSkill_Alteration2")
 then v = "The Dragon Break Re-Examined" return v 
elseif (v == "bk_easternprovincesimpartial")
 then v = "The Eastern Provinces..." return v 
elseif (v == "bk_EggOfTime")
 then v = "The Egg of Time" return v 
elseif (v == "bookskill_enchant5")
 then v = "The Final Lesson" return v 
elseif (v == "bk_firmament")
 then v = "The Firmament" return v 
elseif (v == "bookskill_mysticism1")
 then v = "The Firsthold Revolt" return v 
elseif (v == "bk_five_far_stars")
 then v = "The Five Far Stars" return v 
elseif (v == "bookskill_restoration3")
 then v = "The Four Suitors of Benitah" return v 
elseif (v == "bookskill_marksman1")
 then v = "The Gold Ribbon of Merit" return v 
elseif (v == "bookskill_blunt weapon1")
 then v = "The Hope of the Redoran" return v 
elseif (v == "bookskill_destruction1")
 then v = "The Horror of Castle Xyr" return v 
elseif (v == "bk_HouseOfTroubles_c")
 then v = "The House of Troubles" return v 
elseif (v == "bk_HouseOfTroubles_o")
 then v = "The House of Troubles" return v 
elseif (v == "BookSkill_Blunt Weapon2")
 then v = "The Importance of Where" return v 
elseif (v == "bk_LegendaryScourge")
 then v = "The Legendary Scourge" return v 
elseif (v == "bookskill_security1")
 then v = "The Locked Room" return v 
elseif (v == "bk_thelostprophecy")
 then v = "The Lost Prophecy" return v 
elseif (v == "BookSkill_Alteration5")
 then v = "The Lunar Lorkhan" return v 
elseif (v == "bk_lustyargonianmaid")
 then v = "The Lusty Argonian Maid" return v 
elseif (v == "bk_madnessofpelagius")
 then v = "The Madness of Pelagius" return v 
elseif (v == "bookskill_marksman4")
 then v = "The Marksmanship Lesson" return v 
elseif (v == "bookskill_block2")
 then v = "The Mirror" return v 
elseif (v == "bk_manyfacesmissinggod")
 then v = "The Monomyth" return v 
elseif (v == "bk_oldways")
 then v = "The Old Ways" return v 
elseif (v == "bk_PigChildren")
 then v = "The Pig Children" return v 
elseif (v == "bk_PilgrimsPath")
 then v = "The Pilgrim's Path" return v 
elseif (v == "bk_PostingOfTheHunt")
 then v = "The Posting of the Hunt" return v 
elseif (v == "bookskill_hand to hand1")
 then v = "The Prayers of Baranat" return v 
elseif (v == "BookSkill_Athletics1")
 then v = "The Ransom of Zarek" return v 
elseif (v == "bk_RealBarenziah1")
 then v = "The Real Barenziah v I" return v 
elseif (v == "bk_realbarenziah2")
 then v = "The Real Barenziah v II" return v 
elseif (v == "bk_realbarenziah3")
 then v = "The Real Barenziah v III" return v 
elseif (v == "bk_realbarenziah4")
 then v = "The Real Barenziah v IV" return v 
elseif (v == "bk_RealBarenziah5")
 then v = "The Real Barenziah v V" return v 
elseif (v == "bk_RealNerevar")
 then v = "The Real Nerevar" return v 
elseif (v == "BookSkill_Light Armor1")
 then v = "The Rear Guard" return v 
elseif (v == "bk_redbookofriddles")
 then v = "The Red Book of Riddles" return v 
elseif (v == "bk_tamrielicreligions")
 then v = "The Ruins of Kemel-Ze" return v 
elseif (v == "BookSkill_Axe3")
 then v = "The Seed" return v 
elseif (v == "bk_thesevencurses")
 then v = "The Seven Curses" return v 
elseif (v == "bk_a2_1_sevenvisions")
 then v = "The Seven Visions" return v 
elseif (v == "bk_a2_1_thestranger")
 then v = "The Stranger" return v 
elseif (v == "BookSkill_Axe1")
 then v = "The Third Door" return v 
elseif (v == "bk_truenatureoforcs")
 then v = "The True Nature of Orcs" return v 
elseif (v == "bk_truenoblescode")
 then v = "The True Noble's Code" return v 
elseif (v == "bk_VagariesOfMagica")
 then v = "The Vagaries of Magicka" return v 
elseif (v == "bk_WaroftheFirstCouncil")
 then v = "The War of the First Council" return v 
elseif (v == "bookskill_conjuration5")
 then v = "The Warrior's Charge" return v 
elseif (v == "bk_WatersOfOblivion")
 then v = "The Waters of Oblivion" return v 
elseif (v == "bk_wildelves")
 then v = "The Wild Elves" return v 
elseif (v == "bookskill_security2")
 then v = "The Wolf Queen, Book I" return v 
elseif (v == "bookskill_hand to hand2")
 then v = "The Wolf Queen, Book II" return v 
elseif (v == "bookskill_illusion1")
 then v = "The Wolf Queen, Book III" return v 
elseif (v == "bookskill_mercantile2")
 then v = "The Wolf Queen, Book IV" return v 
elseif (v == "bookskill_speechcraft2")
 then v = "The Wolf Queen, Book V" return v 
elseif (v == "bookskill_sneak1")
 then v = "The Wolf Queen, Book VI" return v 
elseif (v == "bookskill_speechcraft4")
 then v = "The Wolf Queen, Book VII" return v 
elseif (v == "BookSkill_Enchant2")
 then v = "The Wolf Queen, Book VIII" return v 
elseif (v == "bookskill_unarmored1")
 then v = "The Wraith's Wedding Dowry" return v 
elseif (v == "bk_yellowbookofriddles")
 then v = "The Yellow Book of Riddles" return v 
elseif (v == "bk_tiramgadarscredentials")
 then v = "Tiram Gadar's Credentials" return v 
elseif (v == "bk_arrilles_tradehouse")
 then v = "tradehouse notice" return v 
elseif (v == "bookskill_sneak4")
 then v = "Trap" return v 
elseif (v == "bk_treasuryorders")
 then v = "Treasury Orders" return v 
elseif (v == "bk_treasuryreport")
 then v = "Treasury Report" return v 
elseif (v == "bookskill_short blade1")
 then v = "Unnamed Book" return v 
elseif (v == "bk_vampiresofvvardenfell1")
 then v = "Vampires of Vvardenfell, v I" return v 
elseif (v == "bk_vampiresofvvardenfell2")
 then v = "Vampires of Vvardenfell, v II" return v 
elseif (v == "bk_varietiesoffaithintheempire")
 then v = "Varieties of Faith..." return v 
elseif (v == "bookskill_marksman3")
 then v = "Vernaccus and Bourlor" return v 
elseif (v == "bk_vivecandmephala")
 then v = "Vivec and Mephala" return v 
elseif (v == "bk_Warehouse_log")
 then v = "Warehouse shipping log" return v 
elseif (v == "bk_contract_ralen")
 then v = "Weapons and Armor Contract" return v 
elseif (v == "bk_wherewereyoudragonbroke")
 then v = "Where Were You ... Dragon Broke" return v 
elseif (v == "bk_widowdeed")
 then v = "Widow Vabdas' Land Deed" return v 
elseif (v == "bookskill_restoration1")
 then v = "Withershins" return v 
elseif (v == "BookSkill_Long Blade1")
 then v = "Words and Philosophy" return v 
elseif (v == "bk_wordsclanmother")
 then v = "Words of Clan Mother Ahnissi" return v 
elseif (v == "bk_words_of_the_wind")
 then v = "Words of the Wind" return v 
elseif (v == "bk_yellowbook426")
 then v = "Yellow Book of 3E 426" return v 
elseif (v == "bk_ynglingledger")
 then v = "Yngling's Ledger" return v 
elseif (v == "bk_ynglingletter")
 then v = "Yngling's Letter" return v 
elseif (v == "bk_a1_11_zainsubaninotes")
 then v = "Zainsubani's Notes" return v 
elseif (v == "amulet of 6th house")
 then v = "6th House Amulet" return v 
elseif (v == "Adusamsi's_Ring")
 then v = "Adusamsi's Ring" return v 
elseif (v == "Adusamsi's_robe")
 then v = "Adusamsi's Robe" return v 
elseif (v == "Akatosh Ring")
 then v = "Akatosh's Ring" return v 
elseif (v == "Akatosh's Ring")
 then v = "Akatosh's Ring" return v 
elseif (v == "amulet of admonition")
 then v = "Amulet of Admonition" return v 
elseif (v == "amulet of almsivi intervention")
 then v = "Amulet of Almsivi Intervention" return v 
elseif (v == "amulet of ashamanu (unique)")
 then v = "Amulet of Ashamanu" return v 
elseif (v == "amulet of balyna's antidote")
 then v = "Amulet of Balyna's Antidote" return v 
elseif (v == "amulet of divine intervention")
 then v = "Amulet of Divine Intervention" return v 
elseif (v == "amulet of domination")
 then v = "Amulet of Domination" return v 
elseif (v == "amulet of far silence")
 then v = "Amulet of Far Silence" return v 
elseif (v == "amuletfleshmadewhole_uniq")
 then v = "Amulet of Flesh Made Whole" return v 
elseif (v == "amulet of frost")
 then v = "Amulet of Frost" return v 
elseif (v == "amulet_gem_feeding")
 then v = "Amulet of Gem Feeding" return v 
elseif (v == "amulet of health")
 then v = "Amulet of Health" return v 
elseif (v == "artifact_amulet of heartfire")
 then v = "Amulet of Heartfire" return v 
elseif (v == "artifact_amulet of heartheal")
 then v = "Amulet of Heartheal" return v 
elseif (v == "artifact_amulet of heartrime")
 then v = "Amulet of Heartrime" return v 
elseif (v == "artifact_amulet of heartthrum")
 then v = "Amulet of Heartthrum" return v 
elseif (v == "amulet of igniis")
 then v = "Amulet of Igniis" return v 
elseif (v == "amulet of levitating")
 then v = "Amulet of Levitating" return v 
elseif (v == "amulet of light")
 then v = "Amulet of Light" return v 
elseif (v == "amulet of locking")
 then v = "Amulet of Locking" return v 
elseif (v == "amulet of mark")
 then v = "Amulet of Mark" return v 
elseif (v == "amulet of mighty blows")
 then v = "Amulet of Mighty Blows" return v 
elseif (v == "amulet of opening")
 then v = "Amulet of Opening" return v 
elseif (v == "amulet of recall")
 then v = "Amulet of Recall" return v 
elseif (v == "amulet of rest")
 then v = "Amulet of Rest" return v 
elseif (v == "sanguineamuletenterprise")
 then v = "Amulet of Sanguine Enterprise" return v 
elseif (v == "sanguineamuletglibspeech")
 then v = "Amulet of Sanguine Glib Speech" return v 
elseif (v == "sanguineamuletnimblearmor")
 then v = "Amulet of Sanguine Nimble Armor" return v 
elseif (v == "amulet of shades")
 then v = "Amulet of Shades" return v 
elseif (v == "amulet of shadows")
 then v = "Amulet of Shadows" return v 
elseif (v == "amulet of shield")
 then v = "Amulet of Shield" return v 
elseif (v == "amulet of silence")
 then v = "Amulet of Silence" return v 
elseif (v == "amulet of slowfalling")
 then v = "Amulet of Slowfalling" return v 
elseif (v == "amulet of balyna's soothing bal")
 then v = "Amulet of Soothing Balm" return v 
elseif (v == "amulet of spell absorption")
 then v = "Amulet of Spell Absorption" return v 
elseif (v == "amulet of stamina")
 then v = "Amulet of Stamina" return v 
elseif (v == "amulet_unity_uniq")
 then v = "Amulet of Unity" return v 
elseif (v == "amulet_usheeja")
 then v = "Amulet of Usheeja" return v 
elseif (v == "amulet of water walking")
 then v = "Amulet of Water Walking" return v 
elseif (v == "summon ancestor amulet")
 then v = "Ancestor's Amulet" return v 
elseif (v == "ancestor's ring")
 then v = "Ancestor's Ring" return v 
elseif (v == "Exquisite_Amulet_Arobar1")
 then v = "Arobar's Amulet" return v 
elseif (v == "aryongloveleft")
 then v = "Aryon's Dominator" return v 
elseif (v == "aryongloveright")
 then v = "Aryon's Helper" return v 
elseif (v == "exquisite_shirt_01_wedding")
 then v = "Ashkhan's Wedding Gift" return v 
elseif (v == "amulet_Agustas_unique")
 then v = "Augustus' Amulet" return v 
elseif (v == "amulet_aundae")
 then v = "Aundae Amulet" return v 
elseif (v == "extravagant_ring_aund_uni")
 then v = "Aundae Signet Ring" return v 
elseif (v == "balm amulet")
 then v = "Balm Amulet" return v 
elseif (v == "belt of balyna's soothing balm")
 then v = "Belt of Balyna's Soothing Balm" return v 
elseif (v == "belt of charisma")
 then v = "Belt of Charisma" return v 
elseif (v == "belt of fortitude")
 then v = "Belt of Fortitude" return v 
elseif (v == "belt of free action")
 then v = "Belt of Free Action" return v 
elseif (v == "artifact_belt_of_heartfire")
 then v = "Belt of Heartfire" return v 
elseif (v == "belt of heartfire")
 then v = "Belt of Heartfire" return v 
elseif (v == "extravagant_belt_hf")
 then v = "Belt of Heartfire" return v 
elseif (v == "belt of feet of notorgo")
 then v = "Belt of Iron Will" return v 
elseif (v == "belt of iron will")
 then v = "Belt of Iron Will" return v 
elseif (v == "belt of jack of trades")
 then v = "Belt of Jack of Trades" return v 
elseif (v == "belt of nimbleness")
 then v = "Belt of Nimbleness" return v 
elseif (v == "Belt of Northern Knuck Knuck")
 then v = "Belt of Northern Knuck Knuck" return v 
elseif (v == "belt of orc's strength")
 then v = "Belt of Orc's Strength" return v 
elseif (v == "sanguinebeltbalancedarmor")
 then v = "Belt of Sanguine Balanced Armor" return v 
elseif (v == "sanguinebeltdeepbiting")
 then v = "Belt of Sanguine Deep Biting" return v 
elseif (v == "sanguinebeltdenial")
 then v = "Belt of Sanguine Denial" return v 
elseif (v == "sanguinebeltfleetness")
 then v = "Belt of Sanguine Fleetness" return v 
elseif (v == "sanguinebelthewing")
 then v = "Belt of Sanguine Hewing" return v 
elseif (v == "sanguinebeltimpaling")
 then v = "Belt of Sanguine Impaling Thrus" return v 
elseif (v == "sanguinebeltmartialcraft")
 then v = "Belt of Sanguine Martial Craft" return v 
elseif (v == "sanguinebeltsmiting")
 then v = "Belt of Sanguine Smiting" return v 
elseif (v == "sanguinebeltstolidarmor")
 then v = "Belt of Sanguine Stolid Armor" return v 
elseif (v == "sanguinebeltsureflight")
 then v = "Belt of Sanguine Sureflight" return v 
elseif (v == "belt of the armor of god")
 then v = "Belt of the Armor of God" return v 
elseif (v == "hortatorbelt")
 then v = "Belt of the Hortator" return v 
elseif (v == "belt of vigor")
 then v = "Belt of Vigor" return v 
elseif (v == "belt of wisdom")
 then v = "Belt of Wisdom" return v 
elseif (v == "amulet_berne")
 then v = "Berne Amulet" return v 
elseif (v == "bitter_hand")
 then v = "Bitter Hand" return v 
elseif (v == "ring_blackjinx_uniq")
 then v = "Black Jinx" return v 
elseif (v == "common_glove_l_moragtong")
 then v = "Black Left Glove" return v 
elseif (v == "common_glove_r_moragtong")
 then v = "Black Right Glove" return v 
elseif (v == "blind ring")
 then v = "Blind Ring" return v 
elseif (v == "blood belt")
 then v = "Blood Belt" return v 
elseif (v == "blood despair amulet")
 then v = "Blood Despair Amulet" return v 
elseif (v == "artifact_blood_ring")
 then v = "Blood Ring" return v 
elseif (v == "blood ring")
 then v = "Blood Ring" return v 
elseif (v == "bonebiter charm")
 then v = "Bonebiter Charm" return v 
elseif (v == "bone charm")
 then v = "Bone Charm" return v 
elseif (v == "bone guard belt")
 then v = "Bone Guard Belt" return v 
elseif (v == "exquisite_ring_brallion")
 then v = "Brallion's Exquisite Ring" return v 
elseif (v == "brawlers_belt")
 then v = "Brawler's Belt" return v 
elseif (v == "sarandas_shirt_2")
 then v = "Brocade Shirt" return v 
elseif (v == "bugharz's belt")
 then v = "Bugharz's Belt" return v 
elseif (v == "Caius_pants")
 then v = "Caius' Black Pants" return v 
elseif (v == "caius_shirt")
 then v = "Caius' Black Shirt" return v 
elseif (v == "Caius_ring")
 then v = "Caius' Ring" return v 
elseif (v == "caliginy ring")
 then v = "Caliginy Ring" return v 
elseif (v == "chameleon ring")
 then v = "Chameleon Ring" return v 
elseif (v == "champion belt")
 then v = "Champion Belt" return v 
elseif (v == "clench charm")
 then v = "Clench Charm" return v 
elseif (v == "common_amulet_01")
 then v = "Common Amulet" return v 
elseif (v == "common_amulet_02")
 then v = "Common Amulet" return v 
elseif (v == "common_amulet_03")
 then v = "Common Amulet" return v 
elseif (v == "common_amulet_04")
 then v = "Common Amulet" return v 
elseif (v == "common_amulet_05")
 then v = "Common Amulet" return v 
elseif (v == "common_belt_01")
 then v = "Common Belt" return v 
elseif (v == "common_belt_02")
 then v = "Common Belt" return v 
elseif (v == "common_belt_03")
 then v = "Common Belt" return v 
elseif (v == "common_belt_04")
 then v = "Common Belt" return v 
elseif (v == "common_belt_05")
 then v = "Common Belt" return v 
elseif (v == "common_glove_left_01")
 then v = "Common Left Glove" return v 
elseif (v == "common_pants_01")
 then v = "Common Pants" return v 
elseif (v == "common_pants_01_a")
 then v = "Common Pants" return v 
elseif (v == "common_pants_01_e")
 then v = "Common Pants" return v 
elseif (v == "common_pants_01_u")
 then v = "Common Pants" return v 
elseif (v == "common_pants_01_z")
 then v = "Common Pants" return v 
elseif (v == "common_pants_02")
 then v = "Common Pants" return v 
elseif (v == "common_pants_03")
 then v = "Common Pants" return v 
elseif (v == "common_pants_03_b")
 then v = "Common Pants" return v 
elseif (v == "common_pants_03_c")
 then v = "Common Pants" return v 
elseif (v == "common_pants_04")
 then v = "Common Pants" return v 
elseif (v == "common_pants_04_b")
 then v = "Common Pants" return v 
elseif (v == "common_pants_05")
 then v = "Common Pants" return v 
elseif (v == "common_glove_right_01")
 then v = "Common Right Glove" return v 
elseif (v == "common_ring_01")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_arena")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_fg_corp01")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_fg_nchur01")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_fg_nchur02")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_fg_nchur03")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_fg_nchur04")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_haunt_Ken")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_mgbwg")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_mge")
 then v = "Common Ring" return v 
elseif (v == "common_ring_01_tt_mountkand")
 then v = "Common Ring" return v 
elseif (v == "common_ring_02")
 then v = "Common Ring" return v 
elseif (v == "common_ring_03")
 then v = "Common Ring" return v 
elseif (v == "common_ring_04")
 then v = "Common Ring" return v 
elseif (v == "common_ring_05")
 then v = "Common Ring" return v 
elseif (v == "common_robe_01")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_h")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_hh")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_r")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_rr")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_t")
 then v = "Common Robe" return v 
elseif (v == "common_robe_02_tt")
 then v = "Common Robe" return v 
elseif (v == "common_robe_03")
 then v = "Common Robe" return v 
elseif (v == "common_robe_03_a")
 then v = "Common Robe" return v 
elseif (v == "common_robe_03_b")
 then v = "Common Robe" return v 
elseif (v == "common_robe_04")
 then v = "Common Robe" return v 
elseif (v == "common_robe_05")
 then v = "Common Robe" return v 
elseif (v == "common_robe_05_a")
 then v = "Common Robe" return v 
elseif (v == "common_robe_05_b")
 then v = "Common Robe" return v 
elseif (v == "common_robe_05_c")
 then v = "Common Robe" return v 
elseif (v == "common_shirt_01")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_01_a")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_01_e")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_01_u")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_01_z")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_h")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_hh")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_r")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_rr")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_t")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_02_tt")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_03")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_03_b")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_03_c")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_04")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_04_a")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_04_b")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_04_c")
 then v = "Common Shirt" return v 
elseif (v == "common_shirt_05")
 then v = "Common Shirt" return v 
elseif (v == "common_shoes_01")
 then v = "Common Shoes" return v 
elseif (v == "common_shoes_02")
 then v = "Common Shoes" return v 
elseif (v == "common_shoes_03")
 then v = "Common Shoes" return v 
elseif (v == "common_shoes_04")
 then v = "Common Shoes" return v 
elseif (v == "common_shoes_05")
 then v = "Common Shoes" return v 
elseif (v == "common_skirt_01")
 then v = "Common Skirt" return v 
elseif (v == "common_skirt_02")
 then v = "Common Skirt" return v 
elseif (v == "common_skirt_03")
 then v = "Common Skirt" return v 
elseif (v == "common_skirt_04")
 then v = "Common Skirt" return v 
elseif (v == "common_skirt_04_c")
 then v = "Common Skirt" return v 
elseif (v == "common_skirt_05")
 then v = "Common Skirt" return v 
elseif (v == "crimson despair amulet")
 then v = "Crimson Despair Amulet" return v 
elseif (v == "cruel flamebolt ring")
 then v = "Cruel Flamebolt Ring" return v 
elseif (v == "cruel shardbolt ring")
 then v = "Cruel Shardbolt Ring" return v 
elseif (v == "cruel sparkbolt ring")
 then v = "Cruel Sparkbolt Ring" return v 
elseif (v == "cruel viperbolt ring")
 then v = "Cruel Viperbolt Ring" return v 
elseif (v == "crying ring")
 then v = "Crying Ring" return v 
elseif (v == "Daedric_special")
 then v = "Daedric Sanctuary Amulet" return v 
elseif (v == "common_ring_danar")
 then v = "Danar's Ring" return v 
elseif (v == "expensive_amulet_delyna")
 then v = "Delyna's Locket" return v 
elseif (v == "ring_denstagmer_unique")
 then v = "Denstagmer's Ring" return v 
elseif (v == "sarandas_shoes_2")
 then v = "Designer Shoes" return v 
elseif (v == "Detect_Enchantment_ring")
 then v = "Detect Enchantment Ring" return v 
elseif (v == "dire flamebolt ring")
 then v = "Dire Flamebolt Ring" return v 
elseif (v == "dire shardbolt ring")
 then v = "Dire Shardbolt Ring" return v 
elseif (v == "dire sparkbolt ring")
 then v = "Dire Sparkbolt Ring" return v 
elseif (v == "dire viperbolt ring")
 then v = "Dire Viperbolt Ring" return v 
elseif (v == "distraction ring")
 then v = "Distraction Ring" return v 
elseif (v == "doze charm")
 then v = "Doze Charm" return v 
elseif (v == "sarandas_ring_2")
 then v = "Ebony Ring" return v 
elseif (v == "black_blindfold_glove")
 then v = "Elvul's Black Blindfold" return v 
elseif (v == "ember_hand")
 then v = "Ember Hand" return v 
elseif (v == "ember hand")
 then v = "Ember Hand" return v 
elseif (v == "peakstar_belt_unique")
 then v = "Embroidered belt" return v 
elseif (v == "ring_keley")
 then v = "Engraved Ring of Healing" return v 
elseif (v == "evil eye charm")
 then v = "Evil Eye Charm" return v 
elseif (v == "expensive_amulet_01")
 then v = "Expensive Amulet" return v 
elseif (v == "expensive_amulet_02")
 then v = "Expensive Amulet" return v 
elseif (v == "expensive_amulet_03")
 then v = "Expensive Amulet" return v 
elseif (v == "expensive_amulet_aeta")
 then v = "Expensive Amulet" return v 
elseif (v == "expensive_belt_01")
 then v = "Expensive Belt" return v 
elseif (v == "expensive_belt_02")
 then v = "Expensive Belt" return v 
elseif (v == "expensive_belt_03")
 then v = "Expensive Belt" return v 
elseif (v == "expensive_glove_left_01")
 then v = "Expensive Left Glove" return v 
elseif (v == "expensive_pants_01")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_01_a")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_01_e")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_01_u")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_01_z")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_02")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_pants_03")
 then v = "Expensive Pants" return v 
elseif (v == "expensive_glove_right_01")
 then v = "Expensive Right Glove" return v 
elseif (v == "expensive_ring_01")
 then v = "Expensive Ring" return v 
elseif (v == "expensive_ring_01_BILL")
 then v = "Expensive Ring" return v 
elseif (v == "expensive_ring_02")
 then v = "Expensive Ring" return v 
elseif (v == "expensive_ring_03")
 then v = "Expensive Ring" return v 
elseif (v == "expensive_ring_aeta")
 then v = "Expensive Ring" return v 
elseif (v == "expensive_robe_01")
 then v = "Expensive Robe" return v 
elseif (v == "expensive_robe_02")
 then v = "Expensive Robe" return v 
elseif (v == "expensive_robe_02_a")
 then v = "Expensive Robe" return v 
elseif (v == "expensive_robe_03")
 then v = "Expensive Robe" return v 
elseif (v == "expensive_shirt_01")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_01_a")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_01_e")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_01_u")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_01_z")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_02")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shirt_03")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_skirt_03")
 then v = "Expensive Shirt" return v 
elseif (v == "expensive_shoes_01")
 then v = "Expensive Shoes" return v 
elseif (v == "expensive_shoes_02")
 then v = "Expensive Shoes" return v 
elseif (v == "expensive_shoes_03")
 then v = "Expensive Shoes" return v 
elseif (v == "expensive_skirt_01")
 then v = "Expensive Skirt" return v 
elseif (v == "expensive_skirt_02")
 then v = "Expensive Skirt" return v 
elseif (v == "exquisite_amulet_01")
 then v = "Exquisite Amulet" return v 
elseif (v == "exquisite_belt_01")
 then v = "Exquisite Belt" return v 
elseif (v == "exquisite_pants_01")
 then v = "Exquisite Pants" return v 
elseif (v == "exquisite_ring_01")
 then v = "Exquisite Ring" return v 
elseif (v == "exquisite_ring_02")
 then v = "Exquisite Ring" return v 
elseif (v == "exquisite_robe_01")
 then v = "Exquisite Robe" return v 
elseif (v == "exquisite_shirt_01")
 then v = "Exquisite Shirt" return v 
elseif (v == "exquisite_shirt_01_rasha")
 then v = "Exquisite Shirt" return v 
elseif (v == "exquisite_shoes_01")
 then v = "Exquisite Shoes" return v 
elseif (v == "exquisite_skirt_01")
 then v = "Exquisite Skirt" return v 
elseif (v == "extravagant_belt_01")
 then v = "Extravagant Belt" return v 
elseif (v == "extravagant_belt_02")
 then v = "Extravagant Belt" return v 
elseif (v == "extravagant_glove_left_01")
 then v = "Extravagant Left Glove" return v 
elseif (v == "extravagant_pants_01")
 then v = "Extravagant Pants" return v 
elseif (v == "extravagant_pants_02")
 then v = "Extravagant Pants" return v 
elseif (v == "extravagant_glove_right_01")
 then v = "Extravagant Right Glove" return v 
elseif (v == "extravagant_ring_01")
 then v = "Extravagant Ring" return v 
elseif (v == "extravagant_ring_02")
 then v = "Extravagant Ring" return v 
elseif (v == "extravagant_robe_01")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_a")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_b")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_c")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_h")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_r")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_01_t")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_robe_02")
 then v = "Extravagant Robe" return v 
elseif (v == "extravagant_amulet_02")
 then v = "Extravagant Ruby Amulet" return v 
elseif (v == "extravagant_amulet_01")
 then v = "Extravagant Sapphire Amulet" return v 
elseif (v == "extravagant_shirt_01")
 then v = "Extravagant Shirt" return v 
elseif (v == "extravagant_shirt_01_h")
 then v = "Extravagant Shirt" return v 
elseif (v == "extravagant_shirt_01_r")
 then v = "Extravagant Shirt" return v 
elseif (v == "extravagant_shirt_01_t")
 then v = "Extravagant Shirt" return v 
elseif (v == "extravagant_shirt_02")
 then v = "Extravagant Shirt" return v 
elseif (v == "extravagant_shoes_01")
 then v = "Extravagant Shoes" return v 
elseif (v == "extravagant_shoes_02")
 then v = "Extravagant Shoes" return v 
elseif (v == "extravagant_skirt_01")
 then v = "Extravagant Skirt" return v 
elseif (v == "extravagant_skirt_02")
 then v = "Extravagant Skirt" return v 
elseif (v == "eye-maze ring")
 then v = "Eye-Maze Ring" return v 
elseif (v == "ring_fathasa_unique")
 then v = "Fathasa's Ring" return v 
elseif (v == "father's belt")
 then v = "Father's Belt" return v 
elseif (v == "feather belt")
 then v = "Feather Belt" return v 
elseif (v == "feather ring")
 then v = "Feather Ring" return v 
elseif (v == "fenrick's doorjam ring")
 then v = "Fenrick's Doorjam Ring" return v 
elseif (v == "fighter_ring")
 then v = "Fighter Ring" return v 
elseif (v == "sarandas_amulet")
 then v = "Firejade Amulet" return v 
elseif (v == "firestone")
 then v = "Firestone" return v 
elseif (v == "first barrier belt")
 then v = "First Barrier Belt" return v 
elseif (v == "first barrier ring")
 then v = "First Barrier Ring" return v 
elseif (v == "flamebolt ring")
 then v = "Flamebolt Ring" return v 
elseif (v == "flameeater robe")
 then v = "Flameeater Robe" return v 
elseif (v == "flameguard robe")
 then v = "Flameguard Robe" return v 
elseif (v == "flamemirror robe")
 then v = "Flamemirror Robe" return v 
elseif (v == "foe-grinder")
 then v = "Foe-Grinder" return v 
elseif (v == "foe-quern")
 then v = "Foe-Quern" return v 
elseif (v == "founder's belt")
 then v = "Founder's Belt" return v 
elseif (v == "frosteater robe")
 then v = "Frosteater Robe" return v 
elseif (v == "frostguard robe")
 then v = "Frostguard Robe" return v 
elseif (v == "frostmirror robe")
 then v = "Frostmirror Robe" return v 
elseif (v == "fuddle charm")
 then v = "Fuddle Charm" return v 
elseif (v == "extravagant_rt_art_wild")
 then v = "Gambolpuddy" return v 
elseif (v == "ghost charm")
 then v = "Ghost Charm" return v 
elseif (v == "sarandas_ring_1")
 then v = "Glass Ring" return v 
elseif (v == "sanguinerglovehornyfist")
 then v = "Glove of Sanguine Horny Fist" return v 
elseif (v == "sanguinelglovesafekeeping")
 then v = "Glove of Sanguine Safekeeping" return v 
elseif (v == "sanguinergloveswiftblade")
 then v = "Glove of Sanguine Swiftblade" return v 
elseif (v == "common_shirt_gondolier")
 then v = "Gondolier Shirt" return v 
elseif (v == "graveward amulet")
 then v = "Graveward Amulet" return v 
elseif (v == "gripes charm")
 then v = "Gripes Charm" return v 
elseif (v == "expensive_shirt_hair")
 then v = "Hair Shirt of Saint Aralor" return v 
elseif (v == "hawkshaw ring")
 then v = "Hawkshaw Ring" return v 
elseif (v == "heartbite ring")
 then v = "Heartbite Ring" return v 
elseif (v == "hearth belt")
 then v = "Hearth Belt" return v 
elseif (v == "artifact_heart_ring")
 then v = "Heart Ring" return v 
elseif (v == "heart ring")
 then v = "Heart Ring" return v 
elseif (v == "heartstone")
 then v = "Heartstone" return v 
elseif (v == "common_pants_02_hentus")
 then v = "Hentus Pants" return v 
elseif (v == "herder's belt")
 then v = "Herder's Belt" return v 
elseif (v == "hex charm")
 then v = "Hex Charm" return v 
elseif (v == "exquisite_amulet_hlervu1")
 then v = "Hlervu Locket" return v 
elseif (v == "hlervu_locket_unique")
 then v = "Hlervu Locket" return v 
elseif (v == "hoptoad ring")
 then v = "Hoptoad Ring" return v 
elseif (v == "hort_ledd_robe_unique")
 then v = "Hort-Ledd's Robe" return v 
elseif (v == "hunter's belt")
 then v = "Hunter's Belt" return v 
elseif (v == "expensive_glove_left_ilmeni")
 then v = "Ilmeni's glove" return v 
elseif (v == "imperial belt")
 then v = "Imperial Belt" return v 
elseif (v == "imperial skirt_clothing")
 then v = "Imperial Skirt" return v 
elseif (v == "templar belt")
 then v = "Imperial Templar Belt" return v 
elseif (v == "templar skirt obj")
 then v = "Imperial Templar Skirt" return v 
elseif (v == "indoril_belt")
 then v = "Indoril Belt" return v 
elseif (v == "juicedaw ring")
 then v = "Juicedaw Feather Ring" return v 
elseif (v == "Julielle_Aumines_Amulet")
 then v = "Julielle Aumine's Amulet" return v 
elseif (v == "khan belt")
 then v = "Khan Belt" return v 
elseif (v == "common_glove_l_balmolagmer")
 then v = "Left Bal Molagmer Glove" return v 
elseif (v == "Left_Hand_of_Zenithar")
 then v = "Left Hand of Zenithar" return v 
elseif (v == "Left_Hand_of_Zenithar_EN")
 then v = "Left Hand of Zenithar" return v 
elseif (v == "life belt")
 then v = "Life Belt" return v 
elseif (v == "life ring")
 then v = "Life Ring" return v 
elseif (v == "lifestone")
 then v = "Lifestone" return v 
elseif (v == "light amulet")
 then v = "Light Amulet" return v 
elseif (v == "light ring")
 then v = "Light Ring" return v 
elseif (v == "Linus_Iulus_Maran Amulet")
 then v = "Linus Iulus' Maran Amulet" return v 
elseif (v == "Linus_Iulus_Stendarran_Belt")
 then v = "Linus Iulus' Stendarran Belt" return v 
elseif (v == "madstone")
 then v = "Madstone of the Ahemmusa" return v 
elseif (v == "mage_ring")
 then v = "Mage Ring" return v 
elseif (v == "magickguard robe")
 then v = "Magickguard Robe" return v 
elseif (v == "malipu_ataman's_belt")
 then v = "Malipu-Ataman's Belt" return v 
elseif (v == "mandas_locket")
 then v = "Mandas Family Locket" return v 
elseif (v == "Maran Amulet")
 then v = "Maran Amulet" return v 
elseif (v == "ring_marara_unique")
 then v = "Marara's Ring" return v 
elseif (v == "Maras_Blouse")
 then v = "Mara's Blouse" return v 
elseif (v == "Maras_Skirt")
 then v = "Mara's Skirt" return v 
elseif (v == "Mark_Ring")
 then v = "Mark Ring" return v 
elseif (v == "extravagant_glove_left_maur")
 then v = "Maurrie's Left Glove" return v 
elseif (v == "extravagant_glove_right_maur")
 then v = "Maurrie's Right Glove" return v 
elseif (v == "ring_mentor_unique")
 then v = "Mentor's Ring" return v 
elseif (v == "expensive_amulet_methas")
 then v = "Methas Hlaalu's Amulet" return v 
elseif (v == "moon_and_star")
 then v = "Moon-and-Star" return v 
elseif (v == "mother's ring")
 then v = "Mother's Ring" return v 
elseif (v == "murdrum ring")
 then v = "Murdrum Ring" return v 
elseif (v == "necromancers_amulet_uniq")
 then v = "Necromancer's Amulet" return v 
elseif (v == "Expensive_Ring_01_HRDT")
 then v = "Nervion Ancestor Ring" return v 
elseif (v == "Nuccius_ring")
 then v = "Nuccius's Cursed Ring" return v 
elseif (v == "ondusi's key")
 then v = "Ondusi's Key" return v 
elseif (v == "othril_ring")
 then v = "Othril Ring" return v 
elseif (v == "poisoneater robe")
 then v = "Poisoneater Robe" return v 
elseif (v == "poisonguard robe")
 then v = "Poisonguard Robe" return v 
elseif (v == "poisonmirror robe")
 then v = "Poisonmirror Robe" return v 
elseif (v == "amulet_Pop00")
 then v = "Pop's Amulet" return v 
elseif (v == "exquisite_ring_processus")
 then v = "Processus Vitellius' Ring" return v 
elseif (v == "amulet_quarra")
 then v = "Quarra Amulet" return v 
elseif (v == "sarandas_belt")
 then v = "Racer Suede Belt" return v 
elseif (v == "Recall_Ring")
 then v = "Recall Ring" return v 
elseif (v == "Extravagant_Robe_01_Red")
 then v = "Redas Robe of Deeds" return v 
elseif (v == "red despair amulet")
 then v = "Red Despair Amulet" return v 
elseif (v == "Restoration_Shirt")
 then v = "Restoration Shirt" return v 
elseif (v == "common_glove_r_balmolagmer")
 then v = "Right Bal Molagmer Glove" return v 
elseif (v == "Right_Hand_of_Zenithar")
 then v = "Right Hand of Zenithar" return v 
elseif (v == "ring of aversion")
 then v = "Ring of Aversion" return v 
elseif (v == "ring of azura")
 then v = "Ring of Azura" return v 
elseif (v == "ring_dahrkmezalf_uniq")
 then v = "Ring of Dahrk Mezalf" return v 
elseif (v == "ring_equity_uniq")
 then v = "Ring of Equity" return v 
elseif (v == "ring of exhaustion")
 then v = "Ring of Exhaustion" return v 
elseif (v == "ring of telekinesis_UNIQUE")
 then v = "Ring of Far Reaching" return v 
elseif (v == "ring of fireball")
 then v = "Ring of Fireball" return v 
elseif (v == "ring of fireballs")
 then v = "Ring of Fireballs" return v 
elseif (v == "ring of firefist")
 then v = "Ring of Firefist" return v 
elseif (v == "ring of fire storm")
 then v = "Ring of Fire Storm" return v 
elseif (v == "ring of fleabite")
 then v = "Ring of Fleabite" return v 
elseif (v == "ring of hornhand")
 then v = "Ring of Hornhand" return v 
elseif (v == "ring of ice bolts")
 then v = "Ring of Ice Bolts" return v 
elseif (v == "ring of icegrip")
 then v = "Ring of Icegrip" return v 
elseif (v == "ring of ice storm")
 then v = "Ring of Ice Storm" return v 
elseif (v == "ring of ironhand")
 then v = "Ring of Ironhand" return v 
elseif (v == "ring_khajiit_unique")
 then v = "Ring of Khajiit" return v 
elseif (v == "ring of knuckle luck")
 then v = "Ring of Knuckle Luck" return v 
elseif (v == "ring of lightning bolt")
 then v = "Ring of Lightning Bolt" return v 
elseif (v == "ring of lightning storm")
 then v = "Ring of Lightning Storm" return v 
elseif (v == "ring of medusa's gaze")
 then v = "Ring of Medusa's Gaze" return v 
elseif (v == "Ring of Night-Eye")
 then v = "Ring of Night-Eye" return v 
elseif (v == "ring of nullification")
 then v = "Ring of Nullification" return v 
elseif (v == "ring_phynaster_unique")
 then v = "Ring of Phynaster" return v 
elseif (v == "ring of poisonblooms")
 then v = "Ring of Poisonblooms" return v 
elseif (v == "cl_ringofregeneration")
 then v = "Ring of Regeneration" return v 
elseif (v == "sanguineringfluidevasion")
 then v = "Ring of Sanguine Fluid Evasion" return v 
elseif (v == "sanguineringgoldenw")
 then v = "Ring of Sanguine Golden Wisdom" return v 
elseif (v == "sanguineringgreenw")
 then v = "Ring of Sanguine Green Wisdom" return v 
elseif (v == "sanguineringredw")
 then v = "Ring of Sanguine Red Wisdom" return v 
elseif (v == "sanguineringsilverw")
 then v = "Ring of Sanguine Silver Wisdom" return v 
elseif (v == "sanguineringsublimew")
 then v = "Ring of Sanguine Sublime Wisdom" return v 
elseif (v == "sanguineringtranscendw")
 then v = "Ring of Sanguine Transcendence" return v 
elseif (v == "sanguineringtransfigurw")
 then v = "Ring of Sanguine Transfiguring" return v 
elseif (v == "sanguineringunseenw")
 then v = "Ring of Sanguine Unseen Wisdom" return v 
elseif (v == "ring of shadow form")
 then v = "Ring of Shadow Form" return v 
elseif (v == "ring of shockballs")
 then v = "Ring of Shockballs" return v 
elseif (v == "ring of shocking touch")
 then v = "Ring of Shocking Touch" return v 
elseif (v == "ring of sphere of negation")
 then v = "Ring of Sphere of Negation" return v 
elseif (v == "ring of stormhand")
 then v = "Ring of Stormhand" return v 
elseif (v == "ring_surrounding_unique")
 then v = "Ring of Surroundings" return v 
elseif (v == "ring of tears")
 then v = "Ring of Tears" return v 
elseif (v == "ring of the black hand")
 then v = "Ring of the Black Hand" return v 
elseif (v == "ring of the five fingers of pai")
 then v = "Ring of the Five Fingers of Pai" return v 
elseif (v == "hortatorring")
 then v = "Ring of the Hortator" return v 
elseif (v == "ring_wind_unique")
 then v = "Ring of the Wind" return v 
elseif (v == "ring of toxic cloud")
 then v = "Ring of Toxic Cloud" return v 
elseif (v == "ring of transcendent wisdom")
 then v = "Ring of Transcendent Wisdom" return v 
elseif (v == "ring of transfiguring wisdom")
 then v = "Ring of Transfiguring Wisdom" return v 
elseif (v == "ring of vampire's kiss")
 then v = "Ring of Vampire's Kiss" return v 
elseif (v == "ring of wildfire")
 then v = "Ring of Wildfire" return v 
elseif (v == "ring of wizard's fire")
 then v = "Ring of Wizard's Fire" return v 
elseif (v == "ring of wounds")
 then v = "Ring of Wounds" return v 
elseif (v == "robe of burdens")
 then v = "Robe of Burdens" return v 
elseif (v == "robe_of_erur_dan")
 then v = "Robe of Erur-Dan the Wise" return v 
elseif (v == "robe of st roris")
 then v = "Robe of St Roris" return v 
elseif (v == "exquisite_robe_drake's pride")
 then v = "Robe of the Drake's Pride" return v 
elseif (v == "hortatorrobe")
 then v = "Robe of the Hortator" return v 
elseif (v == "robe of trials")
 then v = "Robe of Trials" return v 
elseif (v == "sacrifice ring")
 then v = "Sacrifice Ring" return v 
elseif (v == "heart_of_fire")
 then v = "Sanit-Kil's Heart of Fire" return v 
elseif (v == "scamp slinker belt")
 then v = "Scamp Slinker Belt" return v 
elseif (v == "second barrier belt")
 then v = "Second Barrier Belt" return v 
elseif (v == "second barrier ring")
 then v = "Second Barrier Ring" return v 
elseif (v == "Septim Ring")
 then v = "Septim Ring" return v 
elseif (v == "shadowmask ring")
 then v = "Shadowmask Ring" return v 
elseif (v == "shadowweave ring")
 then v = "Shadowweave Ring" return v 
elseif (v == "shame ring")
 then v = "Shame Ring" return v 
elseif (v == "shardbolt ring")
 then v = "Shardbolt Ring" return v 
elseif (v == "ring_shashev_unique")
 then v = "Shashev's Ring" return v 
elseif (v == "Sheogorath's Signet Ring")
 then v = "Sheogorath's Signet Ring" return v 
elseif (v == "shockeater robe")
 then v = "Shockeater Robe" return v 
elseif (v == "shockguard robe")
 then v = "Shockguard Robe" return v 
elseif (v == "shockmirror robe")
 then v = "Shockmirror Robe" return v 
elseif (v == "Shoes_of_Conviction")
 then v = "Shoes of Conviction" return v 
elseif (v == "sanguineshoesleaping")
 then v = "Shoes of Sanguine Leaping" return v 
elseif (v == "sanguineshoesstalking")
 then v = "Shoes of Sanguine Stalking" return v 
elseif (v == "shoes of st. rilms")
 then v = "Shoes of St. Rilms" return v 
elseif (v == "silence charm")
 then v = "Silence Charm" return v 
elseif (v == "sarandas_pants_2")
 then v = "Silk Pants" return v 
elseif (v == "amulet_skink_unique")
 then v = "Skink's Amulet" return v 
elseif (v == "sleep amulet")
 then v = "Sleep Amulet" return v 
elseif (v == "slippers_of_doom")
 then v = "Slippers of Doom" return v 
elseif (v == "soulpinch charm")
 then v = "Soulpinch Charm" return v 
elseif (v == "artifact_soul_ring")
 then v = "Soul Ring" return v 
elseif (v == "soul ring")
 then v = "Soul Ring" return v 
elseif (v == "sparkbolt ring")
 then v = "Sparkbolt Ring" return v 
elseif (v == "spirit charm")
 then v = "Spirit Charm" return v 
elseif (v == "spiritstrike ring")
 then v = "Spiritstrike Ring" return v 
elseif (v == "st. felm's fire")
 then v = "St. Felm's Fire" return v 
elseif (v == "st. sotha's judgement")
 then v = "St. Sotha's Judgement" return v 
elseif (v == "Stendarran Belt")
 then v = "Stendarran Belt" return v 
elseif (v == "stumble charm")
 then v = "Stumble Charm" return v 
elseif (v == "common_shoes_02_surefeet")
 then v = "Surefeet" return v 
elseif (v == "tailored_trousers")
 then v = "Tailored Trousers" return v 
elseif (v == "teeth")
 then v = "Teeth of the Urshilaku" return v 
elseif (v == "Daedric_special01")
 then v = "Tel Fyr amulet" return v 
elseif (v == "therana's skirt")
 then v = "Therana's Skirt" return v 
elseif (v == "seizing")
 then v = "The Seizing of the Erabenimsun" return v 
elseif (v == "thief_ring")
 then v = "Thief Ring" return v 
elseif (v == "third barrier belt")
 then v = "Third Barrier Belt" return v 
elseif (v == "third barrier ring")
 then v = "Third Barrier Ring" return v 
elseif (v == "thong")
 then v = "Thong of Zainab" return v 
elseif (v == "thunderfall")
 then v = "Thunderfall" return v 
elseif (v == "peakstar_pants_unique")
 then v = "Travel-stained Pants" return v 
elseif (v == "common_ring_tsiya")
 then v = "Tsiya's Ring" return v 
elseif (v == "ring_vampiric_unique")
 then v = "Vampiric Ring" return v 
elseif (v == "veloth's robe")
 then v = "Veloth's Robe" return v 
elseif (v == "viperbolt ring")
 then v = "Viperbolt Ring" return v 
elseif (v == "warden's ring")
 then v = "Warden's Ring" return v 
elseif (v == "ring_warlock_unique")
 then v = "Warlock's Ring" return v 
elseif (v == "watcher's belt")
 then v = "Watcher's Belt" return v 
elseif (v == "weeping robe")
 then v = "Weeping Robe" return v 
elseif (v == "wild sty ring")
 then v = "Wild Sty Ring" return v 
elseif (v == "witch charm")
 then v = "Witch Charm" return v 
elseif (v == "woe charm")
 then v = "Woe Charm" return v 
elseif (v == "Zenithar's_Wiles")
 then v = "Zeinthar's Wiles" return v 
elseif (v == "Zenithar_Frock")
 then v = "Zenithar's Frock" return v 
elseif (v == "Zenithar's_Warning")
 then v = "Zenithar's Warning" return v 
elseif (v == "zenithar_whispers")
 then v = "Zenithar Whispers" return v 
elseif (v == "ingred_alit_hide_01")
 then v = "Alit Hide" return v 
elseif (v == "ingred_bc_ampoule_pod")
 then v = "Ampoule Pod" return v 
elseif (v == "ingred_ash_salts_01")
 then v = "Ash Salts" return v 
elseif (v == "ingred_ash_yam_01")
 then v = "Ash Yam" return v 
elseif (v == "ingred_bittergreen_petals_01")
 then v = "Bittergreen Petals" return v 
elseif (v == "ingred_black_anther_01")
 then v = "Black Anther" return v 
elseif (v == "ingred_black_lichen_01")
 then v = "Black Lichen" return v 
elseif (v == "ingred_bloat_01")
 then v = "Bloat" return v 
elseif (v == "ingred_bonemeal_01")
 then v = "Bonemeal" return v 
elseif (v == "ingred_bread_01")
 then v = "Bread" return v 
elseif (v == "ingred_bread_01_UNI2")
 then v = "Bread" return v 
elseif (v == "ingred_bc_bungler's_bane")
 then v = "Bungler's Bane" return v 
elseif (v == "ingred_chokeweed_01")
 then v = "Chokeweed" return v 
elseif (v == "ingred_bc_coda_flower")
 then v = "Coda Flower" return v 
elseif (v == "ingred_comberry_01")
 then v = "Comberry" return v 
elseif (v == "ingred_corkbulb_root_01")
 then v = "Corkbulb Root" return v 
elseif (v == "ingred_corprus_weepings_01")
 then v = "Corprus weepings" return v 
elseif (v == "ingred_crab_meat_01")
 then v = "Crab Meat" return v 
elseif (v == "ingred_cursed_daedras_heart_01")
 then v = "Daedra's Heart" return v 
elseif (v == "ingred_daedras_heart_01")
 then v = "Daedra's Heart" return v 
elseif (v == "ingred_daedra_skin_01")
 then v = "Daedra Skin" return v 
elseif (v == "ingred_Dae_cursed_diamond_01")
 then v = "Diamond" return v 
elseif (v == "ingred_diamond_01")
 then v = "Diamond" return v 
elseif (v == "ingred_dreugh_wax_01")
 then v = "Dreugh Wax" return v 
elseif (v == "ingred_ectoplasm_01")
 then v = "Ectoplasm" return v 
elseif (v == "ingred_Dae_cursed_emerald_01")
 then v = "Emerald" return v 
elseif (v == "ingred_emerald_01")
 then v = "Emerald" return v 
elseif (v == "ingred_fire_petal_01")
 then v = "Fire Petal" return v 
elseif (v == "ingred_fire_salts_01")
 then v = "Fire Salts" return v 
elseif (v == "ingred_frost_salts_01")
 then v = "Frost Salts" return v 
elseif (v == "ingred_ghoul_heart_01")
 then v = "Ghoul Heart" return v 
elseif (v == "ingred_guar_hide_girith")
 then v = "Girith's Guar Hide" return v 
elseif (v == "ingred_gold_kanet_01")
 then v = "Gold Kanet" return v 
elseif (v == "ingred_gravedust_01")
 then v = "Gravedust" return v 
elseif (v == "ingred_green_lichen_01")
 then v = "Green Lichen" return v 
elseif (v == "ingred_guar_hide_01")
 then v = "Guar Hide" return v 
elseif (v == "ingred_hackle-lo_leaf_01")
 then v = "Hackle-Lo Leaf" return v 
elseif (v == "ingred_heather_01")
 then v = "Heather" return v 
elseif (v == "ingred_hound_meat_01")
 then v = "Hound Meat" return v 
elseif (v == "ingred_human_meat_01")
 then v = "Human Flesh" return v 
elseif (v == "ingred_bc_hypha_facia")
 then v = "Hypha Facia" return v 
elseif (v == "ingred_kagouti_hide_01")
 then v = "Kagouti Hide" return v 
elseif (v == "ingred_kresh_fiber_01")
 then v = "Kresh Fiber" return v 
elseif (v == "ingred_kwama_cuttle_01")
 then v = "Kwama Cuttle" return v 
elseif (v == "ingred_6th_corprusmeat_05")
 then v = "Large Corprusmeat Hunk" return v 
elseif (v == "food_kwama_egg_02")
 then v = "Large Kwama Egg" return v 
elseif (v == "ingred_6th_corprusmeat_01")
 then v = "Large Wrapped Corprusmeat" return v 
elseif (v == "ingred_russula_01")
 then v = "Luminous Russula" return v 
elseif (v == "ingred_marshmerrow_01")
 then v = "Marshmerrow" return v 
elseif (v == "ingred_guar_hide_marsus")
 then v = "Marsus' Guar Hide" return v 
elseif (v == "ingred_6th_corprusmeat_06")
 then v = "Medium Corprusmeat Hunk" return v 
elseif (v == "ingred_6th_corprusmeat_03")
 then v = "Medium Wrapped Corprusmeat" return v 
elseif (v == "ingred_scrib_jelly_02")
 then v = "Meteor Slime" return v 
elseif (v == "ingred_moon_sugar_01")
 then v = "Moon Sugar" return v 
elseif (v == "ingred_muck_01")
 then v = "Muck" return v 
elseif (v == "ingred_bread_01_UNI3")
 then v = "Muffin" return v 
elseif (v == "ingred_netch_leather_01")
 then v = "Netch Leather" return v 
elseif (v == "ingred_Dae_cursed_pearl_01")
 then v = "Pearl" return v 
elseif (v == "ingred_pearl_01")
 then v = "Pearl" return v 
elseif (v == "poison_goop00")
 then v = "Poison" return v 
elseif (v == "ingred_racer_plumes_01")
 then v = "Racer Plumes" return v 
elseif (v == "ingred_rat_meat_01")
 then v = "Rat Meat" return v 
elseif (v == "ingred_Dae_cursed_raw_ebony_01")
 then v = "Raw Ebony" return v 
elseif (v == "ingred_raw_ebony_01")
 then v = "Raw Ebony" return v 
elseif (v == "ingred_raw_glass_01")
 then v = "Raw Glass" return v 
elseif (v == "ingred_raw_glass_tinos")
 then v = "Raw Glass" return v 
elseif (v == "ingred_red_lichen_01")
 then v = "Red Lichen" return v 
elseif (v == "ingred_resin_01")
 then v = "Resin" return v 
elseif (v == "ingred_gold_kanet_unique")
 then v = "Roland's Tear" return v 
elseif (v == "ingred_roobrush_01")
 then v = "Roobrush" return v 
elseif (v == "ingred_Dae_cursed_ruby_01")
 then v = "Ruby" return v 
elseif (v == "ingred_ruby_01")
 then v = "Ruby" return v 
elseif (v == "ingred_saltrice_01")
 then v = "Saltrice" return v 
elseif (v == "ingred_scales_01")
 then v = "Scales" return v 
elseif (v == "ingred_scamp_skin_01")
 then v = "Scamp Skin" return v 
elseif (v == "ingred_scathecraw_01")
 then v = "Scathecraw" return v 
elseif (v == "ingred_scrap_metal_01")
 then v = "Scrap Metal" return v 
elseif (v == "ingred_scrib_jelly_01")
 then v = "Scrib Jelly" return v 
elseif (v == "ingred_scrib_jerky_01")
 then v = "Scrib Jerky" return v 
elseif (v == "ingred_scuttle_01")
 then v = "Scuttle" return v 
elseif (v == "ingred_shalk_resin_01")
 then v = "Shalk Resin" return v 
elseif (v == "ingred_sload_soap_01")
 then v = "Sload Soap" return v 
elseif (v == "ingred_6th_corprusmeat_07")
 then v = "Small Corprusmeat Hunk" return v 
elseif (v == "food_kwama_egg_01")
 then v = "Small Kwama Egg" return v 
elseif (v == "ingred_6th_corprusmeat_02")
 then v = "Small Wrapped Corprusmeat" return v 
elseif (v == "ingred_bc_spore_pod")
 then v = "Spore Pod" return v 
elseif (v == "ingred_stoneflower_petals_01")
 then v = "Stoneflower Petals" return v 
elseif (v == "ingred_trama_root_01")
 then v = "Trama Root" return v 
elseif (v == "ingred_treated_bittergreen_uniq")
 then v = "Treated Bittergreen Petals" return v 
elseif (v == "ingred_vampire_dust_01")
 then v = "Vampire Dust" return v 
elseif (v == "ingred_coprinus_01")
 then v = "Violet Coprinus" return v 
elseif (v == "ingred_void_salts_01")
 then v = "Void Salts" return v 
elseif (v == "ingred_wickwheat_01")
 then v = "Wickwheat" return v 
elseif (v == "ingred_willow_anther_01")
 then v = "Willow Anther" return v 
elseif (v == "ingred_6th_corprusmeat_04")
 then v = "Wrapped Corprusmeat Hunk" return v 
elseif (v == "pick_apprentice_01")
 then v = "Apprentice's Lockpick" return v 
elseif (v == "pick_grandmaster")
 then v = "Grandmaster's Pick" return v 
elseif (v == "pick_journeyman_01")
 then v = "Journeyman's Lockpick" return v 
elseif (v == "pick_master")
 then v = "Master's Lockpick" return v 
elseif (v == "pick_secretmaster")
 then v = "Secret Master's Lockpick" return v 
elseif (v == "skeleton_key")
 then v = "The Skeleton Key" return v 
elseif (v == "key_abebaalslaves_01")
 then v = "Abebaal Slave Key" return v 
elseif (v == "key_elmussadamori")
 then v = "Abebaal Slave Key" return v 
elseif (v == "key_addamasartusslaves_01")
 then v = "Addamasartus Slave Key" return v 
elseif (v == "key_slave_addamasartus")
 then v = "Addamasartus Slave Key" return v 
elseif (v == "key_aharunartusslaves_01")
 then v = "Aharunartus Slave Key" return v 
elseif (v == "key_ahnassi")
 then v = "Ahnassi's key" return v 
elseif (v == "key_alvur")
 then v = "Alvur's Key" return v 
elseif (v == "key_ashurninibi_lost")
 then v = "Ancient, rusted Daedric Key" return v 
elseif (v == "key_ibardad_tomb")
 then v = "Ancient, rusted Daedric Key" return v 
elseif (v == "key_ashalmawia_prisoncell")
 then v = "Ancient daedric Key" return v 
elseif (v == "key_ashurninibi")
 then v = "Ancient daedric Key" return v 
elseif (v == "key_Forge of Rolamus")
 then v = "Ancient daedric Key" return v 
elseif (v == "key_fg_nchur")
 then v = "Ancient Dwemer Door Key" return v 
elseif (v == "index_andra")
 then v = "Andasreth Propylon Index" return v 
elseif (v == "key_anja")
 then v = "Anja's Key" return v 
elseif (v == "key_marvani_tomb")
 then v = "An old, ashy key" return v 
elseif (v == "key_Senim_tomb")
 then v = "An old tomb key" return v 
elseif (v == "misc_dwrv_artifact30")
 then v = "Anumidium Plans" return v 
elseif (v == "key_archcanon_private")
 then v = "Archcanon's Private Key" return v 
elseif (v == "key_vivec_arena_cell")
 then v = "Arena Cell Key" return v 
elseif (v == "key_Arenim")
 then v = "Arenim burial key" return v 
elseif (v == "key_armigers_stronghold")
 then v = "Armigers Stronghold dungeon key" return v 
elseif (v == "key_arobarmanorguard_01")
 then v = "Arobar Manor Guard's Key" return v 
elseif (v == "key_arobarmanor_01")
 then v = "Arobar Manor Key" return v 
elseif (v == "key_arvs-drelen_cell")
 then v = "Arvs-Drelen Cell Key" return v 
elseif (v == "key_chest_aryniorethi_01")
 then v = "Aryni Orethi's Key" return v 
elseif (v == "devote_Nan_Dust_00")
 then v = "Ashes of D. Bryant" return v 
elseif (v == "devote_Lyngas_Dust_00")
 then v = "Ashes of G. Lyngas" return v 
elseif (v == "devote_Brinne_Dust_00")
 then v = "Ashes of Lord Brinne" return v 
elseif (v == "misc_6th_ash_statue_01")
 then v = "Ash Statue" return v 
elseif (v == "key_gshipwreck")
 then v = "A Simple Key" return v 
elseif (v == "key_oritius")
 then v = "A Small Key" return v 
elseif (v == "key_assarnudslaves_01")
 then v = "Assarnud Slave Key" return v 
elseif (v == "key_assi")
 then v = "Assi's Key" return v 
elseif (v == "key_aurane1")
 then v = "Aurane Frernis' Key" return v 
elseif (v == "Misc_SoulGem_Azura")
 then v = "Azura's Star" return v 
elseif (v == "key_shushishi")
 then v = "Bandit's Key" return v 
elseif (v == "key_balmorag_tong_01")
 then v = "Basement Key" return v 
elseif (v == "key_gro-bagrat")
 then v = "Basement Key" return v 
elseif (v == "misc_com_basket_01")
 then v = "Basket" return v 
elseif (v == "misc_com_basket_02")
 then v = "Basket" return v 
elseif (v == "misc_de_basket_01")
 then v = "Basket" return v 
elseif (v == "misc_beaker_01")
 then v = "Beaker" return v 
elseif (v == "key_desele")
 then v = "Bedroom Key" return v 
elseif (v == "misc_de_bellows10")
 then v = "Bellows" return v 
elseif (v == "misc_Beluelle_silver_bowl")
 then v = "Beluelle's Silver bowl" return v 
elseif (v == "index_beran")
 then v = "Berandas Propylon Index" return v 
elseif (v == "artifact_bittercup_01")
 then v = "Bittercup" return v 
elseif (v == "key_bivaleteneran_01")
 then v = "Bivale Teneran's Key" return v 
elseif (v == "misc_de_pot_blue_02")
 then v = "Blue Clay Pot" return v 
elseif (v == "misc_de_pot_blue_01")
 then v = "Blue Glass Pot" return v 
elseif (v == "key_bolayn")
 then v = "Bolayne's chest key" return v 
elseif (v == "misc_clothbolt_01")
 then v = "Bolt of Cloth" return v 
elseif (v == "misc_clothbolt_02")
 then v = "Bolt of Cloth" return v 
elseif (v == "misc_clothbolt_03")
 then v = "Bolt of Cloth" return v 
elseif (v == "devote_bone_Pop00")
 then v = "Bone from Pop Je" return v 
elseif (v == "misc_com_bottle_01")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_02")
 then v = "Bottle" return v 
elseif (v == "Misc_Com_Bottle_04")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_05")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_06")
 then v = "Bottle" return v 
elseif (v == "Misc_Com_Bottle_08")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_09")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_10")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_11")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_13")
 then v = "Bottle" return v 
elseif (v == "Misc_Com_Bottle_14")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_14_float")
 then v = "Bottle" return v 
elseif (v == "misc_com_bottle_15")
 then v = "Bottle" return v 
elseif (v == "misc_com_redware_bowl")
 then v = "Bowl" return v 
elseif (v == "misc_com_redware_bowl_01")
 then v = "Bowl" return v 
elseif (v == "Misc_Com_Wood_Bowl_01")
 then v = "Bowl" return v 
elseif (v == "misc_com_wood_bowl_02")
 then v = "Bowl" return v 
elseif (v == "misc_com_wood_bowl_03")
 then v = "Bowl" return v 
elseif (v == "misc_com_wood_bowl_04")
 then v = "Bowl" return v 
elseif (v == "Misc_Com_Wood_Bowl_05")
 then v = "Bowl" return v 
elseif (v == "misc_de_bowl_01")
 then v = "Bowl" return v 
elseif (v == "misc_de_bowl_white_01")
 then v = "Bowl" return v 
elseif (v == "key_brallion")
 then v = "Brallion's Key" return v 
elseif (v == "misc_com_broom_01")
 then v = "Broom" return v 
elseif (v == "misc_com_bucket_01")
 then v = "Bucket" return v 
elseif (v == "misc_com_bucket_01_float")
 then v = "Bucket" return v 
elseif (v == "misc_com_bucket_boe_UNI")
 then v = "Bucket" return v 
elseif (v == "misc_com_bucket_boe_UNIa")
 then v = "Bucket" return v 
elseif (v == "misc_com_bucket_boe_UNIb")
 then v = "Bucket" return v 
elseif (v == "key_cell_buckmoth_01")
 then v = "Buckmoth Prison Cell Key" return v 
elseif (v == "key_cabin")
 then v = "Cabin Key" return v 
elseif (v == "key_caius_cosades")
 then v = "Caius Cosades' Key" return v 
elseif (v == "key_calderaslaves_01")
 then v = "Caldera Slave Key" return v 
elseif (v == "key_caryarel")
 then v = "Caryarel's Key" return v 
elseif (v == "misc_de_bowl_orange_green_01")
 then v = "Ceramic Bowl" return v 
elseif (v == "misc_lw_bowl_chapel")
 then v = "Chapel Limeware Bowl" return v 
elseif (v == "key_ald_redaynia")
 then v = "Chest Key" return v 
elseif (v == "key_standard_darius_chest")
 then v = "Chest Key" return v 
elseif (v == "key_ciennesintieve_01")
 then v = "Cienne Sintieve's Key" return v 
elseif (v == "misc_de_pot_mottled_01")
 then v = "Clay Pot" return v 
elseif (v == "misc_de_cloth10")
 then v = "Cloth" return v 
elseif (v == "misc_de_cloth11")
 then v = "Cloth" return v 
elseif (v == "key_chest_coduscallonus_01")
 then v = "Codus Callonus' Key" return v 
elseif (v == "misc_com_plate_02_tgrc")
 then v = "Commemorative Plate" return v 
elseif (v == "misc_com_plate_06_tgrc")
 then v = "Commemorative Plate" return v 
elseif (v == "Misc_SoulGem_Common")
 then v = "Common Soul Gem" return v 
elseif (v == "mamaea cell key")
 then v = "Crude Bronze Key" return v 
elseif (v == "Misc_Com_Redware_Cup")
 then v = "Cup" return v 
elseif (v == "misc_com_wood_cup_01")
 then v = "Cup" return v 
elseif (v == "misc_com_wood_cup_02")
 then v = "Cup" return v 
elseif (v == "key_fals")
 then v = "Dagoth Fals's Key" return v 
elseif (v == "key_galmis")
 then v = "Dagoth Galmis's Key" return v 
elseif (v == "key_odros")
 then v = "Dagoth Odros's Key" return v 
elseif (v == "key_tureynul")
 then v = "Dagoth Tureynul's key" return v 
elseif (v == "key_standard_01_darvam hlaren")
 then v = "Darvam Hlaren's Key" return v 
elseif (v == "misc_de_bowl_bugdesign_01")
 then v = "Decorative Bowl" return v 
elseif (v == "key_divayth_fyr")
 then v = "Divayth Fyr's Key" return v 
elseif (v == "key_divayth05")
 then v = "Divayth's 1008th Key" return v 
elseif (v == "key_divayth06")
 then v = "Divayth's 1092nd Key" return v 
elseif (v == "key_divayth07")
 then v = "Divayth's 1155th Key" return v 
elseif (v == "key_divayth00")
 then v = "Divayth's 637th Key" return v 
elseif (v == "key_divayth01")
 then v = "Divayth's 678th Key" return v 
elseif (v == "key_divayth02")
 then v = "Divayth's 738th Key" return v 
elseif (v == "key_divayth03")
 then v = "Divayth's 802nd Key" return v 
elseif (v == "key_divayth04")
 then v = "Divayth's 897th Key" return v 
elseif (v == "key_redoran_treasury")
 then v = "Dralor Treasury Key" return v 
elseif (v == "key_drenplantationslaves_01")
 then v = "Dren Plantation Slave Key" return v 
elseif (v == "key_dren_manor")
 then v = "Dren's Manor Key" return v 
elseif (v == "key_dren_storage")
 then v = "Dren's Storage Sack Key" return v 
elseif (v == "key_dreynos")
 then v = "Dreynos Elvul's Key" return v 
elseif (v == "misc_dwrv_artifact_ils")
 then v = "Drinar Varyon's Dwemer Tube" return v 
elseif (v == "key_chest_drinarvaryon_01")
 then v = "Drinar Varyon's Key" return v 
elseif (v == "misc_de_drum_01")
 then v = "Drum" return v 
elseif (v == "key_dumbuk_strongbox")
 then v = "Dumbuk's Strongbox Key" return v 
elseif (v == "key_Dura_gra-Bol")
 then v = "Dura gra-Bol's Key" return v 
elseif (v == "misc_dwarfbone_unique")
 then v = "Dwarven Bone" return v 
elseif (v == "misc_dwrv_artifact20")
 then v = "Dwemer Airship Plans" return v 
elseif (v == "misc_dwrv_artifact80")
 then v = "Dwemer Centurion Plans" return v 
elseif (v == "misc_dwrv_artifact50")
 then v = "Dwemer Coherer" return v 
elseif (v == "misc_dwrv_coin00")
 then v = "Dwemer Coin" return v 
elseif (v == "misc_dwrv_cursed_coin00")
 then v = "Dwemer Coin" return v 
elseif (v == "misc_dwrv_artifact00")
 then v = "Dwemer Cylinder" return v 
elseif (v == "key_Mudan_Dragon")
 then v = "Dwemer Guardian Key" return v 
elseif (v == "key_table_Mudan00")
 then v = "Dwemer key to table in Mudan" return v 
elseif (v == "misc_dwrv_mug00")
 then v = "Dwemer Mug" return v 
elseif (v == "misc_dwrv_ark_cube00")
 then v = "Dwemer puzzle box" return v 
elseif (v == "misc_dwrv_artifact10")
 then v = "Dwemer Scarab Plans" return v 
elseif (v == "misc_dwrv_artifact40")
 then v = "Dwemer Scarab Schematics" return v 
elseif (v == "misc_dwrv_artifact70")
 then v = "Dwemer Schematic" return v 
elseif (v == "misc_dwrv_artifact60")
 then v = "Dwemer Tube" return v 
elseif (v == "misc_skooma_vial")
 then v = "Empty Vial" return v 
elseif (v == "misc_uni_pillow_unique")
 then v = "Extra-Comfy Pillow" return v 
elseif (v == "Misc_fakesoulgem")
 then v = "Fake Soul Gem" return v 
elseif (v == "index_falas")
 then v = "Falasmaryon Propylon Index" return v 
elseif (v == "index_falen")
 then v = "Falensarano Propylon Index" return v 
elseif (v == "misc_de_lute_01_phat")
 then v = "Fat Lute" return v 
elseif (v == "misc_de_fishing_pole")
 then v = "Fishing Pole" return v 
elseif (v == "misc_com_redware_flask")
 then v = "Flask" return v 
elseif (v == "misc_flask_01")
 then v = "Flask" return v 
elseif (v == "misc_flask_02")
 then v = "Flask" return v 
elseif (v == "misc_flask_03")
 then v = "Flask" return v 
elseif (v == "misc_flask_04")
 then v = "Flask" return v 
elseif (v == "misc_de_foldedcloth00")
 then v = "Folded Cloth" return v 
elseif (v == "misc_com_silverware_fork")
 then v = "Fork" return v 
elseif (v == "misc_com_wood_fork")
 then v = "Fork" return v 
elseif (v == "misc_com_wood_fork_UNI1")
 then v = "Fork" return v 
elseif (v == "misc_com_wood_fork_UNI2")
 then v = "Fork" return v 
elseif (v == "key_standard_01_pel_fort_prison")
 then v = "Fort Pelagiad Prison Key" return v 
elseif (v == "key_GatewayInnslaves_01")
 then v = "Gateway Inn Slave Key" return v 
elseif (v == "key_gnisis_eggmine")
 then v = "Gnisis Eggmine Key" return v 
elseif (v == "misc_com_metal_goblet_01")
 then v = "Goblet" return v 
elseif (v == "misc_com_metal_goblet_02")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_01")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_02")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_03")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_04")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_05")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_06")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_07")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_08")
 then v = "Goblet" return v 
elseif (v == "misc_de_goblet_09")
 then v = "Goblet" return v 
elseif (v == "Gold_001")
 then v = "Gold" return v 
elseif (v == "Gold_005")
 then v = "Gold" return v 
elseif (v == "Gold_010")
 then v = "Gold" return v 
elseif (v == "Gold_025")
 then v = "Gold" return v 
elseif (v == "Gold_100")
 then v = "Gold" return v 
elseif (v == "Gold_Dae_cursed_001")
 then v = "Gold" return v 
elseif (v == "Gold_Dae_cursed_005")
 then v = "Gold" return v 
elseif (v == "misc_uniq_egg_of_gold")
 then v = "Golden Egg" return v 
elseif (v == "Misc_SoulGem_Grand")
 then v = "Grand Soul Gem" return v 
elseif (v == "Misc_SoulGem_Greater")
 then v = "Greater Soul Gem" return v 
elseif (v == "Misc_DE_glass_green_01")
 then v = "Green Glass" return v 
elseif (v == "misc_de_pot_green_01")
 then v = "Green Pot" return v 
elseif (v == "misc_de_drum_02")
 then v = "Guarskin Drum" return v 
elseif (v == "key_dralor")
 then v = "Guldrise Dralor's Key" return v 
elseif (v == "key_habinbaesslaves_01")
 then v = "Habinbaes Slave Key" return v 
elseif (v == "key_hasphat_antabolis")
 then v = "Hasphat Antabolis' Key" return v 
elseif (v == "key_cell_ebonheart_01")
 then v = "Hawkmoth Prison Cell Key" return v 
elseif (v == "key_helvi")
 then v = "Helvi's Key" return v 
elseif (v == "key_hinnabislaves_01")
 then v = "Hinnabi Slave Key" return v 
elseif (v == "key_hlaalo_manor")
 then v = "Hlaalo Manor Key" return v 
elseif (v == "key_vivec_hlaalu_cell")
 then v = "Hlaalu Compound Cell Key" return v 
elseif (v == "key_hvaults2")
 then v = "Hlaalu Vaults Inner Key" return v 
elseif (v == "key_hvaults1")
 then v = "Hlaalu Vaults Outer Key" return v 
elseif (v == "key_chest_avonravel_01")
 then v = "Hlormaren - Avon Ravel's Key" return v 
elseif (v == "index_hlor")
 then v = "Hlormaren Propylon Index" return v 
elseif (v == "key_hlormarenslaves_01")
 then v = "Hlormaren Slave Key" return v 
elseif (v == "key_chest_brilnosullarys_01")
 then v = "Hlormaren Wizard's Key" return v 
elseif (v == "key_Suran_slave")
 then v = "Holding Cell Key" return v 
elseif (v == "misc_hook")
 then v = "Hook" return v 
elseif (v == "misc_de_goblet_04_dagoth")
 then v = "House Dagoth cup" return v 
elseif (v == "misc_goblet_dagoth")
 then v = "House Dagoth cup" return v 
elseif (v == "key_ienasa")
 then v = "Ienasa Radas's Key" return v 
elseif (v == "key_tel_aruhn_slave1")
 then v = "Imayn Slave Cage Key" return v 
elseif (v == "index_indo")
 then v = "Indoranyon Propylon Index" return v 
elseif (v == "Misc_Inkwell")
 then v = "Inkwell" return v 
elseif (v == "key_camp")
 then v = "Iron Key" return v 
elseif (v == "key_persius mercius")
 then v = "Iron Key" return v 
elseif (v == "misc_com_iron_ladle")
 then v = "Iron Ladle" return v 
elseif (v == "key_itar")
 then v = "Itar's Key" return v 
elseif (v == "key_ivrosa")
 then v = "Ivrosa Verethi's Key" return v 
elseif (v == "key_jeanne")
 then v = "Jeanne's Key" return v 
elseif (v == "misc_com_bottle_03")
 then v = "Jug" return v 
elseif (v == "misc_com_bottle_07")
 then v = "Jug" return v 
elseif (v == "misc_com_bottle_07_float")
 then v = "Jug" return v 
elseif (v == "misc_com_bottle_12")
 then v = "Jug" return v 
elseif (v == "key_j'zhirr")
 then v = "J'zhirr's Key" return v 
elseif (v == "key_Aralen")
 then v = "Key Aralen Tombs" return v 
elseif (v == "key_Dareleth_tomb")
 then v = "Key Dareleth tomb" return v 
elseif (v == "key_Venim")
 then v = "Key engraved" return v 
elseif (v == "key_Aleft_chest")
 then v = "Key to Aleft chest" return v 
elseif (v == "key_Andalen_chest")
 then v = "Key to Andalen chest" return v 
elseif (v == "key_Andalen_tomb")
 then v = "Key to Andalen tomb" return v 
elseif (v == "key_Andas_tomb")
 then v = "Key to Andas tomb" return v 
elseif (v == "key_Andavel_tomb")
 then v = "Key to Andavel tomb" return v 
elseif (v == "key_Andrethi_chest")
 then v = "Key to Andrethi tomb chest" return v 
elseif (v == "key_Andules_chest")
 then v = "Key to Andules chest" return v 
elseif (v == "Key_Arano_chest")
 then v = "Key to Arano Tomb chest" return v 
elseif (v == "Key_Arano_door")
 then v = "Key to Arano Tomb Door" return v 
elseif (v == "key_Aran_tomb")
 then v = "Key to Aran tomb" return v 
elseif (v == "key_Arenim_chest")
 then v = "Key to Arenim chest" return v 
elseif (v == "key_Arkngthunch_chest")
 then v = "Key to Arkngthunch chest" return v 
elseif (v == "key_Aryon_chest")
 then v = "Key to Aryon chest" return v 
elseif (v == "key_Ashmelech")
 then v = "Key to Asmelech" return v 
elseif (v == "key_Ashmelech_chest")
 then v = "Key to Asmelech chest" return v 
elseif (v == "key_Baram_tomb")
 then v = "Key to Baram tomb" return v 
elseif (v == "key_Bthanchend_chest")
 then v = "Key to Bthanchend chest" return v 
elseif (v == "key_Bthuand")
 then v = "Key to Bthuand" return v 
elseif (v == "Key_Dralas_chest")
 then v = "Key to Dralas chest" return v 
elseif (v == "Key_Dralas_tomb")
 then v = "Key to Dralas tomb" return v 
elseif (v == "key_Dreloth_tomb")
 then v = "Key to Dreloth tomb" return v 
elseif (v == "key_Fadathram_tomb")
 then v = "Key to Fadathram tomb" return v 
elseif (v == "key_Falas_tomb")
 then v = "Key to Falas tomb" return v 
elseif (v == "key_Falas_chest")
 then v = "Key to Falas Tomb chest" return v 
elseif (v == "key_Favel_chest")
 then v = "Key to Favel Tomb chest" return v 
elseif (v == "key_Galom_Daeus")
 then v = "Key to Galom Daeus" return v 
elseif (v == "Key_Gimothran_chest")
 then v = "Key to Gimothran chest" return v 
elseif (v == "key_Gimothran")
 then v = "Key to Gimothran master burial" return v 
elseif (v == "key_Gimothran_tomb")
 then v = "Key to Gimothran tomb" return v 
elseif (v == "key_Helas_tomb")
 then v = "Key to Helas tomb" return v 
elseif (v == "key_Heran")
 then v = "Key to Heran tomb door" return v 
elseif (v == "key_huleen's_hut")
 then v = "Key to Huleen's Hut" return v 
elseif (v == "key_Ienith_chest")
 then v = "Key to Ienith chest" return v 
elseif (v == "key_Ienith_tomb")
 then v = "Key to Ienith tomb" return v 
elseif (v == "key_TV_CT")
 then v = "Key to Imperial Museum Jail" return v 
elseif (v == "key_Indalen_tomb")
 then v = "Key to Indalen tomb" return v 
elseif (v == "key_Lleran_tomb")
 then v = "Key to Lleran tomb" return v 
elseif (v == "key_Llervu")
 then v = "Key to Llervu tomb" return v 
elseif (v == "key_Brinne_chest")
 then v = "Key to Lord Brinne's chest" return v 
elseif (v == "misc_dwrv_ark_key00")
 then v = "Key to Lower Arkngthand" return v 
elseif (v == "key_Maren_tomb")
 then v = "Key to Maren tomb" return v 
elseif (v == "key_door_Mudan00")
 then v = "Key to Mudan Dwemer Vault" return v 
elseif (v == "key_Mzahnch_chest")
 then v = "Key to Mzahnch chest" return v 
elseif (v == "key_Mzanchend_chest")
 then v = "Key to Mzanchend chest" return v 
elseif (v == "key_Mzuleft")
 then v = "Key to Mzuleft" return v 
elseif (v == "key_Nchardahrk")
 then v = "Key to Nchardahrk" return v 
elseif (v == "key_Nchardahrk_chest")
 then v = "Key to Nchardahrk chest" return v 
elseif (v == "key_Nchuleftingth")
 then v = "Key to Nchuleftingth" return v 
elseif (v == "key_Nchuleftingth_chest")
 then v = "Key to Nchuleftingth chest" return v 
elseif (v == "key_Nelas_chest")
 then v = "Key to Nelas chest" return v 
elseif (v == "key_Nerano_chest")
 then v = "Key to Nerano chest" return v 
elseif (v == "key_neranomanor")
 then v = "Key to Nerano Manor" return v 
elseif (v == "key_Sandas")
 then v = "Key to Nobleman's chest" return v 
elseif (v == "key_Norvayn_chest")
 then v = "Key to Norvayn chest" return v 
elseif (v == "key_Norvayn_tomb")
 then v = "Key to Norvayn tomb" return v 
elseif (v == "key_Odirniran")
 then v = "Key to Odirniran" return v 
elseif (v == "key_Omalen_tomb")
 then v = "Key to Omalen tomb" return v 
elseif (v == "key_Omaren_chest")
 then v = "Key to Omaren chest" return v 
elseif (v == "key_Orethi_tomb")
 then v = "Key to Orethi tomb" return v 
elseif (v == "key_Othrelas_door")
 then v = "Key to Othrelas tomb door" return v 
elseif (v == "key_Ravel_chest")
 then v = "Key to Ravel chest" return v 
elseif (v == "key_Ravel_tomb")
 then v = "Key to Ravel tomb" return v 
elseif (v == "key_Raviro_tomb")
 then v = "Key to Raviro tomb" return v 
elseif (v == "key_Rethandus_chest")
 then v = "Key to Rethandus chest" return v 
elseif (v == "key_Rethandus_tomb")
 then v = "Key to Rethandus tomb" return v 
elseif (v == "key_Rothan_tomb")
 then v = "Key to Rothan tomb" return v 
elseif (v == "key_Sadryon_tomb")
 then v = "Key to Sadryon tomb" return v 
elseif (v == "key_Salvel_chest")
 then v = "Key to Salvel chest" return v 
elseif (v == "key_Salvel_tomb")
 then v = "Key to Salvel tomb" return v 
elseif (v == "key_Sandas_tomb")
 then v = "Key to Sandas tomb" return v 
elseif (v == "key_Sarano_chest")
 then v = "Key to Sarano chest" return v 
elseif (v == "key_Sarano_tomb")
 then v = "Key to Sarano tomb" return v 
elseif (v == "key_Saren_chest")
 then v = "Key to Saren chest" return v 
elseif (v == "key_Saren_tomb")
 then v = "Key to Saren tomb" return v 
elseif (v == "key_Sarethi_tomb")
 then v = "Key to Sarethi tomb" return v 
elseif (v == "key_Savel_tomb")
 then v = "Key to Savel tomb" return v 
elseif (v == "key_Senim_chest")
 then v = "Key to Senim chest" return v 
elseif (v == "key_nelothtelnaga")
 then v = "Key to Tel Naga" return v 
elseif (v == "key_nelothtelnaga2")
 then v = "Key to Tel Naga" return v 
elseif (v == "key_nelothtelnaga3")
 then v = "Key to Tel Naga" return v 
elseif (v == "key_nelothtelnaga4")
 then v = "Key to Tel Naga" return v 
elseif (v == "key_Thalas_tomb")
 then v = "Key to Thalas tomb" return v 
elseif (v == "key_Thiralas_tomb")
 then v = "Key to Thiralas tomb" return v 
elseif (v == "key_Vandus_tomb")
 then v = "Key to Vandus tomb" return v 
elseif (v == "key_varostorage")
 then v = "Key to Varo Tradehouse Storage" return v 
elseif (v == "key_Verelnim_tomb")
 then v = "Key to Verelnim tomb" return v 
elseif (v == "key_WormLord_tomb")
 then v = "Key to Worm Lord's tomb" return v 
elseif (v == "key_kind")
 then v = "Kind's Key" return v 
elseif (v == "misc_com_silverware_knife")
 then v = "Knife" return v 
elseif (v == "misc_com_wood_knife")
 then v = "Knife" return v 
elseif (v == "misc_com_wood_knife_UNI1")
 then v = "Knife" return v 
elseif (v == "misc_com_wood_knife_UNI2")
 then v = "Knife" return v 
elseif (v == "key_kudanatslaves_01")
 then v = "Kudanat Slave Key" return v 
elseif (v == "misc_dwrv_goblet10_tgcp")
 then v = "Large Dewmer Goblet" return v 
elseif (v == "key_Punsabanit")
 then v = "Large Key" return v 
elseif (v == "misc_de_bowl_redware_02")
 then v = "Large Redware Bowl" return v 
elseif (v == "Misc_SoulGem_Lesser")
 then v = "Lesser Soul Gem" return v 
elseif (v == "misc_lw_bowl")
 then v = "Limeware Bowl" return v 
elseif (v == "misc_lw_cup")
 then v = "Limeware Cup" return v 
elseif (v == "misc_lw_flask")
 then v = "Limeware Flask" return v 
elseif (v == "misc_lw_platter")
 then v = "Limeware Platter" return v 
elseif (v == "key_viveclizardheadslave_01")
 then v = "Lizard's Head Slave Key" return v 
elseif (v == "key_Llethri")
 then v = "Llaro Llethri's Key" return v 
elseif (v == "key_llethervari_01")
 then v = "Llether Vari's Key" return v 
elseif (v == "key_llethrimanor_01")
 then v = "Llethri Manor Key" return v 
elseif (v == "key_sarethimanor_01")
 then v = "Llethri Manor Key" return v 
elseif (v == "key_sethan")
 then v = "Llorayna Sethan's Key" return v 
elseif (v == "key_kogoruhn_sewer")
 then v = "Lower Kogoruhn Key" return v 
elseif (v == "misc_de_lute_01")
 then v = "Lute" return v 
elseif (v == "key_madach_room")
 then v = "Madach Room Key" return v 
elseif (v == "key_malpenixblonia_01")
 then v = "Malpenix Blonia's Key" return v 
elseif (v == "index_maran")
 then v = "Marandus Propylon Index" return v 
elseif (v == "key_mebastien")
 then v = "Mebastien's Key" return v 
elseif (v == "key_menta_na")
 then v = "Menta Na's Key" return v 
elseif (v == "Misc_Com_Bucket_Metal")
 then v = "Metal Bucket" return v 
elseif (v == "key_mette")
 then v = "Mette's Key" return v 
elseif (v == "key_Private Quarters")
 then v = "Milo's Quarters Key" return v 
elseif (v == "key_minabislaves_01")
 then v = "Minabi Slave Key" return v 
elseif (v == "key_ministry_cells")
 then v = "Ministry of Truth Cell Key" return v 
elseif (v == "ministry_truth_ext")
 then v = "Ministry of Truth Entrance" return v 
elseif (v == "key_ministry_ext")
 then v = "Ministry of Truth Key" return v 
elseif (v == "key_ministry_sectors")
 then v = "Ministry of Truth Sector Key" return v 
elseif (v == "key_molagmarslaves_01")
 then v = "Molag Mar Slave Key" return v 
elseif (v == "misc_6th_ash_hrmm")
 then v = "Morvayn Ash Statue" return v 
elseif (v == "key_morvaynmanor")
 then v = "Morvayn Manor Key" return v 
elseif (v == "misc_de_muck_shovel_01")
 then v = "Muck Shovel" return v 
elseif (v == "key_murudius_01")
 then v = "Murudius' Key" return v 
elseif (v == "key_tgbt")
 then v = "Nads Tharen's Key" return v 
elseif (v == "key_nedhelas")
 then v = "Nedhelas' key" return v 
elseif (v == "key_Odibaal")
 then v = "Odibaal Outlaw's Key" return v 
elseif (v == "key_odral_helvi")
 then v = "Odral Helvi's Key" return v 
elseif (v == "key_Ashirbadon")
 then v = "Old Key" return v 
elseif (v == "key_assemanu_02")
 then v = "Old Key" return v 
elseif (v == "key_Dubdilla")
 then v = "Old Key" return v 
elseif (v == "key_falaanamo")
 then v = "Old Key" return v 
elseif (v == "lucky_coin")
 then v = "Old Man's Lucky Coin" return v 
elseif (v == "key_omani_01")
 then v = "Omani Manor Key" return v 
elseif (v == "misc_dwrv_bowl00")
 then v = "Ornate Dwemer Bowl" return v 
elseif (v == "misc_dwrv_goblet00")
 then v = "Ornate Dwemer Goblet" return v 
elseif (v == "misc_dwrv_goblet10")
 then v = "Ornate Dwemer Goblet" return v 
elseif (v == "misc_dwrv_pitcher00")
 then v = "Ornate Dwemer Pitcher" return v 
elseif (v == "key_orvas_dren")
 then v = "Orvas Dren's Key" return v 
elseif (v == "key_panatslaves_01")
 then v = "Panat Slave Key" return v 
elseif (v == "misc_de_bowl_glass_peach_01")
 then v = "Peach Glass Bowl" return v 
elseif (v == "misc_de_pot_glass_peach_01")
 then v = "Peach Glass Pot" return v 
elseif (v == "misc_de_pot_glass_peach_02")
 then v = "Peach Glass Pot" return v 
elseif (v == "key_standard_01_pel_guard_tower")
 then v = "Pelagiad Guard Tower Key" return v 
elseif (v == "Misc_SoulGem_Petty")
 then v = "Petty Soul Gem" return v 
elseif (v == "misc_uni_pillow_01")
 then v = "Pillow" return v 
elseif (v == "Misc_Uni_Pillow_02")
 then v = "Pillow" return v 
elseif (v == "Misc_Com_Pitcher_Metal_01")
 then v = "Pitcher" return v 
elseif (v == "misc_com_redware_pitcher")
 then v = "Pitcher" return v 
elseif (v == "misc_de_pitcher_01")
 then v = "Pitcher" return v 
elseif (v == "key_Ibardad")
 then v = "Plain key" return v 
elseif (v == "misc_com_metal_plate_03")
 then v = "Plate" return v 
elseif (v == "misc_com_metal_plate_04")
 then v = "Plate" return v 
elseif (v == "misc_com_metal_plate_05")
 then v = "Plate" return v 
elseif (v == "misc_com_metal_plate_07")
 then v = "Plate" return v 
elseif (v == "misc_com_metal_plate_07_UNI1")
 then v = "Plate" return v 
elseif (v == "misc_com_metal_plate_07_UNI2")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_01")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_02")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_03")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_04")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_05")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_06")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_07")
 then v = "Plate" return v 
elseif (v == "misc_com_plate_08")
 then v = "Plate" return v 
elseif (v == "misc_com_redware_plate")
 then v = "Plate" return v 
elseif (v == "misc_com_redware_platter")
 then v = "Platter" return v 
elseif (v == "key_falas tomb keepers")
 then v = "Preserved Ancient Key" return v 
elseif (v == "key_fetid_dreugh_grotto")
 then v = "Preserved Ancient Key" return v 
elseif (v == "key_varoprivate")
 then v = "Private Quarters Key" return v 
elseif (v == "Misc_Quill")
 then v = "Quill Pen" return v 
elseif (v == "misc_de_goblet_01_redas")
 then v = "Redas Goblet" return v 
elseif (v == "key_vivec_redoran_cell")
 then v = "Redoran Compound Cell Key" return v 
elseif (v == "key_pellecia aurrus")
 then v = "Redoran Iron Key" return v 
elseif (v == "key_redoran_basic")
 then v = "Redoran Iron Key" return v 
elseif (v == "misc_de_bowl_redware_01")
 then v = "Redware Bowl" return v 
elseif (v == "misc_de_bowl_redware_03")
 then v = "Redware Bowl" return v 
elseif (v == "misc_de_pot_redware_01")
 then v = "Redware Pot" return v 
elseif (v == "misc_de_pot_redware_02")
 then v = "Redware Pot" return v 
elseif (v == "Misc_DE_pot_redware_03")
 then v = "Redware Pot" return v 
elseif (v == "misc_de_pot_redware_04")
 then v = "Redware Pot" return v 
elseif (v == "misc_rollingpin_01")
 then v = "Rolling Pin" return v 
elseif (v == "index_roth")
 then v = "Rotheran Propylon Index" return v 
elseif (v == "key_rotheranslaves_01")
 then v = "Rotheran Slave Key" return v 
elseif (v == "key_Rufinus_Alleius")
 then v = "Rufinus Alleius' Key" return v 
elseif (v == "misc_dwrv_gear00")
 then v = "Rusty Dwemer Cog" return v 
elseif (v == "key_assemanu_01")
 then v = "Rusty Key" return v 
elseif (v == "key_assi_serimilk")
 then v = "Rusty Key" return v 
elseif (v == "key_kagouti_colony")
 then v = "Rusty Key" return v 
elseif (v == "key_shipwreck9-11")
 then v = "Rusty Key" return v 
elseif (v == "key_skeleton")
 then v = "Rusty Key" return v 
elseif (v == "key_Indaren")
 then v = "Rusty key into Indaren Tomb" return v 
elseif (v == "key_tukushapal_1")
 then v = "Rusty Old Key" return v 
elseif (v == "key_sadrithmoraslaves_01")
 then v = "Sadrith Mora Slave Key" return v 
elseif (v == "key_saryoni")
 then v = "Saryoni's Key" return v 
elseif (v == "key_Sarys_chest")
 then v = "Sarys chest key" return v 
elseif (v == "key_saturanslaves_01")
 then v = "Saturan Slave Key" return v 
elseif (v == "key_savilecagekey")
 then v = "Savile's Slavepod Key" return v 
elseif (v == "key_savilecagekey02")
 then v = "Savile's Slavepod Key" return v 
elseif (v == "key_vivec_secret")
 then v = "Secret Palace Entrance Key" return v 
elseif (v == "misc_skull10")
 then v = "Servant's Skull" return v 
elseif (v == "key_shaadnius")
 then v = "Sha-Adnius Key" return v 
elseif (v == "key_shaadniusslaves_01")
 then v = "Sha-Adnius Slave Key" return v 
elseif (v == "key_shashev")
 then v = "Shashev's Key" return v 
elseif (v == "misc_shears_01")
 then v = "Shears" return v 
elseif (v == "key_shilipuran")
 then v = "Shilipuran's Key" return v 
elseif (v == "key_miles")
 then v = "Shiny Key" return v 
elseif (v == "key_miun_gei")
 then v = "Shiny Key" return v 
elseif (v == "key_ebon_tomb")
 then v = "Shrine Key" return v 
elseif (v == "key_shushanslaves_01")
 then v = "Shushan Slave Key" return v 
elseif (v == "Misc_Imp_Silverware_Bowl")
 then v = "Silverware Bowl" return v 
elseif (v == "misc_imp_silverware_cup")
 then v = "Silverware Cup" return v 
elseif (v == "Misc_Imp_Silverware_Cup_01")
 then v = "Silverware Cup" return v 
elseif (v == "misc_imp_silverware_pitcher")
 then v = "Silverware Pitcher" return v 
elseif (v == "misc_imp_silverware_plate_01")
 then v = "Silverware Plate" return v 
elseif (v == "misc_imp_silverware_plate_02")
 then v = "Silverware Plate" return v 
elseif (v == "misc_imp_silverware_plate_03")
 then v = "Silverware Plate" return v 
elseif (v == "key_assarnud")
 then v = "Simple Key" return v 
elseif (v == "key_eldrar")
 then v = "Simple Key" return v 
elseif (v == "key_hinnabi")
 then v = "Simple Key" return v 
elseif (v == "key_hodlismod")
 then v = "Simple Key" return v 
elseif (v == "key_irgola")
 then v = "Simple Key" return v 
elseif (v == "key_minabi")
 then v = "Simple Key" return v 
elseif (v == "key_nund")
 then v = "Simple Key" return v 
elseif (v == "key_ra'zhid")
 then v = "Simple Key" return v 
elseif (v == "key_telbranoratower")
 then v = "Simple Key" return v 
elseif (v == "key_sinsibadonslaves_01")
 then v = "Sinsibadon Slave Key" return v 
elseif (v == "key_sirilonwe")
 then v = "Sirilonwe's Key" return v 
elseif (v == "misc_skull00")
 then v = "Skull" return v 
elseif (v == "misc_Skull_Llevule")
 then v = "Skull of Llevule Andrano" return v 
elseif (v == "key_rothran")
 then v = "Slave Cell Key" return v 
elseif (v == "key_shushishislaves")
 then v = "Slave key" return v 
elseif (v == "key_adibael")
 then v = "Small Key" return v 
elseif (v == "key_aldruhn_underground")
 then v = "Small Key" return v 
elseif (v == "key_aldsotha")
 then v = "Small Key" return v 
elseif (v == "key_eldafire")
 then v = "Small Key" return v 
elseif (v == "key_hanarai_assutlanipal")
 then v = "Small Key" return v 
elseif (v == "key_hasphat_antabolis2")
 then v = "Small Key" return v 
elseif (v == "key_keelraniur")
 then v = "Small Key" return v 
elseif (v == "key_nileno_dorvayn")
 then v = "Small Key" return v 
elseif (v == "key_ralen_hlaalo")
 then v = "Small Key" return v 
elseif (v == "key_relien_rirne")
 then v = "Small Key" return v 
elseif (v == "key_saetring")
 then v = "Small Key" return v 
elseif (v == "mamaea quarters key")
 then v = "Small Shiny Key" return v 
elseif (v == "misc_spool_01")
 then v = "Spool" return v 
elseif (v == "misc_com_silverware_spoon")
 then v = "Spoon" return v 
elseif (v == "misc_com_wood_spoon_01")
 then v = "Spoon" return v 
elseif (v == "misc_com_wood_spoon_01_UNI1")
 then v = "Spoon" return v 
elseif (v == "misc_com_wood_spoon_01_UNI2")
 then v = "Spoon" return v 
elseif (v == "misc_com_wood_spoon_02")
 then v = "Spoon" return v 
elseif (v == "key_olms_storage")
 then v = "St. Olms Storage Room Key" return v 
elseif (v == "key_arrile")
 then v = "Standard Key" return v 
elseif (v == "key_draramu")
 then v = "Standard Key" return v 
elseif (v == "key_gindrala")
 then v = "Standard Key" return v 
elseif (v == "key_standard_01")
 then v = "Standard Key" return v 
elseif (v == "key_standard_01_hassour zainsub")
 then v = "Standard Key" return v 
elseif (v == "key_berandas")
 then v = "Stolen Key" return v 
elseif (v == "key_drarayne_thelas")
 then v = "Storage Key" return v 
elseif (v == "key_balmorag_tong_02")
 then v = "Storage Room Key" return v 
elseif (v == "key_dulnea_ralaal")
 then v = "Storeroom Key" return v 
elseif (v == "key_summoning_room")
 then v = "Summoning Room Key" return v 
elseif (v == "key_suranslaves_01")
 then v = "Suran Slave Key" return v 
elseif (v == "misc_6th_ash_hrcs")
 then v = "Suspicious Ash Statue" return v 
elseif (v == "misc_com_tankard_01")
 then v = "Tankard" return v 
elseif (v == "misc_de_tankard_01")
 then v = "Tankard" return v 
elseif (v == "key_telaruhnslaves_01")
 then v = "Tel Aruhn Slave Key" return v 
elseif (v == "index_telas")
 then v = "Telasero Propylon Index" return v 
elseif (v == "key_telbranoraslaves_01")
 then v = "Tel Branora Slave Key" return v 
elseif (v == "key_vivectelvannislaves_01")
 then v = "Telvanni Canalworks Slave Key" return v 
elseif (v == "key_vivec_telvanni_cell")
 then v = "Telvanni Compound Cell Key" return v 
elseif (v == "key_tvault")
 then v = "Telvanni Vault Key" return v 
elseif (v == "key_telvosjailslaves_01")
 then v = "Tel Vos Jail Slave Key" return v 
elseif (v == "key_temple_01")
 then v = "Temple Key" return v 
elseif (v == "key_Tharys_chest")
 then v = "Tharys chest key" return v 
elseif (v == "misc_argonianhead_01")
 then v = "The Head Of Scourge" return v 
elseif (v == "key_Thelas_chest")
 then v = "Thelas chest key" return v 
elseif (v == "key_thorek")
 then v = "Thorek's Key" return v 
elseif (v == "key_falas tomb keepers_2")
 then v = "Tomb Door Key" return v 
elseif (v == "key_gen_tomb")
 then v = "Tomb Door Key" return v 
elseif (v == "key_dawnvault")
 then v = "Tower of Dawn Vault Key" return v 
elseif (v == "key_duskvault")
 then v = "Tower of Dusk Vault Key" return v 
elseif (v == "key_tuvesobeleth_01")
 then v = "Tuveso Beleth's Key" return v 
elseif (v == "key_ulvil")
 then v = "Ulvil's Key" return v 
elseif (v == "misc_wraithguard_no_equip")
 then v = "Unique Dwemer Artifact" return v 
elseif (v == "key_rvaults1")
 then v = "Upper Redoran Vault Key" return v 
elseif (v == "index_valen")
 then v = "Valenvaryon Propylon Index" return v 
elseif (v == "misc_com_redware_vase")
 then v = "Vase" return v 
elseif (v == "key_venimmanor")
 then v = "Venim Manor Key" return v 
elseif (v == "misc_vivec_ashmask_01")
 then v = "Vivec Ashmask" return v 
elseif (v == "misc_vivec_ashmask_01_fake")
 then v = "Vivec Ashmask" return v 
elseif (v == "key_volrina_01")
 then v = "Volrina Quarra's Key" return v 
elseif (v == "key_vorarhelas")
 then v = "Vorar Helas' Key" return v 
elseif (v == "Key_SN_Warehouse")
 then v = "Warehouse Key" return v 
elseif (v == "key_widow_vabdas")
 then v = "Widow Vabdas' Key" return v 
elseif (v == "key_impcomsecrdoor")
 then v = "Worn Imperial Key" return v 
elseif (v == "key_farusea_salas")
 then v = "Worn Key" return v 
elseif (v == "key_fedar")
 then v = "Worn Key" return v 
elseif (v == "key_FQT")
 then v = "Worn Key" return v 
elseif (v == "key_obscure_alit_warren")
 then v = "Worn Key" return v 
elseif (v == "key_Palansour")
 then v = "Worn Key" return v 
elseif (v == "key_yagram")
 then v = "Yagrum's Key" return v 
elseif (v == "key_yakanalitslaves_01")
 then v = "Yakanalit Slave Key" return v 
elseif (v == "misc_de_glass_yellow_01")
 then v = "Yellow Glass" return v 
elseif (v == "misc_de_bowl_glass_yellow_01")
 then v = "Yellow Glass Bowl" return v 
elseif (v == "key_yinglingbasement")
 then v = "Yngling Manor Basement Key" return v 
elseif (v == "key_zainsipiluslaves_01")
 then v = "Zainsipilu Slave Key" return v 
elseif (v == "key_zebabislaves_01")
 then v = "Zebabi Slave Key" return v 
elseif (v == "probe_apprentice_01")
 then v = "Apprentice's Probe" return v 
elseif (v == "probe_bent")
 then v = "Bent Probe" return v 
elseif (v == "probe_grandmaster")
 then v = "Grandmaster's Probe" return v 
elseif (v == "probe_journeyman_01")
 then v = "Journeyman's Probe" return v 
elseif (v == "probe_master")
 then v = "Master's Probe" return v 
elseif (v == "probe_secretmaster")
 then v = "Secret Master's Probe" return v 
elseif (v == "hammer_repair")
 then v = "Apprentice's Armorer's Hammer" return v 
elseif (v == "repair_grandmaster_01")
 then v = "GrandMaster's Armorer's Hammer" return v 
elseif (v == "repair_journeyman_01")
 then v = "Journeyman's Armorer's Hammer" return v 
elseif (v == "repair_master_01")
 then v = "Master's Armorer's Hammer" return v 
elseif (v == "repair_prongs")
 then v = "Repair Prongs" return v 
elseif (v == "repair_secretmaster_01")
 then v = "Sirollus Saccus' Hammer" return v 
elseif (v == "false_sunder")
 then v = "* Sunder *" return v 
elseif (v == "sunder_fake")
 then v = "* Sunder *" return v 
elseif (v == "VFX_AlterationBolt")
 then v = "(null)" return v 
elseif (v == "VFX_ConjureBolt")
 then v = "(null)" return v 
elseif (v == "VFX_DefaultBolt")
 then v = "(null)" return v 
elseif (v == "VFX_DestructBolt")
 then v = "(null)" return v 
elseif (v == "VFX_FrostBolt")
 then v = "(null)" return v 
elseif (v == "VFX_IllusionBolt")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple2")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple3")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple4")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple5")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple6")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple7")
 then v = "(null)" return v 
elseif (v == "VFX_Multiple8")
 then v = "(null)" return v 
elseif (v == "VFX_MysticismBolt")
 then v = "(null)" return v 
elseif (v == "VFX_PoisonBolt")
 then v = "(null)" return v 
elseif (v == "VFX_RestoreBolt")
 then v = "(null)" return v 
elseif (v == "Airan_Ahhe's_Spirit_Spear_uniq")
 then v = "Airan-Ahhe's Spirit Spear" return v 
elseif (v == "devil_tanto_tgamg")
 then v = "Anarenen's Devil Tanto" return v 
elseif (v == "steelstaffancestors_ttsa")
 then v = "Ancestral Wisdom Staff" return v 
elseif (v == "Silver Dagger_Hanin Cursed")
 then v = "Ancient Silver Dagger" return v 
elseif (v == "ane_teria_mace_unique")
 then v = "Ane Teria's Mace" return v 
elseif (v == "daedric_club_tgdc")
 then v = "Anora's Club" return v 
elseif (v == "arrow of wasting flame")
 then v = "Arrow of Wasting Flame" return v 
elseif (v == "arrow of wasting shard")
 then v = "Arrow of Wasting Shard" return v 
elseif (v == "arrow of wasting spark")
 then v = "Arrow of Wasting Spark" return v 
elseif (v == "arrow of wasting viper")
 then v = "Arrow of Wasting Viper" return v 
elseif (v == "Rusty_Dagger_UNIQUE")
 then v = "A Rusty Dagger" return v 
elseif (v == "ebony_bow_auriel")
 then v = "Auriel's Bow" return v 
elseif (v == "azura_star_unique")
 then v = "Azura's Star" return v 
elseif (v == "banhammer_unique")
 then v = "BanHammer" return v 
elseif (v == "battle axe of wounds")
 then v = "Battle Axe of Wounds" return v 
elseif (v == "daedric dagger_mtas")
 then v = "Black Hands Dagger" return v 
elseif (v == "boethiah's walking stick")
 then v = "Boethiah's Walking Stick" return v 
elseif (v == "bonebiter_bow_unique")
 then v = "Bonebiter Bow of Sul-Senipul" return v 
elseif (v == "bonemold arrow")
 then v = "Bonemold Arrow" return v 
elseif (v == "bonemold bolt")
 then v = "Bonemold Bolt" return v 
elseif (v == "bonemold long bow")
 then v = "Bonemold Long Bow" return v 
elseif (v == "bound_battle_axe")
 then v = "Bound Battle Axe" return v 
elseif (v == "bound_dagger")
 then v = "Bound Dagger" return v 
elseif (v == "bound_longbow")
 then v = "Bound Longbow" return v 
elseif (v == "bound_longsword")
 then v = "Bound Longsword" return v 
elseif (v == "bound_mace")
 then v = "Bound Mace" return v 
elseif (v == "bound_spear")
 then v = "Bound Spear" return v 
elseif (v == "longbow_shadows_unique")
 then v = "Bow of Shadows" return v 
elseif (v == "dwarven halberd_soultrap")
 then v = "Bthuangth's Harvester" return v 
elseif (v == "chitin arrow")
 then v = "Chitin Arrow" return v 
elseif (v == "chitin club")
 then v = "Chitin Club" return v 
elseif (v == "chitin dagger")
 then v = "Chitin Dagger" return v 
elseif (v == "chitin short bow")
 then v = "Chitin Short Bow" return v 
elseif (v == "chitin shortsword")
 then v = "Chitin Shortsword" return v 
elseif (v == "chitin spear")
 then v = "Chitin Spear" return v 
elseif (v == "chitin throwing star")
 then v = "Chitin Throwing Star" return v 
elseif (v == "chitin war axe")
 then v = "Chitin War Axe" return v 
elseif (v == "claymore_chrysamere_unique")
 then v = "Chrysamere" return v 
elseif (v == "cleaverstfelms")
 then v = "Cleaver of St. Felms" return v 
elseif (v == "cloudcleaver_unique")
 then v = "Cloudcleaver" return v 
elseif (v == "clutterbane")
 then v = "Clutterbane" return v 
elseif (v == "conoon_chodala_axe_unique")
 then v = "Conoon Chodala's Axe" return v 
elseif (v == "corkbulb arrow")
 then v = "Corkbulb Arrow" return v 
elseif (v == "corkbulb bolt")
 then v = "Corkbulb Bolt" return v 
elseif (v == "crosierstllothis")
 then v = "Crosier of St. Llothis" return v 
elseif (v == "cruel flamearrow")
 then v = "Cruel Flamearrow" return v 
elseif (v == "cruel flameblade")
 then v = "Cruel Flameblade" return v 
elseif (v == "cruel flame bolt")
 then v = "Cruel Flame Bolt" return v 
elseif (v == "cruel flamestar")
 then v = "Cruel Flamestar" return v 
elseif (v == "cruel flamesword")
 then v = "Cruel Flamesword" return v 
elseif (v == "cruel frostarrow")
 then v = "Cruel Frostarrow" return v 
elseif (v == "cruel shardarrow")
 then v = "Cruel Shardarrow" return v 
elseif (v == "cruel shardblade")
 then v = "Cruel Shardblade" return v 
elseif (v == "cruel shard bolt")
 then v = "Cruel Shard Bolt" return v 
elseif (v == "cruel shardstar")
 then v = "Cruel Shardstar" return v 
elseif (v == "cruel shardsword")
 then v = "Cruel Shardsword" return v 
elseif (v == "cruel sparkarrow")
 then v = "Cruel Sparkarrow" return v 
elseif (v == "cruel sparkblade")
 then v = "Cruel Sparkblade" return v 
elseif (v == "cruel spark bolt")
 then v = "Cruel Spark Bolt" return v 
elseif (v == "cruel sparkstar")
 then v = "Cruel Sparkstar" return v 
elseif (v == "cruel sparksword")
 then v = "Cruel Sparksword" return v 
elseif (v == "cruel viperarrow")
 then v = "Cruel Viperarrow" return v 
elseif (v == "cruel viperblade")
 then v = "Cruel Viperblade" return v 
elseif (v == "cruel viper bolt")
 then v = "Cruel Viper Bolt" return v 
elseif (v == "cruel viperstar")
 then v = "Cruel Viperstar" return v 
elseif (v == "cruel vipersword")
 then v = "Cruel Vipersword" return v 
elseif (v == "daedric arrow")
 then v = "Daedric Arrow" return v 
elseif (v == "daedric battle axe")
 then v = "Daedric Battle Axe" return v 
elseif (v == "daedric claymore")
 then v = "Daedric Claymore" return v 
elseif (v == "daedric club")
 then v = "Daedric Club" return v 
elseif (v == "daedric_crescent_unique")
 then v = "Daedric Crescent" return v 
elseif (v == "daedric dagger")
 then v = "Daedric Dagger" return v 
elseif (v == "daedric dai-katana")
 then v = "Daedric Dai-katana" return v 
elseif (v == "daedric dart")
 then v = "Daedric Dart" return v 
elseif (v == "daedric katana")
 then v = "Daedric Katana" return v 
elseif (v == "daedric long bow")
 then v = "Daedric Long Bow" return v 
elseif (v == "daedric longsword")
 then v = "Daedric Longsword" return v 
elseif (v == "daedric mace")
 then v = "Daedric Mace" return v 
elseif (v == "daedric shortsword")
 then v = "Daedric Shortsword" return v 
elseif (v == "daedric spear")
 then v = "Daedric Spear" return v 
elseif (v == "daedric staff")
 then v = "Daedric Staff" return v 
elseif (v == "daedric tanto")
 then v = "Daedric Tanto" return v 
elseif (v == "daedric wakizashi")
 then v = "Daedric Wakizashi" return v 
elseif (v == "daedric wakizashi_hhst")
 then v = "Daedric Wakizashi" return v 
elseif (v == "daedric war axe")
 then v = "Daedric War Axe" return v 
elseif (v == "daedric warhammer")
 then v = "Daedric Warhammer" return v 
elseif (v == "Dagger of Judgement")
 then v = "Dagger of Judgement" return v 
elseif (v == "dagoth dagger")
 then v = "Dagoth Dagger" return v 
elseif (v == "dart_uniq_judgement")
 then v = "Dart of Judgment" return v 
elseif (v == "iron_arrow_uniq_judgement")
 then v = "Dart of Judgment" return v 
elseif (v == "daunting mace")
 then v = "Daunting Mace" return v 
elseif (v == "demon katana")
 then v = "Demon Katana" return v 
elseif (v == "demon longbow")
 then v = "Demon Longbow" return v 
elseif (v == "demon mace")
 then v = "Demon Mace" return v 
elseif (v == "demon tanto")
 then v = "Demon Tanto" return v 
elseif (v == "devil katana")
 then v = "Devil Katana" return v 
elseif (v == "devil longbow")
 then v = "Devil Longbow" return v 
elseif (v == "devil spear")
 then v = "Devil Spear" return v 
elseif (v == "devil tanto")
 then v = "Devil Tanto" return v 
elseif (v == "dire flamearrow")
 then v = "Dire Flamearrow" return v 
elseif (v == "dire flameblade")
 then v = "Dire Flameblade" return v 
elseif (v == "dire flame bolt")
 then v = "Dire Flamebolt" return v 
elseif (v == "dire flamesword")
 then v = "Dire Flamesword" return v 
elseif (v == "dire frostarrow")
 then v = "Dire Frostarrow" return v 
elseif (v == "dire shardarrow")
 then v = "Dire Shardarrow" return v 
elseif (v == "dire shardblade")
 then v = "Dire Shardblade" return v 
elseif (v == "dire shard bolt")
 then v = "Dire Shardbolt" return v 
elseif (v == "dire shardsword")
 then v = "Dire Shardsword" return v 
elseif (v == "dire sparkarrow")
 then v = "Dire Sparkarrow" return v 
elseif (v == "dire sparkblade")
 then v = "Dire Sparkblade" return v 
elseif (v == "dire spark bolt")
 then v = "Dire Sparkbolt" return v 
elseif (v == "dire sparksword")
 then v = "Dire Sparksword" return v 
elseif (v == "dire viperarrow")
 then v = "Dire Viperarrow" return v 
elseif (v == "dire viperblade")
 then v = "Dire Viperblade" return v 
elseif (v == "dire viper bolt")
 then v = "Dire Viperbolt" return v 
elseif (v == "dire vipersword")
 then v = "Dire Vipersword" return v 
elseif (v == "divine judgement silver staff")
 then v = "Divine Judgement Silver Staff" return v 
elseif (v == "dreugh club")
 then v = "Dreugh Club" return v 
elseif (v == "dreugh staff")
 then v = "Dreugh Staff" return v 
elseif (v == "dwarven battle axe")
 then v = "Dwarven Battle Axe" return v 
elseif (v == "dwarven claymore")
 then v = "Dwarven Claymore" return v 
elseif (v == "dwarven crossbow")
 then v = "Dwarven Crossbow" return v 
elseif (v == "dwarven halberd")
 then v = "Dwarven Halberd" return v 
elseif (v == "dwarven mace")
 then v = "Dwarven Mace" return v 
elseif (v == "dwarven shortsword")
 then v = "Dwarven Shortsword" return v 
elseif (v == "dwarven spear")
 then v = "Dwarven Spear" return v 
elseif (v == "dwarven war axe")
 then v = "Dwarven War Axe" return v 
elseif (v == "dwarven warhammer")
 then v = "Dwarven Warhammer" return v 
elseif (v == "dwemer jinksword")
 then v = "Dwemer Jinksword" return v 
elseif (v == "dwarven axe_soultrap")
 then v = "Dwemer Pneuma-Trap" return v 
elseif (v == "ebony arrow")
 then v = "Ebony Arrow" return v 
elseif (v == "ebony broadsword")
 then v = "Ebony Broadsword" return v 
elseif (v == "ebony broadsword_Dae_cursed")
 then v = "Ebony Broadsword" return v 
elseif (v == "ebony dart")
 then v = "Ebony Dart" return v 
elseif (v == "ebony longsword")
 then v = "Ebony Longsword" return v 
elseif (v == "ebony mace")
 then v = "Ebony Mace" return v 
elseif (v == "ebony_dagger_mehrunes")
 then v = "Ebony Shortsword" return v 
elseif (v == "ebony shortsword")
 then v = "Ebony Shortsword" return v 
elseif (v == "ebony spear")
 then v = "Ebony Spear" return v 
elseif (v == "ebony spear_hrce_unique")
 then v = "Ebony Spear" return v 
elseif (v == "ebony staff")
 then v = "Ebony Staff" return v 
elseif (v == "ebony throwing star")
 then v = "Ebony Throwing Star" return v 
elseif (v == "ebony war axe")
 then v = "Ebony War Axe" return v 
elseif (v == "katana_bluebrand_unique")
 then v = "Eltonbrand" return v 
elseif (v == "glass_dagger_enamor")
 then v = "Enamor" return v 
elseif (v == "erur_dan_spear_unique")
 then v = "Erud-Dan's Spear" return v 
elseif (v == "dagger_fang_unique")
 then v = "Fang of Haynekhtnamet" return v 
elseif (v == "ebony staff caper")
 then v = "Felen's Ebony Staff" return v 
elseif (v == "fiend battle axe")
 then v = "Fiend Battle Axe" return v 
elseif (v == "fiend katana")
 then v = "Fiend Katana" return v 
elseif (v == "fiend longbow")
 then v = "Fiend Longbow" return v 
elseif (v == "fiend spear")
 then v = "Fiend Spear" return v 
elseif (v == "fiend spear_Dae_cursed")
 then v = "Fiend Spear" return v 
elseif (v == "fiend tanto")
 then v = "Fiend Tanto" return v 
elseif (v == "firebite club")
 then v = "Firebite Club" return v 
elseif (v == "firebite dagger")
 then v = "Firebite Dagger" return v 
elseif (v == "firebite star")
 then v = "Firebite Star" return v 
elseif (v == "firebite sword")
 then v = "Firebite Sword" return v 
elseif (v == "firebite war axe")
 then v = "Firebite War Axe" return v 
elseif (v == "fireblade")
 then v = "Fireblade" return v 
elseif (v == "flame arrow")
 then v = "Flame Arrow" return v 
elseif (v == "flame_bolt")
 then v = "Flamebolt" return v 
elseif (v == "flamestar")
 then v = "Flamestar" return v 
elseif (v == "dwe_jinksword_curse_Unique")
 then v = "Flawed Dwemer Jinksword" return v 
elseif (v == "flying viper")
 then v = "Flying Viper" return v 
elseif (v == "foeburner")
 then v = "Foeburner" return v 
elseif (v == "fork_horripilation_unique")
 then v = "Fork of Horripilation" return v 
elseif (v == "magic_bolt")
 then v = "FOR SPELL CASTING" return v 
elseif (v == "shield_bolt")
 then v = "FOR SPELL CASTING" return v 
elseif (v == "shock_bolt")
 then v = "FOR SPELL CASTING" return v 
elseif (v == "Fury")
 then v = "Fury" return v 
elseif (v == "gavel of the ordinator")
 then v = "Gavel of the Ordinator" return v 
elseif (v == "glass arrow")
 then v = "Glass Arrow" return v 
elseif (v == "glass claymore")
 then v = "Glass Claymore" return v 
elseif (v == "glass dagger")
 then v = "Glass Dagger" return v 
elseif (v == "glass dagger_Dae_cursed")
 then v = "Glass Dagger" return v 
elseif (v == "glass firesword")
 then v = "Glass Firesword" return v 
elseif (v == "glass frostsword")
 then v = "Glass Frostsword" return v 
elseif (v == "glass halberd")
 then v = "Glass Halberd" return v 
elseif (v == "glass jinkblade")
 then v = "Glass Jinkblade" return v 
elseif (v == "glass longsword")
 then v = "Glass Longsword" return v 
elseif (v == "glass netch dagger")
 then v = "Glass Netch Dagger" return v 
elseif (v == "glass poisonsword")
 then v = "Glass Poisonsword" return v 
elseif (v == "glass staff")
 then v = "Glass Staff" return v 
elseif (v == "glass stormblade")
 then v = "Glass Stormblade" return v 
elseif (v == "glass stormsword")
 then v = "Glass Stormsword" return v 
elseif (v == "glass throwing knife")
 then v = "Glass Throwing Knife" return v 
elseif (v == "glass throwing star")
 then v = "Glass Throwing Star" return v 
elseif (v == "glass war axe")
 then v = "Glass War Axe" return v 
elseif (v == "katana_goldbrand_unique")
 then v = "Goldbrand" return v 
elseif (v == "Greed")
 then v = "Greed" return v 
elseif (v == "grey shaft of holding")
 then v = "Grey Shaft of Holding" return v 
elseif (v == "grey shaft of nonsense")
 then v = "Grey Shaft of Nonsense" return v 
elseif (v == "grey shaft of unraveling")
 then v = "Grey Shaft of Unraveling" return v 
elseif (v == "we_hellfirestaff")
 then v = "Hellfire Staff" return v 
elseif (v == "herder_crook")
 then v = "Herder's Crook" return v 
elseif (v == "claymore_iceblade_unique")
 then v = "Ice Blade of the Monarch" return v 
elseif (v == "icebreaker")
 then v = "Icebreaker" return v 
elseif (v == "icicle")
 then v = "Icicle" return v 
elseif (v == "we_illkurok")
 then v = "Illkurok" return v 
elseif (v == "imperial broadsword")
 then v = "Imperial Broadsword" return v 
elseif (v == "imperial netch blade")
 then v = "Imperial Netch Blade" return v 
elseif (v == "imperial shortsword")
 then v = "Imperial Shortsword" return v 
elseif (v == "iron arrow")
 then v = "Iron Arrow" return v 
elseif (v == "iron battle axe")
 then v = "Iron Battle Axe" return v 
elseif (v == "iron bolt")
 then v = "Iron Bolt" return v 
elseif (v == "iron broadsword")
 then v = "Iron Broadsword" return v 
elseif (v == "iron claymore")
 then v = "Iron Claymore" return v 
elseif (v == "iron club")
 then v = "Iron Club" return v 
elseif (v == "chargen dagger")
 then v = "Iron Dagger" return v 
elseif (v == "iron dagger")
 then v = "Iron Dagger" return v 
elseif (v == "iron dagger_telasero_unique")
 then v = "Iron Dagger" return v 
elseif (v == "iron flameblade")
 then v = "Iron Flameblade" return v 
elseif (v == "iron flamecleaver")
 then v = "Iron Flamecleaver" return v 
elseif (v == "iron flamemace")
 then v = "Iron Flamemace" return v 
elseif (v == "iron flamemauler")
 then v = "Iron Flamemauler" return v 
elseif (v == "iron flameskewer")
 then v = "Iron Flameskewer" return v 
elseif (v == "iron flameslayer")
 then v = "Iron Flameslayer" return v 
elseif (v == "iron flamesword")
 then v = "Iron Flamesword" return v 
elseif (v == "iron fork")
 then v = "Iron Fork" return v 
elseif (v == "iron halberd")
 then v = "Iron Halberd" return v 
elseif (v == "iron longsword")
 then v = "Iron Longsword" return v 
elseif (v == "iron mace")
 then v = "Iron Mace" return v 
elseif (v == "iron saber")
 then v = "Iron Saber" return v 
elseif (v == "iron shardaxe")
 then v = "Iron Shardaxe" return v 
elseif (v == "iron shardblade")
 then v = "Iron Shardblade" return v 
elseif (v == "iron shardcleaver")
 then v = "Iron Shardcleaver" return v 
elseif (v == "iron shardmace")
 then v = "Iron Shardmace" return v 
elseif (v == "iron shardmauler")
 then v = "Iron Shardmauler" return v 
elseif (v == "iron shardskewer")
 then v = "Iron Shardskewer" return v 
elseif (v == "iron shardslayer")
 then v = "Iron Shardslayer" return v 
elseif (v == "iron shardsword")
 then v = "Iron Shardsword" return v 
elseif (v == "iron shortsword")
 then v = "Iron Shortsword" return v 
elseif (v == "iron sparkaxe")
 then v = "Iron Sparkaxe" return v 
elseif (v == "iron sparkblade")
 then v = "Iron Sparkblade" return v 
elseif (v == "iron sparkcleaver")
 then v = "Iron Sparkcleaver" return v 
elseif (v == "iron sparkmace")
 then v = "Iron Sparkmace" return v 
elseif (v == "iron sparkmauler")
 then v = "Iron Sparkmauler" return v 
elseif (v == "iron sparkskewer")
 then v = "Iron Sparkskewer" return v 
elseif (v == "iron sparkslayer")
 then v = "Iron Sparkslayer" return v 
elseif (v == "iron sparksword")
 then v = "Iron Sparksword" return v 
elseif (v == "Iron Long Spear")
 then v = "Iron Spear" return v 
elseif (v == "iron spear")
 then v = "Iron Spear" return v 
elseif (v == "iron spider dagger")
 then v = "Iron Spider Dagger" return v 
elseif (v == "iron tanto")
 then v = "Iron Tanto" return v 
elseif (v == "iron throwing knife")
 then v = "Iron Throwing Knife" return v 
elseif (v == "iron viperaxe")
 then v = "Iron Viperaxe" return v 
elseif (v == "iron viperblade")
 then v = "Iron Viperblade" return v 
elseif (v == "iron vipercleaver")
 then v = "Iron Vipercleaver" return v 
elseif (v == "iron vipermauler")
 then v = "Iron Vipermauler" return v 
elseif (v == "iron viperskewer")
 then v = "Iron Viperskewer" return v 
elseif (v == "iron viperslayer")
 then v = "Iron Viperslayer" return v 
elseif (v == "iron vipersword")
 then v = "Iron Vipersword" return v 
elseif (v == "iron wakizashi")
 then v = "Iron Wakizashi" return v 
elseif (v == "iron war axe")
 then v = "Iron War Axe" return v 
elseif (v == "iron warhammer")
 then v = "Iron Warhammer" return v 
elseif (v == "Karpal's Friend")
 then v = "Karpal's Friend" return v 
elseif (v == "keening")
 then v = "Keening" return v 
elseif (v == "last rites")
 then v = "Last Rites" return v 
elseif (v == "last wish")
 then v = "Last Wish" return v 
elseif (v == "lightofday_unique")
 then v = "Light of Day" return v 
elseif (v == "light staff")
 then v = "Light Staff" return v 
elseif (v == "long bow")
 then v = "Long Bow" return v 
elseif (v == "lugrub's axe")
 then v = "Lugrub's Axe" return v 
elseif (v == "mace of molag bal_unique")
 then v = "Mace of Molag Bal" return v 
elseif (v == "glass claymore_magebane")
 then v = "Magebane" return v 
elseif (v == "ebony_staff_tges")
 then v = "Maryon's Staff" return v 
elseif (v == "mehrunes'_razor_unique")
 then v = "Mehrunes' Razor" return v 
elseif (v == "mephala's teacher")
 then v = "Mephala's Teacher" return v 
elseif (v == "merisan club")
 then v = "Merisan Club" return v 
elseif (v == "miner's pick")
 then v = "Miner's Pick" return v 
elseif (v == "nordic battle axe")
 then v = "Nordic Battle Axe" return v 
elseif (v == "nordic broadsword")
 then v = "Nordic Broadsword" return v 
elseif (v == "nordic claymore")
 then v = "Nordic Claymore" return v 
elseif (v == "orcish battle axe")
 then v = "Orcish Battle Axe" return v 
elseif (v == "orcish bolt")
 then v = "Orcish Bolt" return v 
elseif (v == "orcish warhammer")
 then v = "Orc Warhammer" return v 
elseif (v == "peacemaker")
 then v = "Peacemaker" return v 
elseif (v == "racerbeak")
 then v = "Racerbeak" return v 
elseif (v == "dwarven war axe_redas")
 then v = "Redas War Axe" return v 
elseif (v == "saint's black sword")
 then v = "Saint's Black Sword" return v 
elseif (v == "daedric_scourge_unique")
 then v = "Scourge" return v 
elseif (v == "shard arrow")
 then v = "Shard Arrow" return v 
elseif (v == "shard_bolt")
 then v = "Shardbolt" return v 
elseif (v == "shardstar")
 then v = "Shardstar" return v 
elseif (v == "we_shimsil")
 then v = "Shimsil" return v 
elseif (v == "shockbite battle axe")
 then v = "Shockbite Battle Axe" return v 
elseif (v == "shockbite halberd")
 then v = "Shockbite Halberd" return v 
elseif (v == "shockbite mace")
 then v = "Shockbite Mace" return v 
elseif (v == "shockbite war axe")
 then v = "Shockbite War Axe" return v 
elseif (v == "shockbite warhammer")
 then v = "Shockbite Warhammer" return v 
elseif (v == "short bow")
 then v = "Short Bow" return v 
elseif (v == "shortbow of sanguine sureflight")
 then v = "Shortbow of Sanguine Sureflight" return v 
elseif (v == "silver arrow")
 then v = "Silver Arrow" return v 
elseif (v == "silver bolt")
 then v = "Silver Bolt" return v 
elseif (v == "silver claymore")
 then v = "Silver Claymore" return v 
elseif (v == "silver dagger")
 then v = "Silver Dagger" return v 
elseif (v == "silver dart")
 then v = "Silver Dart" return v 
elseif (v == "silver flameaxe")
 then v = "Silver Flameaxe" return v 
elseif (v == "silver flameblade")
 then v = "Silver Flameblade" return v 
elseif (v == "silver flameskewer")
 then v = "Silver Flameskewer" return v 
elseif (v == "silver shardskewer")
 then v = "Silver Flameskewer" return v 
elseif (v == "silver flameslayer")
 then v = "Silver Flameslayer" return v 
elseif (v == "silver flamesword")
 then v = "Silver Flamesword" return v 
elseif (v == "silver longsword")
 then v = "Silver Longsword" return v 
elseif (v == "silver shardaxe")
 then v = "Silver Shardaxe" return v 
elseif (v == "silver shardblade")
 then v = "Silver Shardblade" return v 
elseif (v == "silver shardslayer")
 then v = "Silver Shardslayer" return v 
elseif (v == "silver shardsword")
 then v = "Silver Shardsword" return v 
elseif (v == "silver shortsword")
 then v = "Silver Shortsword" return v 
elseif (v == "silver sparkaxe")
 then v = "Silver Sparkaxe" return v 
elseif (v == "silver sparkblade")
 then v = "Silver Sparkblade" return v 
elseif (v == "silver sparkskewer")
 then v = "Silver Sparkskewer" return v 
elseif (v == "silver sparkslayer")
 then v = "Silver Sparkslayer" return v 
elseif (v == "silver sparksword")
 then v = "Silver Sparksword" return v 
elseif (v == "silver spear")
 then v = "Silver Spear" return v 
elseif (v == "silver_staff_dawn_uniq")
 then v = "Silver Staff" return v 
elseif (v == "silver staff")
 then v = "Silver Staff" return v 
elseif (v == "silver staff of chastening")
 then v = "Silver Staff of Chastening" return v 
elseif (v == "silver staff of hunger")
 then v = "Silver Staff of Hunger" return v 
elseif (v == "silver staff of peace")
 then v = "Silver Staff of Peace" return v 
elseif (v == "silver staff of reckoning")
 then v = "Silver Staff of Reckoning" return v 
elseif (v == "silver staff of shaming")
 then v = "Silver Staff of Shaming" return v 
elseif (v == "silver staff of war")
 then v = "Silver Staff of War" return v 
elseif (v == "silver throwing star")
 then v = "Silver Throwing Star" return v 
elseif (v == "silver viperaxe")
 then v = "Silver Viperaxe" return v 
elseif (v == "silver viperblade")
 then v = "Silver Viperblade" return v 
elseif (v == "silver viperskewer")
 then v = "Silver Viperskewer" return v 
elseif (v == "silver viperslayer")
 then v = "Silver Viperslayer" return v 
elseif (v == "silver vipersword")
 then v = "Silver Vipersword" return v 
elseif (v == "silver war axe")
 then v = "Silver War Axe" return v 
elseif (v == "6th bell hammer")
 then v = "Sixth House Bell Hammer" return v 
elseif (v == "warhammer_crusher_unique")
 then v = "Skull Crusher" return v 
elseif (v == "snowy crown")
 then v = "Snowy Crown" return v 
elseif (v == "daedric dagger_soultrap")
 then v = "Soul Drinker" return v 
elseif (v == "spark arrow")
 then v = "Spark Arrow" return v 
elseif (v == "spark_bolt")
 then v = "Sparkbolt" return v 
elseif (v == "sparkstar")
 then v = "Sparkstar" return v 
elseif (v == "spear_mercy_unique")
 then v = "Spear of Bitter Mercy" return v 
elseif (v == "spear_of_light")
 then v = "Spear of Light" return v 
elseif (v == "spiderbite")
 then v = "Spiderbite" return v 
elseif (v == "spiked club")
 then v = "Spiked Club" return v 
elseif (v == "spirit-eater")
 then v = "Spirit-Eater" return v 
elseif (v == "staff_hasedoki_unique")
 then v = "Staff of Hasedoki" return v 
elseif (v == "staff_of_llevule")
 then v = "Staff of Llevule" return v 
elseif (v == "staff_magnus_unique")
 then v = "Staff of Magnus" return v 
elseif (v == "staff of the forefathers")
 then v = "Staff of the Forefathers" return v 
elseif (v == "steel arrow")
 then v = "Steel Arrow" return v 
elseif (v == "steel axe")
 then v = "Steel Axe" return v 
elseif (v == "steel battle axe")
 then v = "Steel Battle Axe" return v 
elseif (v == "steel blade of heaven")
 then v = "Steel Blade of Heaven" return v 
elseif (v == "steel bolt")
 then v = "Steel Bolt" return v 
elseif (v == "steel broadsword")
 then v = "Steel Broadsword" return v 
elseif (v == "steel broadsword of hewing")
 then v = "Steel Broadsword of Hewing" return v 
elseif (v == "steel claymore")
 then v = "Steel Claymore" return v 
elseif (v == "steel claymore of hewing")
 then v = "Steel Claymore of Hewing" return v 
elseif (v == "steel club")
 then v = "Steel Club" return v 
elseif (v == "steel crossbow")
 then v = "Steel Crossbow" return v 
elseif (v == "steel dagger")
 then v = "Steel Dagger" return v 
elseif (v == "steel dagger of swiftblade")
 then v = "Steel Dagger of Swiftblade" return v 
elseif (v == "steel dai-katana")
 then v = "Steel Dai-katana" return v 
elseif (v == "steel dart")
 then v = "Steel Dart" return v 
elseif (v == "steel firesword")
 then v = "Steel Firesword" return v 
elseif (v == "steel flameaxe")
 then v = "Steel Flameaxe" return v 
elseif (v == "steel flameblade")
 then v = "Steel Flameblade" return v 
elseif (v == "steel flamecleaver")
 then v = "Steel Flamecleaver" return v 
elseif (v == "steel flamemace")
 then v = "Steel Flamemace" return v 
elseif (v == "steel flamemauler")
 then v = "Steel Flamemauler" return v 
elseif (v == "steel flamescythe")
 then v = "Steel Flamescythe" return v 
elseif (v == "steel flameskewer")
 then v = "Steel Flameskewer" return v 
elseif (v == "steel flameslayer")
 then v = "Steel Flameslayer" return v 
elseif (v == "steel flamesword")
 then v = "Steel Flamesword" return v 
elseif (v == "steel frostsword")
 then v = "Steel Frostsword" return v 
elseif (v == "steel halberd")
 then v = "Steel Halberd" return v 
elseif (v == "steel jinkblade")
 then v = "Steel Jinkblade" return v 
elseif (v == "steel jinkblade of the aegis")
 then v = "Steel Jinkblade of the Aegis" return v 
elseif (v == "steel jinksword")
 then v = "Steel Jinksword" return v 
elseif (v == "steel katana")
 then v = "Steel Katana" return v 
elseif (v == "steel longbow")
 then v = "Steel Longbow" return v 
elseif (v == "steel longsword")
 then v = "Steel Longsword" return v 
elseif (v == "steel mace")
 then v = "Steel Mace" return v 
elseif (v == "steel poisonsword")
 then v = "Steel Poisonsword" return v 
elseif (v == "steel saber")
 then v = "Steel Saber" return v 
elseif (v == "steel shardaxe")
 then v = "Steel Shardaxe" return v 
elseif (v == "steel shardblade")
 then v = "Steel Shardblade" return v 
elseif (v == "steel shardcleaver")
 then v = "Steel Shardcleaver" return v 
elseif (v == "steel shardmace")
 then v = "Steel Shardmace" return v 
elseif (v == "steel shardmauler")
 then v = "Steel Shardmauler" return v 
elseif (v == "steel shardscythe")
 then v = "Steel Shardscythe" return v 
elseif (v == "steel shardskewer")
 then v = "Steel Shardskewer" return v 
elseif (v == "steel shardslayer")
 then v = "Steel Shardslayer" return v 
elseif (v == "steel shardsword")
 then v = "Steel Shardsword" return v 
elseif (v == "steel shortsword")
 then v = "Steel Shortsword" return v 
elseif (v == "steel sparkaxe")
 then v = "Steel Sparkaxe" return v 
elseif (v == "steel sparkblade")
 then v = "Steel Sparkblade" return v 
elseif (v == "steel sparkcleaver")
 then v = "Steel Sparkcleaver" return v 
elseif (v == "steel sparkmace")
 then v = "Steel Sparkmace" return v 
elseif (v == "steel sparkmauler")
 then v = "Steel Sparkmauler" return v 
elseif (v == "steel sparkscythe")
 then v = "Steel Sparkscythe" return v 
elseif (v == "steel sparkskewer")
 then v = "Steel Sparkskewer" return v 
elseif (v == "steel sparkslayer")
 then v = "Steel Sparkslayer" return v 
elseif (v == "steel sparksword")
 then v = "Steel Sparksword" return v 
elseif (v == "steel spear")
 then v = "Steel Spear" return v 
elseif (v == "steel spear of impaling thrust")
 then v = "Steel Spear of Impaling Thrust" return v 
elseif (v == "steel spider blade")
 then v = "Steel Spider Blade" return v 
elseif (v == "steel staff")
 then v = "Steel Staff" return v 
elseif (v == "steel staff of chastening")
 then v = "Steel Staff of Chastening" return v 
elseif (v == "steel staff of divine judgement")
 then v = "Steel Staff of Divine Judgement" return v 
elseif (v == "steel staff of peace")
 then v = "Steel Staff of Peace" return v 
elseif (v == "steel staff of shaming")
 then v = "Steel Staff of Shaming" return v 
elseif (v == "steel staff of the ancestors")
 then v = "Steel Staff of the Ancestors" return v 
elseif (v == "steel staff of war")
 then v = "Steel Staff of War" return v 
elseif (v == "steel stormsword")
 then v = "Steel Stormsword" return v 
elseif (v == "steel tanto")
 then v = "Steel Tanto" return v 
elseif (v == "steel throwing knife")
 then v = "Steel Throwing Knife" return v 
elseif (v == "steel throwing star")
 then v = "Steel Throwing Star" return v 
elseif (v == "steel viperaxe")
 then v = "Steel Viperaxe" return v 
elseif (v == "steel viperblade")
 then v = "Steel Viperblade" return v 
elseif (v == "steel vipercleaver")
 then v = "Steel Vipercleaver" return v 
elseif (v == "steel vipermace")
 then v = "Steel Vipermace" return v 
elseif (v == "steel vipermauler")
 then v = "Steel Vipermauler" return v 
elseif (v == "steel viperscythe")
 then v = "Steel Viperscythe" return v 
elseif (v == "steel viperskewer")
 then v = "Steel Viperskewer" return v 
elseif (v == "steel viperslayer")
 then v = "Steel Viperslayer" return v 
elseif (v == "steel vipersword")
 then v = "Steel Vipersword" return v 
elseif (v == "steel wakizashi")
 then v = "Steel Wakizashi" return v 
elseif (v == "steel war axe")
 then v = "Steel War Axe" return v 
elseif (v == "steel war axe of deep biting")
 then v = "Steel War Axe of Deep Biting" return v 
elseif (v == "steel warhammer")
 then v = "Steel Warhammer" return v 
elseif (v == "steel warhammer of smiting")
 then v = "Steel Warhammer of Smiting" return v 
elseif (v == "stormblade")
 then v = "Stormblade" return v 
elseif (v == "we_stormforge")
 then v = "Stormforge" return v 
elseif (v == "Stormkiss")
 then v = "Stormkiss" return v 
elseif (v == "sunder")
 then v = "Sunder" return v 
elseif (v == "claymore_Agustas")
 then v = "Sword of Agustas" return v 
elseif (v == "sword of white woe")
 then v = "Sword of White Woe" return v 
elseif (v == "we_temreki")
 then v = "Temreki, Shackler of Souls" return v 
elseif (v == "throwing knife of sureflight")
 then v = "Throwing Knife of Sureflight" return v 
elseif (v == "ebony_staff_trebonius")
 then v = "Trebonius' Staff" return v 
elseif (v == "longsword_umbra_unique")
 then v = "Umbra Sword" return v 
elseif (v == "daedric warhammer_ttgd")
 then v = "Veloth's Judgement" return v 
elseif (v == "viper arrow")
 then v = "Viper Arrow" return v 
elseif (v == "viper_bolt")
 then v = "Viperbolt" return v 
elseif (v == "viperstar")
 then v = "Viperstar" return v 
elseif (v == "dwarven_hammer_volendrung")
 then v = "Volendrung" return v 
elseif (v == "war_axe_airan_ammu")
 then v = "War Axe of Airan Ammu" return v 
elseif (v == "war axe of wounds")
 then v = "War Axe of Wounds" return v 
elseif (v == "warhammer of wounds")
 then v = "Warhammer of Wounds" return v 
elseif (v == "water spear")
 then v = "Water Spear" return v 
elseif (v == "widowmaker_unique")
 then v = "Widowmaker" return v 
elseif (v == "wild flameblade")
 then v = "Wild Flameblade" return v 
elseif (v == "wild flamesword")
 then v = "Wild Flamesword" return v 
elseif (v == "wild shardblade")
 then v = "Wild Shardblade" return v 
elseif (v == "wild shardsword")
 then v = "Wild Shardsword" return v 
elseif (v == "wild sparkblade")
 then v = "Wild Sparkblade" return v 
elseif (v == "wild sparksword")
 then v = "Wild Sparksword" return v 
elseif (v == "wild viperblade")
 then v = "Wild Viperblade" return v 
elseif (v == "wild vipersword")
 then v = "Wild Vipersword" return v 
elseif (v == "Wind of Ahaz")
 then v = "Wind of Ahaz" return v 
elseif (v == "axe_queen_of_bats_unique")
 then v = "Wings of the Queen of Bats" return v 
elseif (v == "ebony wizard's staff")
 then v = "Wizard's Staff" return v 
elseif (v == "wooden staff")
 then v = "Wooden Staff" return v 
elseif (v == "wooden staff of chastening")
 then v = "Wooden Staff of Chastening" return v 
elseif (v == "wooden staff of divine")
 then v = "Wooden Staff of Judgement" return v 
elseif (v == "wooden staff of peace")
 then v = "Wooden Staff of Peace" return v 
elseif (v == "wooden staff of shaming")
 then v = "Wooden Staff of Shaming" return v 
elseif (v == "wooden staff of war")
 then v = "Wooden Staff of War" return v 
end
end

customCommandHooks.registerCommand("ah", Auction.Option)
customCommandHooks.registerCommand("perchase", Auction.Buy)
customCommandHooks.registerCommand("selling", Auction.Sell)

return Auction
