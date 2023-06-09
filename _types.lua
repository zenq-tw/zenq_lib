local types = {}


--==================================================================================================================================--
--                                                          Type checks
--==================================================================================================================================--


---@param value any
---@return boolean
function types.is_number(value)
    return type(value) == "number"
end


---@param value any
---@return boolean
function types.is_boolean(value)
	return type(value) == "boolean";
end;


--==================================================================================================================================--
--                                                   Public namespace initialization
--==================================================================================================================================--


return types
