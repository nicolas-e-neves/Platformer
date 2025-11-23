local player = {}
player.x = 0
player.y = 0
player.spriteSize = {width = 16, height = 32}
player.colliderSize = {width = 10, height = 32}
player.horizontal = 1
player.vertical = -1

player.state = "grounded"
local states = {
   jump = require("modules/player/jumpState"), 
   grounded = require("modules/player/groundedState"),
   pickup = require("modules/player/pickupState")
}

--> in tiles
player.minJumpHeight = 1
player.maxJumpHeight = 3 + 4/16
player.chargedJumpHeight = 5 + 6/16
player.chargeTime = 1

player.jumpDone = false
player.holdingJump = false
player.jumpBufferDuration = 0.1
player.jumpBufferTimer = 0

player.jumping = 0
player.onGround = true
player.crouching = 0

player.heldItem = nil
player.targetItem = nil
player.pickupTimer = 0
player.throwing = 0

player.health = 2
player.powerup = "big"

player.acceleration = VECTOR.new(0,0)

player.maxSpeeds = {
   walking = 5 + 10/16,
   running = 8 + 7/16
}

--[[
   onFoot = 470,
   onFootTurning = 600,
   inAir = 410,
   inAirTurning = 500
]]

player.accelerations = {
   onFoot = 29 + 6/16,
   onFootTurning = 37 + 8/16,
   inAir = 25 + 10/16,
   inAirTurning = 31 + 4/16
}

player.deaccelerations = {
   onFoot = 31 + 4/16
}

function player.updateCollider()
   player.collider = WORLD:newRectangleCollider(player.x, player.y, player.colliderSize.width, player.colliderSize.height)
   player.collider:setFixedRotation(true)
   player.collider:setCollisionClass("Player")
   player.collider:setFriction(0)
   player.collider:setMass(1)

   player.collider:setPreSolve(function(collider_1, collider_2, contact)
      if collider_1.collision_class == 'Player' and collider_2.collision_class == 'SemiSolid' then
         local px, py = collider_1:getPosition()
         local ph = player.colliderSize.height
         local tx, ty = collider_2:getPosition() 
         local th = 1
         if py + ph/2 > ty - th/2 then contact:setEnabled(false) end
         return
      end

      local cantCollide = (collider_2.parentItem and collider_2.parentItem.pickedUp) or (collider_2.body:getType() == "dynamic")

      if cantCollide and collider_1.collision_class == 'Player' and collider_2.collision_class == 'Item' then
         contact:setEnabled(false)
         return
      end
  end)
end


function player.createAnimationGrid()
   local sheetWidth  = player.sprite:getWidth()
   local sheetHeight = player.sprite:getHeight()

   player.grid = anim8.newGrid(player.spriteSize.width, player.spriteSize.height, sheetWidth, sheetHeight)
   player.animationState = "idle"
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
         small = anim8.newAnimation(player.grid('1-2', 1), 0.05),
         big   = anim8.newAnimation(player.grid('1-2', 2), 0.05)
      },

      walkpickup = {
         small = anim8.newAnimation(player.grid('3-4', 1), 0.05),
         big   = anim8.newAnimation(player.grid('3-4', 2), 0.05)
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
end


function player.setCharacter(characterName)
   player.character = characterName
   player.sprite = love.graphics.newImage("sprites/characters/" .. player.character .. ".png")
   player.updateCollider()
   player.createAnimationGrid()
end


function decideAnimationState()
   if player.pickupTimer > 0 then
      if player.pickupTimer < 0.187 then
         return "crouchpickup"
      end
      return "pickup"
   end

   local pickup = (not player.heldItem) and "" or "pickup"

   if player.crouching > 0 then
      return "crouch" .. pickup
   end

   if player.throwing > 0 then
      return "throw"
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

   if math.abs(joystick[axis]) > 0 and not (player.crouching ~= 0 and player.pickupTimer ~= 0 and player.onGround) then
      local turning = (math.sign(velocity[axis]) ~= math.sign(joystick[axis])) and "Turning" or ""

      if player.onGround then
         player.acceleration[axis] = player.accelerations["onFoot" .. turning] * 16
      else
         player.acceleration[axis] = player.accelerations["inAir" .. turning] * 16
      end

      player.acceleration[axis] = player.acceleration[axis] * direction
      return
   end

   if not player.onGround or math.abs(velocity[axis]) == 0 then
      player.acceleration[axis] = 0
      return
   end

   --> Account for friction
   player.acceleration[axis] = player.deaccelerations.onFoot * 16 * -math.sign(velocity[axis])

   local timeToStop = velocity[axis] / -player.acceleration[axis]
   if timeToStop < dt then
      player.acceleration[axis] = -velocity[axis] / dt
   end
end


function player.update(dt)
   local joystick = CONTROLS.getJoystick()
   
   if player.pickupTimer <= 0 then
      player.horizontal = math.sign(joystick.x, player.horizontal)
      player.vertical = math.sign(joystick.y, player.vertical)
   end

   local velocity = VECTOR.new(player.collider:getLinearVelocity())
   updateAcceleration("x", joystick, velocity, dt)

   local atx = player.acceleration.x * dt

   local maxSpeedX = CONTROLS.isDown("run") and player.maxSpeeds.running or player.maxSpeeds.walking
   maxSpeedX = maxSpeedX * 16
   local newVelocityX = math.clamp(velocity.x + atx, -maxSpeedX, maxSpeedX)

   if player.pickupTimer <= 0 then
      player.collider:applyLinearImpulse(newVelocityX - velocity.x, 0)
   else
      player.collider:setLinearVelocity(0, 0)
      player.collider:applyForce(0, -GRAVITY)
   end

   local colliderWidth = 10

   player.onGround = false
   player.targetItem = nil

   if velocity.y <= 0 then
      local colliders = WORLD:queryRectangleArea(
         player.x - colliderWidth / 2,
         player.y + player.colliderSize.height / 2 - 1,
         colliderWidth,
         5,
         {"Solid", "SemiSolid", "Item"}
      )
      player.onGround = (#colliders > 0)

      for _, collider in pairs(colliders) do
         if collider.collision_class == "Item" and collider.parentItem and not collider.parentItem.pickedUp then
            player.targetItem = collider.parentItem
            break
         end
      end
   end

   --> Crouching is not a state
   if player.onGround then
      if CONTROLS.isDown("down") then
         player.crouching = player.crouching + dt
      else
         player.crouching = 0
      end
   else
      --> Prevent the player from charging in the air
      player.crouching = math.clamp(player.crouching, 0, dt)
   end
   
   --> Handling throwing items
   player.throwing = math.max(0, player.throwing - dt)
   if player.heldItem and CONTROLS.isDown("run") and love.keyboard.isDown("q") then
      player.heldItem.collider:setType("dynamic")
      player.heldItem.collider:setLinearVelocity(0, 0)

      local throwImpulse = 304
      player.heldItem.collider:applyLinearImpulse((throwImpulse + velocity.x) * player.horizontal, 0) --> TODO: calculate impulse for throwing
      
      player.heldItem.pickedUp = false
      player.heldItem = nil
      player.throwing = 0.167
   end

   --> TODO: Jump buffering and coyote time
   local newState = states[player.state].update(player, dt)
   if newState and newState ~= player.state then
      player.state = newState
      states[player.state].enter(player, dt)
   end

   player.animationState = decideAnimationState()
   player.animations[player.animationState][player.powerup]:update(dt)
end


function player.draw()
   --love.graphics.setColor(0,0.5,1,1)
   
   local position = VECTOR.new(player.collider:getPosition())
   local velocity = VECTOR.new(player.collider:getLinearVelocity())

   --[[
   if math.abs(velocity.x) <= 0.1 then
      position.x = math.floor(position.x + 0.5)
   end
   --]]
   if math.abs(velocity.y) <= 0.1 then
      position.y = math.floor(position.y + 0.5)
   end

   local palette = PALETTES.character
   if player.crouching > player.chargeTime and (30 * player.crouching) % 1 <= 0.5 then
      palette = PALETTES.charge
   end

   SHADERS.pixelate:send("palette", palette)
   player.animations[player.animationState][player.powerup]:draw(
      player.sprite,
      position.x, position.y,
      nil,
      player.horizontal, 1,
      player.spriteSize.width / 2, player.spriteSize.height / 2
   )
   
   --> Debugging
   --[[
   --love.graphics.rectangle("fill", player.x - player.size.width / 2, player.y - player.size.height / 2, player.size.width, player.size.height)
   if player.jumpDone then
      love.graphics.setColor(1,0,0,1)
      love.graphics.circle("fill", player.x, player.y - 20, 5)
      love.graphics.setColor(1,1,1,1)
   end
   --]]
end


return player