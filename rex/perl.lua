local M = {}
local config_dir = assert(debug.getinfo(1, "S").source:match("^@?(.+/)"))

local function run(args, input, error_prefix)
  table.insert(args, 1, "/usr/bin/perl")
  local result, err = rex.exec(args, { stdin = input })
  if not result then error(error_prefix .. err, 0) end
  if not result.ok then error(error_prefix .. result.stderr, 0) end
  return result.stdout
end

function M.extract_urls(input)
  return run({ config_dir .. "extract-urls.pl" }, input, "Could not extract URLs: ")
end

return M
