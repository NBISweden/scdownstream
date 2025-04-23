process ADATA_ENTROPY {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/anndata_pyyaml_scipy:71dced6759c2f3b8':
        'community.wave.seqera.io/library/anndata_pyyaml_scipy:ff09149e11f2b4ee' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    tuple val(meta), path("*.pkl") , emit: pkl
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    group_col = task.ext.group_col ?: "leiden"
    entropy_col = task.ext.entropy_col ?: "batch"
    template 'entropy.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.h5ad
    touch ${prefix}.pkl
    touch versions.yml
    """
}
