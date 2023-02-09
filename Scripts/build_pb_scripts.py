import os

SRCROOT = os.getenv("SRCROOT")
os.popen(f"/bin/zsh -c \"(cd {SRCROOT}/CiderPlaybackAgent/Web\ Scripts/; yarn build)\"")
