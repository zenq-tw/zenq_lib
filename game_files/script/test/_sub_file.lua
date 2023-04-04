ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

ModLog('/test/_sub_file.lua:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
ModLog('/test/_sub_file.lua:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))

local zlib = require('script.zenq_large_garrisons.zlib.header') ---@module "script.zenq_large_garrisons.zlib.header"
ModLog('/test/_sub_file.lua:  (require)   zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
ModLog('/test/_sub_file.lua:  (require)   getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))

-- local zlib = core:load_global_script('script.zenq_large_garrisons.zlib.header') ---@module "script.zenq_large_garrisons.zlib.header"
-- ModLog('/test/_sub_file.lua:  (core:load_global_script)   zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
-- ModLog('/test/_sub_file.lua:  (core:load_global_script)   getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))

local res = zlib.load.init_lib_file('.sub_package', 'init', true)
-- ModLog("/test/_sub_file.lua:  (require)   zlib.load.init_lib_file('.sub_package', 'init', true)=" .. tostring(res))
ModLog("/test/_sub_file.lua:  (core:load_global_script)   zlib.load.init_lib_file('.sub_package', 'init', true)=" .. tostring(res))

ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

return '_sub_file.lua'
