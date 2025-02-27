# UHPC-Tools

UPPC-Tools ("Unusual HPC tools") is a lightweight collection of handy Bash scripts for Slurm clusters. Current scripts:

- **ahpc-list**   
  Lists all cluster nodes with CPU, memory, and GPU usage.  
   - By default, prints every node.  
   - `--free` shows only MIX or IDLE#nodes or those with free CPUs.

- **uhpc-multipush**   
  Streams a local file (for example, from `/dev/shm`) to `/dev/shm` on one or more allocated Slurm nodes, bypassing shared filesystem quotas.

## Installation

**Option 1: User-Local Installation**

1. Clone this repository:
    `git clone https://github.com/jpers1/uhpc-tools.git`
    cl uhpc-tools

2. Run the installation script (it will copy scripts to `~/.local/bin`):
    `./install.sh --user`

3. Ensure `>~/.local/bin` is on your `PATH`  (usually it is, but if not, add something like:
    `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc`

***Option 2: System-Wide Installation**

1. Clone this repository:
    `git clone https://github.com/jpers1/uhpc-tools.git`
    cd uhpc-tools

2. Run the installation script with `sudo` :
    `sudo ./install.sh --system`
By default, it installs into 
	`/usr/local/bin` 
You can customize paths inside `install.sh` if needed.


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

### uhpc-multipush
1. Allocate some nodes first, for example:
```ash
salloc --nodes=2 --nodelist=wn208,wn209 --time=1:00:00
```

2. Push a local file to `/dev/shm` on those nodes:

```bash
uhpc-multipush /dev/shm/mydata_local.dat /dev/shm/mydata_remote.dat wn208,wn209
```

## License

See the [LICENSE](LICENSE) file for details on usage terms. Contributions and issues are welcome!
