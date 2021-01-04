local time = 0

love = {
  timer = {
    getTime = function()
      return time
    end,

    setTime = function(ts)
      time = ts
    end
  }
}

