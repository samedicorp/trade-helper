-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
--  Created by Samedi on 06/09/2022.
--  All code (c) 2022, The Samedi Corporation.
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

local useLocal = true --export: Use require() to load local scripts if present. Useful during development.
local logging = true --export: Enable controller debug output.

modulaSettings = { 
    name = "Trade Helper",
    version = "1.0",
    logging = logging, 
    useLocal = useLocal,
    modules = {
        ["samedicorp.modula.modules.containers"] = { },
        ["samedicorp.modula.modules.screen"] = { },
        ["samedicorp.modula.modules.console"] = { name = "main" },
        ["samedicorp.trade-helper.main"] = { }
    }
}


