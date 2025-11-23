function math.sign(x, default)
   if x > 0 then
      return 1
   end
   if x < 0 then
      return -1
   end
   if x == 0 or not x then
      return default or 0
   end
end

function math.clamp(n, min, max)
   return math.min(math.max(n, min), max)
end

function math.lerp(a, b, t)
   return a + (b - a) * t
end


function impulseForHeight(height) --> in tiles
   return math.sqrt(2 * math.abs(GRAVITY * height * 16))
end


function loadMap(map)
   GAME_MAP = STI(map)

   local mapPaletteName = GAME_MAP.layers["Palette"].properties.map
   local characterPaletteVariant = GAME_MAP.layers["Palette"].properties.character
   local characterPaletteName = player.character .. "_" .. characterPaletteVariant

   PALETTES.map = love.graphics.newImage("sprites/palettes/map/" .. mapPaletteName .. ".png") or PALETTES.map
   PALETTES.character = love.graphics.newImage("sprites/palettes/character/" .. characterPaletteName .. ".png") or PALETTES.character

   ITEMS = {}
   for _, object in pairs(GAME_MAP.layers["Mushrooms"].objects) do
      local item = ITEM.new("mushroomblock1", object.x, object.y)
      table.insert(ITEMS, item)
   end

   WALLS = {}
   WALLS.solid = {}
   WALLS.semisolid = {}

   --> Add walls around the map
   local wall = WORLD:newRectangleCollider(
      -50,
      -50,
      50,
      GAME_MAP.height * GAME_MAP.tilewidth + 100
   )
   wall:setType("static")
   table.insert(WALLS.solid, wall)

   wall = WORLD:newRectangleCollider(
      GAME_MAP.width * GAME_MAP.tilewidth,
      -50,
      50,
      GAME_MAP.height * GAME_MAP.tilewidth + 100
   )
   wall:setType("static")
   table.insert(WALLS.solid, wall)

   --[[
   --> Ceiling
   wall = WORLD:newRectangleCollider(
      -50,
      -50,
      GAME_MAP.width * GAME_MAP.tilewidth + 100,
      50
   )
   wall:setType("static")
   table.insert(WALLS.solid, wall)
   --]]

   if GAME_MAP.layers["SolidCollision"] then
      for _, object in pairs(GAME_MAP.layers["SolidCollision"].objects) do
         wall = WORLD:newRectangleCollider(
            object.x,
            object.y,
            object.width,
            object.height
         )
         wall:setType("static")
         wall:setCollisionClass("Solid")
         table.insert(WALLS.solid, wall)
      end
   end

   if GAME_MAP.layers["SemiSolidCollision"] then
      for _, object in pairs(GAME_MAP.layers["SemiSolidCollision"].objects) do
         wall = WORLD:newRectangleCollider(
            object.x,
            object.y,
            object.width,
            1
         )
         wall:setType("static")
         wall:setCollisionClass("SemiSolid")
         table.insert(WALLS.semisolid, wall)
      end
   end

   if GAME_MAP.layers["Spawn"] then
      if #GAME_MAP.layers["Spawn"].objects > 0 then
         local object = GAME_MAP.layers["Spawn"].objects[1]
         player.collider:setPosition(
            object.x + object.width  / 2,
            object.y + object.height / 2
         )
      end
   end
end


function love.load()
   windfield = require("libraries/windfield")
   anim8 = require("libraries/anim8")
   CONTROLS = require("modules/player/controls")
   STI = require("libraries/sti")
   CAMERA = require("libraries/camera")(0, 0, 3)
   VECTOR = require("libraries/vector")

   ITEM = require("modules/items/item")
   
   love.physics.setMeter(16)
   GRAVITY = 60 * 16
   WORLD = windfield.newWorld(0, GRAVITY)
   WORLD:addCollisionClass("Player")
   WORLD:addCollisionClass("Solid")
   WORLD:addCollisionClass("SemiSolid")
   WORLD:addCollisionClass("Item")
   
   --> NES screen resolution (PAL) 256x224
   GAME_X, GAME_Y = 256, 224
   WINDOW_X, WINDOW_Y = GAME_X * CAMERA.scale, GAME_Y * CAMERA.scale
   FULLSCREEN = false

   love.window.setTitle("Platformer")
   love.window.setMode(WINDOW_X, WINDOW_Y, {fullscreen = FULLSCREEN, resizable = true})
   love.graphics.setDefaultFilter("nearest")
   love.window.setIcon(love.image.newImageData("sprites/Mini DRENICO novo 40x40.png"))
   
   PALETTES = {}
   PALETTES.charge = love.graphics.newImage("sprites/palettes/character/charge.png")

   player = require("modules/player/player")
   player.setCharacter("mario")

   SPRITES = {}
   SPRITES.sky = love.graphics.newImage("sprites/tiles/sky.png")
   SPRITES.door = love.graphics.newImage("sprites/tiles/door.png")

   loadMap("maps/1-1/map2.lua")

   SHADERS = {}
   SHADERS.palette = love.graphics.newShader(require("shaders/palette"))
   SHADERS.pixelate = love.graphics.newShader(require("shaders/pixelate"))
end


function clampCamera()
   local mapWidth = GAME_MAP.width * GAME_MAP.tilewidth
   local mapHeight = GAME_MAP.height * GAME_MAP.tileheight
   
   local minX, minY = GAME_X / 2, GAME_Y / 2
   local maxX, maxY = mapWidth - GAME_X / 2, mapHeight - GAME_Y / 2

   if minX > maxX then
      CAMERA.x = math.floor(mapWidth / 2 + 0.5)
   else
      CAMERA.x = math.clamp(CAMERA.x, minX, maxX)
   end

   if minY > maxY then
      CAMERA.y = maxY
      --CAMERA.y = math.floor(mapHeight / 2 + 0.5)
   else
      CAMERA.y = math.clamp(CAMERA.y, minY, maxY)
   end
end


function love.update(dt)
   WINDOW_X, WINDOW_Y = love.window.getMode()
   GAME_X, GAME_Y = WINDOW_X / CAMERA.scale, WINDOW_Y / CAMERA.scale

   player.update(dt)
   WORLD:update(dt)
   player.x, player.y = player.collider:getPosition()
   
   for _, item in pairs(ITEMS) do
      item:update(dt)
   end

   --> TEMPORARY
   if player.heldItem then
      local offset = (player.crouching <= 0) and -14 or -4
      player.heldItem.collider:setPosition(player.x, player.y + offset)
   end

   CAMERA:lookAt(player.x, player.y)
   clampCamera()
end


function love.draw()
   love.graphics.setShader(SHADERS.pixelate)
   SHADERS.pixelate:send("palette", PALETTES.map)

   love.graphics.draw(
      SPRITES.sky,
      0, 0,
      0,
      WINDOW_X, WINDOW_Y
      --[[
      GAME_MAP.width  * GAME_MAP.tilewidth,
      GAME_MAP.height * GAME_MAP.tilewidth
      --]]
   )

   CAMERA:attach()
      GAME_MAP:drawLayer(GAME_MAP.layers["Background"])
      GAME_MAP:drawLayer(GAME_MAP.layers["Solid"])
      
      for _, object in pairs(GAME_MAP.layers["Doors"].objects) do
         love.graphics.draw(
            SPRITES.door,
            object.x, object.y
         )
      end

      player.draw()
      SHADERS.pixelate:send("palette", PALETTES.map)

      for _, item in pairs(ITEMS) do
         item:draw()
      end

      --WORLD:draw()
   CAMERA:detach()
end


function love.keypressed(key)
   if key == "f11" then
      FULLSCREEN = not FULLSCREEN
      love.window.setFullscreen(FULLSCREEN)
   end
   --CONTROLS.updateKey(key)
end