Command Parameter Mod
=====================
Minetest Library for parsing Minetest command arguments


Example usage:

    minetest.register_chatcommand("set-team-spawn", {
        params = "<team> [(<x> <y> <z>)]",
        description = "Sets the spawn for this team on the location provided. If not provided, then it will use your location",
        -- We will use the "cparams" function added by this mod, which takes a function and a format and returns a new function that parses the format and gives it to the interal function
        func = cparams(function(name, params)
            -- Obviously, this function doesn't  implement the described function. But it's for demostration purposes
            minetest.chat_send_player(name, minetest.serialize(params)) -- params is a table
        end, "<team> (<x> <y> <z>)")
    })

On chat, type:

    set-team-spawn red 1 2 3
    set-team-spawn red 1 2
    set-team-spawn red