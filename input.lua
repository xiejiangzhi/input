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

M.ts = -1
M.prev_ts = -2
M.state = {}
M.state_ts = {}
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

function M.set_key_state(key, state)
  if M.state[key] == state then return end
  M.state[key] = state

  local ts = GetTime()
  M.prev_state_duration[key] = ts - (M.state_ts[key] or 0)
  M.state_ts[key] = ts
end

function M.get_pressed_keys()
  local keys = {}
  for k, v in pairs(M.state) do
    keys[#keys + 1] = k
  end
  return keys
end

-- Return is_down, data, is_changed_in_current_frame
function M.get_state_info(key)
  local data = M.state[key]
  local changed_at = M.state_ts[key]
  return data ~= nil, data, changed_at and changed_at >= M.ts
end

M.down = M.get_state_info

-- Return: is_pressed, data
function M.pressed(key)
  local is_down, data, changed = M.get_state_info(key)
  return is_down and changed, data
end

-- Return: is_released, pressed duration
function M.released(key)
  local is_down, _data, changed = M.get_state_info(key)
  return not is_down and changed, M.prev_state_duration[key]
end

-- Return:
--  nil: not trigger
--  >= 0: duration time in seconds
function M.get_state_duration(key)
  local changed_at = M.state_ts[key]
  if not changed_at then return nil end
  return GetTime() - changed_at
end

------------------------

function M.keypressed(key)
  M.set_key_state(key, true)
end

function M.keyreleased(key)
  M.set_key_state(key, nil)
end

function M.mousepressed(x, y, btn)
  M.set_key_state(MouseKeysMapping[btn], true)
end

function M.mousereleased(x, y, btn)
  M.set_key_state(MouseKeysMapping[btn], nil)
end

function M.wheelmoved(x, y)
  if x < 0 then
    M.set_key_state('wheelleft', -x)
    M.set_key_state('wheelx', x)
  elseif y > 0 then
    M.set_key_state('wheelright', x)
    M.set_key_state('wheelx', x)
  end

  if y < 0 then
    M.set_key_state('wheelup', -y)
    M.set_key_state('wheely', y)
  elseif y > 0 then
    M.set_key_state('wheeldown', y)
    M.set_key_state('wheely', y)
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
    local ts = M.state_ts[k]
    if ts and ts < M.ts then
      M.set_key_state(k, nil)
    end
  end

  M.prev_ts = M.ts
  M.ts = GetTime()
end

return M
