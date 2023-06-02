--- lorenz attractor
-- by sam wolk 2019.10.13 via galapagoose
-- in1 resets the attractor to the {x,y,z} coordinates stored in the lorenz.origin table
-- in2 controls the speed of the attractor
-- out1 is the x-coordinate (by default)
-- out2 is the y-coordinate (by default)
-- out3 is the z-coordinate (by default)
-- out4 is a weighted sum of x and y (by default)
-- the lorenz.weights table allows you to specify the weight of each axis for each output.

local lattice = require "lattice"

pixel,pixels = include('semiconductor/lib/macros/pixels')

--------------------------------
-- lorenz 
--------------------------------
SCREEN_REFRESH_DENOMINATOR = 10 
LORENZ_WEIGHTS_DEFAULT = {{1,0,0}, {0,1,0}, {0,0,1}, {2.0,1.0,1.0}}

CENTER_X = 64
CENTER_Y = 32

local lorenz = {
  draw = false,
  origin = {0.01,0.5,0},
  sigma = 2.333,
  -- sigma = 10,
  rho = 28,
  beta = 4/3,
  -- beta = 3/2,
  -- beta = 8/3,
  state = {0.01,0,0},
  steps = 1,
  -- keep td < 0.05l
  dt = 0.015,
  -- dt = 0.001,
  first = 0,
  second = 0,
  third = 0,
  x_map = 0,
  y_map = 0,
  -- boundary = {51,5,74,55}
}

function lorenz.init()
  lorenz.x_map = lorenz.first
  lorenz.y_map = lorenz.second
  lorenz.pixels = pixels:new()
  lorenz_lattice:start()
  lorenz_pattern:stop()
end

-- lorenz.weights = {{1,0,0}, {0,1,0}, {0,0,1}, {0.33,0.33,0}}
lorenz.weights = LORENZ_WEIGHTS_DEFAULT


lorenz_lattice = lattice:new{
  auto = true,
  meter = 4,
  ppqn = 96
}

lorenz_pattern = lorenz_lattice:new_sprocket{
  action = function(t) 
    lorenz.update()
    lorenz.pixels.update(true) 
    
    -- if pixels[pixels.active] then
    --   local lb = lorenz.get_boundary()
    --   local lb_sample_min = lb[1]*lb[2]
    --   local lb_sample_max = lb[3]*lb[4]
    --   lorenz_sample_val = pixels[pixels.active].x_display * pixels[pixels.active].y_display
    --   lorenz_sample_val = util.linlin(lb_sample_min,lb_sample_max,0,1,lorenz_sample_val)
    --   engine.set_lorenz_sample(lorenz_sample_val)
    --   -- engine.set_lorenz_sample(sample_val + math.random()*(params:get("rise_time")*1000)+params:get("fall_time")*1000)
    -- end
  end,
  division = 1/256, --1/16,
  enabled = true
}

function lorenz:draw_pat(flag)
  if flag == false and self.draw == true then
    self.draw = false
    lorenz_pattern:stop()
  elseif flag == true and self.draw == false then
    self.draw = true
    lorenz_pattern:start()
  end
end

function lorenz:process(steps,dt)
  steps = steps or self.steps
  dt = dt or self.dt
  for i=1,steps do
    local dx = self.sigma*(self.state[2]-self.state[1])
    local dy = self.state[1]*(self.rho-self.state[3])-self.state[2]
    local dz = self.state[1]*self.state[2]-self.beta*self.state[3]
    self.state[1] = self.state[1]+dx*dt
    self.state[2] = self.state[2]+dy*dt
    self.state[3] = self.state[3]+dz*dt
  end
end

function lorenz.get_boundary()
  
  -- local rows = #sound_controller.sectors
  -- local cols = #sound_controller.sectors[rows]
  -- local x = lorenz.boundary[1]
  -- local y = lorenz.boundary[2]
  -- local w = sound_controller.sectors[1][1].w*cols
  -- local h = sound_controller.sectors[1][1].h*rows
  -- local boundary = {x,y,w-2,h-2}
  -- local boundary = {x,y,w-2,h-2}
  
  local boundary = {1,1,127,64}
  -- local boundary = {51,5,51,48}
  return boundary
end

function lorenz:clear()
  -- if norns.sc_menu.status() == false then 
  --   local gd = sound_controller:get_dimensions()
  --   screen.level(0)
  --   screen.rect(gd.x,gd.y,gd.w,gd.h)
  --   screen.fill()
  --   screen.stroke()
  -- end
end



lorenz.update = function()
  if sc_menu.pmaps_set == false then
    screen.move(64,10*3)
    screen.text_center("no param maps selected")
  else
    lorenz:process()
  
    local xyz = {}
    for i=1,4 do
      local sum = 0
      for j=1,3 do
        xyz[j] = lorenz.weights[i][j]*lorenz.state[j]
        sum = sum+lorenz.weights[i][j]*lorenz.state[j]  
      end
    end

    lorenz.first = math.floor(xyz[1])
    lorenz.second = math.floor(xyz[2])
    lorenz.third = math.floor(xyz[3])

    local lz_x_input = params:get("lz_x_input")      
    if lz_x_input == 1 then lorenz.x_map = lorenz.first 
    elseif lz_x_input == 2 then lorenz.x_map = lorenz.second
    elseif lz_x_input == 3 then lorenz.x_map = lorenz.third 
    end

    local lz_y_input = params:get("lz_y_input")      
    if lz_y_input == 1 then lorenz.y_map = lorenz.first 
    elseif lz_y_input == 2 then lorenz.y_map = lorenz.second
    elseif lz_y_input == 3 then lorenz.y_map = lorenz.third 
    end

    local x = (lorenz.x_map) 
    local y = (lorenz.y_map) 
    -- print(x,y)

    if lorenz.x_map~=0 and lorenz.y_map ~= 0 then
      local xy_exists = false
      for i=1,#lorenz.pixels,1 do
        local prev_x = lorenz.pixels[i].x
        local prev_y = lorenz.pixels[i].y
        if prev_x == x and prev_y == y then 
          xy_exists = true
        end
      end
      if xy_exists == false then
        
        local px = pixel:new(x,y)
        lorenz.pixels[#lorenz.pixels+1] = px
      end
      -- print(xy_exists,x,y)
    end
  end
end

return lorenz