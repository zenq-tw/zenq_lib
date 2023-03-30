--==================================================================================================================================--
--                                                        table extensions
--==================================================================================================================================--

local t = {}

--------------------------------------------------------------------------------------------------------------------------------------
--                                                   table.indexed_to_lookup()
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


--------------------------------------------------------------------------------------------------------------------------------------
--                                                   table.lookup_to_indexed()
--------------------------------------------------------------------------------------------------------------------------------------


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
--                                                      table.deepcopy()
--------------------------------------------------------------------------------------------------------------------------------------


--Author: Vandy (Groove Wizard)
function t.deepcopy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = type(v) == 'table' and t.deepcopy(v) or v
	end
	return ret
end


--------------------------------------------------------------------------------------------------------------------------------------
--                                                        table.pack()
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


--------------------------------------------------------------------------------------------------------------------------------------
--                                                       table.unpack()
--------------------------------------------------------------------------------------------------------------------------------------


local table_unpack
if table.unpack then                ---@diagnostic disable-line: deprecated
    table_unpack = table.unpack     ---@diagnostic disable-line: deprecated
else
    table_unpack = unpack
end

t.unpack = table_unpack



--==================================================================================================================================--
--                                                 Public namespace initialization
--==================================================================================================================================--



return t
