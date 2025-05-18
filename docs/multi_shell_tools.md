# Helper Scripts for Multiple Interactive Shells

Allocate resources once and open any number of shells in the same Slurm job.

## `uhpc-salloc`
Allocates a node (or nodes) using `salloc --no-shell` and prints the job ID so you can attach shells later.

**Usage**
```bash
uhpc-salloc [--partition=<part>] [--time=<HH:MM:SS>] [other Slurm options...]
```

## `uhpc-login`
Open a new interactive shell attached to the job created by `uhpc-salloc`.

**Usage**
```bash
uhpc-login <JOBID> [<SHELL_INDEX>]
```
`SHELL_INDEX` is optional and helps label each shell.

## `uhpc-unalloc`
Cancel the job and free all allocated resources.

**Usage**
```bash
uhpc-unalloc <JOBID>
```

## `uhpc-logoff`
Attempt to detach from an attached shell while keeping it running in the background. This relies on `sattach` and may not work in all environments.

**Usage**
```bash
uhpc-logoff
```

### Example workflow
```bash
uhpc-salloc --partition=gpu --time=2:00:00
uhpc-login 123456
uhpc-login 123456 2
uhpc-login 123456 3
# When done
uhpc-unalloc 123456
```
