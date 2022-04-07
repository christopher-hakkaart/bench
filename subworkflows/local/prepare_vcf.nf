//
// Prepare tuth set
//

params.options = [:]
params.genome_options = [:]

include { REMOVE_CHR  } from '../../modules/local/remove_chr'                       addParams( options: params.options )
include { TABIX_BGZIP } from '../../modules/nf-core/modules/tabix/bgzip/main'       addParams( options: params.genome_options )
include { TABIX_TABIX } from '../../modules/nf-core/modules/tabix/tabix/main'       addParams( options: params.genome_options )


workflow PREPARE_VCF {
    take:
    vcf_ch //

    main:
    /*
     * Rename using meta
     */
    vcf_ch.map{ meta, vcf ->
        new_meta = meta.clone()
        new_meta.id = file(vcf).simpleName == meta.truth_set ? meta.truth_set : meta.id
        [new_meta, vcf]
        }
    .set{vcf_renamed}

    /*
     * Remove chr prefix from chromosomes
     */
    REMOVE_CHR (
        vcf_renamed
    )
    vcf_nochr = REMOVE_CHR.out.vcf
    bcftools_version = REMOVE_CHR.out.versions

    /*
     * BGZIP vcf file
     */
    TABIX_BGZIP (
        vcf_nochr
    )
    vcf_gz = TABIX_BGZIP.out.gz
    bgzip_version = TABIX_BGZIP.out.versions

    /*
     * TABIX vcf file
     */
    TABIX_TABIX (
        vcf_gz
    )
    vcf_tbi = TABIX_TABIX.out.tbi
    tabix_version = TABIX_TABIX.out.versions

    /*
     * Revert rename using meta
     */
    vcf_gz
        .join(vcf_tbi, by: [0] )
        .set { vcf_gz_tbi }
    

    vcf_gz_tbi.map{ meta, gz, tbi ->
        new_meta = meta.clone()
        new_meta.id = meta.workflow
        [new_meta, gz, tbi]
        }
    .set{ch_vcf}

    emit:
    ch_vcf
    bgzip_version
    bcftools_version
    tabix_version
}
