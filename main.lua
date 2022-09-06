-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
--  Created by Samedi on 27/08/2022.
--  All code (c) 2022, The Samedi Corporation.
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

-- If setting up manually, add the following handler to any connected screens:
    -- local failure = modula:call("onScreenReply", output)
    -- if failure then 
    --     error(failure) 
    -- end

local Module = { }
local CountTable = {}

function Module:register(parameters)
    modula:registerForEvents(self, "onStart", "onFastUpdate")
    modula:withElements("Industry1", function(element)
        printf(element)
    end)
end

-- ---------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------

function Module:onStart()
    debugf("Trade Helper started.")

    self.inventory = {}
    self.index = {}
    self.recipes = {}
    self.ores = CountTable.new()
    self.running = true

    -- example ids
    local ids = {
        polycarb = 2014531313,
        spaceCore = 5904195,
        basicConnector = 2872711779
    }

    local id = ids['spaceCore']

    self.input = { { id = id, quantity = 50.0 } }

    printf("\nRequest")
    for i,item in ipairs(self.input) do
        local info = self:itemInfo(item.id)
        printf("- %s x %s", item.quantity, self:itemDescription(info))
    end
end

function Module:onFastUpdate()
    if self.running then
        local input = self.input
        self.input = {}
        for i,item in ipairs(input) do
            self:request(item.id, item.quantity)
        end

        self.running = #self.input > 0
        if not self.running then
            printf("\nOperations")
            for id, entry in pairs(self.recipes) do
                if entry.count > 0 then
                    local item = self:itemInfo(id)
                    local total = entry.count * entry.quantityPerBatch
                    printf("- %s x %s --> %s", entry.count, self:itemDescription(item), total)
                end
            end
    
            printf("\nSurplus")
            for id, count in pairs(self.inventory) do
                if count > 0 then
                    local item = self:itemInfo(id)
                    printf("- %s x %s", count, self:itemDescription(item))
                end
            end

            printf("\nOres")
            for id, count in pairs(self.ores) do
                if count > 0 then
                    local item = self:itemInfo(id)
                    printf("- %s x %s", count, self:itemDescription(item))
                end
            end

            printf("Done")
        end
    end
end

-- ---------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------

function Module:request(id, amount)
    local item = self:itemInfo(id)
    -- debugf("Processing %s", item.name)
    local inputs = self.input
    local inventory = self.inventory
    local got = inventory[id] or 0.0
    if got >= amount then
        inventory[id] = got - amount
    else
        inventory[id] = 0.0
        amount = amount - got
        local recipe = self:bestRecipe(id)
        if recipe then
            self:build(item, recipe, amount)
        else
            self.ores:add(id, amount)
        end
    end
end

function Module:itemDescription(item)
    return string.format("%s (%s)", item.locDisplayName, item.id)
end

function Module:bestRecipe(id)
    local time
    local best
    local recipes = system.getRecipes(id)
    for i,recipe in ipairs(recipes) do
        if (not time) or time > recipe.time then
            best = recipe
            time = recipe.time
        end
    end
    return best
end

function Module:addToInventory(id, amount)
    local current = self.inventory[id] or 0.0
    local new = current + amount
    self.inventory[id] = new
end

function Module:addToTable(table, key, amount)
    local current = table[key] or 0.0
    local new = current + amount
    table[key] = new
end

function Module:build(item, recipe, amount)
    local id = item.id

    -- how much of the thing we need does each recipe make?
    local quantityPerBatch = 0.0
    for i,product in ipairs(recipe.products) do
        if product.id == item.id then
            quantityPerBatch = product.quantity
            break
        end
    end

    -- how many times do we need to run the recipe?
    local batches = math.ceil(amount / quantityPerBatch)
    -- debugf("Need to build %s x %s (%s batches)", amount, item.locDisplayName, batches)

    -- log that we build this recipe
    self:addToBuildLog(id, recipe, batches, quantityPerBatch)

    -- add the byproducts to our inventory, along
    -- with any spare of the one we are building
    for i,product in ipairs(recipe.products) do
        local amountMade = product.quantity * batches
        if product.id == id then
            amountMade = amountMade - amount
        end
        if amountMade > 0 then
            self:addToInventory(product.id, amountMade)
            if product.id ~= id then
                local byproduct = self:itemInfo(product.id)
                -- debugf("%s byproduct of %s", self:itemDescription(byproduct), self:itemDescription(item))
            end
        end
    end

    -- add the required ingredients to the input list,
    -- for further processing
    local input = self.input
    for i, item in pairs(recipe.ingredients) do
        table.insert(input, { id = item.id, quantity = item.quantity * batches })
    end
end

function Module:addToBuildLog(id, recipe, batches, quantityPerBatch)
    local entry = self.recipes[id]
    if not entry then
        entry = { recipe = recipe, count = 0, quantityPerBatch = quantityPerBatch }
        self.recipes[id] = entry
    end
    entry.count = entry.count + batches
end

function Module:itemInfo(id)
    local info = self.index[id]
    if not info then
        info = system.getItem(id)
        self.index[id] = info
    end
    return info
end

function Module:attachToScreen()
    -- TODO: send initial container data as part of render script
    local service = modula:getService("screen")
    if service then
        local screen = service:registerScreen(self, false, self.renderScript)
        if screen then
            self.screen = screen
        end
    end
end

Module.renderScript = [[

containers = containers or {}

if payload then
    local name = payload.name
    if name then
        containers[name] = payload
    end
    reply = { name = name, result = "ok" }
end

local screen = toolkit.Screen.new()
local layer = screen:addLayer()
local chart = layer:addChart(layer.rect:inset(10), containers, "Play")

layer:render()
screen:scheduleRefresh()
]]

-- ---------------------------------------------------------------------
-- CountTable
-- ---------------------------------------------------------------------

function CountTable.new() 
    local t = {}
    setmetatable(t, { __index = CountTable })
    return t
end

function CountTable:add(key, amount)
    local current = self[key] or 0.0
    local new = current + amount
    self[key] = new
end

function CountTable:get(key)
    return self[key] or 0.0
end

-- ---------------------------------------------------------------------

return Module