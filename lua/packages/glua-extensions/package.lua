name = "glua-extensions"
version = "0.37.0"
autorun = true
init = {
    ["client"] = "cl_init.lua",
    ["server"] = "init.lua"
}

send = {
    "shared.lua"
}