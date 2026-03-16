process CELLTYPES_SINGLER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e6/e6357085b1229ae89d526d930b7e4b68e968c85a42a912435f87ed1725e21184/data'
        : 'community.wave.seqera.io/library/bioconductor-anndatar_bioconductor-hdf5array_bioconductor-singlecellexperiment_bioconductor-singler_r-ggplot2:bef482138e855d36'}"

    input:
    tuple val(meta), path(h5ad), val(symbol_col)
    tuple val(meta2), val(names), val(labels), path(references)

    output:
    //tuple val(meta), path("*.h5ad"), emit: h5ad
    tuple val(meta), path("*.csv")             , emit: obs
    tuple val(meta), path("*_distribution.pdf"), emit: distribution
    tuple val(meta), path("*_heatmap.pdf")     , emit: heatmap
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SINGLER module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    template 'singleR.R'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SINGLER module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    """
    touch ${prefix}_distribution.pdf
    touch ${prefix}_heatmap.pdf
    touch ${prefix}.csv
    touch versions.yml
    """
}
