json = require "semiconductor/lib/json/json"
osc_lib = include('semiconductor/lib/osc_lib')

local player_params = {}
player_params.__index = player_params

function player_params:new()
  local p = {
    tSEPARATOR = 0,
    tNUMBER = 1,
    tOPTION = 2,
    tCONTROL = 3,
    tFILE = 4,
    tTAPER = 5,
    tTRIGGER = 6,
    tGROUP = 7,
    tTEXT = 8,
    tBINARY = 9,
    sets = {},
    count = 0
  }
  setmetatable(p, player_params)

  --uuid from: https://gist.github.com/jrus/3197011
  local function uuid()
    local random = math.random
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
  end

  function p.gen_cb()
    return "cb"..uuid()
  end

  --- get params.
  p.params_slices = {}
  p.params_json = ""
  function p:get_params(final_cb, norns_ip, norns_name, script)
    cbid = p.gen_cb()
    callbacks[cbid] = function(params_slice, slice_idx, norns_name, script)
      -- print("get params callback returned",cbid, slice_idx)
      local sep_idx = string.find(slice_idx,"_")
      local slice_num = string.sub(slice_idx,1,sep_idx-1)
      local num_slices = string.sub(slice_idx,sep_idx+1,string.len(slice_idx))
      if slice_num == 1 then
        p.params_slices = {}
      end
      p.params_slices[tonumber(slice_num)] = params_slice
      if slice_num == num_slices then
        p.params_json = ""
        print("reassemble slices ",sep_idx,slice_num,num_slices,slice_num==num_slices)
        for i=1,slice_num do
          p.params_json = p.params_json .. p.params_slices[i]
        end
        callbacks[cbid]=nil
        self.norns_name = norns_name
        self.script = script
        print("norns_name, script",norns_name, script)
        local prams = json.decode(p.params_json)
        for k,v in pairs(prams) do
          self[k] = v
        end   
        final_cb(norns_name)
      end
    end
    local to = {norns_ip,10111}
    osc_lib.send(to,'get_params_call',{cbid,norns_name, script})
  end

  --- delta.
  function p:delta(ip,pix,delta)
      cbid = p.gen_cb()
      callbacks[cbid] = function(pix,str)
        -- print("get string callback returned",pix,string)
        callbacks[cbid]=nil
        menu.pvals[pix] = str
        menu.redraw()
      end
      -- menu.pvals[pix]=""
      local to = {ip,10111}
      print("send delta call",pix,ip, to[1],to[2])
      osc_lib.send(to,'delta_call',{cbid,pix,delta})
    end
  
    --- set to range.
  function p:set_to_range(ip,pix,val)
      local to = {ip,10111}
      osc_lib.send(to,'set_to_range_call',{pix,val})
    -- osc_lib.send(to,'set_to_range_call',{cbid,pix,delta})
      -- cbid = p.gen_cb()
      -- callbacks[cbid] = function(pix,str)
      --   -- print("get string callback returned",pix,string)
      --   callbacks[cbid]=nil
      --   menu.pvals[pix] = str
      --   menu.redraw()
      -- end
      -- -- menu.pvals[pix]=""
      -- local to = {ip,10111}
      -- print("send delta call",pix,ip, to[1],to[2])
      -- osc_lib.send(to,'delta_call',{cbid,pix,delta})
    end

  --- count.
  -- function p:get_count()
  --   cbid = p.gen_cb()
  --   callbacks[cbid] = function(count)
  --     -- print("callback returned",cbid, count)
  --     callbacks[cbid]=nil
  --     p.count = count
  --   end
  --   osc_lib.send(to,'get_count_call',{cbid})
  -- end

  --- name.
  function p:get_name(pix)
    return self.params[pix].name or ""
  end

  --- group size.
  function p:get_group_size(pix)
    return self.params[pix].n or ""
  end

  --- string.
  -- function p:string(pix)
  function p.get_string(ip, pix)
    clock.sleep(0.001)
    -- local param = self:lookup_param(pix)
    -- return param:string()
    cbid = p.gen_cb()
    callbacks[cbid] = function(pix,string)
      -- print("get string callback returned",pix,string)
      callbacks[cbid]=nil
      menu.pvals[pix] = string
    end
    menu.pvals[pix]=""
    local to = {ip,10111}
    osc_lib.send(to,'get_string_call',{cbid,pix})
  end

  --- get
  function p:get(pix)
    local param = self:lookup_param(pix)
    return param:get()
  end

  --- get_raw (for control types only).
  function p:get_raw(pix)
    local param = self:lookup_param(pix)
    return param:get_raw()
  end

  --- get type
  function p:t(pix)
    local param = self:lookup_param(pix)
    if param ~= nil then
      return param.t
    end
  end

  --- get visibility.
  -- parameters are visible by default.
  function p:visible(pix)
    return not self.hidden[pix]
  end

  -- lookup
  function p:lookup_param(pix)
    if type(pix) == "string" and self.lookup[pix] then
      return self.params[self.lookup[pix]]
    elseif self.params[pix] then
      return self.params[pix]
    else
      error("invalid pix")
    end
  end

  return p

end

return player_params