#!/usr/bin/env python3
"""
Fix: Disable should_be_disabled() in the installed comfyui_manager pip package
so that the custom_nodes/comfyui-manager web extension can be registered.

The pip package's should_be_disabled() function blocks any custom_nodes directory
whose name contains "comfyui-manager" to prevent the "legacy" Manager from loading
when the pip package is installed. But when using the pip package + custom_nodes
source together, this prevents the web extension from being registered.

This script finds the installed comfyui_manager package and modifies the
should_be_disabled() function to always return False.
"""

import os
import glob

# Find the installed comfyui_manager package
site_packages = glob.glob('/opt/conda/lib/python*/site-packages')[0]
filepath = os.path.join(site_packages, 'comfyui_manager', '__init__.py')

with open(filepath, 'r') as f:
    lines = f.readlines()

with open(filepath, 'w') as f:
    for line in lines:
        if line.strip().startswith("if 'comfyui-manager' in dir_name:"):
            f.write('        if False: # Disabled to allow custom_nodes web extension\n')
        else:
            f.write(line)

print(f'Fixed should_be_disabled() in {filepath}')
