process SCANPY_CELLCYCLE {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/76/7618fd3150ad10ff6df187fd9c18dbe8af2cad6e403a0b4882ce62e2dd9272fd/data'
        : 'community.wave.seqera.io/library/bbknn_harmonypy_anndata_leidenalg_pruned:91b5a755255359d2'}"

    input:
    tuple val(meta), path(h5ad)
    path s_genes
    path g2m_genes
    val symbol_col

    output:
    tuple val(meta), path("${prefix}.pkl"),  emit: obs
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    if ("${prefix}.h5ad" == "${h5ad}") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }
    template('cellcycle.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pkl
    touch ${prefix}.h5ad
    touch versions.yml
    """
}
