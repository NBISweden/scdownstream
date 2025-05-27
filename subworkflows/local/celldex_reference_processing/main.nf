include { CELLTYPES_CELLDEXDOWNLOAD } from '../../../modules/local/celltypes/celldexdownload'

workflow CELLDEX_REFERENCE_PROCESSING {
    take:
    reference_string

    main:
    def refdirs = Channel.empty()
    def ref_list = reference_string.split(',').collect{it.trim()}
    def to_download = []

    ref_list.each { r ->
        def referencedir = r ==~ /celldex_.*_h5_se/ ? file(r) : file("celldex_${r}_h5_se")

        if (!referencedir.exists()) {
            to_download << r // Appending to the list using the left-shift operator
        } else if (referencedir.isDirectory()) {
            def assaysFile = file("${r}/assays.h5")
            def seFile = file("${r}/se.rds")
            if (seFile.exists() && assaysFile.exists()) {
                refdirs = refdirs.mix(Channel.value(referencedir))
            } else {
                error "Directory ${referencedir} exists but doesn't contain the expected 'assays.h5' and 'se.rds' files"
            }
        }
    }

    if (to_download.size() > 0) {
        Channel.fromList(to_download) | CELLTYPES_CELLDEXDOWNLOAD
        refdirs = refdirs.mix(CELLTYPES_CELLDEXDOWNLOAD.out.refdir)
    }
    emit: referenceDirs = refdirs.collect()
}
