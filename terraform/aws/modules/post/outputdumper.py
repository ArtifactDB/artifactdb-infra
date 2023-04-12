import os
import json
import subprocess
import sys

strmods = sys.argv[-1]
if strmods == "*":
    strmods = ",".join([d for d in os.listdir("..") if os.path.isdir(f"../{d}") and d != 'post' and not d.startswith(".")])

outputs = {}

print("Working dir;: %s, Modules: %s" % (os.path.abspath(os.path.curdir),strmods))
for modpath in strmods.split(","):
    mod = modpath.split("/")[-1]
    print(f"Extracting outputs for module {mod}")
    status, stdout = subprocess.getstatusoutput(f"cd {modpath}/ && terragrunt output -json 2> /dev/null  && cd - > /dev/null")
    if status != 0:
        raise Exception("Error executing outputdumper: {}".format(stdout))
    outputs[mod] = json.loads(stdout)

json.dump(outputs,open("outputs.json","w"),indent=4)
