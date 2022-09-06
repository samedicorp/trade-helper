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
    modula:registerForEvents(self, "onStart")
end

-- ---------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------

function Module:onStart()
    debugf("Trade Helper started.")

    self.inventory = {}
    self.index = {}
    self.builds = {}
    local id = modula.core.getItemId()
    self:build(id)

    for id, count in pairs(self.builds) do
        local item = self.index[id]
        local name = item.name
        printf("%s: %s", name, count)
        printf(item)
    end
    -- self:attachToScreen()
end



-- ---------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------

function Module:build(id)
    local index = self.index
    local item = index[id] or self:addToIndex(id, index)
    local builds = self.builds
    local count = builds[id] or 0
    count = count + 1
    builds[id] = count
end

function Module:addToIndex(id, index)
    local item = system.getItem(id)
    index[id] = item
    return item
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