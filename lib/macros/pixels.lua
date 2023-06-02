--------------------------------
-- pixels
--------------------------------
local pixels = {}
pixels.__index = pixels

local blank_pixel = screen.peek(1,1,2,2)

function pixels:new()
  local p={
    active = nil
  }
  setmetatable(p, pixels)

  function p.update(display)
    local lb = sc_lorenz.get_boundary()
    for i=1,#p,1 do
      p[i]:update(display)
    end
    for i=1,#p,1 do
      if p[i] and p[i].remove == true  then
        if display == true and (p[i].last_x>lb[1] and p[i].last_x<lb[1]+lb[3] and p[i].last_y>lb[2] and p[i].last_y<lb[2]+lb[4]) then
          local x = math.floor(p[i].last_x)
          local y = math.floor(p[i].last_y)
          if (x and y) then
            screen.poke(x-1,y-1,2,2,blank_pixel)
          end
        end
        table.remove(p,i)
      elseif p[i] and p[i].remove == false then
        local lb = sc_lorenz.get_boundary()
        if (p[i].last_x>lb[1] and p[i].last_x<lb[1]+lb[3] and p[i].last_y>lb[2] and p[i].last_y<lb[2]+lb[4]) then
          p.active = i
        end
      end
    end
  end

  return p
end


local pixel = {}
pixel.__index = pixel

function pixel:new(x,y)
  local p={}
  setmetatable(p, pixel)

  p.x = x
  p.y = y
  p.x_display = x
  p.y_display = y

  p.last_x = x
  p.last_y = y
  p.timer = 1
  p.level = 15
  p.remove = false
  p.redraw = true
  
  return p
end 

function pixel:update(display)
  
  self.timer = self.timer + 1
  if self.timer == SCREEN_REFRESH_DENOMINATOR then
    self.level = self.level > 8 and 8 or self.level - 0.5
    self.timer = 1
    self.redraw = true
  end
  if self.level <= 0 then
    self.remove = true  
  elseif self.level > 0 and self.redraw == true then
    local lb = sc_lorenz.get_boundary()
    -- if display == true then
    --   if (self.last_x>lb[1] and self.last_x<lb[1]+lb[3] and self.last_y>lb[2] and self.last_y<lb[2]+lb[4]) then
    --     screen.level(0)
    --     screen.pixel(self.last_x,self.last_y)
    --     screen.stroke()
    --   end
    -- end

    local lz_x_offset = params:get("lz_x_offset")
    local lz_y_offset = params:get("lz_y_offset")
    local lz_x_scale = params:get("lz_x_scale")
    local lz_y_scale = params:get("lz_y_scale")

    
    self.x_display = ((self.x*lz_x_scale)+lz_x_offset)+(CENTER_X)
    self.y_display = ((self.y*lz_y_scale)+lz_y_offset)+(CENTER_Y)
    local x = self.x_display
    local y = self.y_display
    if (x>lb[1] and x<lb[1]+lb[3] and y>lb[2] and y<lb[2]+lb[4]) then
      -- if (x>lb[1] and x<lb[1]+lb[3] and y>lb[2] and y<lb[2]+lb[4]) then
      self.last_x = x
      self.last_y = y
      if display == true then
        screen.level(math.ceil(self.level))
        if self.active == true then
          screen.move(x,y)
          screen.rect(x,y,x+1,y+1)
        else
          screen.pixel(x,y)
        end
        screen.stroke()
      end
    end
    self.redraw = false
  end
end

return pixel, pixels