dt = require "darktable"

local _debug = false

local function split_path(path)
  return string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
end

local function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local python_path = os.capture("/usr/bin/env python")
local scripts_dir, _, _ = split_path(debug.getinfo(1).source:match("@(.*)$"))
local python_uploader_stem = python_path.." "..scripts_dir.."flickr_upload.py"

local function _store_image(storage, image, filename)
  local cmd = ""
  for _, tag in ipairs(dt.tags.get_tags(image)) do
    cmd = cmd..'--tag "'..tag.name..'" '
  end

  if image.title then
    cmd = cmd..'--title "'..image.title..'" '
  else
    filename_strip_prefix = string.match(image.filename, "^(.+)%..+$")
    cmd = cmd..'--title "'..filename_strip_prefix..'" '
  end

  if image.description then
    cmd = cmd..'--description "'..image.description..'" '
  end

  cmd = python_uploader_stem.." "..cmd..filename
  --dt.control.execute(cmd)
  return nil, cmd
end

function _store_handler(storage, image, format, filename, number, total, high_quality, extra_data)
  dt.print(image.filename.." uploading")
  if (_debug) then
    --Do a regular call, which will output complete error traceback to console
    _store_image(storage, image, filename)
  else
    local success, err = pcall(_store_image, storage, image, filename)
    if (not success) then
      dt.print_error("Error uploading to Flickr")
      dt.print_error("Error: "..tostring(err))
    end
  end
end

function _finalize_handler(storage, image_table, extra_data)
end

dt.register_storage("flickr_upload", "Flickr", _store_handler, _finalize_handler)

