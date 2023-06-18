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
cs = require 'controlspec'
textentry = require 'textentry'
fileselect = require 'fileselect'

sc_json = require "semiconductor/lib/json/json"

include('semiconductor/lib/globals')
sc_menu = include('semiconductor/lib/menu')
player_params = include('semiconductor/lib/player_params')
sc_save_load = include('semiconductor/lib/save_load')
--lz sc_lorenz = include('semiconductor/lib/macros/lorenz')


--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some state values
--

local state = {
  norns_ips = {}, -- table for ips of registered norns 
  inited = false,
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
    
    old_osc_event = osc.event
    osc_lib = include('semiconductor/lib/osc_lib')

    sc_menu.local_script_loaded = true
    --lz sc_lorenz.init()
    params:add_separator("semiconductor")
  
    -- params:add_option("semiconductor_host_enabled","host enbaled", {"false", "true"},2)
    -- params:set_action("semiconductor_host_enabled", function(x) 
    --   if x == 2 then
    --     sc_menu.set_host_mode(true)
    --   else
    --     sc_menu.set_host_mode(false)
    --   end
    -- end )
    
    --[[
      --macro control params
      pix = -- get pix from sc_menu.pmap_vals table
      local dx = p.fine and (d/20) or d
      local reg = p.get_registration_by_idx(p.selected_script)
      local ip = reg.ip
      pparams[norns_to_edit]:delta(ip,pix,dx)
    ]]
    params:add_group("group sync",3)
    params:add_control("output_levels", "output levels", 
      cs.new(-math.huge,6,'db',0,norns.state.mix.output,"dB"))
      params:set_action("output_levels", function(val) 
        osc_lib.set_param_all("output_level",val)
    end)
    params:add_number("clock_tempos", "tempos", 1, 300, norns.state.clock.tempo)
    params:set_action("clock_tempos", function(val) 
      osc_lib.set_param_all("clock_tempo",val)
    end)
    params:add_trigger("clocks_reset", "clocks reset")
    params:set_action("clocks_reset", function(val) 
      osc_lib.set_param_all("clock_reset",val)
    end)

    -------------------------
    --macro controls
    -------------------------
    params:add_group("macro controls",max_pmaps)
      for i=1,max_pmaps do 
        params:add_control("macro_control"..i," macro control"..i, cs.new(0, 1, "lin", 0.001, 0.0, ""))
        params:set_action("macro_control"..i, function(val) 
          mcm = get_macro_control_map(i)
          for i=1,#mcm do
            if mcm[i].norns_name then
              local norns_name = mcm[i].norns_name
              local ip = mcm[i].ip
              for j=1,#mcm[i].ixes do
                pparams[norns_name]:set_to_range(ip,mcm[i].ixes[j],val)
              end
            end
          end
        end)
    end
    -- params:add_number("macro_x","macro x",1,max_pmaps,1)
    -- params:add_number("macro_y","macro y",2,max_pmaps,2)

  --[[ lorenz
    --lorenz params
    params:add_group("lorenz macro params",7)

    params:add{
      type="option", id = "lz_x_input", name = "x input", options={"first","second","third"},default = 1,
      action=function(x) 
        -- lorenz:clear()
      end
    }
    params:add{
      type="option", id = "lz_y_input", name = "y input", options={"first","second","third"},default = 2,
      action=function(x) 
        -- lorenz:clear()
      end
    }

    params:add{
      type="number", id = "lz_x_offset", name = "x offset",min=-128, max=128, default = 0,
      action=function(x) 
        -- lorenz:clear()
      end
    }
    params:add{
      type="number", id = "lz_y_offset", name = "y offset",min=-64, max=64, default = 0,
      action=function(x) 
        -- lorenz:clear()
      end
    }

    params:add{
      type="number", id = "lz_xy_offset", name = "xy offset",min=-64, max=64, default = 0,
      action=function(x) 
        params:set("lz_x_offset",x)
        params:set("lz_y_offset",x)
        -- lorenz:clear()
      end
    }

    params:add{
      type="taper", id = "lz_x_scale", name = "x scale",min=0.01, max=10, default = 1,
      action=function(x) 
        -- lorenz:clear()
      end
    }
    
    params:add{
      type="taper", id = "lz_y_scale", name = "y scale",min=0.01, max=10, default = 1,
      action=function(x) 
        -- lorenz:clear()
      end
    }    

    params:add_group("lorenz weights",16)
    local xyz = {}
    local sc_lz_weights_cs = cs.new(0, 3, 'lin', 0.01, 0, "",0.001)
    for i=1,4 do
      local outs = {"1st","2nd","3rd","sum"}
      local axes = {"x","y","z"}
      local out,axis
      for j=1,3 do
        if j==1 then
          params:add_separator("output: " .. outs[i])
        end
        out=outs[i]
        axis=axes[j]
        local cs = deep_copy(sc_lz_weights_cs)
        cs.default = LORENZ_WEIGHTS_DEFAULT[i][j]
        params:add{
          type="control", id = "sc_lz_weight"..i.."_"..j, name = "w-" .. out..": "..axis.."", controlspec=cs,
          -- type="number", id = "sc_lz_weight"..i.."_"..j, name = "lz weight "..out..": "..axis.."", min=0,max=10,default = LORENZ_WEIGHTS_DEFAULT[i][j],
          action=function(x) 
            sc_lorenz.weights[i][j] = x
          end
        }
        
      end
    end
  ]]

    sc_save_load.init()
    state.inited = true
  end
end)

function get_macro_control_map(ix)
  mcm={}
  local script_num = 1
  if sc_menu.registrations == nil then return nil end
  for k,v in pairs(sc_menu.registrations) do
    local norns_name = v.norns_name
    mcm[script_num] = {}
    mcm[script_num].norns_name = norns_name
    mcm[script_num].ip = v.ip
    mcm[script_num].ixes = {}
    local pmap_vals = sc_menu.pmap_vals[norns_name]
    local num_params = 1
    if pmap_vals then
      for k1,v1 in pairs(pmap_vals) do
        if ix == v1 then
          mcm[script_num].ixes[num_params] = k1
          num_params = num_params + 1
        end
      end
    end
    script_num = script_num + 1
  end
  return mcm
end

--
-- [optional]   menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--



mod.hook.register("script_post_cleanup", "clear the matrix for the next script", function()
  sc_menu.unregister()
  sc_menu.reset()
  print("semiconductor cleanup")
  osc.event = old_osc_event

end)

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, sc_menu)


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