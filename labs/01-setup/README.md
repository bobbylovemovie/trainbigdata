# Lab 1 -- Setup

[ภาษาไทย](README.th.md) | **English**

Do this once, before class if possible.

## Step 1: Install

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows, macOS, or Linux)
- [Git](https://git-scm.com/downloads)

## Step 2: Clone

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata
```

## Step 3: Start

```bash
docker compose pull
docker compose up -d
```

`pull` downloads the pre-built course image (no local building needed).
First run also downloads a few GB, so do this on good Wi-Fi if you can.

## Step 4: Check

```bash
./scripts/student-check.sh
```

On Windows without Git Bash/WSL, use PowerShell instead:

```powershell
.\scripts\student-check.ps1
```

You should see:

```text
Environment READY

You can start LAB 02 -- HDFS.
```

If something fails, the script tells you exactly what to do next.

## Step 5: Enter the lab

```bash
docker compose exec bigdata bash
```

```bash
labctl status
```

From here on, every lab command is a Linux command run inside this
container -- identical whether your laptop is Windows, macOS, or Linux.

## If something breaks

```bash
./scripts/restart-lab.sh   # restart, keep your data
./scripts/reset-lab.sh     # full wipe, start clean (asks for confirmation)
```

## Updating during the semester

```bash
git pull              # get updated lab instructions/datasets
docker compose pull   # get an updated runtime image, if one was published
docker compose up -d
```
