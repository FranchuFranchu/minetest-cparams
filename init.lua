cparams = {}
local meta = {}


setmetatable(cparams, meta)

if table.unpack == nil then
    table.unpack = function (t, i)
        i = i or 1
        if t[i] ~= nil then
            return t[i], unpack(t, i + 1)
        end
    end
end
cparams.compile = function (format)
    local reverses = {
        ["<"] = ">",
        ["["] = "]",
        ["("] = ")",
    }
    local tree = {format, {}}
    local deepness_indexes = {}

    local in_levels = {}
    format:gsub(".", function(c)
        if reverses[c] ~= nil then
            in_levels[#in_levels+1] = c
            if (deepness_indexes[#in_levels] ~= nil) then
                deepness_indexes[#in_levels] = deepness_indexes[#in_levels] + 1
            else
                deepness_indexes[#in_levels] = 1
            end
        end
        local close = reverses[in_levels[#in_levels]] == c
        local curr = tree[2]
        for i,v in ipairs(deepness_indexes) do
            if (i == (#deepness_indexes)) then
                if curr[v] == nil then
                    curr[v] = {c, {}}
                else
                    curr[v][1] = curr[v][1] .. c
                end
            else
                curr[v][1] = curr[v][1] .. c
                curr = curr[v][2]
            end
        end
        if close then
            deepness_indexes[#in_levels+1] = nil
            in_levels[#in_levels] = nil
            --print(minetest.serialize(deepness_indexes), #in_levels)
            --deepness_indexes[#in_levels] =  deepness_indexes[#in_levels] + 1
        end
        print( c, #in_levels, minetest.serialize(deepness_indexes))
    end)
    return tree
end

cparams.parse_command_parameters = function(tree, name, params)
    -- Given a tree produced by tree.compile, generates a table with parameters. Will send error message to player if the pattern doesn't match

    local reverses = {
        ["<"] = ">",
        ["["] = "]",
        ["("] = ")",
    }
    local param_tokens = {""}
    local idx = 1

    local in_string = false
    local in_escape = false

    params:gsub(".", function(c) 
        if (c == " ") and (param_tokens[idx] ~= "") and (not in_string) then
            in_escape = false
            idx = idx + 1
            param_tokens[idx] = ""
        elseif ((c == "\\") and (not in_escape)) then
            in_escape = true
        elseif ((c == "\"") and (not in_escape)) then
            in_escape = false
            in_string = not in_string
        elseif (c ~= " ") or (in_string and (not in_escape)) or ((in_escape) and (c == "\\")) then
            in_escape = false
            param_tokens[idx] = param_tokens[idx] .. c
        end

    end)

    local param_tree = {}

    local function matches(subtree, tokens, idx)
        idx = idx or 1
        local start_idx = idx
        local ret_params = {}
        for i,v in ipairs(subtree) do
            local prefix = v[1]:sub(1,1)
            local content = string.match(v[1], "%" .. prefix .. ".*" .. "%" .. reverses[prefix])
            content = content:sub(2, #content-1)
            if prefix == "<" then
                if param_tokens[idx] then
                    ret_params[content] = param_tokens[idx]
                    idx = idx + 1 -- Consume a token
                else 
                    return false, 0, {}
                end
            elseif prefix == "[" then
                if param_tokens[idx] then
                    ret_params[content] = param_tokens[idx]
                    idx = idx + 1 -- Consume a token
                end
            elseif prefix == "(" then
                local ret, consume, ret_params_e = matches(v[2], tokens, idx)
                if ret then
                    for k,v in pairs(ret_params_e) do ret_params[k] = v end
                    idx = idx + consume
                end
            end

        end
        return true, idx - start_idx, ret_params
    end
    local b, consume, ret_params = matches(tree[2], param_tokens)
    if consume < #param_tokens then
        minetest.chat_send_player(name, "Invalid format! You have " .. tostring(#param_tokens - consume) .. " spare arguments!")
    end

    if (b == false) then
        minetest.chat_send_player(name, "Invalid format!")
    end
    return ret_params
end

meta.__call = function(t, func, format) 
    local tree = cparams.compile(format)
    print(minetest.serialize(tree))
    local _internal = function(name, params) 
        tabl = cparams.parse_command_parameters(tree, name, params)
        func(name, tabl)
    end
    return _internal
end