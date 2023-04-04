---@class load
local load = {}



---__load package__ by loading initialization file `init.lua` (proxy function for `load.init_lib_file`)
---@param pkg string ex: `my.package.path` (`init.lua` must be in `my/package/path`)
---@param exec? boolean if `true` and if module returns a function, then this function will be executed with the passed parameters (`...`) [default = `false`]
---@param ... any any arguments to be passed to the initialization function (valid only if `exec=true`)
---@return nil | any # anything that returns a package or anything returned by an initialization function (if `exec=true`)
---* __~may be buggy~, but should't)__
---* package will be loaded in patched environment that allows relative imports
---* to use relative import put a dot (`.`) at the beginning of the module path, for example: `require('.local_module')`
---* if something goes wrong, no error will be thrown - use the `assert` statement to check if everything is ok
---* _NOTE: You should not use this function for import 'zlib' package itself_
function load.package(pkg, exec, ...)
    return load.init_lib_file(pkg, 'init', exec, ...)
end


---__load library__ by loading initialization file `header.lua` (proxy function for `load.init_lib_file`)
---@param lib string ex: `my.lib.path` (`header.lua` must be in `my/lib/path`)
---@param exec? boolean if `true` and if module returns a function, then this function will be executed with the passed parameters (`...`) [default = `false`]
---@param ... any any arguments to be passed to the initialization function (valid only if `exec=true`)
---@return nil | any # anything that returns a package or anything returned by an initialization function (if `exec=true`)
---* __~may be buggy~, but should't)__
---* package will be loaded in patched environment that allows relative imports
---* to use relative import put a dot (`.`) at the beginning of the module path, for example: `require('.local_module')`
---* if something goes wrong, no error will be thrown - use the `assert` statement to check if everything is ok
---* _NOTE: You should not use this function for import 'zlib' package itself_
function load.lib(lib, exec, ...)
    return load.init_lib_file(lib, 'header', exec, ...)
end




local _self_lib_load_path = ''
local _self_lib_name = ''



local function _load_module_in_environment(dotted_module_path, env)
    ModLog('    _load_module_in_environment: dotted_module_path=' .. tostring(dotted_module_path) .. '; env=' .. tostring(env))  --FIXME: remove
    local real_path = dotted_module_path:gsub('%.', '/')

    local file_path = real_path .. '.lua'

    -- local file = loadfile(file_path)
    -- if not file then return end

    local file, err = loadfile(file_path)  --FIXME: remove
    if not file then
        ModLog('    _load_module_in_environment 1: failure = ' .. tostring(err))
        return
    end

    ModLog('    _load_module_in_environment: getfenv(file) = ' .. tostring(getfenv(file)))
    setfenv(file, env)
    ModLog('    _load_module_in_environment: getfenv(file) [UPDATED?] = ' .. tostring(getfenv(file)))
    -- local is_success, retval = pcall(file, dotted_module_path, real_path)
    -- if not is_success then return nil end

    local is_success, retval = pcall(file, dotted_module_path)  --FIXME: remove
    if not is_success then
        ModLog('    _load_module_in_environment 2: failure = ' .. tostring(retval))
        return nil
    end

    ModLog('    _load_module_in_environment: return (success)')
    return retval
end


---patch table key with new value by specified `keys_chain` (while keeping `__index` for original tables)
---@param keys_chain string[]
---@param new_value any
---@param fenv table environment in which patched table is available
---@return table
---#### DIRTY HACK
local function _patch(keys_chain, new_value, fenv)
    assert(#keys_chain >= 2)

    local return_root = ('return %s%%s'):format(table.remove(keys_chain, 1))  --> return <root>%s
    local closing_brackets, intermediate_brackets = "['%s']", "']['"

    local table_keys_path

    local function dump_keys_path(keys) 
        table_keys_path = table.concat(keys, intermediate_brackets)
        if table_keys_path == '' then return '' end
        return  closing_brackets:format(table_keys_path)
    end

    local _get_value_str, _compiled_code_chunk, _value

    ---@param keys string[]
    ---@return any
    local function get_table_value(keys)
        _get_value_str = return_root:format(dump_keys_path(keys))

        -- ModLog('      get_table_value:  (_get_value_str) return_root:format(table_keys_path) => ' .. tostring(_get_value_str))
        _compiled_code_chunk = assert(loadstring(_get_value_str))
        _compiled_code_chunk = setfenv(_compiled_code_chunk, fenv)
        -- ModLog('      get_table_value:  (_compiled_code_chunk) loadstring(z) = ' .. tostring(_compiled_code_chunk))
        _value = assert(_compiled_code_chunk())
        -- ModLog('      get_table_value:  return _compiled_code_chunk() = ' .. tostring(_value))
        return _value
        -- return setfenv(assert(loadstring(table_keys_path_string:format(table.concat(keys, "']['")))), fenv)()
    end

    local key, parent_table, patching_table
    -- local i, desc = #keys_chain, ''
    local function patch_recursive()
        -- desc = '    _patch_recursive (' .. tostring(i) .. '): '
        -- ModLog(desc ..' keys_chain=[' .. tostring(table.concat(keys_chain, ', ')) .. ']')
        if #keys_chain == 0 then
            -- ModLog('===========')
            return new_value
        end
        key = table.remove(keys_chain)
        -- i = i - 1
        parent_table = get_table_value(keys_chain)
        patching_table = {[key]=new_value}
        -- ModLog(desc .. '_patch_recursive: patching_table({[key]=new_value}) => {[' .. tostring(key) .. ']=' .. tostring(new_value) .. '}' .. ',  mt.__index=' .. tostring(parent_table))
        new_value = setmetatable(patching_table, {__index=parent_table})
        -- ModLog('-----------')
        return patch_recursive()
    end

    return patch_recursive()
end


---generic `<Retval>` (luaServer is buggy in this case)
---@param fun fun(...): any  -- `fun(...): <Retval>`
---@param env table environment
---@param ... any function arguments
---@return any origin_retval  #`<Retval>`
local function _call_function_in_env(fun, env, ...)
    local origin_env = getfenv(fun)
    local res = setfenv(fun, env)(...)
    setfenv(fun, origin_env)
    return res
end


---this doesnt affect `require` itself, but loaded file will have specified environment (so `package.loaded` and other patched stuff will be preserved)
---@param path string
---@param env table
---@return any require_retval
---#### _--TODO: maybe it's better to use `loadfile` instead (less dirty magic) - think about it later_
local function _call_require_in_env(path, env)
    local original_env = getfenv(0)
    setfenv(0, env)
    local res = require(path)
    setfenv(0, original_env)
    return res
end


local function _get_patched_package_env(package_dotted_path)
    local patched_env, res

    local patched__require = function (modname)
        ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
        ModLog('  patched  [require]:  modname = ' .. tostring(modname)) --FIXME: remove
        if string.sub(modname, 1, 1) == '.' then
            modname = package_dotted_path .. modname
            ModLog('  patched  [require]:  new modname = ' .. tostring(modname)) --FIXME: remove
        end

        if patched_env.package.loaded[modname] then
            -- forces <require> respect <package.loaded>
            -- (by default it uses its own reference to <package> which we can't change in any way)
            res = patched_env.package.loaded[modname]
            ModLog('  patched  [require]:  returned stored res from patched package.loaded = ' .. tostring(res)) --FIXME: remove
            ModLog('  patched  [require]:  original value = ' .. tostring(package.loaded[modname]))
            ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
            return res
        end

        res = _call_require_in_env(modname, patched_env)
        ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
        return res
        -- return require(modname)
    end

    local patched__init_lib_file = function (dotted_directory_path, ...)
        ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
        ModLog('  patched   [zlib.load.init_lib_file]:  dotted_directory_path = ' .. tostring(dotted_directory_path)) --FIXME: remove
        if string.sub(dotted_directory_path, 1, 1) == '.' then
            dotted_directory_path = package_dotted_path .. dotted_directory_path
            ModLog('  patched   [zlib.load.init_lib_file]:  new dotted_directory_path = ' .. tostring(dotted_directory_path)) --FIXME: remove
        end

        ModLog('  patched   [zlib.load.init_lib_file]:  patched_env = ' .. tostring(patched_env))
        ModLog('  patched   [zlib.load.init_lib_file]:  getfenv(load.init_lib_file) = ' .. tostring(getfenv(load.init_lib_file))) --FIXME: remove
        res = _call_function_in_env(load.init_lib_file, patched_env, dotted_directory_path, ...)
        ModLog('  patched   [zlib.load.init_lib_file]:  ENVED(load.init_lib_file(...)) = ' .. tostring(res)) --FIXME: remove

        ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
        return res
    end

    local patched__get_env  --TODO: remove
    local patched_keys, parent_env
    if core == nil then
        patched_keys, parent_env = {}, _G
    else
        local patched__load_global_script = function (self, modname, ...)
            ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
            ModLog('  patched   [load_global_script]:  modname = ' .. tostring(modname)) --FIXME: remove
            if string.sub(modname, 1, 1) == '.' then
                modname = package_dotted_path .. modname
                ModLog('  patched   [load_global_script]:  new modname = ' .. tostring(modname)) --FIXME: remove
            end

            ModLog('  patched   [load_global_script]:  patched_env = ' .. tostring(patched_env))
            ModLog('  patched   [load_global_script]:  getfenv(core.load_global_script) = ' .. tostring(getfenv(core.load_global_script))) --FIXME: remove
            res = _call_function_in_env(core.load_global_script, patched_env, self, modname, ...)
            ModLog('  patched   [load_global_script]:  ENVED(core.load_global_script(self, modname, ...)) = ' .. tostring(res)) --FIXME: remove

            ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
            return res
        end
        
        patched__get_env = function ()
            ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
            ModLog('  patched   [core.get_env]:  returning patched env = ' .. tostring(patched_env))
            ModLog('#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@')
            return patched_env
        end

        parent_env = core:get_env()
        local patched_core = _patch({'core', 'load_global_script'}, patched__load_global_script, parent_env)
        patched_core.get_env = patched__get_env
        patched_keys = {
            core=patched_core,
        }
    end

    patched_keys.require = patched__require

    local patched_package = _patch({'package', 'loaded', _self_lib_load_path, 'load', 'init_lib_file'}, patched__init_lib_file, parent_env)
    patched_keys.package = patched_package
    patched_keys[_self_lib_name] = patched_package.loaded[_self_lib_load_path]

    ModLog('    patched_keys.package.loaded[' .. tostring(_self_lib_load_path) .. ']=' .. tostring(patched_keys.package.loaded[_self_lib_load_path]))
    ModLog('    patched_keys[' .. tostring(_self_lib_name) .. ']=' .. tostring(patched_keys[_self_lib_name]))
    ModLog('    patched_keys[' .. tostring(_self_lib_name) .. '][load][init_lib_file]=' .. tostring(patched_keys[_self_lib_name].load.init_lib_file))

    -- patched_keys._G = _patch({'_G', _self_lib_name}, patched_package.loaded[_self_lib_load_path], parent_env)
    -- env._G = _patch({'_G', 'package', 'loaded', _lib_load_path, 'load', 'init_lib_file'}, patched__init_lib_file, getfenv(1))
    
    -- ModLog('zlib.load._get_patched_package_env:  env._G= ' .. tostring(env._G))
    -- ModLog('zlib.load._get_patched_package_env:  env._G.package= ' .. tostring(env._G.package))
    -- ModLog('zlib.load._get_patched_package_env:  env._G.package["loaded"]= ' .. tostring(env._G.package["loaded"]))

    -- ModLog('==================')

    -- ModLog('    zlib.load._get_patched_package_env:  patched_keys.package= ' .. tostring(patched_keys.package))
    -- ModLog('    zlib.load._get_patched_package_env:  patched_keys.package["loaded"]= ' .. tostring(patched_keys.package["loaded"]))

    -- ModLog('------------------')
    patched_env = setmetatable(patched_keys, {__index=parent_env})

    -- ModLog('    zlib.load._get_patched_package_env:  env= ' .. tostring(patched_env))
    -- ModLog('    zlib.load._get_patched_package_env:  env.package= ' .. tostring(patched_env.package))
    -- ModLog('    zlib.load._get_patched_package_env:  env.package["loaded"]= ' .. tostring(patched_env.package["loaded"]))
    ModLog('------------------')
    local zz = getmetatable(parent_env)
    ModLog('    zlib.load._get_patched_package_env:  parent_env.mt.__index= ' .. tostring(zz.__index))

    ModLog('    patched__get_env=' .. tostring(patched__get_env))
    ModLog('    patched_env.core.get_env=' .. tostring(patched_env.core.get_env))
    ModLog('------------------')
    ModLog('    patched_env.core=' .. tostring(patched_env.core))
    ModLog('    patched_env.core:get_env()=' .. tostring(patched_env.core:get_env()))
    ModLog('    patched_env.core.get_env(patched_env.core)=' .. tostring(patched_env.core.get_env(patched_env.core)))
    ModLog('------------------')
    -- ModLog('    zlib.load._get_patched_package_env:  _G.getfenv= ' .. tostring(_G.getfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  getfenv= ' .. tostring(getfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  getfenv(1).getfenv= ' .. tostring(getfenv(1).getfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  env.getfenv= ' .. tostring(patched_env.getfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  parent_env.getfenv= ' .. tostring(patched_env.getfenv))
    -- ModLog('------------------')
    -- ModLog('    zlib.load._get_patched_package_env:  _G.setfenv= ' .. tostring(_G.setfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  setfenv= ' .. tostring(setfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  getfenv(1).setfenv= ' .. tostring(getfenv(1).setfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  env.setfenv= ' .. tostring(patched_env.setfenv))
    -- ModLog('    zlib.load._get_patched_package_env:  parent_env.setfenv= ' .. tostring(patched_env.setfenv))


    -- ModLog('==================')

    return patched_env
end



---load library initialization file in special environment:
---1. all global variables will be available (using `setfenv`)
---2. with patched `require` and `core:load_global_script`, to correct processing of relative imports inside library
---    * also allowing avoiding of consequent imports due to path modifications 
---    * i.e.: `require('file')` -> `require('my.lib.path.file')`
---@param dotted_directory_path string ex: my.lib.path (where initialization file is located)
---@param init_file_name string ex: `init`/`header`/`main` etc. (without `.lua` at the end)
---@param exec? boolean if `true` and if module returns a function, then this function will be executed with the passed parameters (`...`) [default = `false`]
---@param ... any any arguments to be passed to the initialization function (valid only if `exec=true`)
---@return nil | any # anything that returns a package or anything returned by an initialization function (if `exec=true`)
---* __~may be buggy~, but should't)__
---* package will be loaded in patched environment that allows relative imports
---* to use relative import put a dot (`.`) at the beginning of the module path, for example: `require('.local_module')`
---* if something goes wrong, no error will be thrown - use the `assert` statement to check if everything is ok
---* _NOTE: You should not use this function for import 'zlib' package itself_
function load.init_lib_file(dotted_directory_path, init_file_name, exec, ...)
    ModLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    ModLog('  zlib.load.init_lib_file:  dotted_directory_path=' .. tostring(dotted_directory_path) .. '; init_file_name=' .. tostring(init_file_name) .. '; exec=' .. tostring(exec) .. '; and something inside "..."')
    if package.loaded[dotted_directory_path] then
        ModLog('  zlib.load.init_lib_file:  ALREADY LOADED')
        ModLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
        return package.loaded[dotted_directory_path]
	end

    if not type(exec) == 'boolean' then exec = false end

    -- ModLog('--------------------------------------------------')

    local patched_env = _get_patched_package_env(dotted_directory_path)

    ModLog('--------------------------------------------------')
    
    ModLog('  zlib.load.init_lib_file:  patched_env= ' .. tostring(patched_env))
    ModLog('  zlib.load.init_lib_file:  patched_env.package= ' .. tostring(patched_env.package))
    ModLog('  zlib.load.init_lib_file:  patched_env.package["loaded"]= ' .. tostring(patched_env.package["loaded"]))

    ModLog('  zlib.load.init_lib_file:  patched_env[' .. tostring(_self_lib_name) .. ']=' .. tostring(patched_env[_self_lib_name]))
    ModLog('  zlib.load.init_lib_file:  patched_env[' .. tostring(_self_lib_name) .. '].load.init_lib_file=' .. tostring(patched_env[_self_lib_name].load.init_lib_file))
    -- ModLog('zlib.load.init_lib_file:  patched_env._G= ' .. tostring(patched_env._G))
    -- ModLog('zlib.load.init_lib_file:  patched_env._G.package= ' .. tostring(patched_env._G.package))
    -- ModLog('zlib.load.init_lib_file:  patched_env._G.package["loaded"]= ' .. tostring(patched_env._G.package["loaded"]))

    ModLog("  zlib.load.init_lib_file:  original  <init_lib_file> = " .. tostring(load.init_lib_file))
    -- ModLog("zlib.load.init_lib_file:  patched_env._G.package['loaded']['script.zenq_large_garrisons.zlib.header']['load']['init_lib_file'] = " .. tostring(patched_env._G.package['loaded']['script.zenq_large_garrisons.zlib.header']['load']['init_lib_file']))
    ModLog("  zlib.load.init_lib_file:  patched   <init_lib_file> = " .. tostring(patched_env.package['loaded']['script.zenq_large_garrisons.zlib.header']['load']['init_lib_file']))

    ModLog('--------------------------------------------------')
    local retval = _load_module_in_environment(dotted_directory_path .. '.' .. init_file_name, patched_env)
    if not retval then
        return
        ModLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    end    --TODO: add err?

    if exec and type(retval) == 'function' then
        ModLog('--------------------------------------------------')
        local is_success
        setfenv(retval, patched_env)  --FIXME: need this????
        is_success, retval = pcall(retval,  ...)
        if not is_success then
            ModLog('  zlib.load.init_lib_file:  ERROR =' .. tostring(retval)) --FIXME: remove
            ModLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
            return nil
        end  --TODO: add err?
    end
    
    package.loaded[dotted_directory_path] = retval or true;

    ModLog('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    return retval
end


---@private
function load.__set_lib_load_path(self_lib_load_path, self_lib_name)
    _self_lib_load_path = self_lib_load_path
    _self_lib_name = self_lib_name
end

return load
