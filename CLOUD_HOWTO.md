# CLOUD_HOWTO.md

## Overview

This guide explains how to mount a cloud storage folder (e.g., OneDrive, Dropbox) on an HPC cluster **without admin privileges** using [rclone](https://rclone.org/). However, **mounting cloud storage on HPC** comes with important caveats and usage patterns you must follow.

## 1. Requirements

1. **rclone** installed in your user environment.  
2. **FUSE** support (i.e., `fusermount`).  
3. An **rclone remote** configured for your cloud provider (e.g. `onedrive_remote:`).

## 2. HPC Caveats & Warnings

1. **Login Node Only**:  
   - Most HPCs require user-space FUSE mounts to happen on the **login node**. Do **not** attempt to mount your cloud remote from a compute node—this can result in your cloud account being **blocked** or temporarily suspended if too many parallel nodes open connections.

2. **Mount → Copy → HPC**:  
   - After mounting the shared cloud folder on the **login node**, **copy** the needed data into a location that doesn’t affect your HPC quota—for instance, `/dev/shm/$USER`.  
   - Then use tools like **`uhpc-multipush`** to distribute data from `/dev/shm` to your allocated compute nodes.  
   - **Direct pushes** from the mounted cloud path to compute nodes **will not work**—Slurm doesn’t see the mount, and concurrency from multiple nodes would hammer the cloud service.  
   - The HPC best practice is to treat the mounted folder like a “source” on the login node only. Avoid leaving it mounted during your compute job.

3. **Quotas & RAM**:  
   - If you do large file operations, be mindful that storing data in your **home directory** can blow HPC quotas.  
   - If you choose `/dev/shm`, note that it’s a **RAM disk**—you must have enough memory on the login node to hold your data.

4. **Performance**:  
   - Cloud-based I/O is slower and less reliable than HPC scratch. Copy large data sets **once** from the cloud to HPC, then do your computations locally.  
   - Relying on real-time cloud access during compute jobs is risky, can cause slowdowns, and is often against HPC policies.

## 3. Create and Configure Your Rclone Remote

If you haven’t already:

```bash
rclone config
```
Choose a cloud provider (OneDrive, Dropbox, Google Drive, etc.) and follow the prompts. Test with:
```bash
rclone ls onedrive_remote:
```
Replace `onedrive_remote:` with your actual remote name.

## 4. Mounting the Remote (Login Node Only)

Use the new UHPC-Tools scripts: **`uhpc-cloud-mount`** and **`uhpc-cloud-umount`**.

### Example

```bash
uhpc-cloud-mount onedrive_remote:myfolder /dev/shm/$USER/my_cloud_mount
```
- This script:
  1. Ensures no existing rclone processes are running under your user.
  2. Creates a RAM-based cache (default `/dev/shm/rclone_cache_$USER`).
  3. Spawns `rclone mount` in the background (logs to a file).
  
Once mounted, your cloud files appear in `/dev/shm/$USER/my_cloud_mount`.  

**After the mount**:
1. **Copy** the data you need from `/dev/shm/$USER/my_cloud_mount` to another local directory (e.g., `/dev/shm/$USER/dataset`).  
2. **Use** `uhpc-multipush /dev/shm/$USER/dataset /dev/shm/$USER/dataset <nodes>` to distribute your files to allocated compute nodes.  

### Unmount

When done:
```bash
uhpc-cloud-umount /dev/shm/$USER/my_cloud_mount
```
This calls `fusermount -u` and optionally removes the cache directory.

## 5. Summary of Best Practices

- **Mount** on the **login node** only.  
- **Copy** data from the mounted drive to a local (RAM or HPC scratch) path.  
- **Unmount** to avoid leaving an ongoing FUSE process.  
- **Push** or **multipush** that local data to compute nodes.  
- **Do not** mount the cloud remote on every compute node, to avoid concurrency, rate-limiting, or HPC policy violations.

## 6. Troubleshooting

- **“fusermount3: not found”**: Symlink `fusermount` to `fusermount3` or set `export RCLONE_FUSE_COMMAND=fusermount`.  
- **Quota Errors**: If the mount’s cache is in your home directory, you can blow your quota. Use `/dev/shm` or HPC scratch.  
- **Stalled/Dead Mount**: HPC might kill your process upon logout or job completion. Try using a `tmux`/`screen` session or short sessions to copy data quickly.

## Conclusion

Mounting cloud storage on HPC is best for light data access or quick file grabs. For large or parallel workflows, **syncing** or **copying** data from the login node to HPC scratch is more stable. Always consult HPC administrators if you’re uncertain about concurrency or data usage policies.