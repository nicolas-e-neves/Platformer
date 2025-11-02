CONTROLS = {}

CONTROLS.actions = {}
CONTROLS.actions.up = {}
CONTROLS.actions.up.value = 0
CONTROLS.actions.up.keys = {"w"}

CONTROLS.actions.left = {}
CONTROLS.actions.left.value = 0
CONTROLS.actions.left.keys = {"a"}

CONTROLS.actions.down = {}
CONTROLS.actions.down.value = 0
CONTROLS.actions.down.keys  = {"s"}

CONTROLS.actions.right = {}
CONTROLS.actions.right.value = 0
CONTROLS.actions.right.keys = {"d"}

CONTROLS.actions.jump = {}
CONTROLS.actions.jump.value = 0
CONTROLS.actions.jump.keys = {"space"}


function CONTROLS.updateKey(key)
   for control, buttonTable in pairs(CONTROLS.actions) do
      for _, button in pairs(buttonTable) do
         if key == button then
            
         end
      end
   end
end


function CONTROLS.isDown(control)
   local buttonTable = CONTROLS.actions[control].keys
   if not buttonTable then return false end

   for _, button in pairs(buttonTable) do
      if love.keyboard.isDown(button) then
         return true
      end
   end
   return false
end


function CONTROLS.getJoystick()
   local up    = CONTROLS.isDown("up")    and -1 or 0
   local left  = CONTROLS.isDown("left")  and -1 or 0
   local down  = CONTROLS.isDown("down")  and  1 or 0
   local right = CONTROLS.isDown("right") and  1 or 0

   local horizontal = right + left
   local vertical = down + up

   if math.abs(horizontal) > 0 and math.abs(vertical) > 0 then
      local magnitude = math.sqrt(horizontal^2 + vertical^2)
      horizontal = horizontal / magnitude
      vertical = vertical / magnitude
   end
   
   return {x = horizontal, y = vertical}
end


return CONTROLS