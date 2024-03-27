local db = {}
db.__index = db

function copy(t)
  local new = {}
  for k, v in pairs(t) do
    new[k] = v
  end
  return new
end

function db:new(path)
  local self = setmetatable({}, db)
  self.path = path

  self.data = {}
  self.file = io.open(path, "r+")

  for line in self.file:lines() do
    local record = loadstring("return " .. line)()
    local collection = self.data[record.collection] or {}
    collection[record.id] = record
    self.data[record.collection] = collection
  end

  return self
end

-- Saves a new record
-- if value has an id, it will update the record
function db:put(collectionId, value)
  local collection = self.data[collectionId] or {}
  local id = value.id or #collection + 1

  local record = copy(value)

  record.id = id
  record.updated = os.time()
  record.collection = collectionId

  collection[id] = record

  self.data[collectionId] = collection

  self:append(record)

  return id
end

function db:get(collectionId, filter)
  local collection = self.data[collectionId] or {}
  local result = {}

  for _, record in pairs(collection) do
    if not filter or filter(record) then
      table.insert(result, record)
    end
  end

  return result
end

function db:append(record)
  self.file:write "{"
  for key, value in pairs(record) do
    if not type(key) == "string" then
    elseif type(value) == "string" then
      self.file:write(string.format("%s = %q,", key, value))
    else
      self.file:write(key, " = ", value, ",")
    end
  end
  self.file:write "}\n"

  -- commit
  self.file:flush()
end

return db
