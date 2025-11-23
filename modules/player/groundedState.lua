local GROUNDED = {}

function GROUNDED.enter(player, dt)
   
end

function GROUNDED.update(player, dt)
   if CONTROLS.isDown("jump") then
      if not player.holdingJump and player.onGround then
         return "jump"
      end
      player.holdingJump = true
    else
      player.holdingJump = false
   end

   --> TEMPORARY
   --[
   if player.targetItem and CONTROLS.isDown("run") and love.keyboard.isDown("q") then
      return "pickup"
   end
   --]]

   return
end


return GROUNDED