-- dependencies
local ffi = require("ffi")
local bit = require("bit")


-- constants, variables, and data structures
local RESERVED_NCS = 0x80
local RFC_4122 = 0x40
local RESERVED_MICROSOFT = 0x20
local VERSION = {
    TIME_BASED = 1,
    DCE_SECURITY = 2,
    RANDOM = 4
}

ffi.cdef[[
    uint32_t rand_r(uint32_t *seed);
    int64_t clock_gettime(clockid_t clk_id, struct timespec *tp);
]]


-- utility functions
local function rand_bytes(n)
    local bytes = ffi.new("uint8_t[?]", n)
    local seed = ffi.new("uint32_t[1]")
    ffi.C.clock_gettime(0, ffi.new("struct timespec", seed))
    for i = 0, n - 1 do
        bytes[i] = bit.band(ffi.C.rand_r(seed), 0xFF)
    end
    return bytes
end

local function bytes_to_uuid(bytes)
    local parts = {
        string.format("%02x%02x%02x%02x", bytes[0], bytes[1], bytes[2], bytes[3]),
        string.format("%02x%02x", bytes[4], bytes[5]),
        string.format("%02x%02x", bytes[6], bytes[7]),
        string.format("%02x%02x", bytes[8], bytes[9]),
        string.format("%02x%02x%02x%02x%02x%02x", bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
    }
    return table.concat(parts, "-")
end

local function generate_time_based()
    local time_low = rand_bytes(4)
    local time_mid = rand_bytes(2)
    local time_hi_and_version = rand_bytes(2)
    time_hi_and_version[1] = bit.bxor(bit.band(time_hi_and_version[1], 0x0F), VERSION.TIME_BASED * 0x10)
    local clock_seq_hi_and_reserved = rand_bytes(1)
    clock_seq_hi_and_reserved[0] = bit.bxor(bit.band(clock_seq_hi_and_reserved[0], 0x3F), RESERVED_NCS)
    local clock_seq_low = rand_bytes(1)
    local node = rand_bytes(6)
    local bytes = ffi.new("uint8_t[16]", time_low, time_mid, time_hi_and_version, clock_seq_hi_and_reserved, clock_seq_low, node)
    return bytes_to_uuid(bytes)
end

local function generate_dce_security()
    local bytes = rand_bytes(16)
    bytes[6] = bit.bxor(bit.band(bytes[6], 0x0F), VERSION.DCE_SECURITY * 0x10)
    bytes[8] = bit.bxor(bit.band(bytes[8], 0x3F), RESERVED_NCS)
    return bytes_to_uuid(bytes)
end

local function generate_random()
    local bytes = rand_bytes(16)
    bytes[6] = bit.bxor(bit.band(bytes[6], 0x0F), VERSION.RANDOM * 0x10)
    bytes[8] = bit.bxor(bit.band(bytes[8], 0x3F), RESERVED_NCS)
    return bytes_to_uuid(bytes)
end


-- public api
local uuid = {}

function uuid.new(version_str)
    local version = VERSION[version_str:upper()]
    if not version then
        error("Invalid uuid version: " .. version_str)
    end

    local obj = {}
    if version == VERSION.TIME_BASED then
        obj.generate = generate_time_based
    elseif version == VERSION.DCE_SECURITY then
        obj.generate = generate_dce_security
    elseif version == VERSION.RANDOM then
        obj.generate = generate_random
    end

    return setmetatable(obj, {
        __index = obj,
        __metatable = "Protected metatable",
        __newindex = function() error("Attempt to modify the environment") end
    })
end

function uuid:generate()
    return self.generate()
end

return uuid
