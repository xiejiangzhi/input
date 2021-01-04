local M = {}
local D = {}

local Callbacks = {
  'keypressed', 'keyreleased',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'gamepadpressed', 'gamepadreleased', 'gamepadaxis'
}

local GetTime = love.timer.getTime

local MouseKeysMapping = {
  move = 'mousemove',
  [1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3',
  [4] = 'mouse4', [5] = 'mouse5', [6] = 'mouse6',
}
local WheelKeysMapping = {
  x = 'wheelx', y = 'wheely'
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

---------------------

function M.init_state()
  D.start_ts = GetTime()
  D.prev_ts = D.start_ts
  D.state = {}
  D.state_time = {}
  D.state_data = {}
  D.prev_state_duration = {}

  M.axis_threshold = {
    leftx = 0.1, lefty = 0.1,
    rightx = 0.1, righty = 0.1,
    l2 = 0.1, r2 = 0.1,
  }

  M.sequence_except_keys = {
    mousemove = true,
    wheelx = true, wheely = true,
    leftx = true, lefty = true,
    rightx = true, righty = true
  }

  M.multiple_gamepad = false

  D.total_gamepads = 0
  D.gamepad_mapping = {}

  D.seq_states = {
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
end

-----------------------------

function M.bind_callbacks(callbacks)
  for _, name in ipairs(Callbacks) do
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
  is_down = is_down and true or nil
  if D.state[key] == is_down then
    D.state_data[key] = data
    return
  end
  D.state[key] = is_down
  D.state_data[key] = data
  local ts = GetTime()
  local prev_changed_at = D.state_time[key]
  D.prev_state_duration[key] = prev_changed_at and (ts - prev_changed_at)
  D.state_time[key] = ts

  if is_down and not M.sequence_except_keys[key] then
    D.seq_states:push(key, ts)
  end
end

-- Params:
--  key:
--  delay: in seconds
--  interval: in seconds
-- Return is_down, data, duration
function M.down(key, delay, interval)
  local is_down = D.state[key]
  if not is_down then return false end
  if not delay then delay = 0 end
  if delay == 0 then
    if not interval then
      return true, D.state_data[key], D.start_ts - D.state_time[key]
    end
  end

  local changed_at = D.state_time[key]
  local duration = D.start_ts - changed_at
  if duration < delay then return false end
  local prev_duration = D.prev_ts - changed_at

  if (prev_duration < delay and duration >= delay) or (delay == 0 and duration == 0) then
    return true, D.state_data[key], duration
  end
  if not interval then return false end
  if interval == 0 then return true, D.state_data[key], duration end

  local dv = math.floor((duration - delay) / interval) * interval + delay
  if prev_duration < dv and duration >= dv then
    return true, D.state_data[key], duration
  else
    return false
  end
end

-- Down multiple keys
-- Return: is_down, data, duration
function M.multidown(keys, delay, interval)
  local min_duration, min_key
  local is_down, data, duration
  if not delay then delay = 0 end

  for _, key in ipairs(keys) do
    is_down, data, duration = M.down(key)
    if is_down and duration >= delay then
      if not min_duration or min_duration > duration then
        min_key, min_duration = key, duration
      end
    else
      return false
    end
  end

  is_down, _, duration = M.down(min_key, delay, interval)
  return is_down, data, duration
end

-- Return: is_pressed, data, relesaed duration
function M.pressed(key)
  local is_down = D.state[key]
  if not is_down then return false end
  local changed_at = D.state_time[key]
  if not changed_at or changed_at < D.start_ts then return false end
  return true, D.state_data[key], D.prev_state_duration[key]
end

-- Return: is_released, data, pressed duration
function M.released(key)
  local is_down = D.state[key]
  if is_down then return false end
  local changed_at = D.state_time[key]
  if not changed_at or changed_at < D.start_ts then return false end
  return true, D.state_data[key], D.prev_state_duration[key]
end

-- Return: is_pressed, data of keys[#keys]
function M.sequence(keys, min_interval, max_interval)
  assert(#keys > 0, 'Keys cannot be empty')
  local node = D.seq_states.last
  if not node then return false end

  -- down in current frame
  if not D.state[node.key] then return false end
  local changed_at = D.state_time[node.key]
  if not changed_at or changed_at < D.start_ts then return false end

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

  return true, M.get_data(keys[#keys])
end

-- Exact duration
-- Return:
--  nil: not trigger
--  >= 0: duration time in seconds
function M.duration(key, exact_time)
  local changed_at = D.state_time[key]
  if not changed_at then return nil end
  local ts = exact_time and GetTime() or D.start_ts
  return ts - changed_at
end

function M.get_data(key)
  return D.state_data[key]
end

-- Params:
--  total: total cannot > seq_states.max
-- return prev down
function M.get_history(total)
  local node = D.seq_states.last
  local r = {}
  for i = 1, D.seq_states.max_total do
    if not node then break end
    r[#r + 1] = { key = node.key, interval = node.interval }
    if i >= total then break end
    node = node.prev_node
  end
  return r
end

function M.get_down_keys()
  local keys = {}
  for k, v in pairs(D.state) do
    keys[#keys + 1] = k
  end
  return keys
end

-- start from 1
function M.get_gamepad_index(joystick)
  local id = joystick:getID()
  local idx = D.gamepad_mapping[id]
  if not idx then
    D.total_gamepads = D.total_gamepads + 1
    idx = D.total_gamepads
    D.gamepad_mapping[id] = idx
  end
  return idx
end

------------------------

function M.keypressed(key)
  M.set_state(key, true, nil)
end

function M.keyreleased(key)
  M.set_state(key, false)
end

function M.mousepressed(x, y, btn)
  M.set_state(MouseKeysMapping[btn], true, { x = x, y = y })
end

function M.mousereleased(x, y, btn)
  M.set_state(MouseKeysMapping[btn], false, { x = x, y = y })
end

function M.mousemoved(x, y, dx, dy, istouch)
  M.set_state(MouseKeysMapping.move, true, { x = x, y = y, dx = dx, dy = dy, istouch = istouch })
end

function M.wheelmoved(x, y)
  if x < 0 then
    M.set_state(WheelKeysMapping.x, true, x)
  elseif x > 0 then
    M.set_state(WheelKeysMapping.x, true, x)
  else
    M.set_state(WheelKeysMapping.x, false)
  end

  if y < 0 then
    M.set_state(WheelKeysMapping.y, true, y)
  elseif y > 0 then
    M.set_state(WheelKeysMapping.y, true, y)
  else
    M.set_state(WheelKeysMapping.y, false)
  end
end

function M.gamepadpressed(joystick, btn)
  local key = GamepadKeysMapping[btn]
  if M.multiple_gamepad then key = key..':'..M.get_gamepad_index(joystick) end
  M.set_state(key, true)
end

function M.gamepadreleased(joystick, btn)
  local key = GamepadKeysMapping[btn]
  if M.multiple_gamepad then key = key..':'..M.get_gamepad_index(joystick) end
  M.set_state(key, false)
end

function M.gamepadaxis(joystick, axis, value)
  local key = GamepadKeysMapping[axis]
  local threshold = M.axis_threshold[key]
  if M.multiple_gamepad then key = key..':'..M.get_gamepad_index(joystick) end
  if math.abs(value) < threshold then
    M.set_state(key, false, value)
  else
    M.set_state(key, true, value)
  end
end

local ShouldResetKeys = {
  'wheelx', 'wheely', 'mousemove'
}
function M.push_state()
  for i, k in ipairs(ShouldResetKeys) do
    if D.state[k] then
      local ts = D.state_time[k]
      if ts and ts < D.start_ts then
        M.set_state(k, false)
      end
    end
  end

  D.prev_ts = D.start_ts
  D.start_ts = GetTime()
end

M.init_state()
return M
