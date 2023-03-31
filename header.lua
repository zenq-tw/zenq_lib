local original_package_path = package.path
print(string.match('script.db_reader.zlib.header', '^(.+)%.header'))
local parent_dir_path = assert((...):match('^(.+)%.header'), 'failed to setup library')
local lib_path = parent_dir_path:gsub('%.', '/') .. '/?.lua'

if not package.path:match(lib_path) then
    package.path = lib_path .. ';' .. package.path
end


local lib = {
    types       = require('_types'),        ---@module "_types"
    table       = require('_table'),        ---@module "_table"
    functools   = require('_functools'),    ---@module "_functools"
    collections = require('_collections'),  ---@module "_collections"
    logging     = require('_logging'),      ---@module "_logging"
}


package.path = original_package_path

return lib
