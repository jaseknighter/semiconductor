--
-- async-await code from: https://github.com/iamcco/async-await.lua

--
-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

--[[
  todo:
    * test binary and text params
    * add check for registering the same norns ip address multiple times
    * add cancellation for registering norns name and ip
    * figure out why REGISTER menu doesn't immediately udpate after registration ('unregister' doesn't show)
    * figure out how to switch hosts
]]


local mod = require 'core/mods'

menu = include('semiconductor/lib/menu')
-- local menu = include('semiconductor/lib/menu')

--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some state values
--

local state = {
  norns_ips = {} -- table for ips of registered norns 
}



--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("system_post_startup", "semiconductor startup", function()
  state.system_post_startup = true
  print("semiconductor post startup!!!")
end)

mod.hook.register("script_pre_init", "semiconductor init", function()
  -- tweak global environment here ahead of the script `init()` function being called
  print("semiconductor init")
  local old_init = init
    init = function()
      old_init()
      menu.local_script_loaded = true
      params:add_separator("semiconductor")
    
      params:add_option("semiconductor_host_enabled","host enbaled", {"false", "true"},1)
      params:set_action("semiconductor_host_enabled", function(x) 
        if x == 2 then
          menu.set_host_mode(true)
        else
          menu.set_host_mode(false)
        end
    end )
  end
end)


--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--


function test_outside(from)
  print("test outside successful from", from)
end

function test_osc_async_await()

  aw.async(function ()
    local osc_aa = aw.await(function (cb)
      osc_lib.send({'192.168.0.193',10111},'test_call_async_await',{'my osc args'})
      cb("success: osc_async_await test completed")
    end)
    print("osc async_await callback received: ",osc_aa)
  end)
end

function test_async_await()
  aw.async(function ()
    print("async func starting")
    local hello = aw.await(function (cb)
      test_outside("hello")
      timer = metro.init(function() 
          cb("hello")
      end, 1, 1)
      timer:start()
    end)
  
    local world = aw.await(function (cb)
      test_outside("world")
      timer = metro.init(function() 
        cb("world")
      end, 1, 1)
      timer:start()
    end)
  
    print(hello, world)
  end)
end

mod.hook.register("script_post_cleanup", "clear the matrix for the next script", function()
  menu.unregister()
  menu.reset()
  print("cleanup")
end)

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, menu)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api = {}

api.get_state = function()
  return state
end

return api