name = "glua-extensions"
version = "0.39.0"
autorun = true
init = {
    ["client"] = "cl_init.lua",
    ["server"] = "init.lua"
}
send = {
    "shared.lua"
}