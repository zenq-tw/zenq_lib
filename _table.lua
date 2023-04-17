--==================================================================================================================================--
--                                                        table extensions
--==================================================================================================================================--

local t = {}

--------------------------------------------------------------------------------------------------------------------------------------
--                                                          lookup tables
--------------------------------------------------------------------------------------------------------------------------------------


--- Returns another table containing all records in the supplied indexed table, except with the values set to keys. The values in the returned table will be <code>true</code> for all records.
---@generic V
---@param indexed V[]
---@param size? integer if the array size is already calculated - you can pass it here
---@return LookupTable<V>
function t.indexed_to_lookup(indexed, size)
    size = size or #indexed
	
    local retval = {}
	for i = 1, size do
		retval[indexed[i]] = true
	end

	return retval
end


---@generic V
---@param lookup_table LookupTable<V>
---@param return_size? boolean false by default
---@return V[], integer?
function t.lookup_to_indexed(lookup_table, return_size)
    local indexed = {}

    local i = 0
    for key, _ in pairs(lookup_table) do
        i = i + 1
        indexed[i] = key
    end

    if return_size then
        return indexed, i
    end

    return indexed
end


--------------------------------------------------------------------------------------------------------------------------------------
--                                                         merging tables
--------------------------------------------------------------------------------------------------------------------------------------


---@generic T1, T2
---@param indexed1 T1[]
---@param indexed2 T2[]
---@return (T1|T2)[] | nil
function t.merge_indexed_tables(indexed1, indexed2)
    local indexed1_size = #indexed1

    local lkp1 = t.indexed_to_lookup(indexed1, indexed1_size)

    if not lkp1 then return end

    local merged = {}

    for i=1, indexed1_size do
        merged[i] = indexed1[i]
    end

    local i = indexed1_size + 1
    for j=1, #indexed2 do
        if lkp1[indexed2[j]] == nil then
            merged[i] = indexed2[j]
            i = i + 1 
        end
        
    end

    return merged
end


--------------------------------------------------------------------------------------------------------------------------------------
--                                                      copying tables
--------------------------------------------------------------------------------------------------------------------------------------


--Author: Vandy (Groove Wizard)
---@generic T
---@param tbl T
---@return T 
function t.deepcopy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = type(v) == 'table' and t.deepcopy(v) or v
	end
	return ret
end


--------------------------------------------------------------------------------------------------------------------------------------
--                                            table.pack()  &  table.unpack()
--------------------------------------------------------------------------------------------------------------------------------------


local table_pack 
if table.pack then                  ---@diagnostic disable-line: deprecated
    table_pack = table.pack         ---@diagnostic disable-line: deprecated
else
    ---@param ... any
    ---@return {n: integer, [integer]: any}
    table_pack = function (...)
        -- Returns a new table with parameters stored into an array, with field "n" being the total number of parameters
        local tbl = {...}
        tbl.n = #tbl
        return tbl
    end
end

t.pack = table_pack



local table_unpack
if table.unpack then                ---@diagnostic disable-line: deprecated
    table_unpack = table.unpack     ---@diagnostic disable-line: deprecated
else
    table_unpack = unpack
end

t.unpack = table_unpack



--------------------------------------------------------------------------------------------------------------------------------------
--                                                          table -> string 
--------------------------------------------------------------------------------------------------------------------------------------



local key_str_open = '["'

local _key_str_close = '"] = '
local _key_str_close_slim = _key_str_close:gsub('%s', '')

local key_other_open = '['

local _key_other_close = '] = '
local _key_other_close_slim = _key_other_close:gsub('%s', '')



local val_str_open = '[=['

local _val_str_close = ']=],\n'
local _val_str_close_slim = _val_str_close:gsub('%s', '')

local _val_other_close = ',\n'
local _val_other_close_slim = _val_other_close:gsub('%s', '')

local _val_unsupported = 'nil,\n'
local _val_unsupported_slim = _val_unsupported:gsub('%s', '')



local _tbl_open  = '{\n'
local _tbl_open_slim = _tbl_open:gsub('%s', '')

local _tbl_close  = '}\n'
local _tbl_close_slim = _tbl_close:gsub('%s', '')

local _sub_tbl_close = '},\n'
local _sub_tbl_close_slim = _sub_tbl_close:gsub('%s', '')


local _t_char = '\t'
local _t_char_slim = _t_char:gsub('%s', '')



---Original Author: Vandy (Groove Wizard)
--- @param tbl DumpableTable
--- @param slim? boolean
--- @param strict? boolean
--- @return string?
---_[should be faster by about 20%]_
function t.dump(tbl, slim, strict)
    local table_concat, string_sub, type, tostring, next = table.concat, string.sub, type, tostring, next

    if type(tbl) ~= 'table' then return end
    if type(slim) ~= 'boolean' then slim = false end
    if type(strict) ~= 'boolean' then strict = false end


    local key_str_close, key_other_close, val_str_close, val_other_close, val_unsupported, tbl_open, tbl_close, sub_tbl_close, t_char

    if slim then
        key_str_close, key_other_close, val_str_close, val_other_close, val_unsupported, tbl_open, tbl_close, sub_tbl_close, t_char = _key_str_close_slim, _key_other_close_slim, _val_str_close_slim, _val_other_close_slim, _val_unsupported_slim, _tbl_open_slim, _tbl_close_slim, _sub_tbl_close_slim, _t_char_slim
    else
        key_str_close, key_other_close, val_str_close, val_other_close, val_unsupported, tbl_open, tbl_close, sub_tbl_close, t_char = _key_str_close, _key_other_close, _val_str_close, _val_other_close, _val_unsupported, _tbl_open, _tbl_close, _sub_tbl_close, _t_char
    end



    local table_string = {tbl_open}  ---@type (string|number)[]

    local stack_lvl = 1
    local next_i = 2
    local depth_t = t_char
    
    local current_tbl = tbl
    local table_stack = {}
    local key_stack = {}
    
    local key, value
    local key_type, value_type
    local skip


    while stack_lvl ~= 0 do
        key, value = next(current_tbl, key)

        while key ~= nil do

            key_type = type(key)
            if key_type == "string" then
                table_string[next_i]     = depth_t
                table_string[next_i + 1] = key_str_open
                table_string[next_i + 2] = key                  --[[@as string]]
                table_string[next_i + 3] = key_str_close

            elseif key_type == "number" then
                table_string[next_i]     = depth_t
                table_string[next_i + 1] = key_other_open
                table_string[next_i + 2] = key                  --[[@as number]]
                table_string[next_i + 3] = key_other_close

            elseif key_type == "boolean" then
                table_string[next_i]     = depth_t
                table_string[next_i + 1] = key_other_open
                table_string[next_i + 2] = tostring(key)
                table_string[next_i + 3] = key_other_close

            elseif strict then
                error("<dump_table>: invalid table key type = '" .. key_type .. "' (key=" .. tostring(key) .. ')')

            else
                skip = true
            end



            if skip then
                skip = false

            else
                next_i = next_i + 4
                value_type = type(value)

                if value_type == "table" then
                    table_string[next_i]     = tbl_open
                    next_i                   = next_i + 1

                    table_stack[stack_lvl]   = current_tbl
                    key_stack[stack_lvl]     = key
                    current_tbl              = value            --[[@as DumpableTable]]
                    depth_t                  = depth_t .. t_char
                    stack_lvl                = stack_lvl + 1
                    key                      = nil

                elseif value_type == "string" then
                    table_string[next_i]     = val_str_open
                    table_string[next_i + 1] = value            --[[@as string]]
                    table_string[next_i + 2] = val_str_close
                    next_i                   = next_i + 3

                elseif value_type == "number" then
                    table_string[next_i]     = value            --[[@as number]]
                    table_string[next_i + 1] = val_other_close
                    next_i                   = next_i + 2

                elseif value_type == "boolean" then
                    table_string[next_i]     = tostring(value)
                    table_string[next_i + 1] = val_other_close
                    next_i                   = next_i + 2

                elseif strict then
                    error("<dump_table>: invalid table value type = '" .. type(value) .. "' (value=" .. tostring(value) .. ')')

                else
                    -- unsupported type, technically.
                    table_string[next_i]     = val_unsupported
                    next_i                   = next_i + 1
                end
            end

            key, value = next(current_tbl, key)
        end

        table_string[next_i - 1] = string_sub(table_string[next_i - 1], 1, -2)  -- remove last ','

        stack_lvl   = stack_lvl - 1
        depth_t     = string_sub(depth_t, 1, stack_lvl)

        key         = key_stack[stack_lvl]
        current_tbl = table_stack[stack_lvl] 

        table_string[next_i]     = depth_t
        table_string[next_i + 1] = sub_tbl_close
        next_i = next_i + 2
    end

    table_string[next_i - 1] = tbl_close
    return table_concat(table_string)
end



--------------------------------------------------------------------------------------------------------------------------------------
--                                                              comparison
--------------------------------------------------------------------------------------------------------------------------------------



---compare two tables
---@param t1 table
---@param t2 table
---@return boolean
function t.compare(t1, t2)
    if not (type(t1) == 'table' and type(t2) == "table") then return false end

    -- local str
    -- local dump_keys_path = function (kpath, curr_key) str = table.concat(kpath, ']['); if str == '' then return '[' .. tostring(curr_key) .. ']' else return '[' .. str .. '][' .. tostring(curr_key) .. ']' end end
    -- local keys_path = {}

    local function _compare(tbl1, tbl2)
        for k in pairs(tbl1) do
            -- assert(type(tbl1[k]) == type(tbl2[k]), '   type(t1' .. dump_keys_path(keys_path, k) .. ') != type(t2'.. dump_keys_path(keys_path, k) ..')  ||  ' .. type(tbl1[k]) .. ' != ' .. type(tbl2[k]))
            assert(type(tbl1[k]) == type(tbl2[k]))
            if type(tbl1[k]) == 'table' then
                -- if type(k) == "string" then str = "'" .. k .. "'" else str = tostring(k) end
                -- table.insert(keys_path, str)
                _compare(tbl1[k], tbl2[k])
                -- table.remove(keys_path)
            else
                -- assert(tbl1[k] == tbl2[k], '   t1' .. dump_keys_path(keys_path, k) .. ' != t2'.. dump_keys_path(keys_path, k) ..'   ||   ' .. tostring(tbl1[k]) .. ' != ' .. tostring(tbl2[k]))
                assert(tbl1[k] == tbl2[k])
            end
        end
    end

    -- return pcall(_compare, t1, t2)
    
    return pcall(_compare, t1, t2)[1]
end



--==================================================================================================================================--
--                                                 Public namespace initialization
--==================================================================================================================================--



return t
