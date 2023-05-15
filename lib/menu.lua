
local mod = require 'core/mods'

local fileselect = require 'fileselect'
local textentry = require 'textentry'
local xy = include('semiconductor/lib/macros/xy')
-- local player_params = include('semiconductor/lib/player_params')
-- local globals = include('semiconductor/lib/globals')

-- pparams={}

local mode_items_prereg = { "REGISTER >"}
local mode_items_postreg = { "REGISTER >", "PLAYERS >","PMAP >", "MACROS >"}
local mode_items = mode_items_prereg
local reg_texts_pre = {"register"}
local reg_texts_post = {"register","unregister"}
local reg_texts = reg_texts_pre
local macro_texts = {"xy"}
-- local macro_texts = {"xy","lorenz"}
-- local pset = {}

local p = {
  mMAIN_MENU = 0,
  mREGISTER = 1,
  mSCRIPT_SELECT = 2,
  mEDIT = 3,
  mPMAP_SCRIPT_SELECT = 4,
  mPMAP_EDIT = 5,
  mMACRO_SELECT = 6,
  mMACRO_CONTROL = 7,
  pvals = {},
  pmap_vals = {},
  pmaps_set=false,
  page=nil,
  pos = 0,
  oldpos = 0,
  group = false,
  groupid = 0,
  alt = false,
  mode = 0, --mMAIN_MENU
  mode_prev = 0, --mMAIN_MENU
  mode_pos = 1,
  map = false,
  mpos = 1,
  dev = 1,
  ch = 1,
  cc = 100,
  pm,
  selected_t=nil,
  selected_value=nil,
  selected_script,
  selected_macro,
  -- ps_pos = 0,
  -- ps_n = 0,
  -- ps_action = 1,
  -- ps_last = 0,
  dir_prev = nil,
  registrations = {},
  registering = false,
  host_ip = nil,
  host_mode = false,
  reg_ip=nil,
  norns_name=nil,
  send = {},
  local_script_loaded = nil,
  on = {},
}

-- -- add norns to local registration table
-- p.host_add_registration = function(norns_name)
-- end 

-- -- add norns from local registration table
-- p.host_remove_registration = function(norns_name)
--   --unregister
-- end 

function p:detect_pmaps ()
  self.pmaps_set = false
  for k,v in pairs(self.pmap_vals) do
    for k1,v1 in pairs(v) do
      if v1 and v1>0 then
        self.pmaps_set = true
        print(k,k1,v1)
      end
    end
  end  
end

p.set_host_ip = function(host_ip)
  p.host_ip = host_ip
end

p.set_host_mode = function(act_as_host)
  p.host_mode = act_as_host
end
-- broadcast added registration
p.host_registration_added = function(norns_name)
  -- table.insert(p.registrations,{host_ip=host_ip, my_ip=wifi.ip,norns_name=p.norns_name, my_script=script})
end 

-- broadcast removed registration
p.host_registration_removed = function(norns_name)
  -- table.insert(p.registrations,{host_ip=host_ip, my_ip=wifi.ip,norns_name=p.norns_name, my_script=script})
end 

  -- register norns with host
p.reg_norns_with_host = function(norns_name)
  if norns_name == nil then -- cancel
    p.registering=false
  else
    p.norns_name = norns_name
    screen.clear()
    textentry.enter(p.reg_ip_with_host, host_ip, "ENTER HOST IP")
  end
  screen.update()
end 

-- register norns with host
p.reg_ip_with_host = function(host_ip)
  --NOTE: remove this line after testing
  if host_ip ~= nil then -- cancel
    p.set_host_ip(host_ip)
    local script = norns.state.name
    osc_lib.send({host_ip,10111}, "register_with_host",{wifi.ip, p.norns_name, script})
  end
  screen.clear()
  p.registering=false
end 

-- unregister norns with host
p.unregister = function()
  -- host_ip=wifi.ip
  local script = norns.state.name
  for k,v in pairs(menu.registrations) do
    local reg = menu.registrations[k]
    osc_lib.send({reg.ip,10111}, "unregister",{wifi.ip, p.norns_name, script})
  end
  -- p.update_menu()
end 

p.get_num_registrations = function()
  local num_reg=0
  for k,v in pairs(menu.registrations) do
    if k then num_reg = num_reg+1 end
  end
  return num_reg
end

p.get_registration_by_idx = function(idx_target)
  local idx=1
  for k,v in pairs(menu.registrations) do
    if idx==idx_target then return v end
    idx=idx+1
  end
end

p.update_menu = function()
  if p.get_num_registrations() > 0 then
    mode_items = mode_items_postreg
    reg_texts = reg_texts_post
  else
    mode_items = mode_items_prereg
    reg_texts = reg_texts_pre
  end
end

-- called from menu on script reset
p.reset = function()
  p.page = nil
  p.pvals = {}
  p.pos = 0
  p.group = false
  -- p.ps_pos = 0
  -- p.ps_n = 0
  -- p.ps_action = 1
  -- p.ps_last = norns.state.pset_last
  p.mode = p.mMAIN_MENU
  --
  p.groupid = 0
  p.alt = false
  p.mode_prev = p.mEDIT
  p.mod_pos = 1
  p.mpos = 1
  p.paramname = nil
  p.param_id = nil
end

local function buildpage(norns_to_edit)
  p.page = {}
  if p.mode == p.mREGISTER then
    for i=1,#reg_texts do table.insert(p.page,i) end
  elseif p.mode == p.mSCRIPT_SELECT then
    for i=1,p.get_num_registrations() do table.insert(p.page,i) end
  elseif p.mode == p.mEDIT then
    local i = 1
    repeat
      if pparams[norns_to_edit]:visible(i) then table.insert(p.page, i) end
      if pparams[norns_to_edit]:t(i) == pparams[norns_to_edit].tGROUP then
        i = i + pparams[norns_to_edit]:get_group_size(i) + 1
      else i = i + 1 end
    until i > pparams[norns_to_edit].count
  elseif p.mode == p.mPMAP_SCRIPT_SELECT then
    for i=1,p.get_num_registrations() do table.insert(p.page,i) end
  elseif p.mode == p.mPMAP_EDIT then
    local i = 1
    repeat
      if pparams[norns_to_edit]:visible(i) then table.insert(p.page, i) end
      if pparams[norns_to_edit]:t(i) == pparams[norns_to_edit].tGROUP then
        i = i + pparams[norns_to_edit]:get_group_size(i) + 1
      else i = i + 1 end
    until i > pparams[norns_to_edit].count
  elseif p.mode == p.mMACRO_SELECT then
    for i=1,#macro_texts do table.insert(p.page,i) end
  end
end

function p.selected_script_unregistered(norns_name)
  pparams[norns_name]=nil
  p.selected_script=nil
  p.on = {}
  p.pos=0
  p.mode=1
  p:set_menu_mode("mMAIN_MENU")
  buildpage()
  p.update_menu()
  -- pparams=player_params:new()
end

local function build_sub(sub)
  p.page = {}
  local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
  for i = 1,pparams[norns_to_edit]:get_group_size(sub) do
    if pparams[norns_to_edit]:visible(i + sub) then
      table.insert(p.page, i + sub)
    end
  end
end

function p:set_menu_mode(mode)
  p.mode = self[mode]
  if mode ~= "mEDIT" and mode ~= "mPMAP_EDIT" and mode ~= "mMACRO_CONTROL" then buildpage() end
end

p.key = function(n,z)
  if n==1 and z==1 then
    p.alt = true
    
  elseif n==1 and z==0 then
    p.alt = false
  -- MODE MENU
  elseif p.mode == p.mMAIN_MENU then
    if n==2 and z== 1 then
      mod.menu.exit()    
    elseif n==3 and z==1 then
      if p.mode_pos == p.mREGISTER then
        p.mode = p.mREGISTER
      elseif p.mode_pos == p.mSCRIPT_SELECT then
        p.mode = p.mSCRIPT_SELECT
      elseif p.mode_pos == p.mPMAP_SCRIPT_SELECT - 1 then
        p.mode = p.mPMAP_SCRIPT_SELECT
      elseif p.mode == p.mMAIN_MENU and p.mode_pos == p.mMACRO_SELECT - 2 then
        p.mode = p.mMACRO_SELECT
      end
      buildpage()
    end
  -- MODE REGISTER
  elseif p.mode == p.mREGISTER then
    local i = p.page[p.pos+1]
    if n==2 and z==1 then
      if p.mode ~= p.mMAIN_MENU then
        p.mode = p.mMAIN_MENU
      end
    elseif n==3 and z==1 then
      if reg_texts[i] == "register" then
        screen.clear()
        p.registering=true
        textentry.enter(p.reg_norns_with_host, norns_name, "ENTER NORNS NAME")
        screen.update()
      elseif reg_texts[i] == "unregister" then
        p.unregister()
      end
    end
  -- MODE SELECT SCRIPT
  elseif p.mode == p.mSCRIPT_SELECT then
    local i = p.page[p.pos+1]
    if n==2 and z==1 then
      if p.mode ~= p.mMAIN_MENU then
        p.mode = p.mMAIN_MENU
      end
    elseif n==3 and z==1 then
      screen.clear()
      --IMPORTANT: this is where we get_params
      p.selected_script = i
      p:set_menu_mode("mEDIT")
      local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
      print("selscript,norns_to_edit",p.selected_script,norns_to_edit)
      buildpage(norns_to_edit)
      p.update_menu()
    end
  -- EDIT
  elseif p.mode == p.mEDIT and pparams[p.get_registration_by_idx(p.selected_script).norns_name].count > 0 then
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    local i = p.page[p.pos+1]
    local t = pparams[norns_to_edit]:t(i)
    if n==2 and z==1 then
      if p.group==true then
        p.group = false
        buildpage(norns_to_edit)
        p.pos = p.oldpos
      elseif p.mode ~= p.mMAIN_MENU then
        p.mode = p.mSCRIPT_SELECT
        buildpage()
        p.pos = p.oldpos
      end
    elseif n==3 and z==1 then
      if t == pparams[norns_to_edit].tGROUP then
        build_sub(i)
        p.group = true
        p.groupid = i
        -- p.groupname = params:string(i)
        local mp = pparams[norns_to_edit]:lookup_param(i)
        p.groupname = mp.name
        p.oldpos = p.pos
        p.pos = 0
      elseif t == pparams[norns_to_edit].tSEPARATOR then
        local n = p.pos+1
        repeat
          n = n+1
          if n > #p.page then n = 1 end
        until pparams[norns_to_edit]:t(p.page[n]) == pparams[norns_to_edit].tSEPARATOR
        p.pos = n-1
      elseif t == pparams[norns_to_edit].tFILE then
        -- if p.mode == p.mEDIT then
        --   fileselect.enter(_path.dust, p.newfile)
        --   local fparam = params:lookup_param(i)
        --   local dir_prev = fparam.dir or p.dir_prev
        --   if dir_prev ~= nil then
        --     fileselect.pushd(dir_prev)
        --   end
        -- end
      elseif t == pparams[norns_to_edit].tTEXT then
        if p.mode == p.mEDIT then
          textentry.enter(p.newtext, p.selected_value, "PARAM: "..pparams[norns_to_edit]:get_name(i))
        end
      elseif t == pparams[norns_to_edit].tTRIGGER then
        if p.mode == p.mEDIT then
          params:set(i)
          p.triggered[i] = 2
        end
      elseif t == pparams[norns_to_edit].tBINARY and p.mode == p.mEDIT then 
        local reg = p.get_registration_by_idx(p.selected_script)
        local ip = reg.ip
        pparams[norns_to_edit]:delta(ip,i,1)
        if pparams[norns_to_edit]:lookup_param(i).behavior == 'trigger' then 
          p.triggered[i] = 2
        -- else p.on[i] = params:get(i) end
        else p.on[i] = p.selected_value end
      else
        p.fine = true
      end
    elseif n==3 and z==0 then
      p.fine = false
      if t == pparams[norns_to_edit].tBINARY then
        if p.mode == p.mEDIT then
          local reg = p.get_registration_by_idx(p.selected_script)
          local ip = reg.ip
            pparams[norns_to_edit]:delta(ip,i, 0)
          if pparams[norns_to_edit]:lookup_param(i).behavior ~= 'trigger' then
            p.on[i] = p.selected_value
            -- p.on[i] = params:get(i) 
          end
        end
      end
    end
  -- PMAP SELECT SCRIPT
  elseif p.mode == p.mPMAP_SCRIPT_SELECT then
    local i = p.page[p.pos+1]
    print("map script select i",i)
    if n==2 and z==1 then
      if p.mode ~= p.mMAIN_MENU then
        p.mode = p.mMAIN_MENU
      end
    elseif n==3 and z==1 then
      screen.clear()
      p.selected_script = i
      p:set_menu_mode("mPMAP_EDIT")
      local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
      print("selscript,norns_to_edit_map",p.selected_script,norns_to_edit)
      buildpage(norns_to_edit)
      p.update_menu()
    end
  -- PMAP EDIT
  elseif p.mode == p.mPMAP_EDIT and pparams[p.get_registration_by_idx(p.selected_script).norns_name].count > 0 then
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    local i = p.page[p.pos+1]
    local t = pparams[norns_to_edit]:t(i)
    if n==2 and z==1 then
      print(i,t,p.pos)
      if p.group==true then
        p.group = false
        buildpage(norns_to_edit)
        p.pos = p.oldpos
      elseif p.mode ~= p.mMAIN_MENU then
        p.mode = p.mPMAP_SCRIPT_SELECT
        buildpage()
        p.pos = p.oldpos
      end
    elseif n==3 and z==1 then
      if t == pparams[norns_to_edit].tGROUP then
        build_sub(i)
        p.group = true
        p.groupid = i
        -- p.groupname = params:string(i)
        local mp = pparams[norns_to_edit]:lookup_param(i)
        p.groupname = mp.name
        p.oldpos = p.pos
        p.pos = 0
      elseif t == pparams[norns_to_edit].tSEPARATOR then
        local n = p.pos+1
        repeat
          n = n+1
          if n > #p.page then n = 1 end
        until pparams[norns_to_edit]:t(p.page[n]) == pparams[norns_to_edit].tSEPARATOR
        p.pos = n-1
      elseif t == pparams[norns_to_edit].tFILE then
        -- if p.mode == p.mEDIT then
        --   fileselect.enter(_path.dust, p.newfile)
        --   local fparam = params:lookup_param(i)
        --   local dir_prev = fparam.dir or p.dir_prev
        --   if dir_prev ~= nil then
        --     fileselect.pushd(dir_prev)
        --   end
        -- end
      elseif t == pparams[norns_to_edit].tTEXT then
        if p.mode == p.mEDIT then
          textentry.enter(p.newtext, p.selected_value, "PARAM: "..pparams[norns_to_edit]:get_name(i))
        end
      elseif t == pparams[norns_to_edit].tTRIGGER then
        if p.mode == p.mEDIT then
          params:set(i)
          p.triggered[i] = 2
        end
      elseif t == pparams[norns_to_edit].tBINARY and p.mode == p.mEDIT then 
        local reg = p.get_registration_by_idx(p.selected_script)
        local ip = reg.ip
        pparams[norns_to_edit]:delta(ip,i,1)
        if pparams[norns_to_edit]:lookup_param(i).behavior == 'trigger' then 
          p.triggered[i] = 2
        -- else p.on[i] = params:get(i) end
        else p.on[i] = p.selected_value end
      else
        p.fine = true
      end
    elseif n==3 and z==0 then
      p.fine = false
      if t == pparams[norns_to_edit].tBINARY then
        if p.mode == p.mEDIT then
          local reg = p.get_registration_by_idx(p.selected_script)
          local ip = reg.ip
            pparams[norns_to_edit]:delta(ip,i, 0)
          if pparams[norns_to_edit]:lookup_param(i).behavior ~= 'trigger' then
            p.on[i] = p.selected_value
            -- p.on[i] = params:get(i) 
          end
        end
      end
    end
  elseif p.mode == p.mMACRO_SELECT then
    local i = p.page[p.pos+1]
    if n==2 and z==1 then
      if p.mode ~= p.mMAIN_MENU then
        p.mode = p.mMAIN_MENU
      end
    elseif n==3 and z==1 then
      screen.clear()
      --IMPORTANT: this is where we get_params
      p.selected_macro = i
      p:set_menu_mode("mMACRO_CONTROL")
      p:detect_pmaps()
      buildpage()
      p.update_menu()
    end
  elseif p.mode == p.mMACRO_CONTROL then
    -- local i = p.page[p.pos+1]
    if n==2 and z==1 then
      p.mode = p.mMACRO_SELECT
      buildpage()
      p.pos = p.oldpos
    
    elseif n==3 and z==1 then
      -- screen.clear()
      -- --IMPORTANT: this is where we get_params
      -- p.selected_macro = i
      -- p:set_menu_mode("mMACRO_CONTROL")
      -- buildpage()
      -- p.update_menu()
    end
  end
  p.redraw()
  _menu.redraw()
end

p.enc = function(n,d)
  -- MODE MENU
  if p.mode == p.mMAIN_MENU then
    local prev = p.mode_pos
    p.mode_pos = util.clamp(p.mode_pos + d, 1, #mode_items)
    if p.mode_pos ~= prev then _menu.redraw() end
  -- MODE REGISTER
  elseif p.mode == p.mREGISTER then
    if n==2 and p.alt==false then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
    end
  -- MODE SELECT SCRIPT
  elseif p.mode == p.mSCRIPT_SELECT then
    if n==2 and p.alt==false then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
  end
  -- MODE EDIT SCRIPT PARAMS
  -- elseif p.mode == p.mEDIT then
  --   if n==2 and p.alt==false then
  --     local prev = p.pos
  --     p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
  --     if p.pos ~= prev then p.redraw() end
  --   end

  elseif p.mode == p.mEDIT then
  --   local prev = p.mode_pos
  --   p.mode_pos = util.clamp(p.mode_pos + d, 1, 3)
  --   if p.mode_pos ~= prev then p.redraw() end
  -- -- EDIT
  -- elseif p.mode == p.mEDIT or p.mode == mMAP then
    -- normal scroll
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    if n==2 and p.alt==false then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
      p.selected_t=pparams[norns_to_edit]:t(p.page[p.pos+1])
      if p.selected_t==pparams.tTEXT then
        local mp = pparams[norns_to_edit]:lookup_param(p.page[p.pos+1])
        p.selected_value=mp.text
      elseif (p.selected_t==pparams.tBINARY) then
        local mp = pparams[norns_to_edit]:lookup_param(p.page[p.pos+1])
        p.selected_value=mp.value
      else 
        --setting to nil because p.selected_value is only needed to get the value of text and binary in the key func 
        p.selected_value=nil
      end
    -- jump section
    elseif n==2 and p.alt==true then
      d = d>0 and 1 or -1
      local i = p.pos+1
      repeat
        i = i+d
        if i > #p.page then i = 1 end
        if i < 1 then i = #p.page end
      until pparams[norns_to_edit]:t(p.page[i]) == pparams[norns_to_edit].tSEPARATOR or i==1
      p.pos = i-1
    -- adjust value
    elseif p.mode == p.mEDIT and n==3 and pparams[norns_to_edit].count > 0 then
      local dx = p.fine and (d/20) or d
      -- p.pvals[p.page[p.pos+1]]=nil
      local reg = p.get_registration_by_idx(p.selected_script)
      local ip = reg.ip
      pparams[norns_to_edit]:delta(ip,p.page[p.pos+1],dx)
      -- p.redraw()
    end
  elseif p.mode == p.mPMAP_SCRIPT_SELECT then
    if n==2 and p.alt==false then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
  end
  -- MODE EDIT SCRIPT PARAMS
  -- elseif p.mode == p.mEDIT then
  --   if n==2 and p.alt==false then
  --     local prev = p.pos
  --     p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
  --     if p.pos ~= prev then p.redraw() end
  --   end

  elseif p.mode == p.mPMAP_EDIT then
  --   local prev = p.mode_pos
  --   p.mode_pos = util.clamp(p.mode_pos + d, 1, 3)
  --   if p.mode_pos ~= prev then p.redraw() end
  -- -- EDIT
  -- elseif p.mode == p.mEDIT or p.mode == mMAP then
    -- normal scroll
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    if n==2 and p.alt==false then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
      p.selected_t=pparams[norns_to_edit]:t(p.page[p.pos+1])
      if p.selected_t==pparams.tTEXT then
        local mp = pparams[norns_to_edit]:lookup_param(p.page[p.pos+1])
        p.selected_value=mp.text
      elseif (p.selected_t==pparams.tBINARY) then
        local mp = pparams[norns_to_edit]:lookup_param(p.page[p.pos+1])
        p.selected_value=mp.value
      else 
        --setting to nil because p.selected_value is only needed to get the value of text and binary in the key func 
        p.selected_value=nil
      end
    -- jump section
    elseif n==2 and p.alt==true then
      d = d>0 and 1 or -1
      local i = p.pos+1
      repeat
        i = i+d
        if i > #p.page then i = 1 end
        if i < 1 then i = #p.page end
      until pparams[norns_to_edit]:t(p.page[i]) == pparams[norns_to_edit].tSEPARATOR or i==1
      p.pos = i-1
    -- adjust value
    elseif p.mode == p.mPMAP_EDIT and n==3 and pparams[norns_to_edit].count > 0 then
      -- local dx = p.fine and (d/20) or d
      -- local reg = p.get_registration_by_idx(p.selected_script)
      -- local ip = reg.ip
      -- pparams[norns_to_edit]:delta(ip,p.page[p.pos+1],dx)
      local pix = p.page[p.pos+1]
      local pmap_val = p.pmap_vals[norns_to_edit][pix]
      if pmap_val == nil then pmap_val = 0 end
      pmap_val = util.clamp(pmap_val+d, 0, max_pmaps)
      p.pmap_vals[norns_to_edit][pix] = pmap_val
      print(d,pmap_val,p.pmap_vals[norns_to_edit][pix])
      -- p.redraw()
    end
  elseif p.mode == p.mMACRO_SELECT then
    if n==2 then
      local prev = p.pos
      p.pos = util.clamp(p.pos + d, 0, #p.page - 1)
      if p.pos ~= prev then p.redraw() end
    end
  -- MODE SELECT SCRIPT
  elseif p.mode == p.mMACRO_CONTROL then
    if macro_texts[p.selected_macro] == "xy" then
      xy.enc(n,d)  
    end
  end
end

-- p.newfile = function(file)
--   if file ~= "cancel" then
--     params:set(p.page[p.pos+1],file)
--     p.dir_prev = file:match("(.*/)")
--     p.redraw()
--   end
-- end

p.newtext = function(txt)
  print("SET TEXT: "..txt)
  if txt ~= "cancel" then
    params:set(p.page[p.pos+1],txt)
    p.redraw()
  end
end

p.redraw = function()
  if p.registering == true then return end
  if p.selected_script and (p.mode ~= p.mEDIT and p.mode ~= p.mPMAP_EDIT) then
    p.selected_script = nil
  end
  screen.clear()
  _menu.draw_panel()
  -- MAIN MENU
  if p.mode == p.mMAIN_MENU then
    screen.level(4)
    screen.move(0,10)
    screen.text("SEMICONDUCTOR")
    for i=1,#mode_items do
      if i==p.mode_pos then screen.level(15) else screen.level(4) end
      screen.move(0,10*i+20)
      screen.text(mode_items[i])
    end
  -- REGISTER SCRIPT
  elseif p.mode == p.mREGISTER and p.registering == false then
    if p.pos == 0 then
      local n = "SEMICONDUCTOR / REGISTRER"
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
        local pix = p.page[i+p.pos-2]
        screen.move(0,10*i)
        screen.text(reg_texts[pix])
        screen.move(127,10*i)
        -- add trigger rect
        screen.rect(124, 10 * i - 4, 3, 3)
        screen.fill()
      end
    end
 -- SELECT SCRIPT
  elseif p.mode == p.mSCRIPT_SELECT and p.registering == false then
    if p.pos == 0 then
      local n = "SEMICONDUCTOR / SCRIPTS"
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
        local pix = p.page[i+p.pos-2]
        local reg = p.get_registration_by_idx(pix)
        local name = reg.norns_name
        local script = reg.script
        local txt = name .. " / " .. script
        screen.move(0,10*i)
        screen.text(txt)
        screen.move(127,10*i)
        -- add trigger rect
        -- screen.rect(124, 10 * i - 4, 3, 3)
        screen.text_right(">")
        screen.fill()
      end
    end
  -- EDIT SCRIPT PARAMS
  elseif p.mode == p.mEDIT and p.page then
    if p.pos == 0 then
      local script = p.get_registration_by_idx(p.selected_script).script
      local n = "SEMICONDUCTOR" .. " / " .. script
      if p.group then n = n .. " / " .. p.groupname end
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    if p.selected_script == nil then
      p.selected_script=1
      print("WARNING: selected script nil!!!")
    end
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
          local pix = p.page[i+p.pos-2]
          local t = pparams[norns_to_edit]:t(pix)
          if t == pparams[norns_to_edit].tSEPARATOR then
            screen.move(0,10*i+2.5)
            screen.line_rel(127,0)
            screen.stroke()
            screen.move(63,10*i)
            screen.text_center(pparams[norns_to_edit]:get_name(pix))
          elseif t == pparams[norns_to_edit].tGROUP then
            screen.move(0,10*i)
            screen.text(pparams[norns_to_edit]:get_name(pix) .. " >")
          else
            screen.move(0,10*i)
            screen.text(pparams[norns_to_edit]:get_name(pix))
            screen.move(127,10*i)
            if t ==  pparams[norns_to_edit].tTRIGGER then
              if p.triggered[pix] and p.triggered[pix] > 0 then
                screen.rect(124, 10 * i - 4, 3, 3)
                screen.fill()
              end
            elseif t == pparams[norns_to_edit].tBINARY then
              fill = p.on[pix] or p.triggered[pix]
              if fill and fill > 0 then
                screen.rect(124, 10 * i - 4, 3, 3)
                screen.fill()
              end
            else
              -- screen.text_right(str)
              local val
              if p.pvals[pix]==nil then 
                local reg = p.get_registration_by_idx(p.selected_script)
                local ip = reg.ip
                clock.run(pparams[norns_to_edit].get_string,ip,pix)
                -- pparams.get_string(pix)
                val=""
              else
                val = p.pvals[pix]
              end
              screen.text_right(val)
            end
          end
        end
      end
  elseif p.mode == p.mPMAP_SCRIPT_SELECT then
    if p.pos == 0 then
      local n = "SEMICONDUCTOR / SCRIPTS"
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
        local pix = p.page[i+p.pos-2]
        local reg = p.get_registration_by_idx(pix)
        local name = reg.norns_name
        local script = reg.script
        local txt = name .. " / " .. script
        screen.move(0,10*i)
        screen.text(txt)
        screen.move(127,10*i)
        -- add trigger rect
        -- screen.rect(124, 10 * i - 4, 3, 3)
        screen.text_right(">")
        screen.fill()
      end
    end
  -- EDIT SCRIPT PARAMS
  elseif p.mode == p.mPMAP_EDIT and p.page then
    if p.pos == 0 then
      local script = p.get_registration_by_idx(p.selected_script).script
      local n = "SEMICONDUCTOR" .. " / " .. script
      if p.group then n = n .. " / " .. p.groupname end
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    if p.selected_script == nil then
      p.selected_script=1
      print("WARNING: selected script nil!!!")
    end
    local norns_to_edit = p.get_registration_by_idx(p.selected_script).norns_name
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
          local pix =   p.page[i+p.pos-2]
          local t = pparams[norns_to_edit]:t(pix)
          if t == pparams[norns_to_edit].tSEPARATOR then
            screen.move(0,10*i+2.5)
            screen.line_rel(127,0)
            screen.stroke()
            screen.move(63,10*i)
            screen.text_center(pparams[norns_to_edit]:get_name(pix))
          elseif t == pparams[norns_to_edit].tGROUP then
            screen.move(0,10*i)
            screen.text(pparams[norns_to_edit]:get_name(pix) .. " >")
          else
            screen.move(0,10*i)
            screen.text(pparams[norns_to_edit]:get_name(pix))
            screen.move(127,10*i)
            if t ==  pparams[norns_to_edit].tTRIGGER then
              if p.triggered[pix] and p.triggered[pix] > 0 then
                screen.rect(124, 10 * i - 4, 3, 3)
                screen.fill()
              end
            elseif t == pparams[norns_to_edit].tBINARY then
              fill = p.on[pix] or p.triggered[pix]
              if fill and fill > 0 then
                screen.rect(124, 10 * i - 4, 3, 3)
                screen.fill()
              end
            else
              local val
              if p.pmap_vals[norns_to_edit] == nil then p.pmap_vals[norns_to_edit] = {} end
              if p.pmap_vals[norns_to_edit][pix]==nil or p.pmap_vals[norns_to_edit][pix]==0 then 
                val="-"
              else
                val = p.pmap_vals[norns_to_edit][pix]
              end
              screen.text_right(val)
            end
          end
        end
      end
  elseif p.mode == p.mMACRO_SELECT then
    if p.pos == 0 then
      local n = "SEMICONDUCTOR / MACROS"
      screen.level(4)
      screen.move(0,10)
      screen.text(n)
    end
    
    for i=1,6 do
      if (i > 2 - p.pos) and (i < #p.page - p.pos + 3) then
        if i==3 then screen.level(15) else screen.level(4) end
        local pix = p.page[i+p.pos-2]
        local txt = macro_texts[pix]
        screen.move(0,10*i)
        screen.text(txt)
        screen.move(127,10*i)
        -- add trigger rect
        -- screen.rect(124, 10 * i - 4, 3, 3)
        screen.text_right(">")
        screen.fill()
      end
    end
  -- EDIT MACRO PARAMS
  elseif p.mode == p.mMACRO_CONTROL then
    if macro_texts[p.selected_macro] == "xy" then
      xy.redraw()  
    end
  end
  screen.update()
end

p.init = function()
  p.update_menu()
  -- pparams.count=0
  -- buildpage()
  -- p.page = nil
  -- pparams:get_params(p.init_complete)

  p.init_complete()
end

p.init_complete = function()
  print("menu init")
  if p.page == nil then buildpage() end
  p.alt = false
  p.fine = false
  p.triggered = {}
  p.timer = metro.init(function()
    for k, v in pairs(p.triggered) do
      if v > 0 then p.triggered[k] = v - 1 end
    end
    p.redraw()
  end)
  p.timer.time = 0.2
  p.timer.count = -1
  p.timer:start()
end

p.deinit = function()
  p.timer:stop()
end

p.params_loaded = function(norns_name)
  print("params loaded")
  -- p.on = {}
  p.on[norns_name] = {}
  for i,param in ipairs(pparams[norns_name].params) do
    if param.t == pparams[norns_name].tBINARY then
        if pparams[norns_name]:lookup_param(i).behavior == 'trigger' then 
          p.triggered[i] = 2
        else 
          local mp = pparams[norns_name]:lookup_param(i)
          p.on[norns_name][i] = mp.value
          -- p.on[i] = params:get(i) 
        end
    end
  end
  p:set_menu_mode("mMAIN_MENU")
  buildpage()
  p.update_menu()
end

p.rebuild_params = function()
  if p.mode == p.mEDIT or p.mode == p.mPMAP_EDIT then 
    if p.group then
      build_sub(p.groupid)
    else
      buildpage()
    end
    if p.mode then
      p.redraw()
    end
  end
end

return p
