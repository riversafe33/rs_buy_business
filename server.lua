local VorpCore = exports.vorp_core:GetCore()
local businessOwners = {}

Citizen.CreateThread(function()
    exports.oxmysql:execute('SELECT * FROM business_owners', {}, function(result)
        for _, row in ipairs(result) do
            local businessId = tonumber(row.business_id)
            if businessId then
                businessOwners[businessId] = tonumber(row.owner_id)
            end
        end

        for _, playerId in ipairs(GetPlayers()) do
            local user = VorpCore.getUser(tonumber(playerId))
            local character = user.getUsedCharacter
            TriggerClientEvent("rs_buy_business:setOwners", tonumber(playerId), businessOwners, character.charIdentifier)
        end
    end)
end)

RegisterServerEvent("rs_buy_business:getPlayerIdentifier")
AddEventHandler("rs_buy_business:getPlayerIdentifier", function()
    local playerId = source
    local user = VorpCore.getUser(playerId)
    local character = user.getUsedCharacter
    local charIdentifier = character.charIdentifier
    TriggerClientEvent("rs_buy_business:setPlayerIdentifier", playerId, charIdentifier)
end)

AddEventHandler("playerConnecting", function(_, _, deferrals)
    local src = source
    TriggerClientEvent("rs_buy_business:setOwners", src, businessOwners)
end)

RegisterServerEvent("rs_buy_business:requestOwnerData")
AddEventHandler("rs_buy_business:requestOwnerData", function()
    local src = source
    local user = VorpCore.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if character and character.charIdentifier then
        TriggerClientEvent("rs_buy_business:setOwners", src, businessOwners, character.charIdentifier)
    end
end)

RegisterServerEvent("rs_buy_business:handleAction")
AddEventHandler("rs_buy_business:handleAction", function(index, action, targetId)
    local src = source
    local User = VorpCore.getUser(src)
    local character = User.getUsedCharacter
    local charIdentifier = character.charIdentifier
    local business = Config.Businesses[index]
    if not business then return end

    if action == "buy" then
        for _, owner in pairs(businessOwners) do
            if owner == charIdentifier then
                TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_AlreadyOwnBusiness, 3000)
                return
            end
        end

        if businessOwners[index] then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_AlreadyHasOwner, 3000)
            return
        end

        if character.money < business.price then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_NotEnoughMoney, 3000)
            return
        end

        character.removeCurrency(0, business.price)
        character.setJob(business.job)
        character.setJobGrade(tonumber(business.grade))

        exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE charidentifier = ?", {
            business.job, business.grade, charIdentifier
        })

        exports.oxmysql:execute("INSERT INTO business_owners (business_id, owner_id) VALUES (?, ?)", {
            index, charIdentifier
        })

        businessOwners[index] = charIdentifier
        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners, charIdentifier)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_BoughtBusiness, 4000)

    elseif action == "sell" then
        if businessOwners[index] ~= charIdentifier then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_NotOwner, 3000)
            return
        end

        local refund = math.floor(business.price * 0.6)
        character.addCurrency(0, refund)
        character.setJob("unemployed", 0)
        character.setJobGrade(0)

        exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE charidentifier = ?", {
            "unemployed", 0, charIdentifier
        })

        exports.oxmysql:execute("DELETE FROM business_owners WHERE business_id = ? AND owner_id = ?", {
            index, charIdentifier
        })

        businessOwners[index] = nil
        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners, charIdentifier)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_SoldBusiness .. " " .. refund .. " $", 4000)

    elseif action == "transfer" and targetId then
        if businessOwners[index] ~= charIdentifier then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_NotOwner, 3000)
            return
        end

        local TargetUser = VorpCore.getUser(tonumber(targetId))
        if not TargetUser then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_InvalidDestination, 3000)
            return
        end

        local TargetCharacter = TargetUser.getUsedCharacter
        local targetCharIdentifier = TargetCharacter.charIdentifier

        for _, owner in pairs(businessOwners) do
            if owner == targetCharIdentifier then
                TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_TargetOwnsBusiness, 3000)
                return
            end
        end

        exports.oxmysql:execute("UPDATE business_owners SET owner_id = ? WHERE business_id = ?", {
            targetCharIdentifier, index
        })

        TargetCharacter.setJob(business.job)
        TargetCharacter.setJobGrade(tonumber(business.grade))
        exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE charidentifier = ?", {
            business.job, business.grade, targetCharIdentifier
        })

        character.setJob("unemployed", 0)
        character.setJobGrade(0)
        exports.oxmysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE charidentifier = ?", {
            "unemployed", 0, charIdentifier
        })

        businessOwners[index] = targetCharIdentifier
        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners, charIdentifier)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_TransferSuccess, 4000)
        TriggerClientEvent("vorp:TipBottom", tonumber(targetId), Config.Locale.Tip_YouHaveNewBusiness, 4000)
    end
end)
