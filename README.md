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

### uhpc-conda-start

Given a SquashFS file (e.g., `myenv.sqsh`) containing a conda environment:

```bash
uhpc-conda-start <SQUASHFS_FILE>
```

- The script infers the environment name from the file’s basename (e.g., `myenv.sqsh` => `myenv`).
- If `<SQUASHFS_FILE>` is not in `/dev/shm`, it’s copied to `/dev/shm/$USER/`.
- Then it’s mounted at `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>` (read-only).
- Finally, the environment is activated via `conda activate /dev/shm/$USER/conda/conda_envs/<ENV_NAME>`.

For example:

```bash
uhpc-conda-start /path/to/myenv.sqsh
# => environment "myenv" is mounted and activated
```

---

### uhpc-conda-stop

Once you’ve finished using an environment started by `uhpc-conda-start`, you can deactivate and unmount it:

```bash
uhpc-conda-stop <ENV_NAME>
```

- Runs `conda deactivate`.
- Unmounts the environment from `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>`.
- Removes the mount point directory.

For example:

```bash
uhpc-conda-stop myenv
```

---

## License

See the [LICENSE](LICENSE) file for details on usage terms. Contributions and issues are welcome!
```