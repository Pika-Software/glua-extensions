name = "glua-extensions"
version = 002600
autorun = true
init = {
    ["client"] = "cl_init.lua",
    ["server"] = "init.lua"
}

send = {
    "shared.lua"
}