local xy = {
  x_loc = 64,
  y_loc = 32
}

function xy.enc(n,d)  
  if n==2 then
    xy.x_loc = util.wrap(xy.x_loc+d,1,127)
    local macro_x = params:get("macro_x")
    local val = util.linlin(1,127,0,1,xy.x_loc)
    params:set("macro_control"..macro_x, val)
  elseif n==3 then
    xy.y_loc = util.wrap(xy.y_loc+d,1,64)
    local macro_y = params:get("macro_y")
    local val = util.linlin(1,127,0,1,xy.y_loc)
    params:set("macro_control"..macro_y, val)
    
  end
end
function xy.redraw()
  -- local n = "SEMICONDUCTOR / MACROS"
  -- screen.level(4)
  -- screen.move(0,10)
  -- screen.text(n)

  if sc_menu.pmaps_set == false then
    screen.move(64,10*3)
    screen.text_center("no param maps selected")
  else
    screen.move(xy.x_loc,xy.y_loc)
    -- add trigger rect
    screen.rect(xy.x_loc - 2,xy.y_loc - 2, 3, 3)
    screen.fill()

  end

  -- tab.print(sc_menu.pmap_vals["fatesorange"])
end

return xy