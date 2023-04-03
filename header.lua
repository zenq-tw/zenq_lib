---@diagnostic disable: invisible

local parent_dir_path = assert((...):match('^(.+)%.header'), 'failed to setup library')


local _load      = assert(core:load_global_script(parent_dir_path .. '._load'))   ---@module "_load"
_load.__setup_lib_load_path(...)
_load.__setup_lib_load_path = nil


local lib = {
    load        = _load,
    types       = assert(core:load_global_script(parent_dir_path .. '._types')),            ---@module "_types"
    table       = assert(core:load_global_script(parent_dir_path .. '._table')),            ---@module "_table"
    functools   = assert(core:load_global_script(parent_dir_path .. '._functools')),        ---@module "_functools"
    collections = assert(core:load_global_script(parent_dir_path .. '._collections')),      ---@module "_collections"
    logging     = assert(core:load_global_script(parent_dir_path .. '._logging')),          ---@module "_logging"
}


return lib