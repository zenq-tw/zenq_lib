local zlib_table = require('._table')


local functools = {}


---@type {table: TFactory<table>, string: TFactory<string>, number: TFactory<number>}
functools.factories = {
    table = (function (key) return {} end),
    string = (function (key) return '' end),
    number = (function (key) return 0 end),
}


---Lazy execution of supplied function
---@generic OriginRetVal
---@param func fun(...): OriginRetVal
---@param ... any
---@return fun(): OriginRetVal
function functools.lazy(func, ...) 
    local args = {...}
    return function ()
        return func(zlib_table.unpack(args))
    end
end



--TODO: rewrite better when LuaServer will support generic varargs in return:
--```lua
-- @param func fun(...): ...<T>
-- @return ...<T> returned_data
--```

---@param func fun(...)
---@param ... any
---@return boolean is_success, string? err_msg, any[] returned_data # returned_data or empty dict
local function _safe(func, ...) 
    local results = zlib_table.pack(pcall(func, ...))

    if results[1] == false then
        return false, results[2], {}
    end

    table.remove(results, 1)
    results.n = results.n - 1

    return true, nil, results
end


---Safe execution of supplied function
---@param func fun(...)
---@param ... any
---@return boolean is_success, string? err_msg, any ...
function functools.safe(func, ...) 
    local is_success, err_msg, retvals = _safe(func, ...)
    if is_success then return true, nil, zlib_table.unpack(retvals) end
    return false, err_msg, nil
end


---Safe execution of supplied function
---@param func fun(...)
---@param ... any
---@return boolean is_success, string? err_msg, string? tb, any ...
function functools.safe_tb(func, ...)
    local is_success, err_msg, retvals = _safe(func, ...)
    if is_success then return true, nil, nil, zlib_table.unpack(retvals) end

    return false, err_msg, debug.traceback('', 2), nil
end


---Safe execution of supplied function
---@param func fun(...)
---@param ... any
---@return boolean is_success, string? err_msg, any[] returned_data # returned by function values packed into indexed table (or empty table if execution was failed)
function functools.safe_N(func, ...)
    return _safe(func, ...)
end


---```lua
---XOR (^)
---xor(true, true) = false
---xor(true, false) = true
---xor(false, true) = true
---xor(false, false) = false
---```
---@param value1 any
---@param value2 any
---@return boolean
function functools.xor(value1, value2)
    return (value1 or value2) and not (value1 and value2)
end


--==================================================================================================================================--
--                                                   Public namespace initialization
--==================================================================================================================================--


return functools