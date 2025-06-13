Config = {}

Config.Locale = {
    PromptText = "Business",

    Tip_AlreadyOwnBusiness = "You already own another business.",
    Tip_AlreadyHasOwner = "This business already has an owner.",
    Tip_InvalidID = "Invalid ID.",
    Tip_Cancelled = "Operation cancelled.",
    Tip_NotEnoughMoney = "You don't have enough money.",
    Tip_BoughtBusiness = "You successfully bought the business.",
    Tip_NotOwner = "You don't own this business.",
    Tip_SoldBusiness = "You sold the business for",
    Tip_InvalidDestination = "Invalid destination.",
    Tip_TargetOwnsBusiness = "The destination player already owns a business.",
    Tip_TransferSuccess = "You have successfully transferred the business.",
    Tip_YouHaveNewBusiness = "You have received new business",

    Menu = {
        Title = "Business Menu",
        Subtext = "Select an action",
        SellLabel = "Sell Business",
        SellDesc = "Sell the business for 60% of its value",
        TransferLabel = "Transfer Business",
        TransferDesc = "Transfer the business to another player",
        BuyLabel = "Buy Business",
        BuyDescPrefix = "Buy the business for $",
    },

    Input = {
        Header = "Transfer Business",
        Placeholder = "Player ID",
        Title = "Numbers only",
        Button = "Confirm",
    }
}


Config.Businesses = {
    [1] = {
        coords = vector3(-5490.74, -2943.2, -0.47),  -- Coordinates of the purchase prompt
        price = 400,                                 -- business sale price
        job = "generaltw",                           -- job assigned to the player when buying the business
        grade = 3,                                   -- grade assigned to the player when buying the business
        name = "General Store",                      -- business name
        owner = nil                                  -- do not change
    },
    -- add more companies continuing with the [2]
}

