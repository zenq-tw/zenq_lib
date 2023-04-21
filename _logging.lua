local ztable = require('._table')
local ztypes = require('._types')


local logging = {}


--[[
======================================================================================
                                      Definitions
======================================================================================
--]]



local DEFAULT_MAX_DUMPED_TABLE_LEN = 150



---@enum LogLvl
local LogLvl = {
    debug=10,
    info=20,
    error=30,
}
logging.lvl = ztable.deepcopy(LogLvl)  ---@type {debug: LogLvl, info: LogLvl, error: LogLvl}
logging.log_lvl_lookup = ztable.indexed_to_lookup(LogLvl)

---@type number
local LOGGING_DEACTIVATED_LVL = 0/0  --  == `NaN` == `-1.#IND` ->  all numeric comparisons will return false



---@param value any
---@return boolean
local function is_valid_log_lvl(value)
    if not ztypes.is_number(value) or value < LogLvl.debug or LogLvl.error < value then 
        return false
    end  
    return true
end




---@class LoggerCls
---@field private _is_activated boolean is logger enabled
---@field private _log_file_name string relative path to log file from WH3 root
---@field private _indent_lvl integer current indentation level 
---@field private _indent string current indentation level string
---@field private _context_stack string[] context that will prepend all log record lines
---@field private _context_chain_dumped string dumped context stack
---@field private _is_newstring boolean should we prepend current context?
---@field private _current_log_level LogLvl
---@field private _logging_level_file_path string path to file that contain current logging level
---@field private _write_log fun(msg: string): nil
---@field private __index LoggerCls
logging.Logger = {
    _logging_level_file_path='data/script/enable_console_logging',
}



--[[
======================================================================================
                                Logger: Main public methods
======================================================================================
--]]


---@nodiscard
---@generic Cls
---@param cls Cls
---@param logger_name? string > `log__<logger_name>.txt`; if not specified, then log will be written with `ModLog` or `out`
---@param log_lvl? LogLvl initial log level [defult is `deactivated`]
---@param clear_existed_log? boolean [default `true`]
---@param max_dumped_table_len? integer table dump in message will be truncated when this value is exceeded
---@return Cls
function logging.Logger.new(cls, logger_name, log_lvl, clear_existed_log, max_dumped_table_len)
    if not is_valid_log_lvl(log_lvl)                then log_lvl = LOGGING_DEACTIVATED_LVL                   end
    if not ztypes.is_boolean(clear_existed_log)     then clear_existed_log = true                            end
    if not ztypes.is_number(max_dumped_table_len)   then max_dumped_table_len = DEFAULT_MAX_DUMPED_TABLE_LEN end

    ---@cast log_lvl LogLvl


    cls.__index = cls
    local self = setmetatable({}, cls)  --[[@as LoggerCls]]

    self._indent = ''
    self._indent_lvl = 0
    self._context_stack = {}
    self._context_chain_dumped = ''
    self._is_newstring = true
    self._current_log_level = log_lvl


    if logger_name == nil then
        self._log_file_name = nil
        self._write_log = ModLog or out  ---@diagnostic disable-line: undefined-global
    else
        self._log_file_name = 'log__' .. logger_name .. '.txt'   
        if clear_existed_log then
            self:_create_file_or_clear_content()
        end
        self._write_log = function (msg) self:_append_to_log_file(msg) end  ---@diagnostic disable-line: invisible
    end


    return self
end


---Log debug varargs. Will concatenate all arguments into log record: ('a', 1, true) -> 'a 1 true'
---@return self
function logging.Logger:debug(...) 
    return self:_log(arg, LogLvl.debug)
end

---Log info varargs. Will concatenate all arguments into log record: ('a', 1, true) -> 'a 1 true'
---@return self
function logging.Logger:info(...) 
    return self:_log(arg, LogLvl.info)
end

---Log error varargs. Will concatenate all arguments into log record: ('a', 1, true) -> 'a 1 true'
---@return self
function logging.Logger:error(...) 
    return self:_log(arg, LogLvl.error)
end


---Log error varargs. Same as log:error(), but will add a stacktrace
---@return self
function logging.Logger:exception(...) 
    return self:_log(arg, LogLvl.error, true)
end


---Log provided traceback.
--- * leading NL will be removed
--- * log level for traceback = `LogLvl.error`
---@param tb string traceback retrieved with `debug.traceback()`
---@param err_msg string? optional message that will be logged before traceback (with ` > ` at the start)
---@return self 
function logging.Logger:traceback(tb, err_msg)
    if not self:is_enabled_for(LogLvl.error) then return self end
    return self:_traceback(tb, err_msg)
end


---Extended version logging method - more control over the process of building a log message
---@param msg any
---@param log_lvl? integer (`debug` is default)
---@param add_new_line? boolean
---@param ignore_indent? boolean ignore indentation lvl (in case of logging in same line again)
---@param eval_functions? boolean
---@param dump_tables? boolean
---@return self
function logging.Logger:log_ext(msg, log_lvl, add_new_line, ignore_indent, eval_functions, dump_tables)
    if not is_valid_log_lvl(log_lvl)       then     log_lvl = LogLvl.debug  end  ---@cast log_lvl LogLvl
    if not self:is_enabled_for(log_lvl)    then     return self             end
    if not ztypes.is_boolean(add_new_line) then     add_new_line = true     end

    ---@cast add_new_line boolean

    local msg_type = type(msg)
    if not msg_type == 'string' then
        if msg_type == 'function' and eval_functions then
            msg = self:_get_function_result(msg)
            msg_type = type(msg)
        end
        
        if msg_type == 'table' and dump_tables then
            msg = self:_dump_table(msg)
        else
            msg = tostring(msg)
        end
    end


    if not ignore_indent then msg = self._indent .. msg end
    if add_new_line then msg = msg .. '\n' end


    self:_append_to_log_file(self:_prepend_context(msg))


    self._is_newstring = add_new_line
    return self
end


---set current logging level
---@param lvl LogLvl `lvl.debug` | `lvl.info` | `lvl.error` or any other numeric value
---@return boolean is_loglvl_set
function logging.Logger:set_log_lvl(lvl)
    if not is_valid_log_lvl(lvl) then   return false    end  
    
    self._current_log_level = lvl
    return true
end

---get current allowed level of messages in log
---@return LogLvl
function logging.Logger:get_current_log_lvl()
    return self._current_log_level
end


--[[
======================================================================================
                        Logger: Additional public methods
======================================================================================
--]]


---is logger enabled for logging level?
---@nodiscard
---@param lvl LogLvl
---@return boolean
function logging.Logger:is_enabled_for(lvl)
    return self._current_log_level <= lvl
end

---force logging off (regardless of initial settings)
---@return nil
function logging.Logger:deactivate()
    self._current_log_level = LOGGING_DEACTIVATED_LVL
end


---@return self
function logging.Logger:add_indent()
    self._indent_lvl = self._indent_lvl + 1
    self._indent = self._indent .. '  '

    return self
end


---@return self
function logging.Logger:remove_indent()
    if self._indent_lvl == 0    then    return self     end

    self._indent_lvl = self._indent_lvl - 1
    self._indent = self._indent:sub(1, -3)

    return self
end


---@vararg string
---@return self
function logging.Logger:enter_context(...)
    local merged_context = table.concat(arg, '][')

    table.insert(self._context_stack, merged_context)
    self._context_chain_dumped = self._context_chain_dumped .. '[' .. merged_context .. ']'

    return self
end


---@return self
function logging.Logger:leave_context()
    local context_name = table.remove(self._context_stack)
    self._context_chain_dumped = string.sub(self._context_chain_dumped, 1, -(#context_name + 2 + 1))

    return self
end

--[[
======================================================================================
                        Logger: Internal functions and methods
======================================================================================
--]]


---@param msg string
---@return string
local function _remove_opening_nl_if_present(msg)
    if msg:sub(1, 1) == '\n' then return msg:sub(2, -1) end
    return msg
end


---@protected
---@param tbl table
---@return string
function logging.Logger:_dump_table(tbl)
    local buffer, buffer_new_id, result_string_len = {}, 0, 0
    local temp_string

    for key, value in pairs(tbl) do
        temp_string = tostring(key) .. ': ' .. tostring(value)
        
        result_string_len = result_string_len + #temp_string
        buffer_new_id = buffer_new_id + 1

        if result_string_len > DEFAULT_MAX_DUMPED_TABLE_LEN then
            buffer[buffer_new_id] = '... <truncated> ...'
            break
        end
        
        buffer[buffer_new_id] = temp_string
    end

    return  '{' .. table.concat(buffer, ', ') .. '}'
end


---@protected
---@param func fun(...)
---@return string
function logging.Logger:_get_function_result(func)
    local is_success_eval, returned_data = pcall(func)

    if is_success_eval then
        return returned_data
    end

    return tostring(func)
end


---@protected
---@param args any[] values for log record
---@param lvl LogLvl
---@param add_traceback? boolean
---@return LoggerCls
function logging.Logger:_log(args, lvl, add_traceback)
    if not self:is_enabled_for(lvl) then    return self     end
    
    local dumped_values = {}

    local argument, arg_type
    for i=1, #args do
        argument = args[i]

        if type(argument) == 'function' then
            argument = self:_get_function_result(argument)
        end

        arg_type = type(argument)

        if arg_type == 'table' then
            argument = self:_dump_table(argument)

        elseif arg_type ~= "string" then
            argument = tostring(argument)

        end

        dumped_values[i] = argument
    end

    local msg = table.concat(dumped_values, ' ')
    if add_traceback then
        msg = 'Error:\n > ' .. _remove_opening_nl_if_present(debug.traceback(msg, 3)) .. '\n'
    else 
        msg = self._indent .. msg
    end

    msg = self:_prepend_context(msg) .. '\n'

    self._write_log(msg)

    return self
end


---@protected
---@param tb string
---@param err_msg string?
function logging.Logger:_traceback(tb, err_msg)
    if type(err_msg) == 'string' then
        err_msg = ' > ' .. err_msg .. '\n'
    else 
        err_msg = '\n' 
    end

    err_msg = err_msg .. _remove_opening_nl_if_present(tb) .. '\n\n'
    self._write_log(err_msg)

    return self
end


---@protected
---@param msg string 
---@return string
function logging.Logger:_prepend_context(msg)
    if self._is_newstring and #self._context_stack > 0 then
        msg = self._context_chain_dumped .. ' ' .. msg
    end

    return msg
end


---@protected
---@param mod? AvailableOpenFileMod `'a'` is default
---@return file*
function logging.Logger:_open_log_file(mod)
    mod = mod or 'a'

    if not (mod == 'a' or mod == 'w') then
        error('attempted to open file in unkown mode: ' .. tostring(mod))  --FIXME: is it good?)
    end

    local file, error_desc = io.open(self._log_file_name, mod)
    assert(file, 'failed to open a file' .. tostring(self._log_file_name) .. '(' .. (error_desc or '<unknown>') .. ')')

    return file
end


---check that file can be opened and also clear its content from previous executions
---@protected
---@return nil
function logging.Logger:_create_file_or_clear_content()
    local file = self:_open_log_file('w')
    file:close()
end


---@protected
---@param msg string 
---@return nil
function logging.Logger:_append_to_log_file(msg)
    local file = self:_open_log_file('a')

    file:write(msg)
    file:close()
end



--[[
======================================================================================
                            Public namespace initialization
======================================================================================
--]]


return logging
