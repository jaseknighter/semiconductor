
local osc_lib = {}

-- dev notes
--[[
  * when 
]]
-- paths
--[[
/preregister, {ip, norns_name}
/register, {ip,norns_name,script,params}
/unregister, {ip,norns_name}
/registrations. {registered_ips}
/request_control
/accept_control

/params_updated, {ip,norns_name,script,updated_params}
/set_param,{ip,norns_name,script,param_id,param_value}

]]

--async calls and responses




function osc.event(path,args,from)
  -- print("osc.event path",path)
  args = args and args or {}
  if path=="register_with_host" then
    menu.registrations[args[2]]={ip=args[1], norns_name=args[2], script=args[3]}
    print("registered with host",args[1], args[2], args[3])
    for k,v in pairs(menu.registrations) do
      local reg = menu.registrations[k]
      for k1,v1 in pairs(menu.registrations) do
        local reg1 = menu.registrations[k1]
        -- osc_lib.send({reg.ip,10111}, "new_norns_registered",{args[1], args[2], args[3]})
        osc_lib.send({reg.ip,10111}, "new_norns_registered",{reg1.ip,reg1.norns_name,reg1.script})
      end
    end
    menu:set_menu_mode("mMAIN_MENU")
  elseif path=="unregister" then
    for k,v in pairs(menu.registrations) do
      local reg = menu.registrations[k]
      if reg.norns_name == args[2] then
        -- remove from local registration table
        menu.registrations[k]=nil
        print("found script to unregister", args[2],args[3])
        -- if unregistered script is currently selected for editing, clear the params
        if i == menu.selected_script then
          print("unregistered script is selected!!! clear params!!!")
          menu.selected_script_unregistered()
        end
      end
      -- osc_lib.send({reg.ip,10111}, "new_norns_registered",{args[1], args[2], args[3]})
    end

    -- elseif path=="get_registered_norns" then
  elseif path=="new_norns_registered" then
    local ip=args[1]
    local norns_name=args[2]
    local script=args[3]
    if params:get("semiconductor_host_enabled")==1 and menu.registrations[norns_name] == nil then
      menu.registrations[norns_name]={ip=args[1], norns_name=args[2], script=args[3]}
    else
      print("new_norns_registered: ", args[1], args[2], args[3])
    end
    menu.update_menu()
    if pparams[norns_name] == nil then
      pparams[norns_name]=player_params:new()
      -- pparams[norns_name]:get_params(menu.params_loaded, ip, norns_name, script)
      pparams[norns_name]:get_params(menu.params_loaded, ip, norns_name, script)
    end
  elseif path=="script_updated_broadcast" then
    --broadcast message about new script loaded to registered norns
  elseif path=="get_params_call" then
    local callback = args[1]
    local params_json = json.encode(params)
    local len = string.len(params_json)
    local max_slice = 800
    local num_iterations = math.ceil(len/max_slice)
    local norns_name = args[2]
    local script = args[3]
    for i=1,num_iterations do
      local slice_idx = i.."_"..num_iterations
      local slice_start = 1+(max_slice*(i-1))
      local slice_end = max_slice + (max_slice*(i-1))
      local slice = string.sub(params_json,slice_start,slice_end)
      osc_lib.send({from[1],10111},'get_params_response',{callback,slice,slice_idx,norns_name, script})
    end
    -- osc_lib.send({from[1],10111},'get_params_response',{callback,params_json})
  elseif path=="get_params_response" then
    print("params received", #callbacks, table.unpack(args))
    -- tab.print(callbacks)
    local callback = args[1]
    local slice = args[2]
    local slice_idx = args[3]
    local norns_name = args[4]
    local script = args[5]
    callbacks[callback](slice,slice_idx,norns_name, script)
  elseif path=="get_string_call" then
    -- osc_lib.send(path,'test_return_async_await',args)
    local callback = args[1]
    local pix = args[2]
    local str = params:string(pix)
    osc_lib.send({from[1],10111},'get_string_response',{callback,pix,str})
  elseif path=="get_string_response" then
    local callback = args[1]
    local pix = args[2]
    local str = args[3]
    -- print("get_string response received", callback,pix,str,callbacks[callback])
    if callbacks[callback] then
      callbacks[callback](pix,str)
    else
      print("WARNING: callback not found for param index ", pix)
    end

  elseif path=="delta_call" then
    -- osc_lib.send(path,'test_return_async_await',args)
    local callback = args[1]
    local pix = args[2]
    local delta = args[3]
    params:delta(pix,delta)
    local str = params:string(pix)
    print("delta call", from[1], callback, pix,delta,str)
    osc_lib.send({from[1],10111},'get_string_response',{callback,pix,str})
  elseif path=="delta_response" then
    local callback = args[1]
    local pix = args[2]
    local str = args[3]
    print("delta response received", callback,pix,str,callbacks[callback])
    if callbacks[callback] then
      
      callbacks[callback](pix,str)
    end

    -- elseif path=="get_count_call" then
  --   -- osc_lib.send(path,'test_return_async_await',args)
  --   local callback = args[1]
  --   osc_lib.send({from[1],10111},'get_count_response',{callback})
  -- elseif path=="get_count_response" then
  --   print("count received", table.unpack(args))
  --   tab.print(callbacks)
  --   callbacks[args[1]](args[2])
  
  
  
  
  elseif path=="test" then -- tests
    print("received!!! >>>>>>>>")
    print("path",path)
    print("from:")
    tab.print(from)
    print("args:")
    tab.print(args)

  elseif path == "test_call_async_await" then
    print("success: test_call_async_await", from[1],from[2],table.unpack(args))
    print("osc_lib.send")
    osc_lib.send({from[1],10111},'test_return_async_await',args)
  elseif path == "test_return_async_await" then
    print("success: test_return_async_await", from[1],from[2],table.unpack(args))
  elseif path == "send" then
    print("external IP "..from[1])
    external_osc_IP = from[1]
  end
end

--example: osc_lib.send({'169.254.166.46',10111},'test',{'received!!!'})
--example: osc_lib.send({'192.168.0.193',10111},'test',{'received!!!'})
--example: osc_lib.send({'192.168.0.193',10111},'test_call_async_await',{'test!!!'})
function osc_lib.send(to, path, args)
  args=args and args or {}
  print("osc_lib send: ", table.unpack(to), path, table.unpack(args))
  osc.send(to, path, args)
end

return osc_lib