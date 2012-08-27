-- Work in progress - not complete or tested yet

-- script to run init.lua in a container for testing

-- creates a container and runs init in it, innit.

-- pushes an interface into the container, but only with local routing, not bridged or mac-vlan'd for now

-- run as root

local oldassert = assert
local function assert(c, s)
  return oldassert(c, tostring(s))
end

if not arg[1] then arg[1] = "root"

S.chdir(arg[1])

-- should use random names
assert(nl.create_interface{name = "veth0", type = "veth", peer = {name = "veth1"}})

local p = assert(S.clone("newnet,newipc,newns,newpid,newuts"))

if p == 0 then -- child
  -- do we need to clean anything?

  -- wait on network arriving

  local i = nl.interfaces()
  i.veth1:rename("eth0")

  assert(S.execve("/sbin/init", {"init"}, {}))
  S.exit("failure")
else -- parent
  -- move veth1 to child

  assert(S.waitpid(-1, "clone"))
end
