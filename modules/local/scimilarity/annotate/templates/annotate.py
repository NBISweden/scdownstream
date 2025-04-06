#!/usr/bin/env python3

import os
import shutil

os.environ["NUMBA_CACHE_DIR"] = "./tmp/numba"

import platform
import pandas as pd
import scanpy as sc
from scimilarity.utils import lognorm_counts, align_dataset
from scimilarity import CellAnnotation
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
ca = CellAnnotation("${model}", use_gpu=use_gpu)

predictions, nn_idxs, nn_dists, nn_stats = ca.get_predictions_knn(
    adata.obsm["X_emb"]
)

adata_raw.obs["annotation:scimilarity"] = predictions.values

# Write the output
adata_raw.write_h5ad("${prefix}.h5ad")
adata_raw.obs[["annotation:scimilarity"]].to_pickle("${prefix}.pkl")

versions = {
    "${task.process}": {
        "python": platform.python_version(),
        "scimilarity": scimilarity.__version__,
        "scanpy": sc.__version__,
    }
}

with open("versions.yml", "w") as f:
    f.write(format_yaml_like(versions))
