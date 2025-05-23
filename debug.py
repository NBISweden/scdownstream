# singularity exec /cfs/klemming/home/p/paulpyl/singularity_cache/community.wave.seqera.io-library-anndata-0.11.1--426fb199a9be8838.img python

import platform
import os
import pickle

import anndata as ad
import pandas as pd
import numpy as np

adata = ad.read_h5ad("SAMN14430801.h5ad")

def simple_name(path):
    basename = os.path.basename(path)
    return basename[:basename.rfind(".")]

def load_pickle_or_csv(path):
    if path.endswith(".pkl"):
        return pd.read_pickle(path)
    elif path.endswith(".csv"):
        return pd.read_csv(path, index_col = 0)
    else:
        raise ValueError(f"Unsupported file extension: {path}")

df_celltypist = load_pickle_or_csv("SAMN14430801_celltypist.pkl").reindex(adata.obs_names)
df_singler = load_pickle_or_csv("SAMN14430801_celldex_hpca__2024-02-26_h5_se_predictions.csv").reindex(adata.obs_names)
df_singler_test = load_pickle_or_csv("test.csv").reindex(adata.obs_names)
