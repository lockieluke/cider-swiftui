import os, subprocess

subprocess.Popen(f"/bin/zsh -c \"task build-discord-rpc-lib\"", env=os.environ.copy())
