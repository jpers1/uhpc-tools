# CONDA_HOWTO.md

## Overview

In this guide, you’ll:

1. **Create** a Conda environment in `/dev/shm/$USER/` (RAM-based storage).  
2. **Install** your packages (e.g., PyTorch).  
3. **Test** that everything works (e.g., detect GPU).  
4. **Compress** the environment into a **SquashFS** file.  
5. Optionally use **uhpc-conda-start** / **uhpc-conda-stop** to mount and activate the environment in RAM.

All steps are done in memory, minimizing HPC filesystem usage and avoiding quotas on shared storage.

---

## 1. Allocate an Interactive Node (Optional)

It’s usually best to do environment creation on a node with enough CPU cores and RAM. For instance:

```bash
salloc --nodes=1 --cpus-per-task=8 --mem=64G --time=2:00:00
```

Adjust resources as needed. Once allocated, you’re on a compute node in an interactive shell. Now you can safely use `/dev/shm`.

---

## 2. Create a Directory in /dev/shm

Set up your working directories in memory:

```bash
mkdir -p /dev/shm/"$USER"/myenv
cd /dev/shm/"$USER"/myenv
```

> Here, `myenv` is just a placeholder name for the environment. Feel free to name it whatever you like.

---

## 3. Load or Access Conda

You have two main ways:

### A) Use a System/Module Conda

If your cluster has a Conda module:

```bash
module load Anaconda3
```
(or `module load miniconda3`, etc.)

Then you have `conda` and `python` commands available.

### B) Use a Local Conda Install

If you already have a local Conda installation but want to do everything in RAM, you can copy your Miniconda install to `/dev/shm` first. However, most HPC setups offer a module for Conda. We’ll assume that’s the approach.

---

## 4. Create the Conda Environment in RAM

Now create a brand-new environment in `/dev/shm/$USER/myenv_env`:

```bash
conda create -y -p /dev/shm/"$USER"/myenv_env python=3.9
```

Notes:
- `-p /path` means “put the environment at this exact path” (not by name).
- `-y` auto-confirms the install prompt.
- `python=3.9` is just an example version.

When finished, you’ll have:

```
/dev/shm/$USER/myenv_env/
├── bin/
├── lib/
├── etc/
└── ...
```

---

## 5. Activate and Install Packages

Activate the new environment from memory:

```bash
conda activate /dev/shm/"$USER"/myenv_env
```

Install whatever packages you need. For example, PyTorch with GPU support:

```bash
conda install -y pytorch torchvision torchaudio cudatoolkit=11.7 -c pytorch -c nvidia
```

> Adjust versions/channels as needed for your HPC environment.  

You can install other packages as well (`conda install -y numpy scikit-learn`, etc.). Everything is being placed in `/dev/shm`.

---

## 6. Verify the GPU Works

A minimal GPU test in Python:

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

It should print `True` if PyTorch detects a GPU. Another test:

```bash
python -c "import torch; print(torch.cuda.get_device_name(0))"
```

Should print the name of your GPU.

---

## 7. (Optional) Clean Up Environment

Conda and pip can leave some cache files. If you want to reduce final size:

```bash
conda clean -y --all
```

---

## 8. Deactivate the Environment

```bash
conda deactivate
```

You now have a complete environment in `/dev/shm/$USER/myenv_env` that you can compress with SquashFS.

---

## 9. Create the SquashFS File

Use `mksquashfs` to compress the environment. Let’s name it `myenv.sqsh`:

```bash
cd /dev/shm/"$USER"   # parent directory of myenv_env
mksquashfs myenv_env myenv.sqsh \
    -comp xz \
    -Xbcj x86 \
    -b 1M \
    -processors 8
```

Explanation:

- **`mksquashfs <SOURCE_DIR> <OUTPUT_FILE>`**  
  - `<SOURCE_DIR>` = `/dev/shm/$USER/myenv_env`.  
  - `<OUTPUT_FILE>` = `myenv.sqsh`.
- **`-comp xz`** uses xz compression (higher ratio, slower to compress).  
- **`-processors 8`** uses 8 CPU threads for compression (change if you have more cores).  
- **`-Xbcj x86`** can optimize xz compression for x86 binaries.  
- **`-b 1M`** sets a 1 MB block size, good for xz.

Once it finishes, you have:

```
/dev/shm/$USER/myenv.sqsh
```

which is a compressed read-only image containing your environment.

---

## 10. Use the Environment via uhpc-conda-start

If you have the **uhpc-conda-start** script (part of UHPC-Tools), you can do:

```bash
uhpc-conda-start /dev/shm/"$USER"/myenv.sqsh
```

Under the hood:

1. It sees the `.sqsh` file is already in `/dev/shm`, so no copy needed.  
2. It mounts read-only to `/dev/shm/$USER/conda/conda_envs/myenv`  
   (assuming your file is named `myenv.sqsh`).  
3. It then runs `conda activate /dev/shm/$USER/conda/conda_envs/myenv`.

Check:

```bash
which python
# => /dev/shm/$USER/conda/conda_envs/myenv/bin/python

python -c "import torch; print(torch.cuda.get_device_name(0))"
# => "Tesla V100-SXM2-16GB" or whatever
```

---

## 11. Stop the Environment

When you’re done:

```bash
uhpc-conda-stop myenv
```

This:

1. Runs `conda deactivate`
2. Unmounts `/dev/shm/$USER/conda/conda_envs/myenv`
3. Removes the mount directory

Your `.sqsh` file remains in `/dev/shm/$USER/myenv.sqsh`. If you want to reclaim memory, you can remove it:

```bash
rm /dev/shm/"$USER"/myenv.sqsh
```

---

## 12. Persistent Storage (Optional)

If you don’t want to lose your `.sqsh` file at the end of the job, **copy it** to your HPC filesystem, e.g.:

```bash
cp /dev/shm/"$USER"/myenv.sqsh /path/to/your/home_or_project_dir/
```

Then you can use it in future jobs. However, be mindful of HPC quotas in your home directory.

---

## Conclusion

You now have a **fully self-contained** Conda environment in `/dev/shm` that you compressed into a **SquashFS** image. You can **mount** and **activate** it quickly with **uhpc-conda-start**, run your GPU jobs, and then **unmount** with **uhpc-conda-stop**. This approach:

- **Minimizes HPC filesystem usage** (everything is in RAM).
- **Bypasses shared filesystem quotas**.
- **Speeds up** environment activation (especially for big frameworks like PyTorch).

Happy computing!