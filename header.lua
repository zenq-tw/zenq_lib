local original_package_path = package.path
local parent_dir_path = assert((...):match('^(.+)%.[%w_]+%.header'), 'failed to setup library')
local lib_path = parent_dir_path:gsub('%.', '/') .. '/?.lua'

if not package.path:match(lib_path) then
    package.path = lib_path .. ';' .. package.path
end


local lib = {
    types       = require('zlib.types'),        ---@module "zlib.types"
    table       = require('zlib.table'),        ---@module "zlib.table"
    functools   = require('zlib.functools'),    ---@module "zlib.functools"
    collections = require('zlib.collections'),  ---@module "zlib.collections"
    logging     = require('zlib.logging'),      ---@module "zlib.logging"
}


package.path = original_package_path

return lib
