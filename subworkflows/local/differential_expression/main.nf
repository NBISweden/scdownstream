include { SCANPY_RANKGENESGROUPS } from '../../../modules/local/scanpy/rankgenesgroups'
include { anndata } from 'plugin/nf-anndata'

workflow DIFFERENTIAL_EXPRESSION {
    take:
    ch_h5ad // channel: [ meta, h5ad ], anndata objects with obs_key and condition_col in meta

    main:
    ch_versions      = channel.empty()
    ch_uns           = channel.empty()
    ch_multiqc_files = channel.empty()

    ch_settings = ch_h5ad.map { meta, h5ad ->
        def obs_key = meta.obs_key
        def condition_col = meta.condition_col
        def ad = anndata(h5ad)

        def conditions = ad.obs[condition_col].unique.toList()
        def labels = ad.obs[obs_key].unique.toList()

        return [meta, h5ad, condition_col, conditions, obs_key, labels]
    }

    ch_global_labels_reference = ch_settings.transpose(by: 5)
    ch_global_labels_contrast = ch_global_labels_reference.mix(
        ch_settings.map { meta, h5ad, condition_col, conditions, obs_key, _labels -> [meta, h5ad, condition_col, conditions, obs_key, 'rest'] }
    )

    ch_global_labels = ch_global_labels_reference
        .combine(ch_global_labels_contrast, by: [0, 1, 2, 3, 4])
        .filter { _meta, _h5ad, _condition_col, _conditions, _obs_key, label1, label2 -> label1 < label2 }
        .map { meta, h5ad, _condition_col, _conditions, obs_key, label1, label2 -> [meta, h5ad, [], [], obs_key, label1, label2] }

    ch_condition_labels_reference = ch_global_labels_reference.transpose(by: 3)
    ch_condition_labels_contrast = ch_global_labels_contrast.transpose(by: 3)

    ch_condition_labels = ch_condition_labels_reference
        .combine(ch_condition_labels_contrast, by: [0, 1, 2, 3, 4])
        .filter { _meta, _h5ad, _condition_col, _conditions, _obs_key, label1, label2 -> label1 < label2 }

    ch_global_conditions_reference = ch_settings.transpose(by: 3)
    ch_global_conditions_contrast = ch_global_conditions_reference.mix(
        ch_settings.map { meta, h5ad, condition_col, _conditions, obs_key, labels -> [meta, h5ad, condition_col, 'rest', obs_key, labels] }
    )

    ch_label_conditions_reference = ch_global_conditions_reference.transpose(by: 5)
    ch_label_conditions_contrast = ch_global_conditions_contrast.transpose(by: 5)

    ch_label_conditions = ch_label_conditions_reference
        .combine(ch_label_conditions_contrast, by: [0, 1, 2, 4, 5])
        .map { meta, h5ad, condition_col, obs_key, label, condition1, condition2 ->
            [meta, h5ad, obs_key, label, condition_col, condition1, condition2]
        }.filter { _meta, _h5ad, _obs_key, _label, _condition_col, condition1, condition2 -> condition1 < condition2 }

    ch_comparisons = ch_global_labels.mix(ch_condition_labels).mix(ch_label_conditions)
    ch_comparisons.view()

    SCANPY_RANKGENESGROUPS(ch_h5ad)
    ch_versions      = ch_versions.mix(SCANPY_RANKGENESGROUPS.out.versions)
    ch_uns           = ch_uns.mix(SCANPY_RANKGENESGROUPS.out.uns)
    ch_multiqc_files = ch_multiqc_files.mix(SCANPY_RANKGENESGROUPS.out.multiqc_files)

    emit:
    uns           = ch_uns           // channel: [ pkl ]
    multiqc_files = ch_multiqc_files // channel: [ json ]
    versions      = ch_versions      // channel: [ versions.yml ]
}
