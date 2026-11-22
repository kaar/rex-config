local M = {}
local config_dir = assert(debug.getinfo(1, "S").source:match("^@?(.+/)"))

local function run(args, input, error_prefix, timeout)
  table.insert(args, 1, "/usr/bin/perl")
  local result, err = rex.exec(args, { stdin = input, timeout = timeout })
  if not result then error(error_prefix .. err, 0) end
  if result.timed_out then error(error_prefix .. "timed out", 0) end
  if not result.ok then error(error_prefix .. result.stderr, 0) end
  return result.stdout
end

function M.extract_urls(input)
  return run({ config_dir .. "extract-urls.pl" }, input, "Could not extract URLs: ")
end

function M.extract_links(input)
  return run({ config_dir .. "extract-paths.pl" }, input, "Could not extract file references: ")
end

-- Returns the set of paths that name regular text files, checked in one
-- command. Perl's -T reads the start of each file to tell text from binary.
-- Paths never contain newlines; the extractor rejects them.
function M.text_files(paths)
  local found = {}
  if #paths == 0 then return found end
  local check_timeout = 2 -- seconds for the entire batch
  local output = run({ "-nle", "print $_ if -f $_ && -T $_" },
    table.concat(paths, "\n") .. "\n", "Could not check files: ", check_timeout)
  for path in output:gmatch("[^\n]+") do found[path] = true end
  return found
end

return M
