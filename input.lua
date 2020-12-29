local M = {}
M.__index = M
M.new = function(...)
  local obj = setmetatable({}, M)
  obj:init(...)
  return obj
end

local Callbacks = {
  'keypressed', 'keyreleased',
  'mousepressed', 'mousereleased', 'wheelmoved',
  'gamepadpressed', 'gamepadreleased', 'gamepadaxis'
}

local GetTime = love.timer.getTime

local MouseKeysMapping = {
  [1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3', [4] = 'mouse4', [5] = 'mouse5'
}

M.start_ts = -1
M.prev_ts = -2
M.state = {}
M.state_time = {}
M.prev_state_duration = {}

function M:init()
  self.actions = {}
end

-- Params:
--  action; string id
--  keys; { 'xxx_key' } or function() return true, data end
function M:bind(action, keys)
  local list = self.actions[action]
  if not list then
    list = {}
    self.actions[action] = list
  end

  if type(keys) == 'function' then
    list[#list + 1] = keys
  else
    assert(#keys > 0, 'Keys cannot be empty')
    list[#list + 1] = keys
  end
end

function M:check(action)
  local list = self.actions[action]
  if not list then error("Not found action "..tostring(action)) end

  for _, desc in ipairs(list) do
    if type(desc) == 'function' then
      local r, data = desc()
      if r then return true, data end
    else
      local ok = true
      for _, key in ipairs(desc) do
        if not M.down(key) then
          ok = false
          break
        end
      end
      if ok then return true end
    end
  end

  return false
end

-----------------------------

function M.bind_events(callbacks)
  for i, name in ipairs(Callbacks) do
    local old_cb = love[name]
    local input_cb = M[name]
    love[name] = function(...)
      input_cb(...)
      if old_cb then old_cb(...) end
    end
  end

  local old_draw = love.draw
  local push_state = M.push_state
  love.draw = function()
    if old_draw then old_draw() end
    push_state()
  end
end

function M.set_state(key, state)
  if M.state[key] == state then return end
  M.state[key] = state

  local ts = GetTime()
  M.prev_state_duration[key] = ts - (M.state_time[key] or 0)
  M.state_time[key] = ts
end

function M.get_pressed_keys()
  local keys = {}
  for k, v in pairs(M.state) do
    keys[#keys + 1] = k
  end
  return keys
end

-- Params:
--  key:
--  delay: in seconds
--  interval: in seconds
-- Return is_down, data, duration
function M.down(key, delay, interval)
  local data = M.state[key]
  if not data then return false end
  if not delay then
    return true, data, M.start_ts - M.state_time[key]
  end

  local changed_at = M.state_time[key]
  local duration = M.start_ts - changed_at
  if duration < delay then return false end
  local prev_duration = M.prev_ts - changed_at

  if prev_duration < delay and duration >= delay then
    return true, data, duration
  end
  if not interval then return false end

  local dv = math.floor((duration - delay) / interval) * interval + delay
  if prev_duration < dv and duration >= dv then
    return true, data, duration
  else
    return false
  end
end

-- Return: is_pressed, data
function M.pressed(key)
  local data = M.state[key]
  if not data then return false end
  local changed_at = M.state_time[key]
  if not changed_at or changed_at < M.start_ts then return false end
  return true, data
end

-- Return: is_released, pressed duration
function M.released(key)
  local data = M.state[key]
  if data then return false end
  local changed_at = M.state_time[key]
  if not changed_at or changed_at < M.start_ts then return false end
  return true, M.prev_state_duration[key]
end

-- Return:
--  nil: not trigger
--  >= 0: duration time in seconds
function M.duration(key)
  local changed_at = M.state_time[key]
  if not changed_at then return nil end
  return GetTime() - changed_at
end

------------------------

function M.keypressed(key)
  M.set_state(key, true)
end

function M.keyreleased(key)
  M.set_state(key, nil)
end

function M.mousepressed(x, y, btn)
  M.set_state(MouseKeysMapping[btn], true)
end

function M.mousereleased(x, y, btn)
  M.set_state(MouseKeysMapping[btn], nil)
end

function M.wheelmoved(x, y)
  if x < 0 then
    M.set_state('wheelleft', -x)
    M.set_state('wheelx', x)
  elseif y > 0 then
    M.set_state('wheelright', x)
    M.set_state('wheelx', x)
  end

  if y < 0 then
    M.set_state('wheelup', -y)
    M.set_state('wheely', y)
  elseif y > 0 then
    M.set_state('wheeldown', y)
    M.set_state('wheely', y)
  end
end

function M.gamepadpressed(key)
  print(key)
end

function M.gamepadreleased(key)
  print(key)
end

function M.gamepadaxis(joystick, axis, value)
  print(axis)
end

local ShouldResetKeys = {
  'wheelleft', 'wheelright', 'wheelx',
  'wheelup', 'wheeldown', 'wheely'
}
function M.push_state()
  for i, k in ipairs(ShouldResetKeys) do
    local ts = M.state_time[k]
    if ts and ts < M.start_ts then
      M.set_state(k, nil)
    end
  end

  M.prev_ts = M.start_ts
  M.start_ts = GetTime()
end

return M
