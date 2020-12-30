local M = {}

local Callbacks = {
  'keypressed', 'keyreleased',
  'mousepressed', 'mousereleased', 'wheelmoved',
  'gamepadpressed', 'gamepadreleased', 'gamepadaxis'
}

local GetTime = love.timer.getTime

local MouseKeysMapping = {
  [1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3',
  [4] = 'mouse4', [5] = 'mouse5', [6] = 'mouse6',
}
local GamepadKeysMapping = {
  a = 'fdown', y = 'fup', x = 'fleft', b = 'fright',
  back = 'back', guide = 'guide', start = 'start',
  leftstick = 'leftstick', rightstick = 'rightstick',
  leftshoulder = 'l1', rightshoulder = 'r1',
  dpup = 'dpup', dpdown = 'dpdown', dpleft = 'dpleft', dpright = 'dpright',

  -- axis
  leftx = 'leftx', lefty = 'lefty',
  rightx = 'rightx', righty = 'righty',
  triggerleft = 'l2', triggerright = 'r2'
}

M.axis_threshold = {
  leftx = 0.1, lefty = 0.1,
  rightx = 0.1, righty = 0.1,
  l2 = 0.1, r2 = 0.1,
}

M.start_ts = -1
M.prev_ts = -2
M.state = {}
M.state_time = {}
M.state_data = {}
M.prev_state_duration = {}

M.seq_states = {
  max_total = 10,
  total = 0,
  first = nil,
  last = nil,

  push = function(self, key, timestamp)
    local node
    if self.total >= self.max_total then
      node = self.first
      self.first = self.first.next_node
      self.first.prev_node = nil
      node.next_node = nil
    else
      node = {}
      self.total = self.total + 1
    end

    node.key = key
    node.ts = timestamp
    if self.last then
      node.interval = node.ts - self.last.ts
    end

    if self.last then
      node.prev_node = self.last
      self.last.next_node = node
      self.last = node
    else
      self.first, self.last = node, node
    end

    return node
  end
}

-----------------------------

function M.bind_callbacks(callbacks)
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

function M.set_state(key, is_down, data)
  if M.state[key] == is_down then
    M.state_data[key] = data
    return
  end
  M.state[key] = is_down
  M.state_data[key] = data
  local ts = GetTime()

  local prev_changed_at = M.state_time[key]
  M.prev_state_duration[key] = prev_changed_at and (ts - prev_changed_at)
  M.state_time[key] = ts

  if is_down then M.seq_states:push(key, ts) end
end

-- Params:
--  key:
--  delay: in seconds
--  interval: in seconds
-- Return is_down, data, duration
function M.down(key, delay, interval)
  local is_down = M.state[key]
  if not is_down then return false end
  if not delay and not interval then
    return true, M.state_data[key], M.start_ts - M.state_time[key]
  end

  if not delay then delay = 0 end

  local changed_at = M.state_time[key]
  local duration = M.start_ts - changed_at
  if duration < delay then return false end
  local prev_duration = M.prev_ts - changed_at

  if prev_duration < delay and duration >= delay then
    return true, M.state_data[key], duration
  end
  if not interval then return false end

  local dv = math.floor((duration - delay) / interval) * interval + delay
  if prev_duration < dv and duration >= dv then
    return true, M.state_data[key], duration
  else
    return false
  end
end

-- Down multiple keys
function M.multidown(keys, delay, interval)
  local min_duration, min_key
  for _, key in ipairs(keys) do
    local is_down, _, duration = M.down(key, delay)
    if is_down then
      if not min_duration or min_duration > duration then
        min_key, min_duration = key, duration
      end
    else
      return false
    end
  end
  return M.down(min_key, delay, interval)
end

-- Return: is_pressed, data, relesaed duration
function M.pressed(key)
  local is_down = M.state[key]
  if not is_down then return false end
  local changed_at = M.state_time[key]
  if not changed_at or changed_at < M.start_ts then return false end
  return true, M.state_data[key], M.prev_state_duration[key]
end

-- Return: is_released, data, pressed duration
function M.released(key)
  local is_down = M.state[key]
  if is_down then return false end
  local changed_at = M.state_time[key]
  if not changed_at or changed_at < M.start_ts then return false end
  return true, M.state_data[key], M.prev_state_duration[key]
end

function M.sequence(keys, min_interval, max_interval)
  assert(#keys > 0, 'Keys cannot be empty')
  local node = M.seq_states.last
  if not node then return false end

  -- down in current frame
  if not M.state[node.key] then return false end
  local changed_at = M.state_time[node.key]
  if not changed_at or changed_at < M.start_ts then return false end

  for i = #keys, 1, -1 do
    if not node then return false end
    local key = keys[i]
    if node.key ~= key then return false end

    -- ignore interval for start key
    if i > 1 then
      local interval = node.interval
      if interval then
        if min_interval and interval < min_interval then return false end
        if max_interval and interval > max_interval then return false end
      end
    end
    node = node.prev_node
  end

  return true
end

-- Exact duration
-- Return:
--  nil: not trigger
--  >= 0: duration time in seconds
function M.duration(key)
  local changed_at = M.state_time[key]
  if not changed_at then return nil end
  return GetTime() - changed_at
end

function M.get_data(key)
  return M.state_data[key]
end

-- Params:
--  total: total cannot > seq_states.max
-- return prev down
function M.get_history(total)
  local node = M.seq_states.last
  local r = {}
  for i = 1, M.seq_states.max_total do
    if not node then break end
    r[#r + 1] = { key = node.key, interval = node.interval }
    if i >= total then break end
    node = node.prev_node
  end
  return r
end

function M.get_down_keys()
  local keys = {}
  for k, v in pairs(M.state) do
    keys[#keys + 1] = k
  end
  return keys
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
    M.set_state('wheelx', true, x)
  elseif y > 0 then
    M.set_state('wheelx', true, x)
  end

  if y < 0 then
    M.set_state('wheely', true, y)
  elseif y > 0 then
    M.set_state('wheely', true, y)
  end
end

function M.gamepadpressed(joystick, btn)
  M.set_state(GamepadKeysMapping[btn], true)
end

function M.gamepadreleased(joystick, btn)
  M.set_state(GamepadKeysMapping[btn], nil)
end

function M.gamepadaxis(joystick, axis, value)
  local key = GamepadKeysMapping[axis]
  local threshold = M.axis_threshold[key]
  if math.abs(value) < threshold then
    M.set_state(key, nil, value)
  else
    M.set_state(key, true, value)
  end
end

local ShouldResetKeys = {
  'wheelx', 'wheely',
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
