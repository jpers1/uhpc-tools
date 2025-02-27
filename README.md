# UHPC-Tools

**UHPC-Tools** ("Unusual HPC Tools") is a lightweight collection of handy Bash scripts for Slurm clusters. Current scripts:

- **uhpc-list**  
  Lists all cluster nodes with CPU, memory, and GPU usage.  
  - By default, prints every node.  
  - `--free` shows only MIX or IDLE nodes or those with free CPUs.

- **uhpc-multipush**  
  Streams a local file (for example, from `/dev/shm`) to `/dev/shm` on one or more allocated Slurm nodes, bypassing shared filesystem quotas.

- **uhpc-conda-start**  
  Given a SquashFS file (e.g., `myenv.sqsh`) containing a conda environment, this script:
  1. Copies it to `/dev/shm/$USER/` if it’s not already on `/dev/shm`.
  2. Mounts it read-only at `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>`.
  3. Activates the environment via `conda activate /dev/shm/$USER/conda/conda_envs/<ENV_NAME>`.

- **uhpc-conda-stop**  
  Deactivates and unmounts an environment that was started with **uhpc-conda-start**:
  1. `conda deactivate`
  2. Unmounts the environment folder (`fusermount -u`)
  3. Removes the mount directory in `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>`

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

---

Below is a comprehensive **CLOUD_HOWTO.md** for mounting cloud storage on HPC (unprivileged) using rclone, followed by two new scripts:

- **`uhpc-cloud-mount`**: A Bash script that encapsulates rclone mount, checks for running processes, sets up a RAM-based cache, and daemonizes itself (runs in the background).  
- **`uhpc-cloud-umount`**: A companion script that unmounts a previously mounted folder.

Finally, there is a **“Cloud Tools”** section that you can append to your existing `README.md` to document these new scripts under the UHPC-Tools collection.

---

# CLOUD_HOWTO.md

## Overview

This guide explains how to mount a cloud storage folder (OneDrive, Dropbox, etc.) onto an HPC cluster using **rclone** without needing admin privileges. You can then access files as if they’re part of your local filesystem, all while respecting HPC policies and quotas.

**Key Points**:

- We rely on **user-space FUSE** (`rclone mount`) with no special privileges.  
- HPC clusters often **limit** or discourage FUSE mounts, so ensure you **understand your site’s policies**.  
- By default, rclone caches writes to your **home directory**, which can quickly exceed your quota. Hence, we show how to use a **RAM-based** cache (e.g., `/dev/shm`) to avoid filling up home directories.

## 1. Requirements

1. **rclone** installed in your PATH (can be a user installation).  
2. **FUSE** support (e.g., `fusermount` is available).  
3. **Cloud remote** configured with `rclone config`. For example, you might have a remote named `onedrive_remote:` or `dropbox_remote:`.

## 2. HPC Caveats

- **Login Node vs. Compute Node**: Some HPC systems only allow FUSE mounts on compute nodes (within an interactive or batch job).  
- **Long-Running Processes**: HPC schedulers may kill user processes that remain after your job ends, or if you log out.  
- **Performance**: Cloud-based I/O is relatively slow compared to HPC scratch/local storage. Copying/syncing data is often better for large or intensive jobs.

## 3. Create and Configure Your Rclone Remote

If you haven’t already, run:
```bash
rclone config
```
to set up a remote for your cloud provider (e.g., OneDrive, Dropbox, Google Drive). Ensure you can do a simple `rclone ls` to confirm it’s working:
```bash
rclone ls onedrive_remote:
```

## 4. Using `uhpc-cloud-mount` and `uhpc-cloud-umount`

### uhpc-cloud-mount

- **Purpose**: Mount a cloud folder to a local path.  
- **Features**:
  1. Checks if `rclone` is already running for the current user.
  2. Creates (or resets) a RAM-based cache directory in `/dev/shm`.
  3. Spawns `rclone mount` in the background (daemonizes) so you keep your shell prompt free.
  4. Uses `fusermount` to handle unprivileged FUSE.

**Example**:
```bash
# Mount "onedrive_remote:MyData" to "/dev/shm/my_mount" using a RAM-based cache
uhpc-cloud-mount onedrive_remote:MyData /dev/shm/my_mount
```

### uhpc-cloud-umount

- **Purpose**: Cleanly unmount a previously mounted folder.  
- **Features**:
  1. Checks if the specified path is actually mounted by rclone.
  2. Calls `fusermount -u` (or similar) to unmount.
  3. Optionally removes the associated cache directory if it was created by uhpc-cloud-mount.

**Example**:
```bash
uhpc-cloud-umount /dev/shm/my_mount
```

## 5. Verify the Mount

After running `uhpc-cloud-mount`, you can open a **new terminal** (or the same one if you backgrounded the command) and do:
```bash
ls /dev/shm/my_mount
```
If it lists your cloud files, you’ve successfully mounted the remote folder.

## 6. Potential Issues & Troubleshooting

- **“fusermount3: not found”**: Some systems only have `fusermount`; see the HPC docs or create a symlink.  
- **Cache Directory Fill-Up**: If the data you write is bigger than the available RAM (in `/dev/shm`), you’ll get “No space left on device” or “disk quota exceeded.”  
- **Scheduler Kills**: If you run on a login node or your job ends, the HPC might kill your rclone process automatically. Consider using `tmux`/`screen` or do the mount inside a batch script.


## Example Workflow: Combining Cloud Tools and Conda Tools

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

## License

See the [LICENSE](LICENSE) file for details on usage terms. Contributions and issues are welcome!
---

## Acknowledgments

This project’s development was assisted by **ChatGPT o1-pro**, an AI-based language model. While we’ve done our best to validate the scripts and instructions, users should keep in mind that **there may be bugs or unforeseen issues**. Always review and test code in your own HPC environment before using it in production.
