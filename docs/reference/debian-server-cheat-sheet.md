# Debian Server Cheat Sheet

A quick reference for connecting to and working with the Debian VM.

---

# Server Information

| Item | Value |
|------|-------|
| Hostname | debian |
| IP Address | 192.168.0.235 |
| User | grego |

---

# SSH Login

Connect to the Debian server:

```bash
ssh grego@192.168.0.235
```

Leave the server:

```bash
exit
```

or press:

```text
Ctrl+D
```

Verify you're on the Debian server:

```bash
hostname
```

Expected output:

```text
debian
```

---

# SSHFS (Mount Debian on the Laptop)

## Install SSHFS (one time)

```bash
sudo apt update
sudo apt install sshfs
```

## Create a mount point

```bash
mkdir -p ~/Network/Debian
```

## Mount the Debian home directory

```bash
sshfs grego@192.168.0.235:/home/grego ~/Network/Debian
```

Browse the mounted directory:

```bash
ls ~/Network/Debian
```

Open with Ranger:

```bash
ranger ~/Network/Debian
```

Unmount when finished:

```bash
fusermount3 -u ~/Network/Debian
```

---

# Secure Copy (SCP)

Copy a file **to** Debian:

```bash
scp myfile.txt grego@192.168.0.235:~
```

Copy a file **from** Debian:

```bash
scp grego@192.168.0.235:~/myfile.txt .
```

Copy an entire directory:

```bash
scp -r MyFolder grego@192.168.0.235:~
```

---

# Samba Shares

Exchange Share:

```text
smb://192.168.0.235/Exchange
```

Home Directory Share:

```text
smb://192.168.0.235/grego
```

List available Samba shares:

```bash
smbclient -L //192.168.0.235 -U grego
```

Connect to the Exchange share:

```bash
smbclient //192.168.0.235/Exchange -U grego
```

Useful `smbclient` commands:

```text
ls
cd
put filename
get filename
quit
```

---

# Useful Diagnostics

Check connectivity:

```bash
ping -c 4 192.168.0.235
```

Show the current hostname:

```bash
hostname
```

Show your IP address:

```bash
hostname -I
```

Display mounted SSHFS filesystems:

```bash
mount | grep fuse
```

Show SSH keys:

```bash
ls ~/.ssh
```

Display the public SSH key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the public key to the clipboard (Wayland):

```bash
wl-copy < ~/.ssh/id_ed25519.pub
```

Verify clipboard contents:

```bash
wl-paste
```

---

# GitHub

Test GitHub authentication:

```bash
ssh -T git@github.com
```

Clone the GLB repository:

```bash
cd ~/Projects

git clone git@github.com:ggregoro/GLB.git
```

Check repository status:

```bash
cd GLB

git status
```

Push changes:

```bash
git add .
git commit -m "Describe your changes"
git push
```

Pull the latest changes:

```bash
git pull
```

---

# Directory Layout

Laptop:

```text
~/Projects/GLB
```

Debian Server:

```text
~/Projects/GLB
```

SSHFS Mount:

```text
~/Network/Debian
```

---

# Future Improvements

- Passwordless SSH to the Debian server from the laptop
- Passwordless SSHFS mounts
- Automatic SSHFS mount script
- Additional reference pages:
  - Git Cheat Sheet
  - Ranger Cheat Sheet
  - Fish Cheat Sheet
  - VirtualBox Cheat Sheet
  - COSMIC Cheat Sheet
