process SCANPY_LEIDEN {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
            ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/76/7618fd3150ad10ff6df187fd9c18dbe8af2cad6e403a0b4882ce62e2dd9272fd/data'
            : 'community.wave.seqera.io/library/bbknn_harmonypy_anndata_leidenalg_pruned:91b5a755255359d2'}"

    input:
    tuple val(meta), path(h5ad, arity: 1)
    val(resolution)
    val(key_added)
    val(plot_umap)

    output:
    tuple val(meta), path("${prefix}.h5ad"), emit: h5ad
    path "${prefix}.pkl", emit: obs
    path "${prefix}.png", emit: plots, optional: true
    path "${prefix}_mqc.json", emit: multiqc_files, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}_leiden"
    template('leiden.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}_leiden"
    """
    touch "${prefix}.h5ad"
    touch "${prefix}.pkl"
    touch "versions.yml"

    if [ "${plot_umap}" = "true" ]; then
        touch "${prefix}.png"
        touch "${prefix}_mqc.json"
    fi
    """
}
