
local dbAdmin = {}
dbAdmin.__index = dbAdmin

-- Function to create a new database explorer instance
function dbAdmin.new(db)
    local self = setmetatable({}, dbAdmin)
    self.db = db
    return self
end

-- Function to list all tables in the database
function dbAdmin:tables()
    local tables = {}
    for row in self.db:nrows("SELECT name FROM sqlite_master WHERE type='table';") do
        table.insert(tables, row.name)
    end
    return tables
end

-- Function to get the record count of a table
function dbAdmin:count(tableName)
    local count_query = string.format("SELECT COUNT(*) AS count FROM %s;", tableName)
    for row in self.db:nrows(count_query) do
        return row.count
    end
end

-- Function to execute a given SQL query
function dbAdmin:exec(sql)
    local results = {}
    for row in self.db:nrows(sql) do
        table.insert(results, row)
    end
    return results
end

function dbAdmin:safeExec(sql, returnResults, ...)
    returnResults = returnResults or false
    local placeholderCount = select(2, sql:gsub("?", ""))
    local params = {...}
    assert(placeholderCount == #params, string.format("Expected %d parameters but got %d", placeholderCount, #params))
    -- Sanitize parameters
    for i, param in ipairs(params) do
        if type(param) == "string" then
            params[i] = string.format("'%s'", param:gsub("'", "''"))
        elseif param == nil then
            params[i] = "NULL"
        else
            params[i] = tostring(param)
        end
    end
    -- Replace placeholders (`?`) with sanitized values
    local query = sql:gsub("%?", function()
        return table.remove(params, 1) or error("Placeholder mismatch: '?' without parameter.")
    end)
    print("dbAdmin query => " .. query)
    -- Execute the final query
    if returnResults then
        local results = {}
        local ok, err = pcall(function()
            for row in self.db:nrows(query) do
                table.insert(results, row)
            end
        end)
        assert(ok, string.format("Database execution failed: %s\nQuery: %s", tostring(err), query))
        return results
    else
        local ok, err = pcall(function()
            self.db:exec(query)
        end)
        assert(ok, string.format("Database execution failed: %s\nQuery: %s", tostring(err), query))
    end
end


return dbAdmin
