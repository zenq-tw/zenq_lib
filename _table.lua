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



--==================================================================================================================================--
--                                                 Public namespace initialization
--==================================================================================================================================--



return t
