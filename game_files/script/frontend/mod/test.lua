ModLog('*****************************************************************************************************************************************************************************************************')
ModLog('*****************************************************************************************************************************************************************************************************')

ModLog('/frontend/mod/test.lua:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
ModLog('/frontend/mod/test.lua:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))

local zlib = assert(core:load_global_script('script.zenq_large_garrisons.zlib.header')) ---@module "script.zenq_large_garrisons.zlib.header"

ModLog('/frontend/mod/test.lua:  getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))

local test = assert(zlib.load.init_lib_file('script.test', 'init', true))
ModLog("/frontend/mod/test.lua:  zlib.load.init_lib_file('script.test', 'init', true)  =  " .. tostring(test))


ModLog('*****************************************************************************************************************************************************************************************************')

ModLog('/frontend/mod/test.lua:  zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
ModLog('/frontend/mod/test.lua:  getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))

local res = zlib.load.init_lib_file('.test', 'init', false)
ModLog("/frontend/mod/test.lua:  zlib.load.init_lib_file('.test', 'init', false)  =  " .. tostring(res))

ModLog('*****************************************************************************************************************************************************************************************************')
ModLog('*****************************************************************************************************************************************************************************************************')