local M = {}

M._lockfile_path = vim.fn.stdpath("config") .. "/mason-lock.json"
M._registry_ready = false
M._registry_updating = false
M._restore_in_progress = false

local function read_file(file)
  local fd = assert(io.open(file, "r"))
  local data = fd:read("*a")
  fd:close()
  return data
end

---@alias ArosMason.Lockfile table<string, string>

---@return ArosMason.Lockfile|nil
local function get_lockfile()
  local ok, lockfile_str = pcall(read_file, M._lockfile_path)
  if not ok then
    return
  end

  local lock_data
  ok, lock_data = pcall(vim.json.decode, lockfile_str)
  if not ok or type(lock_data) ~= "table" then
    return nil
  end

  for key, value in pairs(lock_data) do
    if type(key) ~= "string" then
      return nil
    end
    if type(value) ~= "string" then
      return nil
    end
  end
  return lock_data
end

---@class ArosMason.get_registry_opts
---@field refresh? boolean

---@param opts? ArosMason.get_registry_opts
local function get_registry(opts)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return nil
  end

  local refresh = false
  if opts then
    refresh = opts.refresh
  end
  if refresh then
    if not M._registry_ready and not M._registry_updating then
      M._registry_updating = true
      local callback_handler = function(success)
        M._registry_updating = false
        if success then
          M._registry_ready = true
        end
      end
      registry.refresh(callback_handler)
    end

    ok = vim.wait(1000 * 60, function()
      return M._registry_ready
    end)
    if not ok then
      return nil
    end
  end

  return registry
end

local function get_package(name)
  local registry = get_registry({ refresh = true })
  if not registry then
    return nil
  end

  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    return nil
  end
  return pkg
end

function M.write_lockfile()
  if M._restore_in_progress then
    return
  end

  local registry = get_registry({ refresh = true })
  if not registry then
    return nil
  end

  local packages = registry:get_installed_packages()

  local entries = {}
  for _, package in pairs(packages) do
    if package:is_installed() == false then
      table.insert(entries, nil)
      return
    end

    table.insert(entries, {
      name = package.name,
      version = package:get_installed_version(),
    })
  end

  vim.wait(5000, function()
    return #packages == #entries
  end)

  for i, package in pairs(entries) do
    if package == nil then
      entries[i] = nil
    end
  end

  table.sort(entries, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  local f = assert(io.open(M._lockfile_path, "wb"))
  f:write("{\n")

  for i, package in ipairs(entries) do
    f:write(("  %q: %q"):format(package.name, package.version))
    if i < #entries then
      f:write(",\n")
    end
  end

  f:write("\n}")
  f:close()
  vim.notify("[mason-lock]: Wrote Mason lockfile")
end

function M.restore_from_lockfile()
  if M._restore_in_progress then
    vim.notify("[aros-mason] restore already in progress", vim.log.levels.WARN)
    return false
  end
  local function restore()
    local lockfile = get_lockfile()
    if not lockfile then
      vim.notify("[aros-mason] failed the load lockfile", vim.log.levels.ERROR)
      return false
    end

    local registry = get_registry({ refresh = true })
    if not registry then
      vim.notify("[aros-mason] failed the load registry", vim.log.levels.ERROR)
      return false
    end

    local pending_packages = {}
    local finished_handles = {}
    for package_name, package_version in pairs(lockfile) do
      local pkg = get_package(package_name)
      if not pkg then
        vim.notify('[aros-mason] failed get package "' .. package_name .. '"', vim.log.levels.ERROR)
        return false
      end
      if not pkg:is_installed() or pkg:get_installed_version() ~= package_version then
        table.insert(pending_packages, package_name)
        local handle = pkg:install({
          version = package_version,
        })
        handle:once("closed", function()
          table.insert(finished_handles, package_name)
        end)
      end
    end

    local happy, status = vim.wait(1000 * 60, function()
      return #finished_handles == #pending_packages
    end, 300)
    if not happy then
      if status == -1 then
        vim.notify("[aros-mason]: Timedout waiting for Mason package install", vim.log.levels.ERROR)
      elseif status == -2 then
        vim.notify("[aros-mason]: Wait on Mason package install was interrupted", vim.log.levels.ERROR)
      end
      return false
    end

    vim.notify("[aros-mason]: Restored Mason package versions from lockfile")
    return true
  end

  M._restore_in_progress = true
  local ok, err = pcall(restore)
  M._restore_in_progress = false
  if not ok then
    vim.notify("[aros-mason] restore failed: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return err
end

---@param opts vim.api.keyset.create_user_command.command_args
local function command_handler(opts)
  local fargs = opts.fargs

  if #fargs == 0 then
    vim.notify("require arguments", vim.log.levels.ERROR)
    return
  end
  if fargs[1] == "restore" then
    if #fargs ~= 1 then
      vim.notify('unknown extra argument passed to "restore"', vim.log.levels.ERROR)
      return
    end
    M.restore_from_lockfile()
  end
end

function M.add_event_listeners()
  local registry = get_registry()
  if not registry then
    vim.notify("[aros-mason] failed to load registry", vim.log.levels.ERROR)
    return
  end
  registry:on(
    "package:install:success",
    vim.schedule_wrap(function()
      M.write_lockfile()
    end)
  )

  registry:on(
    "package:uninstall:success",
    vim.schedule_wrap(function()
      M.write_lockfile()
    end)
  )
end

---@class ArosMason.SetupOpts
---@field lockfile_path? string

---@param opts ArosMason.SetupOpts
function M.setup(opts)
  if opts and opts.lockfile_path then
    M._lockfile_path = opts.lockfile_path
  end

  vim.api.nvim_create_user_command("ArosMason", command_handler, {
    desc = "Write current package versions to the Mason lockfile",
  })
  M.add_event_listeners()
end

return M
