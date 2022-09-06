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

function Module:register(parameters)
    modula:registerForEvents(self, "onStart", "onFastUpdate")
end

-- ---------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------

function Module:onStart()
    debugf("Trade Helper started.")

    self.inventory = {}
    self.index = {}
    self.builds = {}
    self.recipes = {}
    self.running = true
    local id = modula.core.getItemId()

    self.input = { { id = id, quantity = 1.0 } }
    -- self:attachToScreen()
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
            printf("Build List")
            for id, count in pairs(self.builds) do
                if count > 0 then
                    local item = self:itemInfo(id)
                    local name = item.locDisplayName
                    printf("- %s x %s", count, name)
                end
            end
    
            printf("Recipes")
            for id, entry in pairs(self.recipes) do
                if entry.count > 0 then
                    local item = self:itemInfo(id)
                    local name = item.locDisplayName
                    printf("- %s x %s", entry.count, name)
                end
            end
    
            printf("Inventory")
            for id, count in pairs(self.inventory) do
                if count > 0 then
                    local item = self:itemInfo(id)
                    local name = item.locDisplayName
                    printf("- %s x %s", count, name)
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
    printf("Processing %s", item.name)
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
            printf("No recipe for %s.", item.name)
            local builds = self.builds
            local count = builds[id] or 0.0
        end
    end
end

function Module:bestRecipe(id)
    local recipes = system.getRecipes(id)
    for i,recipe in ipairs(recipes) do
        return recipe
    end
end

function Module:addToInventory(id, amount)
    local current = self.inventory[id] or 0.0
    local new = current + amount
    self.inventory[id] = new
end

function Module:build(item, recipe, amount)
    local id = item.id

    printf("Need to build %s x %s", amount, item.name)
    local quantity = 0.0
    for i,product in ipairs(recipe.products) do
        if product.id == item.id then
            quantity = product.quantity
            break
        end
    end

    local batches = math.floor(amount / quantity)
    printf("Need %s batches", batches)

    local entry = self.recipes[id]
    if not entry then
        entry = { recipe = recipe, count = 0}
        self.recipes[id] = entry
    end
    entry.count = entry.count + batches

    for i,product in ipairs(recipe.products) do
        self:addToInventory(product.id, product.quantity * batches)
    end

    printf("%s %s", item.name, item.type)
    local input = self.input
    if item.type ~= "material" then
        for i, item in pairs(recipe.ingredients) do
            table.insert(input, { id = item.id, quantity = item.quantity * batches })
        end
    end
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

return Module