REG = require "reg"

local ACC = {}

--[[
An abstraction for the FXOS8700CQ accelerometer and magnetometer.
]]--

ACCEL_STATUS = 0x00
ACCEL_WHOAMI = 0x00
ACCEL_XYZ_DATA_CFG = 0x0E
ACCEL_CTRL_REG1 = 0x2A
ACCEL_M_CTRL_REG1 = 0x5B
ACCEL_M_CTRL_REG2 = 0x5C
ACCEL_WHOAMI_VAL = 0xC7

function ACC:new()
   local obj = {port=storm.i2c.INT, addr = 0x3c, 
                reg=REG:new(storm.i2c.INT, 0x3c)}
   setmetatable(obj, self)
   self.__index = self
   return obj
end

function ACC:init()
    --[[print(ACCEL_WHOAMI)
    print(ACCEL_WHOAMI_VAL)
    local tmp = self.reg:r(ACCEL_WHOAMI)
    assert (tmp == ACCEL_WHOAMI_VAL, "accelerometer insane")
]]--
    --lets put it into standby
    self.reg:w(ACCEL_CTRL_REG1, 0x00);

    --Config magnetometer
    self.reg:w(ACCEL_M_CTRL_REG1, 0x1f)
    self.reg:w(ACCEL_M_CTRL_REG2, 0x20)

    --config accelerometer
    self.reg:w(ACCEL_XYZ_DATA_CFG, 0x01)

    --go out of standby
    self.reg:w(ACCEL_CTRL_REG1, 0x0D)
end

function ACC:get()
    -- lets be efficient and read all 6 values
    local addr = storm.array.create(1, storm.array.UINT8)
    addr:set(1, ACCEL_OUT_X_MSB)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(12, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local ax = dat:get_as(storm.array.INT16_BE, 0)
    local ay = dat:get_as(storm.array.INT16_BE, 2)
    local az = dat:get_as(storm.array.INT16_BE, 4)
    local mx = dat:get_as(storm.array.INT16_BE, 6)
    local my = dat:get_as(storm.array.INT16_BE, 8)
    local mz = dat:get_as(storm.array.INT16_BE, 10)
    return ax, ay, az, mx, my, mz
end

return ACC