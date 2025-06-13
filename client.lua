local VorpCore = exports.vorp_core:GetCore()
local Menu = exports.vorp_menu:GetMenuData()
local prompt = nil
local businessOwners = {}
local myIdentifier = nil
local currentBusinessIndex = nil

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent("rs_buy_business:getPlayerIdentifier")
end)

RegisterNetEvent("rs_buy_business:setPlayerIdentifier")
AddEventHandler("rs_buy_business:setPlayerIdentifier", function(identifier)
    myIdentifier = identifier
    TriggerServerEvent("rs_buy_business:requestOwnerData")
end)

RegisterNetEvent("rs_buy_business:setOwners")
AddEventHandler("rs_buy_business:setOwners", function(businessData)
    businessOwners = businessData

    for businessId, ownerId in pairs(businessData) do
    end
end)

local function createPrompt()
    if not prompt then
        prompt = Uiprompt:new(`INPUT_DYNAMIC_SCENARIO`, "Business")
        prompt:setEnabled(false)
        prompt:setVisible(false)

        prompt:setOnControlJustPressed(function()

            if not currentBusinessIndex then
                return
            end

            local businessIndex = currentBusinessIndex
            local owner = businessOwners[businessIndex]
            local alreadyOwns = false

            for businessId, ownerId in pairs(businessOwners) do
                if ownerId == myIdentifier and businessId ~= businessIndex then
                    alreadyOwns = true
                    break
                end
            end

            if owner == nil then
                if alreadyOwns then
                    TriggerEvent("vorp:TipRight", "You already own another business.", 3000)
                else
                    openBusinessMenu(businessIndex)
                end
            elseif owner == myIdentifier then
                openBusinessMenu(businessIndex)
            else
                TriggerEvent("vorp:TipRight", "This business already has an owner.", 3000)
            end
        end)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        if not businessOwners or not myIdentifier then goto continue end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local shouldShowPrompt = false
        local closestBusinessIndex = nil
        local minDist = math.huge

        for i, business in pairs(Config.Businesses) do
            local dist = #(playerCoords - business.coords)
            local owner = businessOwners[i]

            local alreadyOwns = false
            for businessName, ownerId in pairs(businessOwners) do
                if ownerId == myIdentifier and businessName ~= i then
                    alreadyOwns = true
                    break
                end
            end

            local shouldShow = dist < 2.0 and ((owner == nil and not alreadyOwns) or (owner == myIdentifier))

            if shouldShow and dist < minDist then
                minDist = dist
                closestBusinessIndex = i
                shouldShowPrompt = true
            end
        end

        if shouldShowPrompt then
            if not prompt then
                createPrompt()
            end
            currentBusinessIndex = closestBusinessIndex
            prompt:setEnabled(true)
            prompt:setVisible(true)

        else
            if prompt then
                prompt:setEnabled(false)
                prompt:setVisible(false)
                currentBusinessIndex = nil
            end
        end

        ::continue::
    end
end)

UipromptManager:startEventThread()

function openBusinessMenu(index)
    local elements = {}
    local business = Config.Businesses[index]

    if businessOwners[index] == myIdentifier then
        table.insert(elements, {label = "Sell Business", value = "sell", desc = "Sell the business for 60% of its value"})
        table.insert(elements, {label = "Transfer Business", value = "transfer", desc = "Transfer the business to another player"})
    else
        table.insert(elements, {label = "Buy Business", value = "buy", desc = "Buy the business for $" .. business.price})
    end

    Menu.CloseAll()
    Menu.Open("default", GetCurrentResourceName(), "business_menu", {
        title = "Business Menu",
        subtext = "Select an action",
        align = "top-right",
        elements = elements,
        itemHeight = "4vh"
    }, function(data, menu)
        local action = data.current.value

        if action == "transfer" then
            menu.close()
            OpenSellInput(index)
        else
            TriggerServerEvent("rs_buy_business:handleAction", index, action)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenSellInput(index)
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = "Confirm",
        placeholder = "Player ID",
        style = "block",
        attributes = {
            inputHeader = "Transfer Business",
            type = "text",
            pattern = "[0-9]+",
            title = "Numbers only",
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    local result = exports.vorp_inputs:advancedInput(myInput)

    if result and result ~= "" then
        result = tonumber(result)
        if result then
            TriggerServerEvent("rs_buy_business:handleAction", index, "transfer", result)
        else
            TriggerEvent("vorp:TipRight", "Invalid ID.", 3000)
        end
    else
        TriggerEvent("vorp:TipRight", "Operation cancelled.", 3000)
    end
end
