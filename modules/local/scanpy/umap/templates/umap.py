#!/usr/bin/env python3

# Disable OpenMP CPU topology detection for MacOS compatibility
import os
os.environ["KMP_AFFINITY"] = "disabled"

import platform
import argparse
import shlex

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"
os.environ["MPLCONFIGDIR"] = "./tmp/matplotlib"

import scanpy as sc
import numpy as np
import pandas as pd
import yaml

from threadpoolctl import threadpool_limits
threadpool_limits(int("${task.cpus}"))
sc.settings.n_jobs = int("${task.cpus}")

adata = sc.read_h5ad("${h5ad}", backed='r')
prefix = "${prefix}"
args = "${args}"
parser = argparse.ArgumentParser()
parser.add_argument("--decimals", type=int, default=None)
params = parser.parse_args(shlex.split(args))

sc.tl.umap(adata, random_state=0)

if params.decimals is not None:
    adata.obsm["X_umap"] = np.round(adata.obsm["X_umap"].astype(np.float64), params.decimals)

var_per_dim = np.var(adata.obsm["X_umap"].astype(np.float64), axis=0)
variance_ratio = (var_per_dim / var_per_dim.sum()).tolist()
if params.decimals is not None:
    variance_ratio = np.round(variance_ratio, params.decimals).tolist()

with open(f"variance_ratio_{prefix}.yml", "w") as f:
    yaml.dump({"variance_ratio": variance_ratio}, f)

adata.write_h5ad(f"{prefix}.h5ad")
df = pd.DataFrame(adata.obsm["X_umap"], index=adata.obs_names)
df.to_pickle(f"X_{prefix}.pkl")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scanpy": sc.__version__,
        "pandas": pd.__version__
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
