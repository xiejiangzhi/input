describe('input', function()
  local Input = require 'input'
  Input.bind_callbacks()

  local setTime = love.timer.setTime
  local nextFrame = function(ts)
    setTime(ts)
    love.draw()
  end
  local newJoystick = function(id)
    return { id = id, getID = function(self) return self.id end }
  end

  before_each(function()
    setTime(0)
    Input.init_state()
  end)

  describe('down, pressed, released', function()
    it('down should return state with data and duration', function()
      love.keypressed('a')
      love.mousepressed(1, 2, 1)
      local js = newJoystick(1)
      love.gamepadpressed(js, 'a')
      love.gamepadaxis(js, 'leftx', 0.5)
      love.gamepadaxis(js, 'lefty', 0.01)

      assert.is_same({ Input.down('a') }, { true, nil, 0 })
      assert.is_same({ Input.pressed('a') }, { true, nil, nil })
      assert.is_same({ Input.released('a') }, { false, nil, nil })
      assert.is_same({ Input.down('fdown') }, { true, nil, 0 })
      assert.is_same({ Input.down('leftx') }, { true, 0.5, 0 })
      assert.is_same({ Input.down('lefty') }, { false, nil, nil })
      assert.is_same({ Input.down('mouse1') }, { true, { x = 1, y = 2 }, 0 })

      love.gamepadreleased(js, 'a')
      setTime(1.5)
      assert.is_same({ Input.down('a') }, { true, nil, 0 })
      assert.is_same({ Input.down('mouse1') }, { true, { x = 1, y = 2 }, 0 })
      assert.is_same({ Input.down('fdown') }, { false, nil, nil })
      assert.is_same({ Input.pressed('fdown') }, { false, nil, nil })
      assert.is_same({ Input.down('leftx') }, { true, 0.5, 0 })
      assert.is_same({ Input.down('lefty') }, { false, nil, nil })

      love.draw()
      love.gamepadpressed(js, 'a')
      assert.is_same({ Input.down('a') }, { true, nil, 1.5 })
      assert.is_same({ Input.pressed('a') }, { false, nil, nil })
      assert.is_same({ Input.released('a') }, { false, nil, nil })
      assert.is_same({ Input.down('mouse1') }, { true, { x = 1, y = 2 }, 1.5 })
      assert.is_same({ Input.down('fdown') }, { true, nil, 0 })
      assert.is_same({ Input.pressed('fdown') }, { true, nil, 1.5 })
      assert.is_same({ Input.down('leftx') }, { true, 0.5, 1.5 })
      assert.is_same({ Input.down('lefty') }, { false, nil, nil })


      love.keyreleased('a')
      love.gamepadaxis(js, 'lefty', 0.1)
      assert.is_same({ Input.down('a') }, { false })
      assert.is_same({ Input.pressed('a') }, { false, nil, nil })
      assert.is_same({ Input.released('a') }, { true, nil, 1.5 })
      assert.is_same({ Input.down('mouse1') }, { true, { x = 1, y = 2 }, 1.5 })
      assert.is_same({ Input.down('fdown') }, { true, nil, 0 })
      assert.is_same({ Input.down('leftx') }, { true, 0.5, 1.5 })
      assert.is_same({ Input.down('lefty') }, { true, 0.1, 0 })

      setTime(2.1)
      love.gamepadaxis(js, 'lefty', 0.09)
      love.draw()
      assert.is_same({ Input.down('a') }, { false })
      assert.is_same({ Input.pressed('a') }, { false, nil, nil })
      assert.is_same({ Input.released('a') }, { false, nil, nil })
      assert.is_same({ Input.down('mouse1') }, { true, { x = 1, y = 2 }, 2.1 })
      assert.is_same({ Input.down('fdown') }, { true, nil, 2.1 - 1.5 })
      assert.is_same({ Input.down('leftx') }, { true, 0.5, 2.1 })
      assert.is_same({ Input.down('lefty') }, { false, nil, nil })
    end)

    it('should check delay and interval for down', function()
      love.keypressed('a')
      assert.is_same({ Input.down('a', 0, 0.1) }, { true, nil, 0 })
      assert.is_same({ Input.down('a', 0.1, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.down('a', 0, 0) }, { true, nil, 0 })

      nextFrame(0.05)
      assert.is_same({ Input.down('a', 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.down('a', 0.05, 0.1) }, { true, nil, 0.05 })
      assert.is_same({ Input.down('a', 0, 0) }, { true, nil, 0.05 })

      nextFrame(0.1)
      assert.is_same({ Input.down('a', 0, 0.1) }, { true, nil, 0.1 })
      assert.is_same({ Input.down('a', 0, 0) }, { true, nil, 0.1 })

      nextFrame(0.25)
      assert.is_same({ Input.down('a', 0, 0.1) }, { true, nil, 0.25 })
      assert.is_same({ Input.down('a', 0.05, 0.1) }, { true, nil, 0.25 })
      assert.is_same({ Input.down('a', 0, 0) }, { true, nil, 0.25 })

      nextFrame(0.29)
      assert.is_same({ Input.down('a', 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.down('a', 0.05, 0.1) }, { false, nil, nil })

      nextFrame(0.301)
      assert.is_same({ Input.down('a', 0, 0.1) }, { true, nil, 0.301 })
      assert.is_same({ Input.down('a', 0.05, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.down('a', 0.301) }, { true, nil, 0.301 })
    end)

    it('pressed and released should return data and duration of previous state', function()
      love.keypressed('a')
      love.keypressed('b')
      love.keyreleased('b')
      -- for empty previous state
      assert.is_same({ Input.pressed('a') }, { true, nil, nil })
      assert.is_same({ Input.released('a') }, { false, nil, nil })
      assert.is_same({ Input.pressed('b') }, { false, nil, nil })
      assert.is_same({ Input.released('b') }, { true, nil, 0 })

      nextFrame(0.1)
      love.keyreleased('a')
      love.keypressed('b')
      assert.is_same({ Input.pressed('a') }, { false, nil, nil })
      assert.is_same({ Input.released('a') }, { true, nil, 0.1 })
      assert.is_same({ Input.pressed('b') }, { true, nil, 0.1 })
      assert.is_same({ Input.released('b') }, { false, nil, nil })
    end)
  end)

  describe('multidown', function()
    it('should return key data and duration', function()
      love.keypressed('a')
      love.keypressed('b')
      assert.is_same({ Input.multidown({ 'a', 'b' }) }, { true, nil, 0 })
      assert.is_same({ Input.multidown({ 'b', 'a' }) }, { true, nil, 0 })

      nextFrame(0.1)
      love.keypressed('c')
      love.keypressed('d')
      love.keyreleased('a')
      assert.is_same({ Input.multidown({ 'a', 'b' }) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'b', 'a' }) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }) }, { true, nil, 0 })
    end)

    it('should return key data and duration with delay and interval', function()
      love.keypressed('a')
      love.keypressed('b')
      assert.is_same({ Input.multidown({ 'a', 'b' }, 0, 0.1) }, { true, nil, 0 })

      nextFrame(0.1)
      love.keypressed('c')
      love.keypressed('d')
      love.wheelmoved(0, 2)
      love.keyreleased('a')
      assert.is_same({ Input.multidown({ 'a', 'b' }, 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0, 0.1) }, { true, nil, 0 })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0.05, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd', 'wheely' }) }, { true, 2, 0 })

      nextFrame(0.151)
      assert.is_same({ Input.multidown({ 'a', 'b' }, 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0.05, 0.1) }, { true, nil, 0.151 - 0.1 })

      nextFrame(0.2)
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0, 0.1) }, { true, nil, 0.1 })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0.05, 0.1) }, { false, nil, nil })

      nextFrame(0.22)
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0.05, 0.1) }, { false, nil, nil })

      nextFrame(0.251)
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0, 0.1) }, { false, nil, nil })
      assert.is_same({ Input.multidown({ 'c', 'b', 'd' }, 0.05, 0.1) }, { true, nil, 0.251 - 0.1 })
    end)
  end)

  describe('sequence', function()
    it('should return state ', function()
      love.keypressed('a')
      love.keypressed('b')
      love.keypressed('c')

      nextFrame(0.15)
      love.keypressed('d')
      assert.is_same({ Input.sequence({ 'a', 'b', 'c' }) }, { false, nil })
      assert.is_same({ Input.sequence({ 'a', 'b', 'c', 'd' }) }, { true, nil })
      assert.is_same({ Input.sequence({ 'b', 'c', 'd' }) }, { true, nil })
      assert.is_same({ Input.sequence({ 'c', 'd' }) }, { true, nil })
      assert.is_same({ Input.sequence({ 'd' }) }, { true, nil })
    end)

    it('should check key with down interval', function()
      love.keypressed('a')
      love.keypressed('b')
      assert.is_same({ Input.sequence({ 'a', 'b' }) }, { true, nil })
      assert.is_same({ Input.sequence({ 'a', 'b' }, 0.1) }, { false, nil })
      assert.is_same({ Input.sequence({ 'b', 'c', 'xxx' }) }, { false, nil })

      nextFrame(0.15)
      love.keypressed('c')
      assert.is_same({ Input.sequence({ 'a', 'b', 'c' }, 0, 0.1) }, { false, nil })
      assert.is_same({ Input.sequence({ 'a', 'b', 'c' }, 0.05, 0.2) }, { false, nil })
      assert.is_same({ Input.sequence({ 'a', 'b', 'c' }, 0.2, 0.3) }, { false, nil })

      assert.is_same({ Input.sequence({ 'b', 'c' }, 0, 0.1) }, { false, nil })
      assert.is_same({ Input.sequence({ 'b', 'c' }, 0.05, 0.2) }, { true, nil })
    end)
  end)

  describe('duration', function()
    it('should return action duration', function()
      love.keypressed('a')
      assert.is_equal(Input.duration('a'), 0)
      assert.is_equal(Input.duration('xxx'), nil)

      nextFrame(1)
      assert.is_equal(Input.duration('a'), 1)
      assert.is_equal(Input.duration('a', true), 1)

      setTime(1.5)
      assert.is_equal(Input.duration('a'), 1)
      assert.is_equal(Input.duration('a', true), 1.5)
    end)
  end)

  describe('get_data', function()
    it('should return action duration', function()
      love.wheelmoved(1, 2)
      assert.is_equal(Input.get_data('a'), nil)
      assert.is_equal(Input.get_data('wheelx'), 1)
      assert.is_equal(Input.get_data('wheely'), 2)

      nextFrame(1)
      love.wheelmoved(3, 0)
      assert.is_equal(Input.get_data('wheelx'), 3)
      assert.is_equal(Input.get_data('wheely'), nil)

      nextFrame(2)
      assert.is_equal(Input.get_data('wheelx'), nil)
      assert.is_equal(Input.get_data('wheely'), nil)
    end)
  end)

  describe('get_history', function()
    it('should return pressed keys', function()
      local keys = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', '1', '2', '3', '4', '5' }
      local ts = 0
      for i, k in ipairs(keys) do
        love.keypressed(k)
        ts = ts + i
        setTime(ts)
        love.keyreleased(k)
      end
      setTime(ts + 1)
      love.gamepadpressed('js', 'a')
      setTime(ts + 2)
      love.gamepadaxis('js', 'triggerleft', 1)

      assert.is_same(Input.get_history(3), {
        { key = 'l2', interval = 1 }, { key = 'fdown', interval = 13 }, { key = '5', interval = 11 }
      })

      assert.is_same(#Input.get_history(20), 10)
    end)
  end)

  describe('get_down_keys', function()
    it('should return all down keys', function()
      local keys = { 'a', 'b', 'c', '1', '2', '3' }
      local ts = 0
      for i, k in ipairs(keys) do
        love.keypressed(k)
        ts = ts + i
        setTime(ts)
        if i % 2 == 0 then love.keyreleased(k) end
      end
      setTime(ts + 1)
      love.gamepadpressed('js', 'a')
      setTime(ts + 2)
      love.gamepadaxis('js', 'triggerleft', 1)

      local dkeys = Input.get_down_keys()
      table.sort(dkeys)
      assert.is_same(dkeys, { '2', 'a', 'c', 'fdown', 'l2' })
    end)
  end)

  describe('misc', function()
    it('should ignore key for sequence if a key in except list', function()
      Input.sequence_except_keys['a'] = true
      love.keypressed('a')
      assert.is_same({ Input.down('a') }, { true, nil, 0 })
      -- cannot check a key that is excepted
      assert.is_same({ Input.sequence({ 'a' }) }, { false, nil, nil })
      assert.is_same(Input.get_history(), {})
    end)

    it('should add id to gamepad keys if Input.multiple_gamepad is true', function()
      local js1 = newJoystick('a')
      local js2 = newJoystick('b')
      local js3 = newJoystick('c')

      love.gamepadpressed(js1, 'a')
      Input.multiple_gamepad = true
      love.gamepadpressed(js1, 'a')
      love.gamepadpressed(js2, 'a')
      love.gamepadpressed(js2, 'b')
      love.gamepadaxis(js3, 'leftx', -0.5)

      local dkeys = Input.get_down_keys()
      table.sort(dkeys)
      assert.is_same(dkeys, { 'fdown', 'fdown:1', 'fdown:2', 'fright:2', 'leftx:3' })
    end)
  end)
end)
