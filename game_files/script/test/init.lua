ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
ModLog('/test/init.lua:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
ModLog('/test/init.lua:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))

local zlib = assert(core:load_global_script('script.zenq_large_garrisons.zlib.header')) ---@module "script.zenq_large_garrisons.zlib.header"
ModLog('/test/init.lua:  (core:load_global_script)   zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
ModLog('/test/init.lua:  (core:load_global_script)   getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))


local sub_file = require('._sub_file')
ModLog("/test/init.lua:  (require('._sub_file'))  =  " .. tostring(sub_file))


ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

local function setup()
    ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
    ModLog('/test/init.lua [setup()]:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
    ModLog('/test/init.lua [setup()]:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))

    ModLog('/test/init.lua [setup()]:  (core:load_global_script)   zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
    ModLog('/test/init.lua [setup()]:  (core:load_global_script)   getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))
    
    local res = zlib.load.init_lib_file('.sub_package', 'init', true)
    ModLog("/test/init.lua [setup()]:  zlib.load.init_lib_file('.sub_package', 'init', true)  =  " .. tostring(res))

    ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')
    return 'init.lua:setup()'
end


return setup