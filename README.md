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

### Example Workflow

1. **Allocate** a node:
   ```bash
   salloc --nodes=1 --partition=gpu --time=1:00:00
   ```
2. **Mount** the environment:
   ```bash
   uhpc-conda-start /path/to/myenv.sqsh
   ```
   (It shows you it’s now at `/dev/shm/$USER/conda/conda_envs/myenv`.)

3. **Activate** if desired:
   ```bash
   conda activate /dev/shm/$USER/conda/conda_envs/myenv
   ```
4. **Use** your environment.
5. **Stop** when done:
   ```bash
   conda deactivate   # if used
   uhpc-conda-stop myenv
   ```


## License

See the [LICENSE](LICENSE) file for details on usage terms. Contributions and issues are welcome!
---

## Acknowledgments

This project’s development was assisted by **ChatGPT o1-pro**, an AI-based language model. While we’ve done our best to validate the scripts and instructions, users should keep in mind that **there may be bugs or unforeseen issues**. Always review and test code in your own HPC environment before using it in production.
