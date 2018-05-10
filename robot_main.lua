local robot = require("robot")
local os = require("os")
local computer = require("computer")
local robot_main = {}
-- Constants
-- Since Lua numbers array from 1, we have to use this hack
local dx = {}
dx[0] = -1
dx[1] = 0
dx[2] = 1
dx[3] = 0
dx[4] = 0
dx[5] = 0
local dz = {}
dz[0] = 0
dz[1] = 1
dz[2] = 0
dz[3] = -1
dz[4] = 0
dz[5] = 0
local dy = {}
dy[0] = 0
dy[1] = 0
dy[2] = 0
dy[3] = 0
dy[4] = 1
dy[5] = -1
-- Constans end

local function main_stub()
  print("Please specify function to run, before launching drone")
  os.exit(1)
end

-- Initial parameters
robot_main.x = 0
robot_main.y = 0
robot_main.z = 0
robot_main.dir = 0
robot_main.main = main_stub
robot_main.face_charger = false
robot_main.initial_dir = 0
-- Initial parameters end

-- Internal methods

local function turn_to(turn)
  -- Perform optimal turn to specified dir
  local right_turns = turn - robot_main.dir
  if right_turns < 0 then
    right_turns = right_turns + 4
  end
  local left_turns = robot_main.dir - turn
  if left_turns < 0 then
    left_turns = left_turns + 4
  end
  if left_turns < right_turns then
    for i = 1, left_turns do
      robot.turnLeft()
    end
  else
    for i = 1, right_turns do
      robot.turnRight()
    end
  end
  robot_main.dir = turn
end

local function panic(err)
  for i=1,3 do
    computer.beep()
    os.sleep(1)
  end
  print("CRITICAL ERROR: "..err)
  -- TODO: write coredump
  os.exit(1)
end

local function move(dir)
  --[[
    Move to specified direction. 
    
    Move is not relative to the current direction of the robot.
  ]]
  if dir ~= 4 and dir ~= 5 then
    turn_to(dir)
  end
  repeat
    local ok, err
    if dir == 4 then
      ok, err = robot.up()
    else
      if dir == 5 then
        ok, err = robot.down()
      else
        ok, err = robot.forward()
      end
    end
    if not ok then
      if err == "entity" then
        computer.beep()
        os.sleep(1)
      else
        return nil, err
      end
    end
  until ok
  robot_main.x = robot_main.x + dx[dir]
  robot_main.y = robot_main.y + dy[dir]
  robot_main.z = robot_main.z + dz[dir]
  return true
end

local function greedy_move(dx, dy, dz) 
  print("Doing greedy move")
  print(dx, dy, dz)
  while dx ~= 0 or dy ~= 0 or dz ~= 0 do
    local ok = false
    if dy > 0 and move(4) then
      dy = dy - 1
      ok = true
    end
    if dy < 0 and move(5) then
      dy = dy + 1
      ok = true
    end
    if dx > 0 and move(2) then
      dx = dx - 1
      ok = true
    end
    if dx < 0 and move(0) then
      dx = dx + 1
      ok = true
    end
    if dz > 0 and move(1) then
      dz = dz - 1
      ok = true
    end
    if dz < 0 and move(3) then
      dz = dz + 1
      ok = true
    end
    if not ok then
      panic("Greedy move is stuck")
    end
  end
end

local function turn_to_charger()
  --[[
    Since opencomputers doesn't allow us to detect block id, we assume
    that the charger is the only solid block near robot
  ]]
  local success = false
  for dir = 0,3 do
    turn_to(dir)
    local _, blocktype = robot.detect()
    if blocktype == "solid" then
      success = true
      print("Charger found")
      break
    end
  end
  if not success then
    panic("Couldn't find the charger")
  end
end

local function init()
  print("Starting initialization")
  if robot_main.face_charger then
    print ("Locating charger")
    turn_to_charger()
  end
  robot_main.dir = robot_main.initial_dir
  print("Initialization complete")
end
-- Internal methods end



-- Library methods
function robot_main.run()
  --[[
    Main function of the lib.
    
    Run it after finishing setup to properly start your program.
  ]]
  init()
  robot_main.main()
end

function robot_main.set_initial_dir(dir)
  --[[
    Set the starting direction of robot to <dir>.
    
    Since robot coordinats are relative to the starting position,
    by default program assume, that robot face the forward direction,
    simular to setting dir=0.
    
    For example, if we do set_initial_dir(1), then after calling forward()
    robot will turn left and move.
  ]]
  robot_main.initial_dir = dir
end

-- Move block

function robot_main.forward()
  return move(0)
end

function robot_main.right()
  return move(1)
end

function robot_main.backward()
  return move(2)
end

function robot_main.left()
  return move(3)
end

function robot_main.up()
  return move(4)
end

function robot_main.down()
  return move(5)
end

-- Move block end

-- Turn block

function robot_main.turn_forward()
  turn_to(0)
end

function robot_main.turn_right()
  turn_to(1)
end

function robot_main.turn_backward()
  turn_to(2)
end

function robot_main.turn_left()
  turn_to(3)
end

-- Turn block end

-- Detect block

function robot_main.detect_forward()
  turn_to(0)
  return robot.detect()
end

function robot_main.detect_right()
  turn_to(1)
  return robot.detect()
end

function robot_main.detect_backward()
  turn_to(2)
  return robot.detect()
end

function robot_main.detect_left()
  turn_to(3)
  return robot.detect()
end

function robot_main.detect_up()
  return robot.detectUp()
end

function robot_main.detect_down()
  return robot.detectDown()
end

-- Detect block end

-- Drop block

function robot_main.drop_forward(count)
  turn_to(0)
  return robot.drop(count)
end

function robot_main.drop_right(count)
  turn_to(1)
  return robot.drop(count)
end

function robot_main.drop_backward(count)
  turn_to(2)
  return robot.drop(count)
end

function robot_main.drop_left(count)
  turn_to(3)
  return robot.drop(count)
end

function robot_main.drop_up(count)
  return robot.dropUp(count)
end

function robot_main.drop_down(count)
  return robot.dropDown(count)
end

-- Drop block end

-- Suck block

function robot_main.suck_forward(count)
  turn_to(0)
  return robot.suck(count)
end

function robot_main.suck_right(count)
  turn_to(1)
  return robot.suck(count)
end

function robot_main.suck_backward(count)
  turn_to(2)
  return robot.suck(count)
end

function robot_main.suck_left(count)
  turn_to(3)
  return robot.suck(count)
end

function robot_main.suck_up(count)
  return robot.suckUp(count)
end

function robot_main.suck_down(count)
  return robot.suckDown(count)
end
-- Suck block end

-- Place block
function robot_main.place_forward(side, sneaky)
  turn_to(0)
  return robot.place(side, sneaky)
end

function robot_main.place_right(side, sneaky)
  turn_to(1)
  return robot.place(side, sneaky)
end

function robot_main.place_backward(side, sneaky)
  turn_to(2)
  return robot.place(side, sneaky)
end

function robot_main.place_left(side, sneaky)
  turn_to(3)
  return robot.place(side, sneaky)
end

function robot_main.place_up(side, sneaky)
  return robot.placeUp(side, sneaky)
end

function robot_main.place_down(side, sneaky)
  return robot.placeDown(side, sneaky)
end
-- Place block end

-- Swing block
function robot_main.swing_forward(side, sneaky)
  turn_to(0)
  return robot.swing(side, sneaky)
end

function robot_main.swing_right(side, sneaky)
  turn_to(1)
  return robot.swing(side, sneaky)
end

function robot_main.swing_backward(side, sneaky)
  turn_to(2)
  return robot.swing(side, sneaky)
end

function robot_main.swing_left(side, sneaky)
  turn_to(3)
  return robot.swing(side, sneaky)
end

function robot_main.swing_up(side, sneaky)
  return robot.swingUp(side, sneaky)
end

function robot_main.swing_down(side, sneaky)
  return robot.swingDown(side, sneaky)
end
-- Swing block end

-- Duration block
function robot_main.use_forward(side, sneaky, duration)
  turn_to(0)
  return robot.use(side, sneaky, duration)
end

function robot_main.use_right(side, sneaky, duration)
  turn_to(1)
  return robot.use(side, sneaky, duration)
end

function robot_main.use_backward(side, sneaky, duration)
  turn_to(2)
  return robot.use(side, sneaky, duration)
end

function robot_main.use_left(side, sneaky, duration)
  turn_to(3)
  return robot.use(side, sneaky, duration)
end

function robot_main.use_up(side, sneaky, duration)
  return robot.useUp(side, sneaky, duration)
end

function robot_main.use_down(side, sneaky, duration)
  return robot.useDown(side, sneaky, duration)
end
-- Duration block end


-- Misc methods
function robot_main.get_coords()
  return robot_main.x, robot_main.y, robot_main.z
end

function robot_main.set_main(func)
  robot_main.main = func
end

function robot_main.turn_to_charger(val)
  robot_main.face_charger = val
end

function robot_main.get_coords_from_delta(dx, dy, dz)
  return robot_main.x + dx, robot_main.y + dy, robot_main.z + dz
end

function robot_main.relative_move(dx, dy, dz)
  greedy_move(dx, dy, dz)
end

function robot_main.absolute_move(x, y, z)
  greedy_move(x - robot_main.x, y - robot_main.y, z - robot_main.z)
end


-- Library methods end

return robot_main