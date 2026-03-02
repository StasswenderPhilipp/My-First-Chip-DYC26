import argparse
import sys
import yaml
import os

def parse_flist(file, relpath):
    defines = []
    incdirs = []
    files = []
    
    with open(file, 'r') as f:
        for line in f:
            if line.startswith("+incdir+"):
                # Process the line and extract relevant information
                incdirs.append(line.strip().split("+")[2])
            elif line.startswith("+define+"):
                # Process the line and extract relevant information
                defines.append(line.strip().split("+")[2])
            else:
                files.append(line.strip())
    
    return {"VERILOG_DEFINES": defines, "VERILOG_INCLUDE_DIRS": incdirs, "VERILOG_FILES": files}

def main():
    parser = argparse.ArgumentParser(description="Process a file and convert flist to YAML.")
    parser.add_argument("file", help="Input file to process")
    args = parser.parse_args()
    
    relpath = os.path.dirname(os.path.relpath(args.file))+"/"
    
    # Placeholder for further processing
    result = parse_flist(args.file, relpath)
    print(yaml.dump(result, default_flow_style=False, sort_keys=False))

if __name__ == "__main__":
    main()