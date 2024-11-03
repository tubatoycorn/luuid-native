-- dependencies
local ffi = require("ffi")


-- constants, variables, and data structures
ffi.cdef[[
    typedef int clockid_t;
    typedef struct timespec {
        int64_t tv_sec;
        int64_t tv_nsec;
    } timespec_t;
    uint32_t rand_r(uint32_t *seed);
    int64_t clock_gettime(clockid_t clk_id, struct timespec *tp);
]]

local VERSION = ffi.new([[
    struct {
        uint8_t TIME_BASED;
        uint8_t DCE_SECURITY;
        uint8_t RANDOM;
    }
]], {
    TIME_BASED = 0x10,
    DCE_SECURITY = 0x20,
    RANDOM = 0x40
})

local VERSION_LOOKUP = {
    TIME_BASED = 1,
    DCE_SECURITY = 2,
    RANDOM = 4
}

local uuid_buffer = ffi.new("uint8_t[16]")
local seed = ffi.new("uint32_t[1]")
local timespec = ffi.new("timespec_t")
local uint8_t = ffi.typeof("uint8_t")


-- utility functions
local function band(a, b)
    return tonumber(ffi.cast(uint8_t, ffi.cast(uint8_t, a) & ffi.cast(uint8_t, b)))
end

local function bxor(a, b)
    return tonumber(ffi.cast(uint8_t, ffi.cast(uint8_t, a) ~ ffi.cast(uint8_t, b)))
end

local function get_random_bytes()
    ffi.C.clock_gettime(0, timespec)
    seed[0] = tonumber(timespec.tv_nsec)
    for i = 0, 15 do
        uuid_buffer[i] = band(ffi.C.rand_r(seed), 0xFF)
    end
    return uuid_buffer
end

local function bytes_to_hex()
    return string.format(
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        uuid_buffer[0], uuid_buffer[1], uuid_buffer[2], uuid_buffer[3],
        uuid_buffer[4], uuid_buffer[5],
        uuid_buffer[6], uuid_buffer[7],
        uuid_buffer[8], uuid_buffer[9],
        uuid_buffer[10], uuid_buffer[11], uuid_buffer[12], uuid_buffer[13],
        uuid_buffer[14], uuid_buffer[15]
    )
end

local generators = {
    [1] = function()
        get_random_bytes()
        uuid_buffer[6] = bxor(band(uuid_buffer[6], 0x0F), VERSION.TIME_BASED)
        uuid_buffer[8] = bxor(band(uuid_buffer[8], 0x3F), 0x80)
        return bytes_to_hex()
    end,
    
    [2] = function()
        get_random_bytes()
        uuid_buffer[6] = bxor(band(uuid_buffer[6], 0x0F), VERSION.DCE_SECURITY)
        uuid_buffer[8] = bxor(band(uuid_buffer[8], 0x3F), 0x80)
        return bytes_to_hex()
    end,
    
    [4] = function()
        get_random_bytes()
        uuid_buffer[6] = bxor(band(uuid_buffer[6], 0x0F), VERSION.RANDOM)
        uuid_buffer[8] = bxor(band(uuid_buffer[8], 0x3F), 0x80)
        return bytes_to_hex()
    end
}


-- public api
local uuid = {}
local uuid_mt = {
    __index = uuid,
    __metatable = false,
    __newindex = function() error("Attempt to modify read-only table", 2) end
}

function uuid.new(version_str)
    assert(type(version_str) == "string", "Version must be a string")
    local version_num = VERSION_LOOKUP[version_str:upper()]
    if not version_num then
        error("Invalid UUID version: " .. version_str, 2)
    end
    return setmetatable({
        generate = generators[version_num]
    }, uuid_mt)
end

return uuid
