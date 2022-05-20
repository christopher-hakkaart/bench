#!/usr/bin/env python3

import argparse
import joblib

# Parse definitions
parser = argparse.ArgumentParser(description='Conver Truvari jl file to make it easier to load into R.')
parser.add_argument('-in',dest='jl',help="Input jl file")
parser.add_argument('-out',dest='out',help="Output jl file")
args = parser.parse_args()

# Load jl data
data = joblib.load(args.jl)

# Save as csv
data.to_csv(args.out)
