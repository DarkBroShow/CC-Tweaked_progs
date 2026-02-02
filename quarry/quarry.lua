-- quarry.lua
-- Usage:
--   quarry                -> show help
--   quarry <x> <y> <z>    -> mine a quarry X(right) x Y(down) x Z(forward)
--
-- Assumptions:
-- - Turtle starts directly in front of a chest (the chest is BEHIND the turtle).
-- - Turtle will dig starting ONE BLOCK BELOW its starting Y level.
-- - Fuel:
--     slot 1 = blocks of coal (preferred)
--     slots 2-3 = other fuel (coal, wood, etc.)
-- - Turtle will return to the starting position and dump items into the chest.

local args = { ... }

local function printUsage()
  print("Quarry turtle program")
  print()
  print("Usage:")
  print("  quarry <x> <y> <z>")
  print()
  print("  x - width  (right)")
  print("  y - depth  (down)")
  print("  z - length (forward)")
end

if #args < 3 then
  printUsage()
  return
end

local targetX = tonumber(args[1])
local targetY = tonumber(args[2])
local targetZ = tonumber(args[3])

if not targetX or not targetY or not targetZ or
   targetX <= 0 or targetY <= 0 or targetZ <= 0 then
  print("Invalid arguments.")
  printUsage()
  return
end

-- ========== State ==========

local startX, startY, startZ = 0, 0, 0     -- local coords, start is (0,0,0)
local x, y, z = 0, 0, 0                    -- current local coords
local dir = 0                              -- 0=+Z, 1=+X, 2=-Z, 3=-X

-- ========== Trash setup ==========

local TRASH = {
  ["minecraft:cobblestone"] = true,
  ["minecraft:deepslate"]   = true,
  ["minecraft:tuff"]        = true,
  ["minecraft:dirt"]        = true,
  ["minecraft:gravel"]      = true,
}

local function isTrash(detail)
  return detail and TRASH[detail.name]
end

-- ========== Helpers: movement & orientation ==========

local function refuelFromSlot(slot)
  if turtle.getItemCount(slot) == 0 then return false end
  turtle.select(slot)
  local ok = turtle.refuel(1)
  if not ok then
    turtle.select(1)
    return false
  end
  -- съесть весь стак, если это топливо
  while turtle.getItemCount(slot) > 0 and turtle.refuel(1) do end
  turtle.select(1)
  return true
end

local function refuelIfNeeded()
  if turtle.getFuelLevel() == "unlimited" then return end
  if turtle.getFuelLevel() > 50 then return end

  -- 1) Пытаемся сначала из блоков угля в слоте 1
  if refuelFromSlot(1) then return end

  -- 2) Потом пробуем слоты 2–3 как обычное топливо
  if refuelFromSlot(2) then return end
  if refuelFromSlot(3) then return end
end

local function tryForward()
  while true do
    refuelIfNeeded()
    if turtle.forward() then
      if dir == 0 then z = z + 1
      elseif dir == 1 then x = x + 1
      elseif dir == 2 then z = z - 1
      elseif dir == 3 then x = x - 1
      end
      return true
    else
      -- try to dig or attack
      if turtle.detect() then
        turtle.dig()
      else
        turtle.attack()
      end
      sleep(0.2)
    end
  end
end

local function tryUp()
  while true do
    refuelIfNeeded()
    if turtle.up() then
      y = y - 1
      return true
    else
      if turtle.detectUp() then
        turtle.digUp()
      else
        turtle.attackUp()
      end
      sleep(0.2)
    end
  end
end

local function tryDown()
  while true do
    refuelIfNeeded()
    if turtle.down() then
      y = y + 1
      return true
    else
      if turtle.detectDown() then
        turtle.digDown()
      else
        turtle.attackDown()
      end
      sleep(0.2)
    end
  end
end

local function turnRight()
  turtle.turnRight()
  dir = (dir + 1) % 4
end

local function turnLeft()
  turtle.turnLeft()
  dir = (dir + 3) % 4
end

local function faceDir(targetDir)
  while dir ~= targetDir do
    turnRight()
  end
end

-- move in straight line on local coords
local function goTo(xTarget, yTarget, zTarget)
  -- move vertically first
  while y < yTarget do
    tryDown()
  end
  while y > yTarget do
    tryUp()
  end

  -- move in X
  if xTarget > x then
    faceDir(1) -- +X
    while x < xTarget do
      tryForward()
    end
  elseif xTarget < x then
    faceDir(3) -- -X
    while x > xTarget do
      tryForward()
    end
  end

  -- move in Z
  if zTarget > z then
    faceDir(0) -- +Z
    while z < zTarget do
      tryForward()
    end
  elseif zTarget < z then
    faceDir(2) -- -Z
    while z > zTarget do
      tryForward()
    end
  end
end

-- ========== Inventory / chest handling ==========

local function trashInventory()
  for slot = 4, 16 do
    local detail = turtle.getItemDetail(slot)
    if detail and isTrash(detail) then
      turtle.select(slot)
      turtle.drop()  -- drop forward; change to dropDown/dropUp if needed
    end
  end
  turtle.select(1)
end

local function dropAllToChestBehind()
  -- Face negative Z (assuming chest is behind initial facing)
  -- At start we assume dir == 0 (+Z), so chest is at -Z.
  -- Make sure we face chest:
  faceDir(2) -- -Z
  for slot = 4, 16 do
    if turtle.getItemCount(slot) > 0 then
      turtle.select(slot)
      turtle.drop()
    end
  end
  turtle.select(1)
end

local function returnToBaseAndDump()
  goTo(startX, startY, startZ)
  dropAllToChestBehind()
end

local function isInventoryFull()
  for slot = 4, 16 do
    if turtle.getItemCount(slot) == 0 then
      return false
    end
  end
  return true
end

local function checkInventoryAndDumpIfFull()
  -- 1) Try to trash cobblestone / deepslate / etc.
  trashInventory()

  -- 2) If still full -> go dump to chest and return
  if isInventoryFull() then
    returnToBaseAndDump()
    -- go back to current working Y level one block below start
    goTo(0, 1, 0)
  end
end

-- ========== Quarry logic ==========

local function digLayer()
  -- snake pattern on X/Z at current y
  for dz = 0, targetZ - 1 do
    if dz > 0 then
      -- move to next row
      if dz % 2 == 1 then
        faceDir(1) -- +X
      else
        faceDir(3) -- -X
      end
      tryForward()
      checkInventoryAndDumpIfFull()
    end

    -- mine along X
    if dz % 2 == 0 then
      -- from x=0 to x=targetX-1
      faceDir(1) -- +X
      while x < targetX - 1 do
        if turtle.detectDown() then turtle.digDown() end
        if turtle.detect() then turtle.dig() end
        tryForward()
        checkInventoryAndDumpIfFull()
      end
      -- dig under last position
      if turtle.detectDown() then turtle.digDown() end
    else
      -- from x=targetX-1 to x=0
      faceDir(3) -- -X
      while x > 0 do
        if turtle.detectDown() then turtle.digDown() end
        if turtle.detect() then turtle.dig() end
        tryForward()
        checkInventoryAndDumpIfFull()
      end
      if turtle.detectDown() then turtle.digDown() end
    end
  end
end

local function runQuarry()
  -- initial: go one block down to start below surface
  tryDown()  y = 1

  for layer = 1, targetY do
    digLayer()
    if layer < targetY then
      -- go one layer deeper
      -- move to origin in X/Z of current layer
      goTo(0, y, 0)
      if turtle.detectDown() then turtle.digDown() end
      tryDown()
    end
  end

  -- finish: return to base and dump
  returnToBaseAndDump()
  -- face original direction (+Z)
  faceDir(0)
end

-- ========== Entry point ==========

print("Starting quarry "..targetX.."x"..targetY.."x"..targetZ.."...")
runQuarry()
print("Quarry complete.")
