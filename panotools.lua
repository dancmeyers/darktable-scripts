dt = require "darktable"
table = require "table"

local _debug = true

local hugin_install_path = "/Applications/Hugin/Hugin.app/Contents/MacOS/"
local panorama_source_tag = dt.tags.create("darktable|stack|panorama")
local mini_threshold = 3
local points_tool_pano = "cpfind --multirow --celeste"

local function debug_print(message)
  if _debug then
    print(message)
  end
end

local function getImagePath(i) return "'"..i.path.."/"..i.filename.."'" end

local function create_pto()
  local image_table = dt.gui.selection()
  
  local num_images = 0
  local first_image = nil
  for _,i in pairs(image_table) do
    num_images = num_images + 1
    if num_images == 1 then
      first_image = i
    end
  end
  
  if num_images > 1 then
    local pto_final_path = dt.preferences.read("panotools","PTOOutputDirectory","directory")
    local pto_name = first_image.filename
    if num_images <= mini_threshold then
      pto_name = pto_name.." M"
    else
      pto_name = pto_name.." P"
    end
    
    pto_temp_path = "/tmp/"..pto_name..".pto"
    pto_final_path = pto_final_path.."/"..pto_name..".pto"
    
    local ptogen_command = hugin_install_path.."pto_gen".." -o '"..pto_temp_path.."'"
    
    local previous_image = nil
    for _,image in pairs(image_table) do
      ptogen_command = ptogen_command.." "..getImagePath(image)
      dt.tags.attach(panorama_source_tag, image)
      
      if previous_image ~= nil then
        image.group_with(image, previous_image)
      end
      previous_image = image
    end
    
    local create_success = os.execute(ptogen_command)
    assert(create_success == true)
    
    local points_command = hugin_install_path..points_tool_pano.." -o '"..pto_final_path.."' '"..pto_temp_path.."'"
    --debug_print(points_command)
    coroutine.yield("RUN_COMMAND", points_command)

    local hugin_command = hugin_install_path.."hugin "
    hugin_command = hugin_command.." '"..pto_final_path.."'"
    coroutine.yield("RUN_COMMAND", hugin_command)
  else
    dt.print("Please select at least 2 images to create panorama project")
  end
end

dt.register_event("shortcut",create_pto, "Create new Hugin (.pto) project from selected images")
dt.preferences.register("panotools", "PTOOutputDirectory", "directory", "Panotools: where to put created .pto projects", "", "~/" )
