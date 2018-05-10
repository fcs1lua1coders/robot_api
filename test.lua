local r = require("robot_main")

local function main()
  r.forward()
  r.forward()
  r.left()
  r.left()
end

r.set_main(main)
r.set_initial_dir(2)
r.turn_to_charger(true)
r.run()