process SCANPY_PCA {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pip_scanpy-cli:a15ba86fec3c8ea8':
        'wave.seqera.io/wt/5c36b639fa1d/wave/build:pip_scanpy-cli-0.2.0--ad9d0103a18eb835' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    path "*.pkl"                   , emit: obsm
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    args = task.ext.args ?: ""

    if ("${prefix}.h5ad" == "${h5ad}")
        error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    scanpy-cli pp pca -i ${h5ad} -o ${prefix}.h5ad --embedding-output ${prefix}.pkl ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scanpy-cli: \$(scanpy-cli --version | grep -oP '(?<=version )[\d.]+')
    END_VERSIONS
    """

    stub:
    """"
    touch ${prefix}.h5ad
    touch ${prefix}.pkl
    touch versions.yml
    """
}
