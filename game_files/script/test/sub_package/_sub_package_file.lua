ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

ModLog('/test/sub_package/_sub_pacakge_file.lua:  getfenv(1)=' .. tostring(getfenv(1)) .. '; getfenv(require)=' .. tostring(getfenv(require)))
ModLog('/test/sub_package/_sub_pacakge_file.lua:  getfenv(core.get_env)=' .. tostring(getfenv(core.get_env)) .. '; core:get_env()=' .. tostring(core:get_env())..  '; getfenv(core.load_global_script)=' .. tostring(getfenv(core.load_global_script)))


local zlib = assert(core:load_global_script('script.zenq_large_garrisons.zlib.header')) ---@module "script.zenq_large_garrisons.zlib.header"
ModLog('/test/sub_package/_sub_pacakge_file.lua:  (core:load_global_script)   zlib.load.init_lib_file=' .. tostring(zlib.load.init_lib_file))
ModLog('/test/sub_package/_sub_pacakge_file.lua:  (core:load_global_script)   getfenv(zlib.load.init_lib_file)=' .. tostring(getfenv(zlib.load.init_lib_file)))

ModLog('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&')

return '_sub_package_file.lua'
