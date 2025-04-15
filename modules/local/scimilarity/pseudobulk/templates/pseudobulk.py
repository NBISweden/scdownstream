#!/usr/bin/env python3

import os
import shutil

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"

import platform
import pandas as pd
import scanpy as sc
from scimilarity.utils import pseudobulk_anndata
import scimilarity
import yaml

adata = sc.read_h5ad("${h5ad}")

adata_pseudobulk = pseudobulk_anndata(adata, "cell_type")

# Write the output
adata_pseudobulk.write_h5ad("${prefix}.h5ad")

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scimilarity": scimilarity.__version__,
        "scanpy": sc.__version__,
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
