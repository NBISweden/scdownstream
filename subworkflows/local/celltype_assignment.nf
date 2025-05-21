include { CELLTYPES_CELLTYPIST } from '../../modules/local/celltypes/celltypist'
include { CELLTYPES_SINGLER } from '../../modules/local/celltypes/singler'
include { CELLTYPES_CELLDEXDOWNLOAD } from '../../modules/local/celltypes/celldexdownload'

workflow CELLTYPE_ASSIGNMENT {
    take:
    ch_h5ad

    main:
    ch_versions = Channel.empty()
    ch_obs = Channel.empty()
    // Check if reference is an Rds file or a Celldex reference, if celldex reference, download it
    if (params.celldex_reference.contains('.Rds')) {
        log.info("Contains RDS")
        // Create a reference channel for the Rds file and check if it exists
        celldex_references = Channel
            .from(params.celldex_reference)
            .filter { file -> file.exists()}
    } else if (params.celldex_reference) {
        log.info("Downloading Celldex reference")
        CELLTYPES_CELLDEXDOWNLOAD(params.celldex_reference)
        celldex_references = CELLTYPES_CELLDEXDOWNLOAD.out.rds.collect()

    }

    
    
    if (celldex_references == null && params.celldex_reference) {
        log.info("Celldex reference download failed, disabling singleR")
    }



    
    if (params.celldex_reference) {
        log.info("Celldex variable set")
    }
    if (!workflow.profile.contains('conda')) {
        log.info("Conda profile is not used")
    }

    if (!celldex_references == null) {
        log.info("Celldex reference download failed, disabling singleR")
    }

    celldex_references.view()


    if (params.celldex_reference && !celldex_references == null) {
        celldex_references = celldex_references.split(',')
        celldex_references = Channel.value(celldex_references.collect{it.trim()})
    }
    if (params.celldex_reference && !workflow.profile.contains('conda') && !celldex_references == null) {
        celldex_references = celldex_references.split(',')

        CELLTYPES_SINGLER(ch_h5ad, celldex_references)
        ch_versions = ch_versions.mix(CELLTYPES_SINGLER.out.versions)
        ch_obs = ch_obs.mix(CELLTYPES_SINGLER.out.obs)
    } else {
        // Log that singleR will not run
        log.info("Skipping singleR as Conda profile is used and singleR module doesn't support it")
    }

    if (params.celltypist_model) {
        celltypist_models = Channel.value(params.celltypist_model.split(',').collect{it.trim()})

        CELLTYPES_CELLTYPIST(ch_h5ad, celltypist_models)
        ch_obs = ch_obs.mix(CELLTYPES_CELLTYPIST.out.obs)
        ch_h5ad = CELLTYPES_CELLTYPIST.out.h5ad
        ch_versions = ch_versions.mix(CELLTYPES_CELLTYPIST.out.versions)
    }

    emit:
    obs = ch_obs
    h5ad = ch_h5ad

    versions = ch_versions
}
