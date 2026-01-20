# CVE-2025-9074 Demonstration

⚠ ️ Disclaimer

This repository is for educational and research purposes only. The vulnerability demonstrated here has been publicly disclosed and should only be tested in controlled environments on systems you own or have explicit permission to test. Unauthorized access to computer systems is illegal.


## Overview
This repository demonstrates CVE-2025-9074, a container escape vulnerability that allows a malicious container to write files to the host filesystem, bypassing container isolation.

- CVE ID: `CVE-2025-9074`
- Severity: Critical
- Affected Systems: Docker Desktop 4.42 and earlier (Windows). MacOS is also vulnerable but it is of less importance to our demo

## Demonstration
video demo: https://youtu.be/1B2dakzLKzU

This demo shows how an unsuspecting user might pull a malicious container directly from docker hub that might compromise their machine.


## Vulnerability Description

`CVE-2025-9074` is a critical container escape vulnerability in Docker Desktop for Windows that exposes the Docker daemon API without proper authentication on the internal network interface `192.168.65.7:2375`. This allows any container running on the system to communicate with the Docker daemon and create new containers with arbitrary host filesystem mounts.

In this demonstration, a malicious container exploits this exposed API to:

1. create a new Alpine container with the host's C:\ drive mounted
2. execute commands within that container to access the host filesystem
3. dump sensitive information from the Windows Users directory (including SSH keys)

## Impact

- complete container escape: granting the attacker full r/w access to the host filesystem
- attacker is able to create privileged containers, and make them carry out privileged actions on their behalf
- data exfiltration

## Reproduce the Vulnerability

We can either build the image from the dockerfile in this repository, or pull the image from docker hub using:
```docker pull moah13/malbatata:cve2025-9074```

### Building the image

Clone the repo and run:
```bash
docker build -t malbatata .
```
Run the container:
```bash
docker run malbatata
```

### Verifying the Exploit

Check your C:\test directory for the dumped data:
```powershell
type C:\test\pwn_dump.txt
```

Or navigate to C:\test in File Explorer and open pwn_dump.txt.
The file will contain:
- A timestamp of when the exploit ran
- A list of all user directories on your system
- Contents of .ssh directories (including private keys if present)

After running the container, you should observe:

- The container starts and communicates with the Docker daemon API
- A new Alpine container is created with host filesystem access
- A file `pwn_dump.txt` appears in `C:\test\` on the host machine
- The file contains sensitive information about user directories and SSH keys

All of this happens without any explicit volume mounts or privileged flags in your docker run command

--> This demonstrates a complete container escape with access to sensitive host data.

## Technical Details

CVE-2025-9074 exploits an insecure Docker daemon configuration in Docker Desktop 4.42 for Windows. The vulnerability exists because the Docker daemon API is exposed on the internal network interface at 192.168.65.7:2375 without authentication.

1. The malicious container identifies the exposed Docker API endpoint at 192.168.65.7:2375
2. The exploit sends a POST request to `/containers/create` using `wget` with a JSON payload that:
    - Specifies an Alpine image
    - Includes shell commands to access host data
    - binds the host's `C:\` drive to `/host_root` inside the new container
3. The exploit starts the newly created container via `/containers/{id}/start`
4. The spawned container has full read/write access to C:\ and executes commands to:
    - Create a directory at `C:\test`
    - List all user directories
    - Enumerate .ssh folders containing private keys
    - Write all findings to `C:\test\pwn_dump.txt`
5. The original malicious container remains running to avoid suspicion


## Mitigation
Update Docker Desktop to version at lest 4.43 or the latest version.

## References
- https://nvd.nist.gov/vuln/detail/CVE-2025-9074
- https://blog.qwertysecurity.com/Articles/blog3
- https://docs.docker.com/desktop/release-notes/#4443