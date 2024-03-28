local http = require "http"
local markup = require "markup"

local db = require("db"):new("/tmp/db")

local threads = db:collection "threads"
local messages = db:collection "messages"

-- if no threads, seed the db
if #threads == 0 then
  threads:put { name = "programming" }
  threads:put { name = "gaming" }
  threads:put { name = "offtopic" }
end

local html = markup.html

local head = { 
  markup.link {
    rel = "stylesheet",
    href = "https://unpkg.com/normalize.css@8.0.1/normalize.css"
  },
  markup.link { 
    rel = "stylesheet",
    href = "https://unpkg.com/concrete.css@2.1.1/concrete.css"
  },
  markup.script {
    src = "https://unpkg.com/htmx.org@1.9.11"
  }
}

http
  :handle("GET /", function()
    return html {
      title = "plum board",
      head = head,
      body = markup.main {
        markup.h1 { "welcome to plum board" },
        markup.p { "threads:" },
        markup.ul {
          ["hx-boost"] = "true",
          markup.each {
            data = threads,
            template = markup.li {
              markup.a { href = "/$name", "$name" }
            }
          }
        }
      }
    }
  end)
  :handle("GET /(%w+)", function(request, name)
    local messages = messages:get {
      filter = function(item) return item.thread == name end
    }

    if not messages then
      return html {
        title = "plum board",
        body = markup.main {
          markup.p { "thread not found" }
        }
      }
    end

    return html {
      title = name,
      head = head,
      body = markup.main {
        markup.h1 { "thread: " .. name },
        markup.form {
          ["hx-post"] = "/" .. name,
          ["hx-target"] = "ul",
          ["hx-swap"] = "afterbegin",
          markup.input { type = "text", name = "author", placeholder = "author" },
          markup.textarea { name = "message", placeholder = "message" },
          markup.button { type = "submit", "post" }
        },
        markup.ul {
          markup.each {
            data = messages,
            template = markup.li {
              markup.p { "author: $author" },
              markup.p { "$message" }
            }
          }
        }
      }
    }
  end)
  -- Handle new post
  :handle("POST /(%w+)", function(request, name)
    local author, message = request.body.author, request.body.message
    local timestamp = os.time()

    if not author or not message then
      return { status = 400, body = "bad request" }
    end

    messages:put { author = author, message = message, thread = name }

    return markup.li {
      markup.p { "author: " .. author },
      markup.p { message }
    }:render()
  end)
  :listen(3000)
