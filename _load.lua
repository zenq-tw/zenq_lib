---@class load
local load = {}



---__load package__ by loading initialization file `init.lua` (proxy function for `load.init_lib_file`)
---@param pkg string ex: `my.package.path` (`init.lua` must be in `my/package/path`)
---@param exec? boolean if `true` and if module returns a function, then this function will be executed with the passed parameters (`...`) [default = `false`]
---@param ... any any arguments to be passed to the initialization function (valid only if `exec=true`)
---@return nil | any # anything that returns a package or anything returned by an initialization function (if `exec=true`)
---* __~may be buggy~, but should't)__
---* package will be loaded in patched environment that allows relative imports
---     * to use relative import put a **dot (.)** at the beginning of the module path, for example: **require('.local_module')**
---* if something goes wrong, no error will be thrown -> use **assert** statement to check if everything is ok
---* this library will be injected into the loaded package scope -> **assert(\<lib_folder_name\>) == \<lib\>**
---     * **\<lib_folder_name\>** - name of folder where you placed zenq_lib (eg: _script/my_mod/zlib_ -> _\<lib_folder_name\>_ = **'zlib'**)
---     * **\<lib\>** - table representing zenq_lib (what is returned after importing _\<lib_folder_name\>.header_)
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
---     * to use relative import put a **dot (.)** at the beginning of the module path, for example: **require('.local_module')**
---* if something goes wrong, no error will be thrown -> use **assert** statement to check if everything is ok
---* this library will be injected into the loaded package scope -> **assert(\<lib_folder_name\>) == \<lib\>**
---     * **\<lib_folder_name\>** - name of folder where you placed zenq_lib (eg: _script/my_mod/zlib_ -> _\<lib_folder_name\>_ = **'zlib'**)
---     * **\<lib\>** - table representing zenq_lib (what is returned after importing _\<lib_folder_name\>.header_)
---* _NOTE: You should not use this function for import 'zlib' package itself_
function load.lib(lib, exec, ...)
    return load.init_lib_file(lib, 'header', exec, ...)
end




local _self_lib_load_path = ''
local _self_lib_name = ''




local function _load_module_in_environment(dotted_module_path, env)
    local file_path = dotted_module_path:gsub('%.', '/') .. '.lua'

    local file = loadfile(file_path)
    if not file then return end  --TODO: add err msg?

    setfenv(file, env)

    local is_success, retval = pcall(file, dotted_module_path)
    if not is_success then return end  --TODO: add err msg?
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

    local return_root = ('return %s%%s'):format(table.remove(keys_chain, 1))  --> 'return <root>%s'
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
        _compiled_code_chunk = assert(loadstring(_get_value_str))
        _compiled_code_chunk = setfenv(_compiled_code_chunk, fenv)
        _value = assert(_compiled_code_chunk())
        return _value
    end

    local key, parent_table, patching_table
    local function patch_recursive()
        if #keys_chain == 0 then return new_value end
        key = table.remove(keys_chain)
        parent_table = get_table_value(keys_chain)
        patching_table = {[key]=new_value}
        new_value = setmetatable(patching_table, {__index=parent_table})
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
    setfenv(0, env)                                                                     ---@diagnostic disable-line: param-type-mismatch
    local res = require(path)
    setfenv(0, original_env)                                                            ---@diagnostic disable-line: param-type-mismatch
    return res
end


local function _get_patched_package_env(package_dotted_path)
    local patched_env

    local patched__require = function (modname)
        if string.sub(modname, 1, 1) == '.' then modname = package_dotted_path .. modname end

        if patched_env.package.loaded[modname] then
            -- forces <require> respect <package.loaded>
            -- (by default it uses its own reference to <package> which we can't change in any way)
            return patched_env.package.loaded[modname]
        end

        return _call_require_in_env(modname, patched_env)
    end

    local patched__init_lib_file = function (dotted_directory_path, ...)
        if string.sub(dotted_directory_path, 1, 1) == '.' then dotted_directory_path = package_dotted_path .. dotted_directory_path end
        return _call_function_in_env(load.init_lib_file, patched_env, dotted_directory_path, ...)
    end


    local patched_keys, parent_env
    if core == nil then                                                                                     ---@diagnostic disable-line: undefined-global
        patched_keys, parent_env = {}, _G
    else
        local patched__load_global_script = function (self, modname, ...)  ---FIXME: we really need this?
            if string.sub(modname, 1, 1) == '.' then modname = package_dotted_path .. modname end
            return _call_function_in_env(core.load_global_script, patched_env, self, modname, ...)          ---@diagnostic disable-line: undefined-global
        end

        local patched__get_env = function () return patched_env end

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

    return setmetatable(patched_keys, {__index=parent_env})
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
---     * to use relative import put a **dot (.)** at the beginning of the module path, for example: **require('.local_module')**
---* if something goes wrong, no error will be thrown -> use **assert** statement to check if everything is ok
---* this library will be injected into the loaded package scope -> **assert(\<lib_folder_name\>) == \<lib\>**
---     * **\<lib_folder_name\>** - name of folder where you placed zenq_lib (eg: _script/my_mod/zlib_ -> _\<lib_folder_name\>_ = **'zlib'**)
---     * **\<lib\>** - table representing zenq_lib (what is returned after importing _\<lib_folder_name\>.header_)
---* _NOTE: You should not use this function for import 'zlib' package itself_
function load.init_lib_file(dotted_directory_path, init_file_name, exec, ...)
    if package.loaded[dotted_directory_path] then
        return package.loaded[dotted_directory_path]
	end

    if not type(exec) == 'boolean' then exec = false end


    local patched_env = _get_patched_package_env(dotted_directory_path)

    local retval = _load_module_in_environment(dotted_directory_path .. '.' .. init_file_name, patched_env)
    if not retval then return end  --TODO: add err?

    if exec and type(retval) == 'function' then
        local is_success
        setfenv(retval, patched_env)
        is_success, retval = pcall(retval,  ...)
        if not is_success then return end  --TODO: add err?
    end
    
    package.loaded[dotted_directory_path] = retval or true;
    return retval
end


---@private
function load.__set_lib_load_path(self_lib_load_path, self_lib_name)
    _self_lib_load_path = self_lib_load_path
    _self_lib_name = self_lib_name
end

return load
