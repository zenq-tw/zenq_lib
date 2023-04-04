---@diagnostic disable: invisible

--TODO: rewrite in one regex
local lib_path, lib_name = (...):match('^(.+%.(.+))%.header$')
if not (lib_path and lib_name) then 
    lib_path, lib_name = (...):match('^((.+))%.header$')
end

assert(lib_path and lib_name, 'failed to setup library')


local parent_env, patched_env = getfenv(2), nil
local full_local_module_path, _load_module_file = ('%s%%s'):format(lib_path), nil

local function load_module(module, env)
    if module:sub(1, 1) == '.' then module = full_local_module_path:format(module) end
    return package.loaded[module] or _load_module_file(module, env or patched_env)
end

patched_env = setmetatable({require=load_module}, {__index=parent_env})
_load_module_file = function (module, env)
    package.loaded[module] = (setfenv(assert(loadfile((module):gsub('%.', '/') .. '.lua')), env)()) or true
    return package.loaded[module]
end

local _load = load_module('._load', parent_env)      ---@module "_load"
_load.__set_lib_load_path(..., lib_name)
_load.__set_lib_load_path = nil


local lib = {
    load        = _load,                             ---@module "_load"
    types       = load_module('._types'),            ---@module "_types"
    table       = load_module('._table'),            ---@module "_table"
    functools   = load_module('._functools'),        ---@module "_functools"
    collections = load_module('._collections'),      ---@module "_collections"
    logging     = load_module('._logging'),          ---@module "_logging"
}


return lib