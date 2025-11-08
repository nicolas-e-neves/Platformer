local GROUNDED = {}

function GROUNDED.enter(player, dt)
   
end

function GROUNDED.update(player, dt)
   if CONTROLS.isDown("jump") then
      if not player.holdingJump then
         return "jump"
      end
      player.holdingJump = true
    else
      player.holdingJump = false
   end

   return
end


return GROUNDED