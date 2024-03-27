local m = {}

local document = [[
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>%s</title>
    %s
  </head>
  <body>
    %s
  </body>
</html>
]]

setmetatable(m, {
  __index = function(_, tag)
    return function(data)
      local children = {}
      local attrs = {}

      if type(data) == "table" then
        for k, v in pairs(data) do
          if type(k) == "number" then
            children[k] = v
          else
            attrs[k] = v
          end
        end
      else
        children = {data}
      end

      return {tag = tag, attrs = attrs, children = children, render = m.render}
    end
  end
})

function m.each(node)
  if not node.data then
    error("missing data")
  end

  if not node.template then
    error("missing template")
  end

  local children = {}

  for key, item in pairs(node.data) do
    local context = { key = key }

    for k, v in pairs(item) do context[k] = v end

    table.insert(children, m.render(node.template, context))
  end

  return table.concat(children)
end

function m.render(node, context)
  if type(node) == "string" then
    if context then
      local result, _ = node:gsub("%$(%w+)", context)
      return result
    end
    return node
  end

  if node.tag == "each" then
    return m.each(node)
  end

  local attrs = {}
  for k, v in pairs(node.attrs) do
    if v == true then
      attrs[#attrs + 1] = string.format(" %s", k)
    else
      if context then
        v = v:gsub("%$(%w+)", context)
      end

      attrs[#attrs + 1] = string.format(' %s="%s"', k, v)
    end
  end
  local children = {}
  for _, child in ipairs(node.children) do
    table.insert(children, m.render(child, context))
  end

  if node.tag == "fragment" then
    return table.concat(children)
  end

  return string.format("<%s%s>%s</%s>", node.tag, table.concat(attrs), table.concat(children), node.tag)
end

function m.html(data)
  local heads = {}
  for i, child in ipairs(data.head or {}) do heads[i] = m.render(child) end
  return document:format(data.title, table.concat(heads, "\n"), m.render(data.body))
end

return m
