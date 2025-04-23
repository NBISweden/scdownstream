#!/usr/bin/env python3

import platform
import anndata as ad
import pandas as pd
from scipy.stats import entropy
import scipy
import yaml

group_col = "${group_col}"
entropy_col = "${entropy_col}"
prefix = "${prefix}"
adata = ad.read_h5ad("${h5ad}", backed='r')

def entropy_of_b(group):
    counts = group.value_counts(normalize=True)
    return entropy(counts, base=2)

entropies = adata.obs.groupby(group_col)[entropy_col].apply(entropy_of_b)

colname = f"{entropy_col}:entropy"
adata.obs[colname] = adata.obs[group_col].map(entropies)

adata.obs[[colname]].to_pickle(f"{prefix}.pkl")
adata.write_h5ad(f"{prefix}.h5ad")

# Versions

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "anndata": ad.__version__,
        "pandas": pd.__version__,
        "scipy": scipy.__version__
    }
}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
