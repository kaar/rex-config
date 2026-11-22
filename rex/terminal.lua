local M = {}

local function call(method, args)
  return rex.block.call("com.superlogical.terminal", method, args)
end

function M.recent_output(block_id, format)
  local scan_bytes = 128 * 1024
  -- Rex measures blob_read's limit after JSON escaping, which expands VT output.
  local blob_read_limit = 960 * 1024
  local snapshot = assert(call("format", {
    block_id = block_id,
    format = format,
    trim = true,
    unwrap = true,
    max_bytes = scan_bytes,
  }))
  -- No ID means the whole capture fits. Otherwise, use the ID to read the tail.
  if not snapshot.id then return snapshot.content end

  local offset = math.max(0, snapshot.total - scan_bytes)
  local tail = assert(call("blob_read", {
    block_id = block_id,
    id = snapshot.id,
    offset = offset,
    max_bytes = blob_read_limit,
  }))
  assert(tail.eof, "Could not read the end of the terminal output.")
  if offset == 0 then return tail.data end

  -- The tail can start mid-line. Skip that line.
  local newline = tail.data:find("\n", 1, true)
  return newline and tail.data:sub(newline + 1) or ""
end

-- Use the foreground process's directory, not the terminal's last reported one.
function M.working_directory(block_id)
  local process, err = call("process", { block_id = block_id })
  if not process then error("Could not look up the terminal's working directory: " .. err, 0) end
  local foreground = process.foreground
  local cwd = foreground and foreground.cwd
  if type(cwd) == "string" and cwd:sub(1, 1) == "/" then
    return cwd
  end
end

return M
