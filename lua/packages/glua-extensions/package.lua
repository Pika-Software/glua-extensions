name = "glua-extensions"
version = "0.33.0"
autorun = true
init = {
    ["client"] = "cl_init.lua",
    ["server"] = "init.lua"
}

send = {
    "shared.lua"
}