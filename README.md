Input
===========

Simple and powerful input handler for LOVE2D.

## Features

* Support keyboard, mouse, joystick
* Check key is down with delay and interval. And can get duration time.
* Check pressed or released on current frame.
* Check multiple keys down with delay and interval.
* Check sequence keys down with interval limit.
* Get pressed keys.
* Get history of pressed keys.

## Example

```lua
local Input = require 'input'

function love.load()
  Input.bind_callbacks()
end

function love.update(dt)
  local delay, interval = 0.5, 1
  local is_down, _, duration = Input.down('a', delay, interval)
  local is_down, val, duration = Input.down('leftx')
  local is_pressed, data, released_duration = Input.pressed('a')
  local is_released, data, pressed_duration = Input.released('leftx')
  local is_down = Input.multidown({ 'a', 'b' }, delay, interval)
  local min_interval, max_interval = 0, 0.3
  local is_down, data_of_last_key = Input.sequence({ 'a', 'b' }, min_interval, max_interval)

  local keys = iNput.get_down_keys()
  local keys_info = Input.get_history(2)
end
```
Better example please see [here](https://github.com/xiejiangzhi/input/blob/main/main.lua)

## API

### Bind callbacks

Call it to setup input callbacks.

`Input.bind_callbacks()`


### Check key is down

`is_down, data, duration = Input.down(key, delay, interval)`

`delay` and `interval` unit seconds

`data` is the axis value for axis key. nil for normal key
`duration` is the duration time in second.

```lua
-- for normal key
local is_down, data, duration = Input.down('1')
if is_down then assert(data == nil) end

-- for mouse
local is_down, pos, duration = Input.down('mouse1')
if is_down then print(pos.x, pos.y) end

-- for gamepad axis
local is_down, axis_val, duration = Input.down('leftx')
if is_down then assert(type(data) == 'number') end

-- for wheel
local is_down, wheel_val, duration = Input.down('wheelx')
if is_down then assert(type(wheel_val) == 'number') end
```


### Check multiple keys is down

`is_down, data_of_last_key, duration = Input.multidown(keys, delay, interval)`

`delay` and `interval` unit seconds

```
local is_down, mouse_pos, duration = Input.multidown({ 'fdown', 'mouse1' }, 1, 1)
```


### Check a key is pressed on the current frame

`is_pressed, data, released_time = Input.pressed(key)`

`data` is the axis value for axis key. nil for normal key
`released_time` will be nil for first call


### Check a key is released on the current frame

`is_released, data, released_time = Input.released(key)`

`data` is the axis value for axis key. nil for normal key
`released_time` will be nil for first call


### Check keys is down in sequence

`is_pressed, data_of_last_key = Input.sequence(keys, min_interval, max_interval)`


```lua
  -- any interval
  Input.sequence({ 'a', 'b', 'c' })

  -- The interval between two presses must be less than 0.3s and greater than 0.1s
  Input.sequence({ 'a', 'b', 'c' }, 0.1, 0.3)
```


NOTE: Following keys is invalid for sequence, but you can change the set by `Input.sequence_except_keys`

```lua
-- Default value
Input.sequence_except_keys = {
  mousemove = true,
  wheelx = true, wheely = true,
  leftx = true, lefty = true,
  rightx = true, righty = true
}

-- Except sequence keys 'a', 's' 'd' and 'w'
for i, k in ipairs({ 'a', 's', 'd', 'w' }) do
  Input.sequence_except_keys[k] = true
end
```

### Get a relative to time of the last action(pressed or released)

`seconds = Input.duration(key, strict)`

`strict`: Whether to calculate the exact time. Default value is false, duration relative to last frame.

Return nil if the key has never been down


### Get the history of pressed keys. Max history items is 10.

`items = Input.get_history(n)`

`items`: Sort by pressing time from nearest to far.
`item.key`:
`item.interval`: relative to the time of previous key was pressed


### Get all down keys

`keys = Input.get_down_keys`


### Get key data


`data = Input.get_data(key)`


### Manually input event

Call following callbacks, the arguments is the same as Love2D's callbacks

```lua
local Callbacks = {
  'keypressed', 'keyreleased',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'gamepadpressed', 'gamepadreleased', 'gamepadaxis'
}
```

Example

```
Input.keypressed('a')
Input.keyreleased('a')
```


## Axis threshold

Release axis key if axis value < threshold, but still can get the current axis value by `Input.get_data`

```
Input.axis_threshold = {
  leftx = 0.1, lefty = 0.1,
  rightx = 0.1, righty = 0.1,
  l2 = 0.1, r2 = 0.1,
}
```

## Multiple gamepad

Set `Input.multiple_gamepad = true`, then all gamepad keys will has a suffix `{key}:{index}`

The first trigger gamepad will get index 1, others will be automatically incremented

```
Input.multiple_gamepad = true
Input.down('fdown:1') -- first gamepad
Input.down('fdown:2') -- seconds gamepad
```
**NOTE**: Now, multiple gamepad keys will push to one list, so `Input.sequence` cannot use specified gamepad index. Maybe it will be fixed later

## Keys

**keyborad** [Key Constant](https://love2d.org/wiki/KeyConstant)

**Mouse**
```
local MouseKeysMapping = {
  move = 'mousemove',
  wheelx = 'wheelx', wheely = 'wheely',
  [1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3',
  [4] = 'mouse4', [5] = 'mouse5', [6] = 'mouse6',
}
local WheelKeysMapping = {
  x = 'wheelx', y = 'wheely'
}
```

**Gamepad**

```
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
```
