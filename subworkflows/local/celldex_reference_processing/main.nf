include { CELLTYPES_CELLDEXDOWNLOAD } from '../../../modules/local/celltypes/celldexdownload'

workflow CELLDEX_REFERENCE_PROCESSING {
    take:
    reference_string

    main:
    def reftars = Channel.empty()
    def ref_list = reference_string.split(',').collect{it.trim()}
    def to_download = []

ref_list.each { r ->
    def tarfile = r ==~ /.*celldex_.*_h5_se\.tar\.gz/ ? file(r) : file("celldex_${r}_h5_se.tar.gz")
    if (!tarfile.exists()) {
        to_download << r // Appending to the list using the left-shift operator
    } else if (tarfile.isFile()) {
        reftars = reftars.mix(Channel.value(tarfile))
    } else {
        error "Expected zip file ${tarfile} does not exist or is not a file"
    }
}

    if (to_download.size() > 0) {
        Channel.fromList(to_download) | CELLTYPES_CELLDEXDOWNLOAD
        reftars = reftars.mix(CELLTYPES_CELLDEXDOWNLOAD.out.tar)
    }
    emit: referenceTars = reftars.collect()
}
