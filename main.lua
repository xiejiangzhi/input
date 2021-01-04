local Input = require 'input'

Input.sequence_except_keys.mousemove = false
for i, k in ipairs({ 'a', 's', 'd', 'w' }) do
  Input.sequence_except_keys[k] = true
end
Input.multiple_gamepad = true

local lg = love.graphics

local x, y
local app_input = {
  actions = {},
  bind = function(self, action, fn)
    self.actions[action] = fn
  end,
  check = function(self, action)
    local fn = self.actions[action]
    if not fn then error("Invalid action "..tostring(action)) end
    return fn()
  end
}
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
  Input.bind_callbacks()

  x, y = lg.getDimensions()
  x, y = x / 2, y / 2

  app_input:bind('move_x', function()
    local is_down, _, duration = Input.down('a')
    if is_down then return -math.min(1, duration) end
    is_down, _, duration = Input.down('d')
    if is_down then return math.min(1, duration) end

    local val
    is_down, val = Input.down('wheelx')
    if is_down then return val end
    is_down, val = Input.down('leftx')
    if is_down then return val end
    return 0
  end)

  app_input:bind('move_y', function()
    local is_down, _, duration = Input.down('w')
    if is_down then return -math.min(1, duration) end
    is_down, _, duration = Input.down('s')
    if is_down then return math.min(1, duration) end

    local val
    is_down, val = Input.down('wheely')
    if is_down then return val end
    is_down, val = Input.down('lefty')
    if is_down then return val end
    return 0
  end)

  app_input:bind('new_bubble', function()
    local should_new, duration
    if Input.down('space', 3) then
      Input.keyreleased('space')
      return { { x, y, 200 } }
    else
      should_new, _, duration = Input.released('space')
      if should_new then
        print(1, duration)
        return { { x, y, math.max(duration, 0.1) * 50 } }
      end
    end

    if Input.down('1', 1) then
      return { { x, y, 25 } }
    end

    if Input.down('2', 1, 0.5) then
      return { x, y, 40 }
    end

    if Input.down('3', nil, 0.77) then
      return { { x, y, 40 } }
    end

    if Input.multidown({ 'lctrl', 'n' }, nil, 0.5) then
      return { { x, y, 60 } }
    end

    local pos
    should_new, pos = Input.multidown({ 'lctrl', 'mouse2' }, 0, 0.5)
    if should_new then
      return { { pos.x - 20, pos.y - 20, 60 }, { pos.x + 20, pos.y + 20, 60 } }
    end

    if Input.sequence({ '1', '2', 'q' }) then
      return { { x - 30, y + 20, 40 }, { x + 30, y + 20, 40 }, { x, y - 30, 40 } }
    end

    if Input.sequence({ '1', 'q' }) then
      return { { x, y, 80 } }
    end

    if Input.sequence({ '2', 'q' }, 0.1, 0.3) then
      return { { x - 30, y, 40 }, { x + 30, y, 40 } }
    end

    should_new, pos = Input.sequence({ 'rctrl', 'mousemove' })
    if should_new then
      return { { x + pos.dx * 50, y + pos.dy * 50, 40 } }
    end
  end)

end

function love.update(dt)
  local ov = 100 * dt
  x, y = x + app_input:check('move_x') * ov, y + app_input:check('move_y') * ov
  local is_down, val = Input.released('mouse1')
  if is_down then x, y = val.x, val.y end

  if Input.released('r') then
    x, y = lg.getDimensions()
    x, y = x / 2, y / 2
  end

  local new_data = app_input:check('new_bubble')
  if new_data then
    for i, args in ipairs(new_data) do
      bubbles[#bubbles + 1] = NewBubble(unpack(args))
    end
  end

  -- test performance
  if Input.down('f12') then
    local keys = { 'j', 'k', 'l', ';' }
    for i = 1, 1000 do
      Input.multidown(keys)
      Input.sequence(keys)
    end
  end

  if Input.pressed('x') then
    bubbles[#bubbles] = nil
  end

  local ts = love.timer.getTime()
  for i = #bubbles, 1, -1 do
    local b = bubbles[i]
    b.life = b.life - dt
    if b.life <= 0 then
      table.remove(bubbles, i)
    else
      b.y = b.y - 20 * dt
      b.x = b.x + math.sin(b.y * 0.1 + ts) * 20 * dt
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
  str = str..'\nFPS: '..love.timer.getFPS()
  str = str..string.format('\npos: %i, %i', x, y)
  local down_keys = {}
  for i, key in ipairs(Input.get_down_keys()) do
    local desc = string.format('%s[%.2f]', key, Input.duration(key))
    local _is_down, data = Input.down(key)
    if type(data) == 'number' then
      desc = desc..string.format(': %.2f', data)
    end
    down_keys[#down_keys + 1] = desc
  end
  str = str..'\ndown keys: '..table.concat(down_keys, ', ')
  str = str..'\nbubbles: '..#bubbles

  str = str..'\nbubbles: '..#bubbles
  local seq_keys = {}
  for i, info in ipairs(Input.get_history(8)) do
    seq_keys[#seq_keys + 1] = string.format('%s[%.2f]', info.key, info.interval or 0)
  end

  str = str..'\nhistory: '..table.concat(seq_keys, ', ')
  str = str..string.format('\nx duration: %.2f', Input.duration('x') or 0)
  str = str..string.format('\nleftx value: %.2f', Input.get_data('leftx') or 0)
  lg.print(str, 10, 10)
end

