---@diagnostic disable: invisible

local lib_path, lib_name = (...):match('^(.+%.(.+))%.header$')
assert(lib_path and lib_name, 'failed to setup library')


local _load      = assert(core:load_global_script(lib_path .. '._load'))   ---@module "_load"
_load.__set_lib_load_path(..., lib_name)
_load.__set_lib_load_path = nil


local lib = {
    load        = _load,                                                             ---@module "_load"
    types       = assert(core:load_global_script(lib_path .. '._types')),            ---@module "_types"
    table       = assert(core:load_global_script(lib_path .. '._table')),            ---@module "_table"
    functools   = assert(core:load_global_script(lib_path .. '._functools')),        ---@module "_functools"
    collections = assert(core:load_global_script(lib_path .. '._collections')),      ---@module "_collections"
    logging     = assert(core:load_global_script(lib_path .. '._logging')),          ---@module "_logging"
}


return lib