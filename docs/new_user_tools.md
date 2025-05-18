# Helper Scripts for New HPC Users

These scripts help users with minimal disk quota get up and running quickly. They work on top of Slurm and assume standard Unix tools are available.

## `uhpc-list`
Lists all cluster nodes with CPU, memory, GPU usage and ephemeral SSD capacity.
- `--free` shows only MIX or IDLE nodes or those with free CPUs.

**Usage**
```bash
uhpc-list
uhpc-list --free
```

## `uhpc-multipush`
Streams a local file to `/dev/shm` on one or more allocated nodes, bypassing shared filesystem quotas.

**Usage**
```bash
uhpc-multipush <LOCAL_FILE> <REMOTE_FILE> <NODE_LIST>
```
Where `LOCAL_FILE` is the path to the local file, `REMOTE_FILE` is the desired path on the remote nodes (or a directory ending with `/`), and `NODE_LIST` is a comma separated list of nodes.

**Example**
```bash
salloc --nodes=2 --nodelist=wn208,wn209 --time=1:00:00
uhpc-multipush /dev/shm/mydata_local.dat /dev/shm/mydata_remote.dat wn208,wn209
```

## `uhpc-conda-start`
Mounts a SquashFS-based conda environment in `/dev/shm/$USER/conda/conda_envs/<ENV_NAME>` without activating it.

**Usage**
```bash
uhpc-conda-start <SQUASHFS_FILE>
```
After mounting, activate manually with:
```bash
conda activate /dev/shm/$USER/conda/conda_envs/<ENV_NAME>
```

## `uhpc-conda-stop`
Unmounts the environment mounted with `uhpc-conda-start`.

**Usage**
```bash
uhpc-conda-stop <ENV_NAME>
```
