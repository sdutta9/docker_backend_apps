-- List of paths to test
local paths = {
  "/",
  "/get?id=1'%20OR%20'1'='1",
  "/base64?name=<script>alert(1)</script>",
  "/anything?url=http://169.254.169.254/latest/meta-data/",
  "/flasgger_static/swagger-ui.css",
  "/flasgger_static/lib/jquery.min.js",
  "/${pwd}/serverless.yaml",
  "/image/jpeg",
  "/gzip",
  "/headers"
}

-- Initialize a counter or random seed
math.randomseed(os.time())

request = function()
  -- Select a random path from the list
  local path = paths[math.random(#paths)]
  
  -- Return the request object
  return wrk.format("GET", path)
end