local db = {}
db.__index = db

local q = "%q,"

local function append(file, record)
  file:write "{"
  for key, value in pairs(record) do
    if not type(key) == "string" then
      -- don't save non string keys
    elseif type(value) == "string" then
      file:write(key, "=", string.format("%q", value):gsub("\n", "n"), ",")
    else
      file:write(key, "=", value, ",")
    end
  end
  file:write "}\n"

  -- commit
  file:flush()
end

function db:new(path)
  local self = setmetatable({}, db)
  self.path = path

  self.data = {}
  self.file, err = io.open(path, "r+")

  if self.file then
    for line in self.file:lines() do
      local ok, data = pcall(loadstring("return " .. line))
      if not ok then
        -- ignore this line for now
      else
        local collection = self:collection(data.collection)
        collection[data.id] = data
        collection.next = data.id + 1
      end
    end
  else
    self.file = io.open(path, "a")
  end

  return self
end

local function put(collection, value)
  local id = value.id or collection.next
  if id == collection.next then
    collection.next = collection.next + 1
  end

  local record = {}

  -- shalow copy
  for k, v in pairs(value) do record[k] = v end

  record.id = id
  record.updated = os.time()
  record.collection = collection.name

  collection[id] = record

  append(collection.db.file, record)

  return id
end

-- TODO: add options
local function get(collection, options)
  local result = {}

  for _, record in ipairs(collection) do
    if not options.filter or options.filter(record) then
      table.insert(result, record)
    end
  end

  return result
end

function db:collection(name)
  local collection = self.data[name] or {
    put = put,
    get = get,
    next = 1,
    name = name,
    db = self,
  }

  self.data[name] = collection

  return collection
end

return db
