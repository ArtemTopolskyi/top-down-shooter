function love.load()
  gameTimer = 0

  fonts = {
    system = love.graphics.newFont(10),
  }

  screen = {
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),
  }

  sprites = {
    player = love.graphics.newImage("sprites/player.png"),
    zombie = love.graphics.newImage("sprites/zombie.png"),
    bullet = love.graphics.newImage("sprites/bullet.png"),
    background = love.graphics.newImage("sprites/background.png"),
  }

  player = {
    width = sprites.player:getWidth(),
    height = sprites.player:getHeight(),
    x = screen.width / 2,
    y = screen.height / 2,
    movementSpeed = 200,
    rotation = math.pi / 2,
  }

  zombies = {}
  bullets = {}
end

function love.update(dt)
  gameTimer = gameTimer + dt

  handlePlayerMovement(dt)

  handlePlayerRotation()

  handleZombieMovement(dt)

  handleZombieRotation()

  handleBullets(dt)

  handleDistanceBetweenPlayerAndZombies()

  handleCollisionBetweenBulletAndZombies()
end

function love.draw()
  renderBackground()

  renderZombies()

  renderPlayer()

  renderBullets()

  renderFPS()
end

function love.mousepressed(x, y, button)
  if button == 1 then
    shootBullet()
  end

  if button == 2 then
    spawnZombie()
  end
end

function renderBackground()
  love.graphics.draw(sprites.background, 0, 0)
end

function renderFPS()
  love.graphics.setFont(fonts.system)
  love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), screen.width - 50, 10)
end

function renderPlayer()
  love.graphics.draw(
    sprites.player,
    player.x,
    player.y,
    player.rotation,
    nil,
    nil,
    player.width / 2,
    player.height / 2
  )
end

function renderZombies()
  for _, zombie in ipairs(zombies) do
    love.graphics.draw(
      sprites.zombie,
      zombie.x,
      zombie.y,
      zombie.rotation,
      nil,
      nil,
      sprites.zombie:getWidth() / 2,
      sprites.zombie:getHeight() / 2
    )
  end
end

function renderBullets()
  for _, bullet in ipairs(bullets) do
    love.graphics.draw(
      sprites.bullet,
      bullet.x,
      bullet.y,
      bullet.direction,
      0.2,
      0.2,
      sprites.bullet:getWidth() / 2,
      sprites.bullet:getHeight() / 2
    )
  end
end

function handlePlayerMovement(dt)
  if love.keyboard.isDown("w") then
    player.y = player.y - player.movementSpeed * dt
  end

  if love.keyboard.isDown("s") then
    player.y = player.y + player.movementSpeed * dt
  end

  if love.keyboard.isDown("a") then
    player.x = player.x - player.movementSpeed * dt
  end

  if love.keyboard.isDown("d") then
    player.x = player.x + player.movementSpeed * dt
  end

  if player.x < 0 then
    player.x = 0
  end

  if player.x > screen.width then
    player.x = screen.width
  end

  if player.y < 0 then
    player.y = 0
  end

  if player.y > screen.height then
    player.y = screen.height
  end
end

function handlePlayerRotation()
  player.rotation = calculateAngleBetweenPlayerAndMouse()
end

function handleZombieMovement(dt)
  for _, zombie in ipairs(zombies) do
    zombie.x = zombie.x + (math.cos(zombie.rotation) * zombie.movementSpeed * dt)
    zombie.y = zombie.y + (math.sin(zombie.rotation) * zombie.movementSpeed * dt)
  end
end

function handleZombieRotation()
  for _, zombie in ipairs(zombies) do
    zombie.rotation = calculateAngleBetweenZombieAndPlayer(zombie)
  end
end

function handleDistanceBetweenPlayerAndZombies()
  for _, zombie in ipairs(zombies) do
    local distance = distanceBetweenPoints(player.x, player.y, zombie.x, zombie.y)

    if distance < (player.width / 2 + zombie.width / 2) then
      print("player is dead")
      zombies = {}
    end
  end
end

function handleBullets(dt)
  for i = #bullets, 1, -1 do  -- Iterate backward for safe removal
    local bullet = bullets[i]

    -- Update bullet position
    bullet.x = bullet.x + (math.cos(bullet.direction) * bullet.speed * dt)
    bullet.y = bullet.y + (math.sin(bullet.direction) * bullet.speed * dt)

    -- Remove bullet if it leaves the screen boundaries
    local isBulletOutsideScreen = (
      bullet.x < 0
        or bullet.x > screen.width
        or bullet.y < 0
        or bullet.y > screen.height
    )

    if isBulletOutsideScreen then
      table.remove(bullets, i)
    end
  end
end

function handleCollisionBetweenBulletAndZombies()
  for i, bullet in ipairs(bullets) do
    for j, zombie in ipairs(zombies) do
      local distance = distanceBetweenPoints(bullet.x, bullet.y, zombie.x, zombie.y)

      if (distance < (bullet.width / 2 + zombie.width / 2)) then
        zombie.dead = true
        bullet.aimedZombie = true
      end
    end
  end

  for i = #bullets, 1, -1 do
    local bullet = bullets[i]

    if bullet.aimedZombie then
      table.remove(bullets, i)
    end
  end

  for i = #zombies, 1, -1 do
    local zombie = zombies[i]

    if zombie.dead then
      table.remove(zombies, i)
    end
  end
end

function calculateAngleBetweenPlayerAndMouse()
  local mouseX, mouseY = love.mouse.getPosition()
  local angle = math.atan2(mouseY - player.y, mouseX - player.x)

  return angle
end

function calculateAngleBetweenZombieAndPlayer(zombie)
  local angle = math.atan2(player.y - zombie.y, player.x - zombie.x)

  return angle
end

function distanceBetweenPoints(x1, y1, x2, y2)
  return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function spawnZombie()
  local newZombie = {
    x = love.math.random(0, screen.width),
    y = love.math.random(0, screen.height),
    width = sprites.zombie:getWidth(),
    height = sprites.zombie:getHeight(),
    rotation = 0,
    movementSpeed = 100,
    dead = false,
  }

  newZombie.rotation = calculateAngleBetweenZombieAndPlayer(newZombie)

  table.insert(zombies, newZombie)
end

function shootBullet()
  local bullet = {
    x = player.x,
    y = player.y,
    width = sprites.bullet:getWidth() / 5, -- as we scale the bullet to 0.2 in render function
    height = sprites.bullet:getHeight() / 5,
    direction = player.rotation,
    speed = 700,
    aimedZombie = false,
  }

  table.insert(bullets, bullet)
end
