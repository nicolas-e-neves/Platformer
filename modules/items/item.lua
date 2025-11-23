local item = {}
item.__index = item

local MAX_BOUNCES = 1


function item.new(type, x, y, params)
   params = params or {}
   params.pickedUp = false
   params.bounces = 0
   params.onGround = true

   local self = setmetatable(params, item)
   self.type = type
   self.collider = WORLD:newRectangleCollider(x, y, 16, 16)
   self.collider:setFixedRotation(true)
   self.collider:setCollisionClass("Item")
   self.collider:setFriction(0)
   self.collider:setMass(1)
   self.collider:setType("static")
   self.collider.parentItem = self

   --[[
   self.collider:setPreSolve(function(collider_1, collider_2, contact)
      if collider_1.collision_class == "Item" and collider_2.collision_class == "Player" then
         error(self.collider.body:getType())
         if self.collider:getType() == "static" then
            self.collider:applyLinearImpulse(0, -10)
         end
         contact:setEnabled(false)
      end
   end)
   --]]
   return self
end


function item:update(dt)
   if self.collider.body:getType() == "static" then return end

   local velocity = VECTOR.new(self.collider:getLinearVelocity())
   if velocity.y > 0 then return end

   local position = VECTOR.new(self.collider:getPosition())
   local colliderWidth = 8
   local colliderHeight = 1

   local colliders = WORLD:queryRectangleArea(
      position.x - colliderWidth / 2,
      position.y + 8,
      colliderWidth,
      colliderHeight,
      {"Solid", "SemiSolid"}
   )
   self.onGround = (#colliders > 0)

   if self.onGround then
      if self.bounces < MAX_BOUNCES then
         self.bounces = self.bounces + 1
         self.collider:applyLinearImpulse(0, -impulseForHeight(0.5))
      else
         self.bounces = 0
         self.collider:setType("static")
         
         position.x = math.floor(position.x + 0.5)
         position.y = math.floor(position.y + 0.5)

         self.collider:setPosition(position.x, position.y)
      end
   end
end


function item:draw()
   local sprite = love.graphics.newImage("sprites/tiles/items/" .. self.type .. ".png")
   local position = VECTOR.new(self.collider:getPosition())

   love.graphics.draw(
      sprite,
      position.x, position.y,
      0,
      1, 1,
      8, 8
   )
end


return item