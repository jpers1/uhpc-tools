# UHPC-Tools

**UHPC-Tools** ("Unusual HPC Tools") is a small collection of Bash scripts for Slurm based clusters. The scripts cover common tasks such as listing nodes, starting multiple interactive shells and mounting cloud storage.

## Available Documentation
- [Scripts for new HPC users](docs/new_user_tools.md)
- [Scripts for multiple interactive shells](docs/multi_shell_tools.md)
- [Scripts for working with cloud storage](docs/cloud_tools.md)
- [Detailed cloud how-to](CLOUD_HOWTO.md)
- [Detailed conda how-to](CONDA_HOWTO.md)

## Installation
Clone the repository and run the provided installer with sudo:
```bash
git clone https://github.com/jpers1/uhpc-tools.git
cd uhpc-tools
sudo ./install.sh --system
```
The install script places the commands in `/usr/local/bin` by default.

## License
See [LICENSE](LICENSE) for details. Contributions and issues are welcome!

## Acknowledgments
This project’s development was assisted by **ChatGPT o1-pro**. Although the scripts have been tested, they may still contain bugs. Always review and test code in your own HPC environment.
