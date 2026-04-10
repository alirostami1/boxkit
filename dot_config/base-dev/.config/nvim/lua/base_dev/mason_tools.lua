local M = {}

local configured_filetypes_by_package = {}
local installing = {}
local registry_callbacks = {}
local registry_ready = false
local registry_refreshing = false
local restore_in_progress = false

local REFRESH_TIMEOUT_MS = 60000
local INSTALL_TIMEOUT_MS = 900000

local function lockfile_path()
  return vim.fn.stdpath("config") .. "/mason-lock.json"
end

local function sorted_package_names(packages_by_name)
  local package_names = {}

  for package_name in pairs(packages_by_name) do
    table.insert(package_names, package_name)
  end

  table.sort(package_names)
  return package_names
end

local function sort_packages_by_name(packages)
  table.sort(packages, function(left, right)
    return left.name:lower() < right.name:lower()
  end)
end

local function packages_for_filetypes(filetypes_by_package)
  local packages_by_filetype = {}

  for package_name, filetypes in pairs(filetypes_by_package) do
    for _, filetype in ipairs(filetypes) do
      packages_by_filetype[filetype] = packages_by_filetype[filetype] or {}
      table.insert(packages_by_filetype[filetype], package_name)
    end
  end

  return packages_by_filetype
end

local function refresh_registry()
  local registry = require("mason-registry")
  local refreshed = false

  registry.refresh(function()
    refreshed = true
  end)

  local refresh_finished = vim.wait(REFRESH_TIMEOUT_MS, function()
    return refreshed
  end, 100)

  if not refresh_finished then
    error("Timed out waiting for Mason registry refresh")
  end

  registry_ready = true
  return registry
end

local function with_registry(callback)
  local registry = require("mason-registry")

  if registry_ready then
    callback(registry)
    return
  end

  table.insert(registry_callbacks, callback)
  if registry_refreshing then
    return
  end

  registry_refreshing = true
  registry.refresh(function()
    vim.schedule(function()
      registry_ready = true
      registry_refreshing = false

      local callbacks = registry_callbacks
      registry_callbacks = {}
      for _, queued_callback in ipairs(callbacks) do
        queued_callback(registry)
      end
    end)
  end)
end

local function install_packages(registry, package_specs)
  local missing = {}
  local pending = 0

  for _, spec in ipairs(package_specs) do
    if registry.has_package(spec.name) then
      pending = pending + 1
      local package = registry.get_package(spec.name)
      local install_opts = spec.version and { version = spec.version } or nil
      local version_suffix = spec.version and ("@" .. spec.version) or ""

      print("[mason/install/" .. spec.name .. "]: Installing package" .. version_suffix)
      local handle = install_opts and package:install(install_opts) or package:install()

      handle:once("closed", function()
        pending = pending - 1
        print("[mason/install/" .. spec.name .. "]: Package installed")
      end)
    else
      table.insert(missing, spec.name)
    end
  end

  local install_finished = vim.wait(INSTALL_TIMEOUT_MS, function()
    return pending == 0
  end, 500)

  if not install_finished then
    error("Timed out waiting for Mason installs to finish")
  end

  if #missing > 0 then
    error("Mason package not found: " .. table.concat(missing, ", "))
  end
end

local function specs_from_configured_packages(registry)
  local package_specs = {}

  for _, package_name in ipairs(sorted_package_names(configured_filetypes_by_package)) do
    if not registry.is_installed(package_name) then
      table.insert(package_specs, { name = package_name })
    end
  end

  return package_specs
end

local function specs_from_lockfile()
  local path = lockfile_path()
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local lockfile = table.concat(vim.fn.readfile(path), "\n")
  local lock_data = vim.json.decode(lockfile)
  local package_specs = {}

  for _, package_name in ipairs(sorted_package_names(lock_data)) do
    table.insert(package_specs, {
      name = package_name,
      version = lock_data[package_name],
    })
  end

  return package_specs
end

local function install_missing_packages(packages_by_filetype, filetype)
  local package_names = packages_by_filetype[filetype]
  if not package_names then
    return
  end

  with_registry(function(registry)
    for _, package_name in ipairs(package_names) do
      if not installing[package_name] and not registry.is_installed(package_name) then
        if registry.has_package(package_name) then
          installing[package_name] = true
          print("[mason/install/" .. package_name .. "]: Installing package")
          vim.notify("Mason installing: " .. package_name, vim.log.levels.INFO)
          registry.get_package(package_name):install():once("closed", function()
            installing[package_name] = nil
            print("[mason/install/" .. package_name .. "]: Package installed")
          end)
        else
          vim.notify("Mason package not found: " .. package_name, vim.log.levels.WARN)
        end
      end
    end
  end)
end

local function write_lockfile_on_package_change()
  vim.schedule(function()
    M.write_lockfile()
  end)
end

function M.setup(opts)
  opts = opts or {}
  configured_filetypes_by_package = opts.filetypes_by_package or {}
  local packages_by_filetype = packages_for_filetypes(configured_filetypes_by_package)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MasonEnsureFiletypeTools", { clear = true }),
    callback = function(args)
      install_missing_packages(packages_by_filetype, vim.bo[args.buf].filetype)
    end,
  })

  local registry = require("mason-registry")
  registry:on("package:install:success", write_lockfile_on_package_change)
  registry:on("package:uninstall:success", write_lockfile_on_package_change)
end

function M.install_all()
  local registry = refresh_registry()
  install_packages(registry, specs_from_configured_packages(registry))
end

function M.write_lockfile()
  if restore_in_progress then
    return
  end

  local registry = require("mason-registry")
  local packages = {}

  for _, package in ipairs(registry.get_installed_packages()) do
    if package:is_installed() then
      table.insert(packages, {
        name = package.name,
        version = package:get_installed_version(),
      })
    end
  end

  sort_packages_by_name(packages)

  local file = assert(io.open(lockfile_path(), "w"))
  file:write("{\n")
  for index, package in ipairs(packages) do
    file:write(('  %q: %q'):format(package.name, package.version))
    if index < #packages then
      file:write(",")
    end
    file:write("\n")
  end
  file:write("}\n")
  file:close()

  print("[mason-lock]: Wrote Mason lockfile")
end

function M.restore_from_lockfile()
  local package_specs = specs_from_lockfile()
  if not package_specs then
    vim.notify("Mason lockfile does not exist: " .. lockfile_path(), vim.log.levels.WARN)
    return
  end

  restore_in_progress = true
  local ok, err = pcall(function()
    install_packages(refresh_registry(), package_specs)
  end)
  restore_in_progress = false

  if not ok then
    error(err)
  end

  M.write_lockfile()
end

return M
