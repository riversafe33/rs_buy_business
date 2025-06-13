local VorpCore = exports.vorp_core:GetCore()
local businessOwners = {}

Citizen.CreateThread(function()
    exports.ghmattimysql:execute('SELECT * FROM business_owners', {}, function(result)
        for _, row in ipairs(result) do
            local businessId = tonumber(row.business_id)
            if businessId then
                businessOwners[businessId] = row.owner_id
            end
        end

        for _, playerId in ipairs(GetPlayers()) do
            local user = VorpCore.getUser(tonumber(playerId))
            local character = user.getUsedCharacter
            TriggerClientEvent("rs_buy_business:setOwners", tonumber(playerId), businessOwners, character.identifier)
        end
    end)
end)

RegisterServerEvent("rs_buy_business:getPlayerIdentifier")
AddEventHandler("rs_buy_business:getPlayerIdentifier", function()
    local playerId = source
    local identifier = GetPlayerIdentifiers(playerId)[1]
    
    TriggerClientEvent("rs_buy_business:setPlayerIdentifier", playerId, identifier)
end)

AddEventHandler("playerConnecting", function(_, _, deferrals)
    local src = source
    TriggerClientEvent("rs_buy_business:setOwners", src, businessOwners)
end)

RegisterServerEvent("rs_buy_business:requestOwnerData")
AddEventHandler("rs_buy_business:requestOwnerData", function()
    local src = source
    local user = VorpCore.getUser(src)
    local character = user.getUsedCharacter
    TriggerClientEvent("rs_buy_business:setOwners", src, businessOwners, character.identifier)
end)

RegisterServerEvent("rs_buy_business:handleAction")
AddEventHandler("rs_buy_business:handleAction", function(index, action, targetId)
    local src = source
    local User = VorpCore.getUser(src)
    local character = User.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local business = Config.Businesses[index]
    if not business then return end

    if action == "buy" then
        
        for _, owner in pairs(businessOwners) do
            if owner == identifier then
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

        exports.ghmattimysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE identifier = ?", {business.job, business.grade, identifier})
        exports.ghmattimysql:execute("INSERT INTO business_owners (business_id, owner_id, charid) VALUES (?, ?, ?)", {index, identifier, charid})

        businessOwners[index] = identifier
        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners, identifier)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_BoughtBusiness, 4000)

    elseif action == "sell" then

        if businessOwners[index] ~= identifier then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_NotOwner, 3000)
            return
        end

        local refund = math.floor(business.price * 0.6)
        character.addCurrency(0, refund)
        character.setJob("unemployed", 0)
        character.setJobGrade(0)

        exports.ghmattimysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE identifier = ?", {"unemployed", 0, identifier})
        exports.ghmattimysql:execute("DELETE FROM business_owners WHERE business_id = ? AND owner_id = ?", {index, identifier})

        businessOwners[index] = nil
        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners, identifier)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_SoldBusiness .. " " .. refund .. " $", 4000)

    elseif action == "transfer" and targetId then

        if businessOwners[index] ~= identifier then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_NotOwner, 3000)
            return
        end

        local TargetUser = VorpCore.getUser(tonumber(targetId))
        if not TargetUser then
            TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_InvalidDestination, 3000)
            return
        end

        local TargetCharacter = TargetUser.getUsedCharacter
        local targetIdentifier = TargetCharacter.identifier
        local targetCharid = TargetCharacter.charIdentifier

        for _, owner in pairs(businessOwners) do
            if owner == targetIdentifier then
                TriggerClientEvent("vorp:TipRight", src, Config.Locale.Tip_TargetOwnsBusiness, 3000)
                return
            end
        end

        businessOwners[index] = targetIdentifier
        TargetCharacter.setJob(business.job)
        TargetCharacter.setJobGrade(tonumber(business.grade))

        exports.ghmattimysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE identifier = ?", {business.job, business.grade, targetIdentifier})
        exports.ghmattimysql:execute("UPDATE characters SET job = ?, jobgrade = ? WHERE identifier = ?", {"unemployed", 0, identifier})
        exports.ghmattimysql:execute("DELETE FROM business_owners WHERE business_id = ? AND owner_id = ?", {index, identifier})
        exports.ghmattimysql:execute("INSERT INTO business_owners (business_id, owner_id, charid) VALUES (?, ?, ?)", {index, targetIdentifier, targetCharid})

        character.setJob("unemployed", 0)
        character.setJobGrade(0)

        TriggerClientEvent("rs_buy_business:setOwners", -1, businessOwners)
        TriggerClientEvent("vorp:TipBottom", src, Config.Locale.Tip_TransferSuccess, 4000)
    end
end)
