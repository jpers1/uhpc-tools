# Helper Scripts for Working with Cloud Storage

Tools for mounting a cloud remote (via rclone) and cleaning up the mount when done.

## `uhpc-cloud-mount`
Mount a remote folder to a local path using rclone and FUSE. By default it uses a RAM-based cache in `/dev/shm` and backgrounds the process.

**Usage**
```bash
uhpc-cloud-mount <REMOTE:PATH> <MOUNTPOINT> [--cache-dir DIR] [--vfs-cache-mode MODE]
```

## `uhpc-cloud-umount`
Unmount a previously mounted rclone FUSE mount and optionally remove the cache directory.

**Usage**
```bash
uhpc-cloud-umount <MOUNTPOINT> [--cache-dir DIR]
```

### Example workflow combining cloud and conda tools
1. Mount the cloud folder on the login node
   ```bash
   uhpc-cloud-mount onedrive_remote:MyData /dev/shm/$USER/cloud_mount
   ```
2. Copy needed files from the mount to `/dev/shm`
   ```bash
   cp /dev/shm/$USER/cloud_mount/myenv.sqsh /dev/shm/$USER/
   cp /dev/shm/$USER/cloud_mount/mydata.zip /dev/shm/$USER/
   ```
3. Unmount the cloud folder
   ```bash
   uhpc-cloud-umount /dev/shm/$USER/cloud_mount
   ```
4. Allocate a compute node and distribute data if needed
   ```bash
   salloc --nodes=1 --partition=gpu --time=1:00:00
   uhpc-multipush /dev/shm/$USER/mydata.zip /dev/shm/$USER/mydata.zip <list_of_nodes>
   ```
5. Mount the environment and activate it
   ```bash
   uhpc-conda-start /dev/shm/$USER/myenv.sqsh
   conda activate /dev/shm/$USER/conda/conda_envs/myenv
   ```
6. Run your workload then clean up
   ```bash
   uhpc-conda-stop myenv
   rm -f /dev/shm/$USER/myenv.sqsh /dev/shm/$USER/mydata.zip
   ```
