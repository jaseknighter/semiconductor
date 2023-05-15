-- superconductor
-- a norns ensemble mod

-- @jaseknighter
-- docs: https://github.com/jaseknighter/semiconductor

--[[
  todo:
    * update code for params of type tFILE, tTEXT, tTRIGGER, tBINARY
    * add check for registering the same norns ip address multiple times
    * add cancellation for registering norns name and ip
    * add small delay when requesting params so cpus aren't overloaded
    * figure out why REGISTER menu doesn't immediately udpate after registration ('unregister' doesn't show)
    * figure out how to switch hosts
    * update mod menu values when selected script's params are updated
    * update p.triggered to account for multiple script registrations
    * address use case: host norns stops hosting (e.g. norns restarts or host param is set to "off")
]]


local mod = require 'core/mods'
local controlspec = require 'controlspec'

include('semiconductor/lib/globals')
menu = include('semiconductor/lib/menu')
player_params = include('semiconductor/lib/player_params')

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
    --[[
      --macro control params
      pix = -- get pix from menu.pmap_vals table
      local dx = p.fine and (d/20) or d
      local reg = p.get_registration_by_idx(p.selected_script)
      local ip = reg.ip
      pparams[norns_to_edit]:delta(ip,pix,dx)
    ]]
    params:add_group("macro controls",max_pmaps)
    for i=1,max_pmaps do 
      params:add_control("macro_control"..i," macro control"..i, controlspec.new(0, 1, "lin", 0.001, 0.0, ""))
      params:set_action("macro_control"..i, function(val) 
        mcm = get_macro_control_map(i)
        for i=1,#mcm do
          local norns_name = mcm[i].norns_name
          local ip = mcm[i].ip
          for j=1,#mcm[i].ixes do
            pparams[norns_name]:set_to_range(ip,mcm[i].ixes[j],val)
          end
        end
      end)
    end
    params:add_number("macro_x","macro x",1,max_pmaps,1)
    params:add_number("macro_y","macro y",2,max_pmaps,2)
  end
end)

function get_macro_control_map(ix)
  mcm={}
  local script_num = 1
  for k,v in pairs(menu.registrations) do
    local norns_name = v.norns_name
    mcm[script_num] = {}
    mcm[script_num].norns_name = norns_name
    mcm[script_num].ip = v.ip
    mcm[script_num].ixes = {}
    local pmap_vals = menu.pmap_vals[norns_name]
    local num_params = 1
    for k1,v1 in pairs(pmap_vals) do
      if ix == v1 then
        mcm[script_num].ixes[num_params] = k1
        num_params = num_params + 1
      end
    end
    script_num = script_num + 1
  end
  return mcm
end

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