local r = require("robot_main")
local robot = require("robot")
local os = require("os")
local computer = require("computer")

local HEIGHT = 11
local WIDTH = 9

local function get_to_pos()
  r.left()
  r.relative_move(-8, 0, 0)
  r.up()
  r.up()
  r.relative_move(0, 0, 10)
  r.down()
  r.forward()
end

local function get_energy_level()
  return computer.energy() / computer.maxEnergy()
end

local function recharge(startx, starty, startz)
  print("Doing recharge")
  local x, y, z = r.get_coords()
  r.absolute_move(x, y, startz)
  r.absolute_move(x, starty, startz)
  r.absolute_move(startx, starty, startz)
  r.backward()
  r.up()
  r.relative_move(0, 0, -10)
  r.down()
  r.down()
  r.relative_move(8, 0, 0)
  r.right()
  while get_energy_level() < 0.99 do
    computer.beep()
    os.sleep(10)
  end
  get_to_pos()
  r.absolute_move(x, starty, startz)
  r.absolute_move(x, y, startz)
  r.absolute_move(x, y, z)
  print("Recharge done")
end

local function fill_bucket(startx, starty, startz)
  print("filling the bucket")
  local x, y, z = r.get_coords()
  print(x, y, z)
  print(startx, starty, startz)
  r.absolute_move(x, starty, z)
  print("first absolute move done")
  r.absolute_move(x, starty, startz)
  print("second absolute move done")
  r.absolute_move(startx, starty, startz)
  print("third absolute move done")
  r.backward()
  r.backward()
  print("backwards done")
  r.down()
  print("down done")
  while robot.tankLevel() ~= robot.tankSpace() do
    robot.drainDown()
    os.sleep(1)
  end
  r.up()
  r.forward()
  r.forward()
  r.absolute_move(x, starty, startz)
  r.absolute_move(x, starty, z)
  r.absolute_move(x, y, z)
end

local function place_water(startx, starty, startz)
  if robot.tankLevel() == 0 then
    fill_bucket(startx, starty, startz)
  end
  robot.fillDown()
end

local function fill_level(startx, starty, startz)
  for i=1, HEIGHT do
    place_water(startx, starty, startz)
    r.forward()
  end
  for i=2, WIDTH do
    r.right()
    place_water(startx, starty, startz)
  end
  local x, y, z = r.get_coords()
  r.absolute_move(x, y, startz)
  r.absolute_move(startx, y, startz)
end

local function main()
  get_to_pos()
  print("get_to_pos done")
  local startx, starty, startz = r.get_coords()
  print(startx, starty, startz)
  fill_bucket(startx, starty, startz)
  while true do
    local _, entity = r.detect_down()
    if entity == "solid" or entity == "liquid" then
      break
    end
    r.down()
  end
  print("Find down")
  r.up()
  -- Now we are directly above the last level without liquid.
  local _, cury, _ = r.get_coords()
  while cury ~= starty + 1 do
    print("Doing fill_level")
    fill_level(startx, starty, startz)
    if get_energy_level() < 0.4 then
      recharge(startx, starty, startz)
    end
    r.up()
    _, cury, _ = r.get_coords()
  end
end

r.set_main(main)
r.set_initial_dir(1)
r.turn_to_charger(true)
r.run()