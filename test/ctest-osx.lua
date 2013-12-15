-- generate C test file to check type sizes etc
-- OSX version, similar to BSD

local S = require "syscall"

local abi = S.abi
local types = S.types
local t, ctypes, s = types.t, types.ctypes, types.s
local c = S.c

local ffi = require "ffi"

local reflect = require "include.ffi-reflect.reflect"

-- internal
c.errornames = nil

-- fixups
c.AF.DECnet = c.AF.DECNET
c.AF.DECNET = nil

c.R_OK = c.OK.R
c.W_OK = c.OK.W
c.F_OK = c.OK.F
c.X_OK = c.OK.X
c.OK = nil

c.STD.IN = nil
c.STD.OUT = nil
c.STD.ERR = nil

c.SIGACT = nil -- TODO cast correctly instead, giving warning

print [[
/* this code is generated by ctest-bsd.lua */

#define _BSD_SOURCE
#define _FILE_OFFSET_BITS 64
#define _LARGE_FILES 1
#define __USE_FILE_OFFSET64
#define _INCOMPLETE_XOPEN_C063

#include <stddef.h>
#include <stdint.h>

#include <stdio.h>
#include <limits.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <signal.h>
#include <sys/utsname.h>
#include <time.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/un.h>
#include <poll.h>
#include <sys/mman.h>
#include <sched.h>
#include <sys/xattr.h>
#include <termios.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/uio.h>
#include <net/route.h>
#include <sys/wait.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <sys/reboot.h>
#include <sys/syscall.h>

int ret = 0;

void sassert(int a, int b, char *n) {
  if (a != b) {
    printf("error with %s: %d (0x%x) != %d (0x%x)\n", n, a, a, b, b);
    ret = 1;
  }
}

void sassert_u64(uint64_t a, uint64_t b, char *n) {
  if (a != b) {
    printf("error with %s: %llu (0x%llx) != %llu (0x%llx)\n", n, (unsigned long long)a, (unsigned long long)a, (unsigned long long)b, (unsigned long long)b);
    ret = 1;
  }
}

int main(int argc, char **argv) {
]]

local ignore_offsets = {
  val = "true", -- sigset_t renamed TODO rename back
}

-- iterate over S.ctypes
for k, v in pairs(ctypes) do
  print("sassert(sizeof(" .. k .. "), " .. ffi.sizeof(v) .. ', "' .. k .. '");')
  -- check offset of struct fields
  local refct = reflect.typeof(v)
  if refct.what == "struct" then
    for r in refct:members() do
      local name = r.name
      -- bit hacky - TODO fix these issues
      if ignore_offsets[name] then name = nil end
      if name then
        print("sassert(offsetof(" .. k .. "," .. name .. "), " .. ffi.offsetof(v, name) .. ', " offset of ' .. name .. ' in' .. k .. '");')
      end
    end
  end
end

-- test all the constants

-- renamed ones
local nm = {
  E = "E",
  SIG = "SIG",
  STD = "STD",
  MODE = "S_I",
  MSYNC = "MS_",
  W = "W",
  POLL = "POLL",
  S_I = "S_I",
  LFLAG = "",
  IFLAG = "",
  OFLAG = "",
  CFLAG = "",
  CC = "",
  IOCTL = "",
  B = "B",
  SYS = "SYS___",
  AT_FDCWD = "AT_",
  FCNTL_LOCK = "F_",
  SIGACT = "SIG_",
  UMOUNT = "MNT_",
  SIGPM = "SIG_",
}

for k, v in pairs(c) do
  if type(v) == "number" then
    print("sassert(" .. k .. ", " .. v .. ', "' .. k .. '");')
  elseif type(v) == "table" then
    for k2, v2 in pairs(v) do
      local name = nm[k] or k .. "_"
      if type(v2) ~= "function" then
        if type(v2) == "cdata" and ffi.sizeof(v2) == 8 then
         print("sassert_u64(" .. name .. k2 .. ", " .. tostring(v2)  .. ', "' .. name .. k2 .. '");')
        else
         print("sassert(" .. name .. k2 .. ", " .. tostring(v2)  .. ', "' .. name .. k2 .. '");')
        end
      end
    end
  end
end

print [[
return ret;
}
]]

