local JUMP = {}

function JUMP.enter(player, dt)
   player.jumping = player.jumping + dt
   player.holdingJump = true

   local jumpHeight = player.maxJumpHeight
   if player.crouching >= player.chargeTime then
      jumpHeight = player.chargedJumpHeight
      player.crouching = 0
   end

   local impulse = impulseForHeight(jumpHeight)
   player.collider:applyLinearImpulse(0, -impulse)
end

function JUMP.update(player, dt)
   if CONTROLS.isDown("jump") then
      if player.jumping > 0 then
         player.jumping = player.jumping + dt
      else
         player.holdingJump = true
      end
   else
      player.holdingJump = false
   end
   
   if player.onGround then
      player.jumping = 0
      player.jumpDone = false
      return "grounded"
   end

   if (not player.jumpDone) and (not player.holdingJump) and (player.jumping > 0) then
      --> Cut jump short
      local velocity = VECTOR.new(player.collider:getLinearVelocity())
      local desiredVelocityY = -impulseForHeight(player.minJumpHeight)

      if velocity.y < desiredVelocityY then
         player.collider:applyLinearImpulse(0, desiredVelocityY - velocity.y)
         player.jumpDone = true
      end
   end
end

return JUMP