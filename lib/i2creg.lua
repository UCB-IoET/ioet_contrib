require "cord"
local REG = {}

-- Create a new I2C register binding
function REG:new(port, address)
    obj = {port=port, address=address}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Read a given register address
function REG:r(reg)
    -- TODO:
    -- create array with address
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1,reg)
    -- write address
    local rv1 = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START, arr)
    if rv1 == storm.i2c.OK then
       local rv2 = cord.await(storm.i2c.read, self.port + self.address, storm.i2c.RSTART + storm.i2c.STOP, arr)
       return arr:get(1)
    else return nil
    end
    -- read register with RSTART
    -- check all return values
end

function REG:w(reg, value)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
    local arr = storm.array.create(2,storm.array.UINT8)
    arr:set(1,reg)
    arr:set(2, value)
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
<<<<<<< HEAD
    return rv
end

function REG:w16(reg, value1, value2)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
    local arr = storm.array.create(3,storm.array.UINT8)
    arr:set(1,reg)
    arr:set(2, value1)
    arr:set(3, value2)
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
    return rv
=======
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    return 1
>>>>>>> d2f7de8428d1a0ef6d729e0671f624a0a17f7e8a
end

return REG
