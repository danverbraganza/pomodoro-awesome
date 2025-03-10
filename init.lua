-- Author: François de Metz
-- Author: Danver Braganza


local widget    = widget
local image     = image
local timer     = timer
local awful     = require("awful")
local naughty   = require("naughty")
local beautiful = require("beautiful")
local math      = require("math")
local setmetatable = setmetatable

module("pomodoro")

-- 25 min
local pomodoro_time = 60 * 25

local pomodoro_image_path = beautiful.pomodoro_icon or awful.util.getdir("config") .."/pomodoro/pomodoro.png"

local windup_path = beautiful.pomodoro_windup or awful.util.getdir("config") .."/pomodoro/winding_clock.mp3"

local ticking_path = beautiful.pomodoro_ticking or awful.util.getdir("config") .."/pomodoro/ticking_clock.mp3"

local ringing_path = beautiful.pomodoro_ringing or awful.util.getdir("config") .."/pomodoro/ringing_clock.mp3"


-- setup widget
local pomodoro_image = image(pomodoro_image_path)

pomodoro = widget({ type = "imagebox" })
pomodoro.image = pomodoro_image

-- setup timers
local pomodoro_timer = timer({ timeout = pomodoro_time})
local pomodoro_ticker = timer({ timeout = 3.5 })
local pomodoro_tooltip_timer = timer({ timeout = 1 })
local pomodoro_nbsec = 0

local function pomodoro_start()
    pomodoro_timer:start()
    pomodoro_tooltip_timer:start()
    pomodoro.bg    = beautiful.bg_normal
    pomodoro_ticker:start()
    awful.util.spawn_with_shell("mpg123 " .. windup_path)
 end

local function pomodoro_tick()
      if not (pomodoro_nbsec == 0) then
            awful.util.spawn_with_shell("mpg123 " .. ticking_path)
            pomodoro_ticker:start()
      end
end


local function pomodoro_stop()
   pomodoro_timer:stop(pomodoro_timer)
   pomodoro_tooltip_timer:stop(pomodoro_tooltip_timer)
   pomodoro_nbsec = 0
end

local function pomodoro_end()
    pomodoro_stop()
    awful.util.spawn_with_shell("mpg123 " .. ringing_path)
    pomodoro.bg    = beautiful.bg_urgent
end

local function pomodoro_notify(text)
   naughty.notify({ title = "Pomodoro", text = text, timeout = 10,      
                    icon = pomodoro_image_path, icon_size = 64,
                    width = 200
                 })
end

pomodoro_timer:add_signal("timeout", function(c) 
                                          pomodoro_end()
                                          pomodoro_notify('Ended')  
                                       end)

pomodoro_ticker:add_signal("timeout", function(c)
				          pomodoro_tick()
					  end)

pomodoro_tooltip_timer:add_signal("timeout", function(c) 
                                             pomodoro_nbsec = pomodoro_nbsec + 1
                                       end)

pomodoro_tooltip = awful.tooltip({
                                    objects = { pomodoro },
                                    timer_function = function()
                                                        if pomodoro_timer.started then
                                                           r = (pomodoro_time - pomodoro_nbsec) % 60
                                                           return 'End in ' .. math.floor((pomodoro_time - pomodoro_nbsec) / 60) .. ' min ' .. r
                                                        else
                                                           return 'pomodoro not started'
                                                        end
                                                     end,
})

local function pomodoro_start_timer()
   if not pomodoro_timer.started then
      pomodoro_start()
      pomodoro_notify('Started')
   else
      pomodoro_stop()
      pomodoro_notify('Canceled')
   end
end

pomodoro:buttons(awful.util.table.join(
                    awful.button({ }, 1, pomodoro_start_timer)
              ))

setmetatable(_M, { __call = function () return pomodoro end })
