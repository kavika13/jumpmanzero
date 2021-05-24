local Module = {};

function Module.make_table_read_only(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, key, value)
            error("attempting to change constant " .. tostring(key) .. " to " .. tostring(value), 2);
        end,
        __len = function(t)
            return #tbl;
        end,
        __pairs = function(t)
            return next, tbl, nil;
        end,
    });
end

return Module;
