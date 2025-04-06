#!/usr/bin/env python3

import os
import shutil

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"

import platform
import pandas as pd
import scanpy as sc
from scimilarity.utils import lognorm_counts, align_dataset
from scimilarity import CellQuery
import scimilarity

def format_yaml_like(data: dict, indent: int = 0) -> str:
    """Formats a dictionary to a YAML-like string.

    Args:
        data (dict): The dictionary to format.
        indent (int): The current indentation level.

    Returns:
        str: A string formatted as YAML.
    """
    yaml_str = ""
    for key, value in data.items():
        spaces = "  " * indent
        if isinstance(value, dict):
            yaml_str += f"{spaces}{key}:\\n{format_yaml_like(value, indent + 1)}"
        else:
            yaml_str += f"{spaces}{key}: {value}\\n"
    return yaml_str

adata = sc.read_h5ad("${h5ad}")
adata_raw = adata.copy()

use_gpu = "${task.ext.use_gpu}" == "true"
cq = CellQuery("${model}", use_gpu=use_gpu)

adata.layers["counts"] = adata.X
adata = align_dataset(adata, cq.gene_order)
adata = lognorm_counts(adata)

embeddings = cq.get_embeddings(adata.X)

# Store the embeddings
adata_raw.obsm["X_emb"] = embeddings

# Write the output
adata_raw.write_h5ad("${prefix}.h5ad")
df = pd.DataFrame(embeddings, index=adata_raw.obs_names)
df.to_pickle("X_${prefix}.pkl")

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scimilarity": scimilarity.__version__,
        "scanpy": sc.__version__,
    }
}

with open("versions.yml", "w") as f:
    f.write(format_yaml_like(versions))
