ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

ModLog('/test/sub_package/init.lua:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
ModLog('/test/sub_package/init.lua:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))


local zlib = require('script.zenq_large_garrisons.zlib.header') ---@module "script.zenq_large_garrisons.zlib.header"
ModLog('/test/sub_package/init.lua:  (require)  zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
ModLog('/test/sub_package/init.lua:  (require)  getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))


local sub_package_file = assert(core:load_global_script('._sub_package_file')) ---@module "script.zenq_large_garrisons.zlib.header"
ModLog("/test/sub_package/init.lua:  (core:load_global_script('._sub_package_file'))  =  " .. tostring(sub_package_file))

ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

local function setup()
    ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

    ModLog('/test/sub_package/init.lua [setup()]:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
    ModLog('/test/sub_package/init.lua [setup()]:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))

    ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
    return 'sub_package/init.lua:setup()'
end


return setup