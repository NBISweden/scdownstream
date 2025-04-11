include { HUGOUNIFIER_GET } from '../../modules/local/hugounifier/get'


workflow UNIFY_GENES {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()

    HUGOUNIFIER_GET(
        ch_h5ad.map { meta, h5ad -> [[id: 'hugo-unifier'], meta.id, h5ad] }.groupTuple()
    )

    emit:
    h5ad     = ch_h5ad
    versions = ch_versions
}
