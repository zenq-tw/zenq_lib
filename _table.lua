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



--- Author: Vandy (Groove Wizard)
--- @param tbl table
--- @param loop_value number
--- @return table<string>
local function _inner_dump_table(tbl, loop_value)
    --- @type table<any>
	local table_string = {'{\n'}
	--- @type table<any>
	local temp_table = {}
    for key, value in pairs(tbl) do
        table_string[#table_string + 1] = string.rep('\t', loop_value + 1)

        if type(key) == "string" then
            table_string[#table_string + 1] = '["'
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '"] = '
        elseif type(key) == "number" then
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '] = '
        else
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = tostring(key)
            table_string[#table_string + 1] = '] = '
        end

		if type(value) == "table" then
			temp_table = _inner_dump_table(value, loop_value + 1)
			for i = 1, #temp_table do
				table_string[#table_string + 1] = temp_table[i]
			end
		elseif type(value) == "string" then
			table_string[#table_string + 1] = '[=['
			table_string[#table_string + 1] = value
			table_string[#table_string + 1] = ']=],\n'
		else
			table_string[#table_string + 1] = tostring(value)
			table_string[#table_string + 1] = ',\n'
		end
    end

	table_string[#table_string + 1] = string.rep('\t', loop_value)
    table_string[#table_string + 1] = "},\n"

    return table_string
end




--- Author: Vandy (Groove Wizard)
--- @param tbl table
--- @return string|boolean
function t.dump_table(tbl)
    if not (type(tbl) == "table") then
        return false
    end

    --- @type table<any>
    local table_string = {'{\n'}
	--- @type table<any>
	local temp_table = {}

    for key, value in pairs(tbl) do

        table_string[#table_string + 1] = string.rep('\t', 1)
        if type(key) == "string" then
            table_string[#table_string + 1] = '["'
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '"] = '
        elseif type(key) == "number" then
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '] = '
        else
            --- TODO skip it somehow?
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = tostring(key)
            table_string[#table_string + 1] = '] = '
        end

        if type(value) == "table" then
            temp_table = _inner_dump_table(value, 1)
            for i = 1, #temp_table do
                table_string[#table_string + 1] = temp_table[i]
            end
        elseif type(value) == "string" then
            table_string[#table_string + 1] = '[=['
            table_string[#table_string + 1] = value
            table_string[#table_string + 1] = ']=],\n'
        elseif type(value) == "boolean" or type(value) == "number" then
            table_string[#table_string + 1] = tostring(value)
            table_string[#table_string + 1] = ',\n'
        else
            -- unsupported type, technically.
            table_string[#table_string+1] = "nil,\n"
        end
    end

    table_string[#table_string + 1] = "}\n"

    return table.concat(table_string)
end



--==================================================================================================================================--
--                                                 Public namespace initialization
--==================================================================================================================================--



return t
