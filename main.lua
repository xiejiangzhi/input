local Input = require 'input'

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
  is_down, val = app_input:check('kb_x')
  if is_down then x = x + val end
  is_down, val = app_input:check('kb_y')
  if is_down then y = y + val end
  is_down, val = Input.down('leftx')
  if is_down then x = x + val end
  is_down, val = Input.down('lefty')
  if is_down then y = y + val end
  if Input.released('mouse1') then x, y = love.mouse.getPosition() end

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
    bubbles[#bubbles + 1] = NewBubble(x, y, 40)
  end

  if Input.down('3', nil, 0.77) then
    bubbles[#bubbles + 1] = NewBubble(x, y, 40)
  end

  if Input.multidown({ 'lctrl', 'n' }, nil, 0.5) then
    bubbles[#bubbles + 1] = NewBubble(x, y, 60)
  end

  if Input.sequence({ '1', 'q' }, 0.1, 0.3) then
    bubbles[#bubbles + 1] = NewBubble(x, y, 80)
  end

  if Input.sequence({ '2', 'q' }) then
    bubbles[#bubbles + 1] = NewBubble(x - 30, y, 40)
    bubbles[#bubbles + 1] = NewBubble(x + 30, y, 40)
  end

  if Input.sequence({ '1', '2', 'q' }) then
    bubbles[#bubbles + 1] = NewBubble(x - 30, y + 10, 40)
    bubbles[#bubbles + 1] = NewBubble(x + 30, y + 10, 40)
    bubbles[#bubbles + 1] = NewBubble(x, y - 30, 40)
  end

  if Input.down('f12') then
    local keys = { 'j', 'k', 'l', ';' }
    for i = 1, 1000 do
      Input.multidown(keys)
    end
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

  str = str..'\nbubbles: '..#bubbles
  local seq_keys = {}
  for i, info in ipairs(Input.history(5)) do
    seq_keys[#seq_keys + 1] = string.format('%s[%.2f]', info.key, info.interval or 0)
  end

  str = str..'\nhistory: '..table.concat(seq_keys, ', ')
  lg.print(str, 10, 10)
end

