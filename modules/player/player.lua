local player = {}
player.x = 0
player.y = 0
player.size = {width = 16, height = 32}
player.horizontal = 1
player.vertical = -1

--> in tiles
player.minJumpHeight = 1
player.maxJumpHeight = 4
player.jumpDone = false
player.holdingJump = false

player.jumping = 0
player.onGround = true
player.crouching = 0
player.holdingItem = false

player.state = "idle"
player.grid = anim8.newGrid(player.size.width, player.size.height, 192, 64)
player.animations = {
   idle = {
      small = anim8.newAnimation(player.grid('1-1',1), 1),
      big   = anim8.newAnimation(player.grid('1-1',2), 1)
   },

   idlepickup = {
      small = anim8.newAnimation(player.grid('3-3', 1), 1),
      big   = anim8.newAnimation(player.grid('3-3', 2), 1)
   },

   walk = {
      small = anim8.newAnimation(player.grid('1-2', 1), 0.08),
      big   = anim8.newAnimation(player.grid('1-2', 2), 0.08)
   },

   walkpickup = {
      small = anim8.newAnimation(player.grid('3-4', 1), 0.08),
      big   = anim8.newAnimation(player.grid('3-4', 2), 0.08)
   },
   
   fall = {
      small = anim8.newAnimation(player.grid('2-2', 1), 1),
      big   = anim8.newAnimation(player.grid('2-2', 2), 1)
   },

   fallpickup = {
      small = anim8.newAnimation(player.grid('4-4', 1), 1),
      big   = anim8.newAnimation(player.grid('4-4', 2), 1)
   },
   
   jump = {
      small = anim8.newAnimation(player.grid('4-4', 1), 1),
      big   = anim8.newAnimation(player.grid('4-4', 2), 1)
   },

   climb = {
      small = anim8.newAnimation(player.grid('5-5', 1), 0.2),
      big   = anim8.newAnimation(player.grid('5-5', 2), 0.2)
   },

   crouch = {
      small = anim8.newAnimation(player.grid('6-6', 1), 1),
      big   = anim8.newAnimation(player.grid('6-6', 2), 1)
   },

   crouchpickup = {
      small = anim8.newAnimation(player.grid('7-7', 1), 1),
      big   = anim8.newAnimation(player.grid('7-7', 2), 1)
   },

   pickup = {
      small = anim8.newAnimation(player.grid('8-8', 1), 1),
      big   = anim8.newAnimation(player.grid('8-8', 2), 1)
   },

   throw = {
      small = anim8.newAnimation(player.grid('9-9', 1), 1),
      big   = anim8.newAnimation(player.grid('9-9', 2), 1)
   },

   die = {
      small = anim8.newAnimation(player.grid('10-10', 1), 1),
      big   = anim8.newAnimation(player.grid('10-10', 1), 1)
   }
}

player.velocity = {x = 0, y = 0}
player.acceleration = {x = 0, y = 0}

player.maxSpeeds = {
   walking = 50,
   running = 210
}

player.accelerations = {
   onFoot = 180,
   onFootTurning = 600,
   inAir = 130,
   inAirTurning = 400
}

player.deaccelerations = {
   onFoot = 300
}


function player.setCharacter(characterName)
   player.character = characterName
   player.sprite = love.graphics.newImage("sprites/characters/" .. player.character .. ".png")

   player.collider = WORLD:newRectangleCollider(player.x, player.y, 10, 32)
   player.collider:setFixedRotation(true)
   player.collider:setCollisionClass("Player")
   player.collider:setFriction(0)
   player.collider:setMass(1)
end


function decideState()
   local pickup = player.holdingItem and "pickup" or ""

   if player.crouching > 0 then
      return "crouch" .. pickup
   end

   if player.jumping > 0 then
      return "jump"
   end

   local velocity = VECTOR.new(player.collider:getLinearVelocity())
   if math.abs(velocity.x) > 0 then
      if player.onGround then
         return "walk" .. pickup
      else
         return "fall" .. pickup
      end
   end

   return "idle" .. pickup
end


function updateAcceleration(axis, joystick, velocity, dt)
   local direction = (axis == "x") and player.horizontal or player.vertical

   if math.abs(joystick[axis]) > 0 and player.crouching == 0 then
      local turning = (math.sign(velocity[axis]) ~= math.sign(joystick[axis])) and "Turning" or ""

      if player.onGround then
         player.acceleration[axis] = player.accelerations["onFoot" .. turning]
      else
         player.acceleration[axis] = player.accelerations["inAir" .. turning]
      end

      player.acceleration[axis] = player.acceleration[axis] * direction
      return
   end

   if not player.onGround or math.abs(velocity[axis]) == 0 then
      player.acceleration[axis] = 0
      return
   end

   --> Account for friction
   player.acceleration[axis] = player.deaccelerations.onFoot * -math.sign(velocity[axis])

   local timeToStop = velocity[axis] / -player.acceleration[axis]
   if timeToStop < dt then
      player.acceleration[axis] = -velocity[axis] / dt
   end
end


function impulseForHeight(height) --> in tiles
   return math.sqrt(2 * math.abs(GRAVITY * (height * 16)))
end


function player.update(dt)
   local joystick = CONTROLS.getJoystick()
   
   player.horizontal = math.sign(joystick.x, player.horizontal)
   player.vertical = math.sign(joystick.y, player.vertical)

   local velocity = VECTOR.new(player.collider:getLinearVelocity())
   updateAcceleration("x", joystick, velocity, dt)

   local atx = player.acceleration.x * dt

   local maxSpeedX = player.maxSpeeds.running
   local newVelocityX = math.clamp(velocity.x + atx, -maxSpeedX, maxSpeedX)

   player.collider:applyLinearImpulse(newVelocityX - velocity.x, 0)

   local colliderWidth = 10
   local colliders = WORLD:queryRectangleArea(
      player.x - colliderWidth / 2,
      player.y + player.size.height / 2 - 1,
      colliderWidth,
      2,
      {"Solid"}
   )
   player.onGround = (#colliders > 0)

   --> TODO: Jump buffering and coyote time
   --> TODO: Separate in state machines
   if player.onGround then
      if CONTROLS.isDown("down") then
         player.crouching = player.crouching + dt
      else
         player.crouching = 0
      end

      player.jumpDone = false
      if CONTROLS.isDown("jump") then --> Start jump
         if not player.holdingJump then
            player.jumping = player.jumping + dt
            player.holdingJump = true

            local impulse = impulseForHeight(player.maxJumpHeight)
            player.collider:applyLinearImpulse(0, -impulse)
         else
            player.jumping = 0
         end
      else
         player.jumping = 0
         player.holdingJump = false
      end
   else
      if CONTROLS.isDown("jump") then --> Continue jump
         if player.jumping > 0 then
            player.jumping = player.jumping + dt
         else
            player.holdingJump = true
         end
      else
         player.holdingJump = false
      end
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

   player.state = decideState()
   player.animations[player.state].small:update(dt)
end


function player.draw()
   --love.graphics.setColor(0,0.5,1,1)
   
   player.animations[player.state].small:draw(
      player.sprite,
      player.x, player.y,
      nil,
      player.horizontal, 1,
      player.size.width / 2, player.size.height / 2
   )

   --> Debugging
   --[[
   if player.jumpDone then
      love.graphics.setColor(1,0,0,1)
      love.graphics.circle("fill", player.x, player.y - 20, 5)
      love.graphics.setColor(1,1,1,1)
   end
   --]]
end


return player