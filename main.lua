local Input = require 'input'

local lg = love.graphics

local x, y
local app_input = Input.new()
local bubbles = {}

local random = love.math.random
local NewBubble = function(bx, by, r)
  return {
    x = bx, y = by, r = r,
    life = 10,
    color = { 0.5 + random() * 0.5, 0.5 + random() * 0.5, 0.5 + random() * 0.5, 0.5 }
  }
end

function love.load()
  Input.bind_events()
  x, y = lg.getDimensions()
  x, y = x / 2, y / 2

  app_input:bind('kb_x', function()
    if Input.down('a') then
      return true, math.min(-1, Input.duration('a'))
    elseif Input.down('d') then
      return true, math.max(1, Input.duration('d'))
    end
  end)

  app_input:bind('kb_y', function()
    if Input.down('w') then
      return true, math.min(-1, Input.duration('w'))
    elseif Input.down('s') then
      return true, math.max(1, Input.duration('s'))
    end
  end)
end

function love.update(dt)
  local is_down, val = Input.down('wheelx')
  if is_down then x = x + val end
  is_down, val = Input.down('wheely')
  if is_down then y = y + val end
  if Input.released('mouse1') then
    x, y = love.mouse.getPosition()
  end
  is_down, val = app_input:check('kb_x')
  if is_down then x = x + val end
  is_down, val = app_input:check('kb_y')
  if is_down then y = y + val end

  if Input.released('r') then
    x, y = lg.getDimensions()
    x, y = x / 2, y / 2
  end

  local yes, duration
  if Input.down('space', 3) then
    Input.keyreleased('space')
    yes, duration = true, 5
  else
    yes, duration = Input.released('space')
  end
  if yes then
    bubbles[#bubbles + 1] = NewBubble(x, y, duration * 50)
  end

  if Input.down('1', 1) then
    bubbles[#bubbles + 1] = NewBubble(x, y, 25)
  end

  if Input.down('2', 1, 0.5) then
    bubbles[#bubbles + 1] = NewBubble(x, y, 50)
  end

  local ts = love.timer.getTime()
  for i = #bubbles, 1, -1 do
    local b = bubbles[i]
    b.life = b.life - dt
    if b.life <= 0 then
      table.remove(bubbles, i)
    else
      b.y = b.y - 10 * dt
      b.x = b.x + math.sin(ts) * 5 * dt
    end
  end
end

function love.draw()
  lg.circle('line', x, y, 5)

  for i, b in ipairs(bubbles) do
    lg.setColor(unpack(b.color))
    lg.circle('fill', b.x, b.y, b.r)
  end
  lg.setColor(1, 1, 1, 1)

  local str = ''
  local down_keys = {}
  for i, key in ipairs(Input.get_pressed_keys()) do
    local desc = string.format('%s[%.2f]', key, Input.duration(key))
    local _is_down, data = Input.down(key)
    if type(data) == 'number' then
      desc = desc..string.format(': %.2f', data)
    end
    down_keys[#down_keys + 1] = desc
  end
  str = str..'\ndown keys: '..table.concat(down_keys, ', ')
  str = str..'\nbubbles: '..#bubbles
  lg.print(str, 10, 10)
end

