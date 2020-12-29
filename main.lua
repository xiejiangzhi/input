local Input = require 'input'

local lg = love.graphics

local x, y
local app_input = Input.new()
local bubbles = {}

function love.load()
  Input.bind_events()
  x, y = lg.getDimensions()
  x, y = x / 2, y / 2

  app_input:bind('kb_x', function()
    if Input.down('a') then
      return true, math.min(-1, Input.get_state_duration('a'))
    elseif Input.down('d') then
      return true, math.max(1, Input.get_state_duration('d'))
    end
  end)

  app_input:bind('kb_y', function()
    if Input.down('w') then
      return true, math.min(-1, Input.get_state_duration('w'))
    elseif Input.down('s') then
      return true, math.max(1, Input.get_state_duration('s'))
    end
  end)
end

function love.update(dt)
  local is_down, val = Input.get_state_info('wheelx')
  if is_down then x = x + val end
  is_down, val = Input.get_state_info('wheely')
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

  local yes, duration = Input.released('space')
  if yes then
    local random = love.math.random
    bubbles[#bubbles + 1] = {
      x = x, y = y,
      r = duration * 50,
      life = 10,
      color = { 0.5 + random() * 0.5, 0.5 + random() * 0.5, 0.5 + random() * 0.5, 0.5 }
    } end

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
    local desc = string.format('%s[%.2f]', key, Input.get_state_duration(key))
    local _is_down, data = Input.get_state_info(key)
    if type(data) == 'number' then
      desc = desc..string.format(': %.2f', data)
    end
    down_keys[#down_keys + 1] = desc
  end
  str = str..'\ndown keys: '..table.concat(down_keys, ', ')
  lg.print(str, 10, 10)
end

