Input
===========

Simple input for LOVE2D

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
  Input.bind_events()
end

function love.update(dt)
  local delay, interval = 0.5, 1
  local is_down, _, duration = Input.down('a', delay, interval)
  local is_down, val, duration = Input.down('leftx')
  local is_pressed, data, released_duration = Input.pressed('a')
  local is_released, data, pressed_duration = Input.released('leftx')
  local is_down = Input.multidown({ 'a', 'b' }, delay, interval)
  local min_interval, max_interval = 0, 0.3
  local is_down = Input.sequence({ 'a', 'b' }, min_interval, max_interval)

  local keys = iNput.get_pressed_keys()
  local keys_info = Input.get_history(2)
end
```

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

-- for axis key
local is_down, data, duration = Input.down('leftx')
if is_down then assert(type(data) == 'number') end

local is_down, data, duration = Input.down('wheelup')
if is_down then assert(type(data) == 'number') end
```


### Check multiple keys is down

`is_down = Input.multidown(key, delay, interval)`

`delay` and `interval` unit seconds


### Check a key is pressed on the current frame

`is_pressed, data, released_time = Input.pressed(key)`

`data` is the axis value for axis key. nil for normal key
`released_time` will be nil for first call


### Check a key is released on the current frame

`is_released, data, released_time = Input.released(key)`

`data` is the axis value for axis key. nil for normal key
`released_time` will be nil for first call


### Check keys is down in sequence

`is_triggered = Input.sequence(keys, min_interval, max_interval)`


```lua
  -- any interval
  Input.sequence({ 'a', 'b', 'c' })

  -- The interval between two presses must be less than 0.3s and greater than 0.1s
  Input.sequence({ 'a', 'b', 'c' }, 0.1, 0.3)
```


### Get a relative to time of the last action(pressed or released)

`seconds = Input.duration(key)`

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


### Set a key state

`Input.set_state(key, is_down, data)`


## Axis threshold

Release axis key if axis value < threshold, but still can get the current axis value by `Input.get_data`

```
Input.axis_threshold = {
  leftx = 0.1, lefty = 0.1,
  rightx = 0.1, righty = 0.1,
  l2 = 0.1, r2 = 0.1,
}
```

## Keys

**keyborad** [Key Constant](https://love2d.org/wiki/KeyConstant)

**Mouse**
```
local MouseKeysMapping = {
  [1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3',
  [4] = 'mouse4', [5] = 'mouse5', [6] = 'mouse6',
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
