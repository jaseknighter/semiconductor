local save_load = {}
local folder_path = norns.state.data .. "semiconductor/" 
-- local folder_path = "semiconductor/" 
local pset_folder_path  = folder_path .. ".psets/"
local AUTOSAVE_DEFAULT=2

function save_load.save_sc_data(name_or_path)
  if name_or_path then
    if os.rename(folder_path, folder_path) == nil then
      os.execute("mkdir " .. folder_path)
      os.execute("mkdir " .. pset_folder_path)
      os.execute("touch" .. pset_folder_path)
    end

    local save_path
    if string.find(name_or_path,"/") == 1 then
      local x,y = string.find(name_or_path,folder_path)
      local filename = string.sub(name_or_path,y+1,#name_or_path-4)
      local pset_path = pset_folder_path .. filename
      params:write(pset_path)
      save_path = name_or_path
    elseif string.find(name_or_path,"autosave")==nil then -- load pset unless loading from autosave 
      local pset_path = pset_folder_path .. name_or_path
      params:write(pset_path)
      save_path = folder_path .. name_or_path  ..".scn"
    else
      save_path = folder_path .. name_or_path  ..".scn"
    end
    
    -- save semiconductor_data
    local sc_data = {}
    sc_data.pmap_vals = deep_copy(sc_menu.pmap_vals)
     
    local save_object = {}
    save_object = sc_data
    tab.save(save_object, save_path)
    print("saved semiconductor data!")
  else
    print("save cancel")
  end
end

function save_load.remove_sc_data(path)
   if string.find(path, 'semiconductor') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("data found to remove", path)
      os.execute("rm -rf "..path)

      local start,finish = string.find(path,folder_path)

      local data_filename = string.sub(path,finish+1)
      local start2,finish2 = string.find(data_filename,".scn")
      local pset_filename = string.sub(path,finish+1,finish+start2-1)
      local pset_path = pset_folder_path .. pset_filename
      print("pset path found",pset_path)
      os.execute("rm -rf "..pset_path)  
    else
      print("no data found to remove")
    end
  end
end

function save_load.load_sc_data(path)
  sc_data = tab.load(path)
  if sc_data ~= nil then
    print("semiconductor data found", path)
    local start,finish = string.find(path,folder_path)

    local data_filename = string.sub(path,finish+1)
    local start2,finish2 = string.find(data_filename,".scn")
    local pset_filename = string.sub(path,finish+1,finish+start2-1)
    local pset_path = pset_folder_path .. pset_filename
    -- load pset unless loading from autosave 
    if string.find(pset_path,"autosave")==nil then
      print("pset path found",pset_path)
      print("READ",string.find(pset_path,"autosave"))
      params:read(pset_path)
    end

    -- load semiconductor data
    -- sc_menu.registrations                    = deep_copy(sc_data.registrations)
    sc_menu.pmap_vals                           = deep_copy(sc_data.pmap_vals)

    print("semiconductor data is now loaded")
          
 else
    print("no data")
  end
end

-- function save_load.load_sc_data_finish(sc_data)
  -- clock.sleep(1)layer.reset(i) end
-- end

function save_load.init()

  params:add_group("sc data",5)

  params:add{
    type="option", id = "autosave", name="autosave" ,options={"off","on"}, default=AUTOSAVE_DEFAULT, 
    action=function() end
  }          

  params:add_trigger("save_sc_data", "> SAVE SC DATA")
  params:set_action("save_sc_data", function(x) textentry.enter(save_load.save_sc_data) end)

  params:add_trigger("overwrite_sc_data", "> OVERWRITE SC DATA")
  params:set_action("overwrite_sc_data", function(x) fileselect.enter(folder_path, save_load.save_sc_data) end)

  params:add_trigger("remove_sc_data", "< REMOVE SC DATA")
  params:set_action("remove_sc_data", function(x) fileselect.enter(folder_path, save_load.remove_sc_data) end)

  params:add_trigger("load_sc_data", "> LOAD SC DATA" )
  params:set_action("load_sc_data", function(x) fileselect.enter(folder_path, save_load.load_sc_data) end)

end

return save_load
