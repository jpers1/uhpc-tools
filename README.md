# UHPC-Tools

**UHPC-Tools** ("Unusual HPC Tools") is a lightweight collection of handy Bash scripts for Slurm clusters. Current scripts:

## Table of Contents
1. [Helper Scripts for New HPC Users (Minimal Disk Quota)](#helper-scripts-for-new-hpc-users-often-with-minimal-disk-quota)
2. [Helper Scripts for Multiple Interactive Shells](#helper-scripts-for-multiple-interactive-shells)
3. [Helper Scripts for Working with Cloud Storage](#helper-scripts-for-working-with-cloud-storage-eg-onedrive)
4. [Detailed Cloud How-To](CLOUD_HOWTO.md)
5. [Detailed Conda How-To](CONDA_HOWTO.md)

---


### Helper scripts for new HPC users, often with minimal disk quota


- **uhpc-list**  
  **What it does**:  
  Lists all cluster nodes with CPU, memory, GPU usage, and ephemeral SSD capacity.  
  - By default, prints every node.  
  - `--free` shows only MIX or IDLE nodes or those with free CPUs.  

  **Usage**:  
  ```bash
  uhpc-list
  uhpc-list --free
  ```

**Examples**:

*   `uhpc-list`  
    Lists all nodes in a column-aligned table.
    
*   `uhpc-list --free`  
    Shows only nodes that are MIX, IDLE, or have free CPUs.
    

* * *

*   **uhpc-multipush**  
    **What it does**:  
    Streams a local file (for example, from `/dev/shm`) to `/dev/shm` on one or more allocated Slurm nodes, bypassing shared filesystem quotas.
    
    *   Requires that you already have a Slurm allocation on the target nodes.
        
    
    **Usage**:
    
    ```bash
    uhpc-multipush <LOCAL_FILE> <REMOTE_FILE> <NODE_LIST>
    ```
    
    Where:
    
    *   `LOCAL_FILE` = Path to the local file (e.g., `/dev/shm/data_local.dat`).
        
    *   `REMOTE_FILE` = Desired path on the remote nodes (e.g., `/dev/shm/data_remote.dat`), or a directory ending with `/`.
        
    *   `NODE_LIST` = Comma-separated node names (e.g., `wn208,wn209`).
        
    
    **Example**:
    
    ```bash
    salloc --nodes=2 --nodelist=wn208,wn209 --time=1:00:00
    uhpc-multipush /dev/shm/mydata_local.dat /dev/shm/mydata_remote.dat wn208,wn209
    ```
    
    Copies `mydata_local.dat` from the local machine into `/dev/shm/mydata_remote.dat` on each of `wn208` and `wn209`.
    

* * *

*   **uhpc-conda-start**  
    **What it does**:  
    Given a SquashFS file (e.g., `myenv.sqsh`) containing a Conda environment, this script mounts it read-only in `/dev/shm` (RAM disk).
    
    *   Does **not** automatically activate the environment—users can do so manually.
        
    
    **Usage**:
    
    ```bash
    uhpc-conda-start <SQUASHFS_FILE>
    ```
    
    **Steps**:
    
    1.  Copies `<SQUASHFS_FILE>` to `/dev/shm/$USER/` if it’s not already in `/dev/shm`.
        
    2.  Mounts it read-only at `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>` (derived from the file name minus `.sqsh`/`.squashfs`).
        
    3.  Prints instructions on how to manually activate the environment via Conda or by modifying `PATH`.
        
    
    **Example**:
    
    ```bash
    uhpc-conda-start /home/user/myenv.sqsh
    ```
    
    This mounts the environment in `/dev/shm/$USER/conda/conda_envs/myenv`. You can then do:
    
    ```bash
    conda activate /dev/shm/$USER/conda/conda_envs/myenv
    ```
    

* * *

*   **uhpc-conda-stop**  
    **What it does**:  
    Deactivates (manually, if desired) and **unmounts** a Conda environment that was started with `uhpc-conda-start`.
    
    **Usage**:
    
    ```bash
    uhpc-conda-stop <ENV_NAME>
    ```
    
    **Steps**:
    
    1.  (Optional) `conda deactivate` (if you had activated it).
        
    2.  Unmounts the environment folder (`fusermount -u` or `umount`).
        
    3.  Removes the mount directory in `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>`.
        
    
    **Example**:
    
    ```bash
    uhpc-conda-stop myenv
    ```
    
    Unmounts `/dev/shm/$USER/conda/conda_envs/myenv` and cleans up.
    
### Helper Scripts for Multiple Interactive Shells

These scripts let you allocate HPC resources (once) and open **any number** of interactive Bash shells within the same Slurm job—each in its own terminal window.

1.  **uhpc-salloc**
    
    *   **What it does**:
        
        *   Allocates a node (or nodes) with `salloc --no-shell`, parsing out the **job ID**.
            
        *   Frees your terminal so you can **open multiple interactive shells** in separate windows (each attached to that same job).
            
    *   **Usage**:
        
        ```bash
        uhpc-salloc [--partition=<part>] [--time=<HH:MM:SS>] [other Slurm options...]
        ```
        
        *   Defaults: `partition=compute`, `time=1:00:00`.
            
    *   **Example**:
        
        ```bash
        uhpc-salloc --partition=gpu --time=2:00:00 --gres=gpu:1
        ```
        
        Suppose it prints “Allocated JobID=123456”; you can then open as many terminals as you like, each running `uhpc-login 123456`.
        
2.  **uhpc-login**
    
    *   **What it does**:
        
        *   From another terminal window (or the same one), opens a **new** fully interactive Bash shell inside the already-allocated job.
            
    *   **Usage**:
        
        ```bash
        uhpc-login <JOBID> [<SHELL_INDEX>]
        ```
        
        *   `SHELL_INDEX` is optional; it just helps label each shell step (like `shell1`, `shell2`). If omitted, a random label is used.
            
    *   **Under the Hood**:
        
        *   Uses `srun --jobid=<JOBID> --pty bash` so Slurm grants a real interactive shell, each with its own TTY.
            
3.  **uhpc-unalloc**
    
    *   **What it does**:
        
        *   Cancels (`scancel`) the entire job by ID, killing all open shells and releasing resources.
            
    *   **Usage**:
        
        ```bash
        uhpc-unalloc <JOBID>
        ```

### Helper Scripts for working with cloud storage (e.g. OneDrive)


- **uhpc-cloud-mount**  
  **What it does**:  
  Mounts a remote cloud folder (via rclone) on a local path (FUSE mount), commonly with a RAM-based cache in `/dev/shm`.  
  - Automatically backgrounds the `rclone mount` process and logs to a file in the cache directory.

  **Usage**:  
  ```bash
  uhpc-cloud-mount <REMOTE:PATH> <MOUNTPOINT> [--cache-dir /some/dir] [--vfs-cache-mode mode]
  ```

Where:

*   `<REMOTE:PATH>` is the rclone remote and path (e.g. `onedrive_remote:MyData`).
    
*   `<MOUNTPOINT>` is where the folder will be mounted locally (must exist or be creatable).
    
*   `--cache-dir` (optional) overrides the default `/dev/shm/rclone_cache_$USER`.
    
*   `--vfs-cache-mode` (optional) defaults to `writes`.
    

**Example**:

```bash
uhpc-cloud-mount onedrive_remote:MyData /dev/shm/my_mount \
    --cache-dir /dev/shm/$USER/cloud_cache \
    --vfs-cache-mode writes
```

This sets up a background `rclone mount` process that logs to `/dev/shm/$USER/cloud_cache/rclone_mount.log`, mounting `MyData` to `/dev/shm/my_mount`.

* * *

*   **uhpc-cloud-umount**  
    **What it does**:  
    Unmounts an existing rclone FUSE mount and optionally removes the cache directory.
    
    **Usage**:
    
    ```bash
    uhpc-cloud-umount <MOUNTPOINT> [--cache-dir /some/dir]
    ```
    
    Where:
    
    *   `<MOUNTPOINT>` is the path used by `uhpc-cloud-mount` (e.g. `/dev/shm/my_mount`).
        
    *   `--cache-dir` overrides the default `/dev/shm/rclone_cache_$USER` for cleaning up logs/files.
        
    
    **Example**:
    
    ```bash
    uhpc-cloud-umount /dev/shm/my_mount --cache-dir /dev/shm/$USER/cloud_cache
    ```
    
    This unmounts the FUSE mount at `/dev/shm/my_mount` and removes the cache directory if specified.
    
       
---

## Installation

### Option 1: User-Local Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/jpers1/uhpc-tools.git
   cd uhpc-tools
   ```
2. Run the installation script (it will copy scripts to `~/.local/bin`):
   ```bash
   ./install.sh --user
   ```
3. Ensure `~/.local/bin` is on your `PATH` (usually it is, but if not, add something like:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   ```

### Option 2: System-Wide Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/jpers1/uhpc-tools.git
   cd uhpc-tools
   ```
2. Run the installation script with `sudo`:
   ```bash
   sudo ./install.sh --system
   ```
   By default, it installs into `/usr/local/bin`. You can customize paths inside `install.sh` if needed.

---

## Usage Examples

### uhpc-list

- **List all nodes**:
  ```bash
  uhpc-list
  ```

- **List only free nodes** (MIX, IDLE, or free CPUs):
  ```bash
  uhpc-list --free
  ```

---

### uhpc-multipush

1. Allocate some nodes first, for example:
   ```bash
   salloc --nodes=2 --nodelist=wn208,wn209 --time=1:00:00
   ```
2. Push a local file to `/dev/shm` on those nodes:
   ```bash
   uhpc-multipush /dev/shm/mydata_local.dat /dev/shm/mydata_remote.dat wn208,wn209
   ```

---

### `uhpc-conda-start`

This script mounts a **SquashFS**-compressed Conda environment in `/dev/shm` (RAM disk), without automatically activating it.
**Usage**:
```bash
uhpc-conda-start <SQUASHFS_FILE>
```
**What It Does**:

1. **Resolves** `<SQUASHFS_FILE>` to a full path (if possible).
2. **Unmounts** any stale mount for the same environment name (if it exists).
3. **Copies** the file into `/dev/shm/$USER/` if needed.
4. **Mounts** the file read-only at `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>` (derived from the file’s basename minus `.sqsh` or `.squashfs`).
5. Prints instructions on how to **manually** activate the environment.

**Manual Activation**
After mounting completes, you have two main options:

- **Conda**:
  ```bash
  conda activate /dev/shm/$USER/conda/conda_envs/<ENV_NAME>
  ```
- **PATH**:
  ```bash
  export PATH="/dev/shm/$USER/conda/conda_envs/<ENV_NAME>/bin:$PATH"
  ```

This approach avoids any issues with sub-shells or HPC environment conflicts. **If** you want to “deactivate,” just run `conda deactivate` or open a new shell.

### `uhpc-conda-stop`

Once you’re finished with the environment:

```bash
uhpc-conda-stop <ENV_NAME>
```
**What It Does**:

1. **Unmounts** `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>` if it’s mounted.
2. **Removes** the mount directory.

Note that if you were using `conda activate /dev/shm/...`, you’ll want to manually `conda deactivate` afterward, because `uhpc-conda-stop` no longer attempts to run `conda deactivate`.


### uhpc-cloud-mount

Mount a remote folder to a local path with optional memory-based cache. For example:

```bash
# Basic usage
uhpc-cloud-mount onedrive_remote:MyData /dev/shm/my_mount

# With custom cache directory and vfs mode
uhpc-cloud-mount dropbox_remote:some_folder /mnt/cloud \
    --cache-dir /dev/shm/$USER/cloud_cache \
    --vfs-cache-mode writes
```

This runs `rclone mount` in the background, logs to `--cache-dir/rclone_mount.log`, and frees your shell prompt. Check the log if something goes wrong.

### uhpc-cloud-umount

Unmount the folder:

```bash
uhpc-cloud-umount /dev/shm/my_mount
```

If you used a custom cache directory:

```bash
uhpc-cloud-umount /dev/shm/my_mount --cache-dir /dev/shm/$USER/cloud_cache
```

It unmounts via `fusermount -u` and removes the cache directory if present.

### Common Issues

- **Quota Exceeded**: If you place the rclone cache in your home directory, large writes can exhaust quota. Use `/dev/shm` or HPC scratch.
- **Policy Restrictions**: Some clusters don’t allow background FUSE mounts on login nodes or kill them upon session end. Work around by running in a batch job or `tmux/screen` session.

With these tools, you can quickly spin up a user-level cloud mount on HPC, manipulate files, and tear it down when done.

### Example Workflow: Combining Cloud Tools and Conda Tools

1. **Mount Your Cloud Folder on the Login Node**  
   - On the **login node**, use `uhpc-cloud-mount` to attach your remote folder. For example:
     ```bash
     uhpc-cloud-mount onedrive_remote:MyData /dev/shm/$USER/cloud_mount
     ```
   - Check `/dev/shm/$USER/cloud_mount` to ensure your files (e.g., `myenv.sqsh`, `mydata.zip`) are visible.

2. **Copy Files to a Quota-Free Location (Still on Login Node)**  
   - Copy the files you need from the mounted directory into a separate directory in `/dev/shm` (or HPC scratch), for example:
     ```bash
     cp /dev/shm/$USER/cloud_mount/myenv.sqsh /dev/shm/$USER/
     cp /dev/shm/$USER/cloud_mount/mydata.zip /dev/shm/$USER/
     ```
   - **Important**: HPC often **won’t** recognize FUSE mounts directly in compute jobs, and large parallel reads from cloud can cause rate-limiting. Keeping everything local avoids these issues.

3. **Unmount the Cloud Folder (Optional)**  
   - Once files are copied, free up resources:
     ```bash
     uhpc-cloud-umount /dev/shm/$USER/cloud_mount
     ```
   - This prevents leaving an active rclone process running on the login node.

4. **Allocate a Compute Node**  
   - Request an interactive or batch job, for example:
     ```bash
     salloc --nodes=1 --partition=gpu --time=1:00:00
     ```
   - Now you’re on a **compute node**.

5. **Distribute Data to Compute Node(s)**  
   - If the data is still on the login node, you can push it to the compute node with `uhpc-multipush` (assuming you already allocated a node or multiple nodes). For instance:
     ```bash
     # If not already in the same node's /dev/shm, push from login node:
     uhpc-multipush /dev/shm/$USER/mydata.zip /dev/shm/$USER/mydata.zip <list_of_nodes>
     ```
   - Alternatively, if you are **already** in the shell of that node (salloc interactive), and the files are in `/dev/shm/$USER` from the login node’s session, verify they exist locally. HPC setups vary—sometimes /dev/shm is node-specific.

6. **Mount the Conda Environment with `uhpc-conda-start`**  
   - On the compute node, mount the SquashFS environment you copied:
     ```bash
     uhpc-conda-start /dev/shm/$USER/myenv.sqsh
     ```
   - This will place a read-only environment in `/dev/shm/$USER/conda/conda_envs/myenv`.

7. **Activate the Environment (Optional)**  
   ```bash
   conda activate /dev/shm/$USER/conda/conda_envs/myenv
   ```
   Now `python`, `pytorch`, etc., are available from this environment.

8. **Use the Dataset**  
   - Unzip or process your dataset in `/dev/shm/$USER/` (or HPC scratch) as needed:
     ```bash
     cd /dev/shm/$USER
     unzip mydata.zip
     # run your compute job, etc.
     ```

9. **Stop When Done**  
   - **Deactivate** the Conda environment:
     ```bash
     conda deactivate
     ```
   - **Unmount** the environment:
     ```bash
     uhpc-conda-stop myenv
     ```
   - **Cleanup** any large files you no longer need:
     ```bash
     rm -f /dev/shm/$USER/myenv.sqsh
     rm -f /dev/shm/$USER/mydata.zip
     ```
   - End your job or interactive session as usual.

---

### Why This Workflow?

- **Mounting Cloud Remotes on the Login Node**: HPC often forbids or breaks user FUSE mounts on compute nodes, and parallel cloud access can get your account throttled or blocked by the cloud provider.  
- **Local Copying**: Staging data in `/dev/shm` or HPC scratch ensures fast access and avoids repeated network transfers.  
- **Modular Steps**: You can unmount the cloud remote to avoid leaving a background process, then proceed with normal HPC usage (e.g., Slurm batch jobs).

Following these steps ensures minimal HPC quota usage, respects HPC and cloud provider policies, and streamlines your workflow with both environment images (`.sqsh`) and data files (e.g., `.zip`).

---

### Example Multi-Shell Workflow

```bash
# 1) Allocate resources (no immediate shell) on a GPU node for 2 hours:
uhpc-salloc --partition=gpu --time=2:00:00
# -> prints something like "Allocated JobID=123456"

# 2) In a NEW terminal, open your first shell:
uhpc-login 123456
# -> Now you have a fully interactive Bash prompt on the compute node.

# 3) Open more shells (each in a new terminal) if you wish:
uhpc-login 123456 2
uhpc-login 123456 3
# -> You can watch GPU usage in one shell, run training in another, etc.

# 4) End an individual shell:
exit
# or Ctrl+D in that shell

# 5) When you're finished with all shells, free the resources:
uhpc-unalloc 123456
# -> Cancels the entire job, ending any remaining shells.
```

In this approach, you get multiple independent Bash sessions on the same node. Each is a real interactive step with a TTY from the start, **avoiding** the orphaned background shell issues. If you need to log out or close one shell, the others keep running until you `uhpc-unalloc` or time runs out.



## License

See the [LICENSE](LICENSE) file for details on usage terms. Contributions and issues are welcome!
---

## Acknowledgments

This project’s development was assisted by **ChatGPT o1-pro**, an AI-based language model. While we’ve done our best to validate the scripts and instructions, users should keep in mind that **there may be bugs or unforeseen issues**. Always review and test code in your own HPC environment before using it in production.
