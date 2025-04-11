local DisastersList = {
	DisasterType.TORNADO,
	DisasterType.TOXIC_RAIN,
	DisasterType.VOID_RISE,
	DisasterType.METEORS,
}

local ItemsList = {
	['Tools'] = {
		['Shear'] = ItemType.SHEARS,

		['Pickaxes'] = {
			ItemType.WOOD_PICKAXE,
			ItemType.STONE_PICKAXE,
			ItemType.IRON_PICKAXE,
			ItemType.DIAMOND_PICKAXE,
		},

		['Axes'] = {
			ItemType.WOOD_AXE,
			ItemType.STONE_AXE,
			ItemType.IRON_AXE,
			ItemType.DIAMOND_AXE,
		},

		['Swords'] = {
			ItemType.WOODEN_SWORD,
			ItemType.STONE_SWORD,
			ItemType.IRON_SWORD,
			ItemType.DIAMOND_SWORD,
			ItemType.EMERALD_SWORD
		}
	},

	['Blocks'] = {
		['WoodBlock'] = ItemType.WOOD_PLANK_OAK,
		['WoolBlock'] = 'wool_',
		['StoneBlock'] = ItemType.STONE_BRICK,
	},
}

local BlocksCurrentAmounts = {
    ['Wood'] = {};
    ['Stone'] = {};
    ['Wool'] = {};
}

local ChatMessages = {
    ['SupportsMessages'] = {
        'Want more game modes? Go to https://github.com/noob1183 and get more there!!';
        'Want to check for game mode updates? Go to https://github.com/noob1183/Bedwars_Survive_Disaster then find "LATEST UPDATE(S)".';
        'Follow me on Roblox in my profile to help me get verified badge (@Tranquananh2811)!!';
    };
 
    ['TipsMessage'] = {
        'The server always announce a message 10 seconds earlier before the disaster starting!!';
        'The toxic rain does not work on the stone block??';
        'If one of your teammates died during the disaster. They will not get their gear level up sadly!!';
    };
}
 
local ChatMessagesNames = {
    'SupportsMessages';
    'TipsMessage'
}

local ToolsLevelList = {
	['PickaxeLevel'] = {};
	['AxeLevel'] = {};
}

local DeadList = {}

local IsRunningMatchCountdown = false
local RunOnceDebounce = false
local SetLevelDebounce = false

local Wave = 0
local BlockStarterAmounts = 100
local AppleStarterAmounts = 1
local CountdownTime = 120
local DisasterTime = 180
local CountdownTimeInMinute = CountdownTime / 60
local CurrentTime = CountdownTime

local PickaxeLevel = nil
local AxeLevel = nil
local BlockClampedAmount = nil

local ChatSupportsTag = '[SUPPORTS]: '
local ChatTipsTag = '[TIPS]: '
local OutputMark = '[DisasterGameScript]: '

local function tableFind(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function tableInsert(tbl, value, position)
    position = position or (#tbl + 1)
    for i = #tbl, position, -1 do
        tbl[i + 1] = tbl[i]
    end
    tbl[position] = value
end

Events.PlayerAdded(function (event)
    ChatService.sendMessage(event.player.name .. " joined the game!")
end)

Events.PlayerRemoving(function (event)
    ChatService.sendMessage(event.player.name .. " left the game.")
end)

Events.BlockPlace(function(placeEvent)
    local player = placeEvent.player
    local blockType = placeEvent.blockType

    if not player then
        return
    end

    local playerName = player.name

    BlocksCurrentAmounts['Wood'][playerName] = BlocksCurrentAmounts['Wood'][playerName] or 0
    BlocksCurrentAmounts['Stone'][playerName] = BlocksCurrentAmounts['Stone'][playerName] or 0
    BlocksCurrentAmounts['Wool'][playerName] = BlocksCurrentAmounts['Wool'][playerName] or 0

    if blockType == ItemsList['Blocks']['WoolBlock'] then
        BlocksCurrentAmounts['Wool'][playerName] = BlocksCurrentAmounts['Wool'][playerName] + 1
    elseif blockType == ItemsList['Blocks']['WoodBlock'] then
        BlocksCurrentAmounts['Wood'][playerName] = BlocksCurrentAmounts['Wood'][playerName] + 1
    elseif blockType == ItemsList['Blocks']['StoneBlock'] then
        BlocksCurrentAmounts['Stone'][playerName] = BlocksCurrentAmounts['Stone'][playerName] + 1
    end

    local WoolPlaceAmounts = BlocksCurrentAmounts['Wool'][playerName]
    local WoodPlaceAmounts = BlocksCurrentAmounts['Wood'][playerName]
    local StonePlaceAmounts = BlocksCurrentAmounts['Stone'][playerName]

    -- print(OutputMark..'WoodPlaceAmounts: '..tostring(WoodPlaceAmounts)..', '..'WoolPlaceAmounts: '..tostring(WoolPlaceAmounts)..', '..'StonePlaceAmounts: '..tostring(StonePlaceAmounts))
end)

Events.EntityDeath(function(deathEvent)
	local player = deathEvent.entity:getPlayer()

	if player ~= nil then --// check if the player is not nil and in match then...
		local PlayerName = player.name
		if not tableFind(DeadList, PlayerName) and IsRunningMatchCountdown == false then
			tableInsert(DeadList, PlayerName)
		end
	end
end)

Events.EntitySpawn(function(spawnEvent)
    task.wait()
	local player = spawnEvent.entity:getPlayer()

	if player ~= nil then
        print(OutputMark..'Player is not nil!!')
		local PlayerName = player.name
		local PlayerInventory = InventoryService.getInventory(player)

		if IsRunningMatchCountdown == true then --// if player spawn while match is not started then...

            if PlayerInventory == nil then ---// if player inventory is nil then
                print(OutputMark..'Player inventory is nil!!')
                return
            end
            print(OutputMark..'PlayerInventory is not nil and IsRunningMatchCountdown is true: '..tostring(PlayerInventory)..', '..tostring(IsRunningMatchCountdown))

			local WoolPlaceAmounts = BlocksCurrentAmounts['Wool'][player.name]
			local WoodPlaceAmounts = BlocksCurrentAmounts['Wood'][player.name]
			local StonePlaceAmounts = BlocksCurrentAmounts['Stone'][player.name]

			local RemainingWoolAmounts = BlockClampedAmount - WoolPlaceAmounts
			local RemainingWoodAmounts = BlockClampedAmount - WoodPlaceAmounts
			local RemainingStoneAmounts = BlockClampedAmount - StonePlaceAmounts

			InventoryService.clearInventory(player)

			print(OutputMark..'Successfully cleared player inventory!!')

			if tonumber(PickaxeLevel) ~= nil then
				InventoryService.giveItem(player, ItemsList['Tools']['Pickaxes'][PickaxeLevel], 1, true)
			end
	
			if tonumber(AxeLevel) ~= nil then
				InventoryService.giveItem(player, ItemsList['Tools']['Axes'][AxeLevel], 1, true)
			end

			InventoryService.giveItem(player, ItemsList['Tools']['Shear'], 1, true)

			if tonumber(WoolPlaceAmounts) ~= nil and tonumber(WoodPlaceAmounts) ~= nil and tonumber(StonePlaceAmounts) ~= nil then
				print(OutputMark..'Successfully verified WoolPlaceAmounts, WoodPlaceAmounts, and StonePlaceAmounts as a number. Process to give items!!')
				print(OutputMark..'WoodPlaceAmounts: '..tostring(RemainingWoodAmounts)..', '..'WoolPlaceAmounts: '..tostring(RemainingWoolAmounts)..', '..'StonePlaceAmounts: '..tostring(RemainingStoneAmounts))
				
                if RemainingStoneAmounts > 0 then
                    InventoryService.giveItem(player, ItemsList['Blocks']['StoneBlock'], RemainingStoneAmounts, true)
                end

                if RemainingWoodAmounts > 0 then
                    InventoryService.giveItem(player, ItemsList['Blocks']['WoodBlock'], RemainingWoodAmounts, true)
                end

                if RemainingWoolAmounts > 0 then
                    InventoryService.giveItem(player, ItemsList['Blocks']['WoolBlock']..string.lower(TeamService.getTeam(player).name), RemainingWoolAmounts, true)
                end
				
			else
				print(OutputMark..'WoolPlaceAmounts, WoodPlaceAmounts, or StonePlaceAmounts is not a number: '..tostring(WoodPlaceAmounts)..', '..tostring(WoolPlaceAmounts)..', '..tostring(StonePlaceAmounts))
			end

		elseif IsRunningMatchCountdown == false then --// if player spawn while match is started then...
			print(tableFind(DeadList, PlayerName))
			if tableFind(DeadList, PlayerName) then
                print(OutputMark..'Founded player in deadlist while match is in-progress, process to take action!!')
				InventoryService.clearInventory(player)
				player:getEntity():setPosition(Vector3.new(482.99, 488.85, 470.99))
			end
		end
	end
end)

local function RunMatchSetup()
    print(OutputMark..'Finished clearing current items in players inventory to add new items.')

    for _, player in pairs(PlayerService.getPlayers()) do
        InventoryService.clearInventory(player)
        
        BlockClampedAmount = math.clamp(BlockStarterAmounts, 0, 500)
        PickaxeLevel = ToolsLevelList['PickaxeLevel'][player.name] or 1
        AxeLevel = ToolsLevelList['AxeLevel'][player.name] or 1

        if SetLevelDebounce == false then
            PickaxeLevel = 1
            AxeLevel = 1
            print(OutputMark..'Finished setting up level: '..PickaxeLevel..', '..AxeLevel)
            SetLevelDebounce = true
        end

		ToolsLevelList['PickaxeLevel'][player.name] = PickaxeLevel
        ToolsLevelList['AxeLevel'][player.name] = AxeLevel

		if PickaxeLevel ~= nil and tonumber(PickaxeLevel) ~= nil and PickaxeLevel < #ItemsList['Tools']['Pickaxes'] then
			if not tableFind(DeadList, player.name) and Wave ~= 1 then --- // Check if the player is not in deadlist and the wave is changed.
				PickaxeLevel = PickaxeLevel + 1
			end
		end

		if AxeLevel ~= nil and tonumber(AxeLevel) ~= nil and AxeLevel < #ItemsList['Tools']['Axes'] then
			if not tableFind(DeadList, player.name) and Wave ~= 1 then --- // Check if the player is not in deadlist and the wave is changed.
				AxeLevel = AxeLevel + 1
			end
		end

		DeadList = {}

        if tonumber(PickaxeLevel) ~= nil then
            InventoryService.giveItem(player, ItemsList['Tools']['Pickaxes'][PickaxeLevel], 1, true)
        else
            print(OutputMark..'Failed to give pickaxe because PickaxeLevel is nil or not a number...')
        end

        if tonumber(AxeLevel) ~= nil then
            InventoryService.giveItem(player, ItemsList['Tools']['Axes'][AxeLevel], 1, true)
        else
            print(OutputMark..'Failed to give axe because AxeLevel is nil or not a number...')
        end

        InventoryService.giveItem(player, ItemsList['Tools']['Shear'], 1, true)

        print(OutputMark..'Finished giving players tools to build!!')

        if Wave % 10 == 0 then
            BlockStarterAmounts = BlockStarterAmounts + 1
        end

        print(OutputMark..tostring(BlockClampedAmount))

        InventoryService.giveItem(player, ItemsList['Blocks']['StoneBlock'], BlockClampedAmount, true)
        InventoryService.giveItem(player, ItemsList['Blocks']['WoodBlock'], BlockClampedAmount, true)
        InventoryService.giveItem(player, ItemsList['Blocks']['WoolBlock']..string.lower(TeamService.getTeam(player).name), BlockClampedAmount, true)

        print(OutputMark..'Finished giving players blocks to build!!')
        BlocksCurrentAmounts['Wood'][player.name] = 0
        BlocksCurrentAmounts['Stone'][player.name] = 0
        BlocksCurrentAmounts['Wool'][player.name] = 0
    end

   if CountdownTime > 60 then
	  AnnouncementService.sendAnnouncement('All players only have '..CountdownTimeInMinute..' minutes to build a shelter to prepare for the next disaster wave '..tostring(Wave), Color3.fromRGB(255, 255, 0))
   elseif CountdownTime < 60 then
	  AnnouncementService.sendAnnouncement('All players only have '..CountdownTime..' seconds to build a shelter to prepare for the next disaster wave '..tostring(Wave), Color3.fromRGB(255, 255, 0))
   end
end


local function RunDisaster(DisasterToRun)
	for _, player in pairs(PlayerService.getPlayers()) do
		InventoryService.clearInventory(player)
	end
	print(OutputMark..'Finished clearing all items in players inventory to start disaster!!')

	for _, player in pairs(PlayerService.getPlayers()) do
		if Wave % 5 == 0 then
			AppleStarterAmounts = AppleStarterAmounts + 1
		end

		InventoryService.giveItem(player, ItemType.APPLE, math.clamp(AppleStarterAmounts, 1, 10))
	end
	print(OutputMark..'Finished giving apple to players!!')
	
	AnnouncementService.sendAnnouncement(tostring(DisasterToRun)..' disaster is coming, take cover!!', Color3.fromRGB(255, 0, 0))
	DisasterService.startDisaster(DisasterToRun, DisasterTime)

	task.delay(DisasterTime, function()
		Wave = Wave + 1

		for _, player in pairs(PlayerService.getPlayers()) do
			CombatService.damage(player, math.huge)
		end

		RunMatchSetup()
		IsRunningMatchCountdown = true
	end)
end

Events.MatchStart(function(matchEvent)
	task.spawn(function()
		while task.wait(20) do
			print(OutputMark..'Sending message to chat...')
			local ChosenCategory = ChatMessagesNames[math.random(1, #ChatMessagesNames)]
			local ChosenMessage = ChatMessages[ChosenCategory][math.random(1, #ChatMessages[ChosenCategory])]
	
			if ChosenCategory == 'SupportsMessages' then
				ChatService.sendMessage(ChatSupportsTag..ChosenMessage, Color3.fromRGB(255, 0, 0))
			elseif ChosenCategory == 'TipsMessage' then
				ChatService.sendMessage(ChatTipsTag..ChosenMessage, Color3.fromRGB(255, 255, 0))
			end
		end
	end)
	Wave = 1
	IsRunningMatchCountdown = true
	print(OutputMark..'Match has started, running countdown is: '..tostring(IsRunningMatchCountdown))
end)

while true do
    if IsRunningMatchCountdown == true then
        if RunOnceDebounce == false then
            RunMatchSetup()
            RunOnceDebounce = true
        end
    
        task.wait(1)
    
        CurrentTime = CurrentTime - 1
    
        if CurrentTime == 10 then
            AnnouncementService.sendAnnouncement('All players only have 10 seconds left!!', Color3.fromRGB(255, 0, 0))
        end
    
        if CurrentTime <= 0 then
            IsRunningMatchCountdown = false
            CurrentTime = CountdownTime
            RunDisaster(DisastersList[math.random(1, #DisastersList)])
        end
    else
        task.wait()
    end
end
