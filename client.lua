local VorpCore = exports.vorp_core:GetCore()
local Menu = exports.vorp_menu:GetMenuData()
local prompt = nil
local businessOwners = {}
local myCharIdentifier = nil
local currentBusinessIndex = nil
local tempOwners = nil

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent("rs_buy_business:getPlayerIdentifier")
end)

RegisterNetEvent("rs_buy_business:setPlayerIdentifier")
AddEventHandler("rs_buy_business:setPlayerIdentifier", function(charIdentifier)
    if not charIdentifier or charIdentifier == "" then
        Citizen.SetTimeout(1000, function()
            TriggerServerEvent("rs_buy_business:getPlayerIdentifier")
        end)
        return
    end

    myCharIdentifier = charIdentifier

    TriggerServerEvent("rs_buy_business:requestOwnerData")

    if tempOwners then
        businessOwners = tempOwners
        tempOwners = nil
    end
end)

RegisterNetEvent("rs_buy_business:setOwners")
AddEventHandler("rs_buy_business:setOwners", function(owners)

    if not owners or type(owners) ~= "table" then
        return
    end

    if myCharIdentifier and myCharIdentifier ~= "" then
        businessOwners = owners
        tempOwners = nil
    else
        tempOwners = owners
    end
end)

local function createPrompt()
    if not prompt then
        prompt = Uiprompt:new(`INPUT_DYNAMIC_SCENARIO`, Config.Locale.PromptText)
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
                if ownerId == myCharIdentifier and businessId ~= businessIndex then
                    alreadyOwns = true
                    break
                end
            end

            if owner == nil then
                if alreadyOwns then
                    TriggerEvent("vorp:TipRight", Config.Locale.Tip_AlreadyOwnBusiness, 3000)
                else
                    openBusinessMenu(businessIndex)
                end
            elseif owner == myCharIdentifier then
                openBusinessMenu(businessIndex)
            else
                TriggerEvent("vorp:TipRight", Config.Locale.Tip_AlreadyHasOwner, 3000)
            end
        end)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(500)
        if not businessOwners or not myCharIdentifier then
            goto continue
        end

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
                if ownerId == myCharIdentifier and businessName ~= i then
                    alreadyOwns = true
                    break
                end
            end

            local shouldShow = dist < 2.0 and ((owner == nil and not alreadyOwns) or (owner == myCharIdentifier))

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

    if businessOwners[index] == myCharIdentifier then
        table.insert(elements, {label = Config.Locale.Menu.SellLabel, value = "sell", desc = Config.Locale.Menu.SellDesc})
        table.insert(elements, {label = Config.Locale.Menu.TransferLabel, value = "transfer", desc = Config.Locale.Menu.TransferDesc})
    else
        table.insert(elements, {label = Config.Locale.Menu.BuyLabel, value = "buy", desc = Config.Locale.Menu.BuyDescPrefix .. business.price})
    end

    Menu.CloseAll()
    Menu.Open("default", GetCurrentResourceName(), "business_menu", {
        title = Config.Locale.Menu.Title,
        subtext = Config.Locale.Menu.Subtext,
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
        button = Config.Locale.Input.Button,
        placeholder = Config.Locale.Input.Placeholder,
        style = "block",
        attributes = {
            inputHeader = Config.Locale.Input.Header,
            type = "text",
            pattern = "[0-9]+",
            title = Config.Locale.Input.Title,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    local result = exports.vorp_inputs:advancedInput(myInput)

    if result and result ~= "" then
        result = tonumber(result)
        if result then
            TriggerServerEvent("rs_buy_business:handleAction", index, "transfer", result)
        else
            TriggerEvent("vorp:TipRight", Config.Locale.Tip_InvalidID, 3000)
        end
    else
        TriggerEvent("vorp:TipRight", Config.Locale.Tip_Cancelled, 3000)
    end
end
