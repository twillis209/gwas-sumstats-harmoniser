process harmonization {

    conda (params.enable_conda ? "$projectDir/environments/conda_environment.yml" : null)
    def dockerimg = "ebispot/gwas-sumstats-harmoniser:latest"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ? 'docker://ebispot/gwas-sumstats-harmoniser:latest' : dockerimg }"
    tag "$GCST"

    input:
    tuple val(GCST), val(palin_mode), val(status), val(chrom), path(merged), path(ref), path(yaml)


    output:
    tuple val(GCST), val(palin_mode), path("${chrom}.merged.hm"),path("${chrom}.merged.log.tsv.gz"), emit: hm_by_chrom

    when:
    status=="contiune"

    shell:
    """
    coordinate=\$(grep coordinateSystem $yaml | awk -F ":" '{print \$2}' | tr -d "[:blank:]" )
    header_args=\$(python /Users/yueji/Documents/GitHub/gwas-sumstats-harmoniser/bin/utils.py -f $merged -harm_args);
    python /Users/yueji/Documents/GitHub/gwas-sumstats-harmoniser/bin/main_pysam.py \
    --sumstats $merged \
    --vcf ${params.ref}/homo_sapiens-${chrom}.vcf.gz \
    --hm_sumstats ${chrom}.merged_unsorted.hm \
    --hm_statfile ${chrom}.merged.log.tsv.gz \
    \$header_args \
    --na_rep_in NA \
    --na_rep_out NA \
    --coordinate \$coordinate \
    --palin_mode $palin_mode;

    chr=\$(awk -v RS='\t' '/chromosome/{print NR; exit}' ${chrom}.merged_unsorted.hm)
    pos=\$(awk -v RS='\t' '/base_pair_location/{print NR; exit}' ${chrom}.merged_unsorted.hm)

    head -n1 ${chrom}.merged_unsorted.hm > ${chrom}.merged.hm;
    tail -n+2 ${chrom}.merged_unsorted.hm | sort -n -k\$chr -k\$pos >> ${chrom}.merged.hm
    """
}
