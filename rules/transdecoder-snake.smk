configfile: "config.yaml"

import io
import os
import pandas as pd
from snakemake.exceptions import print_exception, WorkflowError
import sys
sys.path.insert(1, '../scripts')
from importworkspace import *
  
rule transdecoder_indiv:
    input:
        merged = os.path.join(OUTPUTDIR, "assembled", "{assembly}_{assembler}.fasta")
    output:
        pep = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.bed")
    params:
        merged = "{assembly}_{assembler}.indiv",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_err.log"),
        out = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_out.log")
    conda: 
        "../envs/transdecoder-env.yaml"
    shell:
        """
        unset PERL5LIB
        TransDecoder.LongOrfs -t {input.merged} -O {params.merged} -m {params.size} 2> {log.err} 1> {log.out}
        TransDecoder.Predict -t {input.merged} -O {params.merged} --no_refine_starts 2>> {log.err} 1>> {log.out}
        bash rename_td.bash
        """

rule transdecoder_indiv_bed:
    input:
        merged = os.path.join(OUTPUTDIR, "assembled", "{assembly}_{assembler}.fasta"),
        assembly = "{assembly}_{assembler}.indiv.fasta.transdecoder.bed"
    output:
        cds = os.path.join(OUTPUTDIR, "transdecoder_indiv", "{assembly}_{assembler}.fasta.transdecoder.full.cds")
    log:
        err = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_bed_err.log"),
        out = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_bed_out.log")
    params:
        merged = "{assembly}",
        size = TRANSDECODERORFSIZE
    shell:
        """
        unset PERL5LIB
        bedtools getfasta -fi {input.merged} -bed {params.merged}.fasta.transdecoder.bed -fo {output.cds}
        """
        
rule transdecoder_indiv_clean:
    input:
        pep = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_{assembler}.indiv.fasta.transdecoder.bed")
    output:
        pep = os.path.join(OUTPUTDIR, "transdecoder_indiv", "{assembly}_{assembler}.fasta.transdecoder.pep"),
        gff = os.path.join(OUTPUTDIR, "transdecoder_indiv", "{assembly}_{assembler}.fasta.transdecoder.gff3"),
        cds = os.path.join(OUTPUTDIR, "transdecoder_indiv", "{assembly}_{assembler}.fasta.transdecoder.cds"),
        bed = os.path.join(OUTPUTDIR, "transdecoder_indiv", "{assembly}_{assembler}.fasta.transdecoder.bed")
    log:
        err = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_clean_err.log"),
        out = os.path.join("logs","transdecoder","indiv_{assembly}_{assembler}_clean_out.log")
    params:
        merged = "{assembly}_{assembler}",
        size = TRANSDECODERORFSIZE
    shell:
        """
        mv {input.pep} {output.pep}
        mv {input.cds} {output.cds}
        mv {input.gff} {output.gff}
        mv {input.bed} {output.bed}
        rm -rf {params.merged}.fasta.transdecoder_dir*
        rm -rf pipeliner.*.cmds
        """

rule transdecoder_by_assembly:
    input:
        merged = os.path.join(OUTPUTDIR, "merged", "{assembly}_merged.fasta")
    output:
        pep = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.bed")
    params:
        merged = "{assembly}_merged.byassembly",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","byassembly_{assembly}_err.log"),
        out = os.path.join("logs","transdecoder","byassembly_{assembly}_out.log")
    conda: 
        "../envs/transdecoder-env.yaml"
    shell:
        """
        unset PERL5LIB
        cp {input.merged} {params.merged}.fasta
        TransDecoder.LongOrfs -t {params.merged}.fasta -m {params.size} 2> {log.err} 1> {log.out}
        TransDecoder.Predict -t {params.merged}.fasta --no_refine_starts 2>> {log.err} 1>> {log.out}
        rm {params.merged}.fasta
        """
        
rule transdecoder_by_assembly_bed:
    input:
        merged = os.path.join(OUTPUTDIR, "assembled", "{assembly}_merged.fasta"),
        assembly = "{assembly}_merged.byassembly.fasta.transdecoder.bed"
    output:
        cds = os.path.join(OUTPUTDIR, "transdecoder_{folder}", "{assembly}.fasta.transdecoder.full.cds")
    params:
        merged = "{assembly}",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","byassembly_{folder}_{assembly}_bed_err.log"),
        out = os.path.join("logs","transdecoder","byassembly_{folder}_{assembly}_bed_out.log")
    shell:
        """
        unset PERL5LIB
        bedtools getfasta -fi {input.merged} -bed {params.merged}.fasta.transdecoder.bed -fo {output.cds}
        """
        
rule transdecoder_by_assembly_clean:
    input:
        pep = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_merged.byassembly.fasta.transdecoder.bed")
    output:
        pep = os.path.join(OUTPUTDIR, "transdecoder_{folder}", "{assembly}.fasta.transdecoder.pep"),
        gff = os.path.join(OUTPUTDIR, "transdecoder_{folder}", "{assembly}.fasta.transdecoder.gff3"),
        cds = os.path.join(OUTPUTDIR, "transdecoder_{folder}", "{assembly}.fasta.transdecoder.cds"),
        bed = os.path.join(OUTPUTDIR, "transdecoder_{folder}", "{assembly}.fasta.transdecoder.bed")
    params:
        merged = "{assembly}",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","byassembly_{folder}_{assembly}_clean_err.log"),
        out = os.path.join("logs","transdecoder","byassembly_{folder}_{assembly}_clean_out.log")
    shell:
        """
        mv {input.pep} {output.pep}
        mv {input.cds} {output.cds}
        mv {input.gff} {output.gff}
        mv {input.bed} {output.bed}
        rm -rf {params.merged}.fasta.transdecoder_dir*
        rm -rf pipeliner.*.cmds
        """

rule transdecoder_final_proteins:
    input:
        clustered = os.path.join(OUTPUTDIR, "cluster_{folder}", "{assembly}_merged.fasta")
    output:
        pep = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.bed")
    params:
        merged = "{assembly}_merged_{folder}.finalproteins",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","finalproteins_{assembly}_{folder}_err.log"),
        out = os.path.join("logs","transdecoder","finalproteins_{assembly}_{folder}_out.log")
    conda: 
        "../envs/transdecoder-env.yaml"
    shell:
        """
	    unset PERL5LIB
        cp {input.clustered} {params.merged}.fasta
        TransDecoder.LongOrfs -t {params.merged}.fasta -m {params.size} 2> {log.err} 1> {log.out}
        TransDecoder.Predict -t {params.merged}.fasta --no_refine_starts 2>> {log.err} 1>> {log.out}
        rm {params.merged}.fasta
        """

rule transdecoder_finalproteins_bed:
    input:
        merged = os.path.join(OUTPUTDIR, "assembled", "{assembly}_merged.fasta"),
        assembly = "{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.bed"
    output:
        cds = os.path.join(OUTPUTDIR, "transdecoder_{folder}_finalproteins", "{assembly}.fasta.transdecoder.full.cds")
    params:
        merged = "{assembly}_merged_{folder}.finalproteins",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","finalproteins_{folder}_{assembly}_bed_err.log"),
        out = os.path.join("logs","transdecoder","finalproteins_{folder}_{assembly}_bed_out.log")
    shell:
        """
        unset PERL5LIB
        bedtools getfasta -fi {input.merged} -bed {params.merged}.fasta.transdecoder.bed -fo {output.cds}
        """
        
rule transdecoder_finalproteins_clean:
    input:
        pep = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.pep"),
        gff = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.gff3"),
        cds = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.cds"),
        bed = os.path.join("{assembly}_merged_{folder}.finalproteins.fasta.transdecoder.bed")
    output:
        pep = os.path.join(OUTPUTDIR, "transdecoder_{folder}_finalproteins", "{assembly}.fasta.transdecoder.pep"),
        gff = os.path.join(OUTPUTDIR, "transdecoder_{folder}_finalproteins", "{assembly}.fasta.transdecoder.gff3"),
        cds = os.path.join(OUTPUTDIR, "transdecoder_{folder}_finalproteins", "{assembly}.fasta.transdecoder.cds"),
        bed = os.path.join(OUTPUTDIR, "transdecoder_{folder}_finalproteins", "{assembly}.fasta.transdecoder.bed")
    params:
        merged = "{assembly}_merged_{folder}.finalproteins",
        size = TRANSDECODERORFSIZE
    log:
        err = os.path.join("logs","transdecoder","finalproteins_{folder}_{assembly}_clean_err.log"),
        out = os.path.join("logs","transdecoder","finalproteins_{folder}_{assembly}_clean_out.log")
    shell:
        """
        mv {input.pep} {output.pep}
        mv {input.cds} {output.cds}
        mv {input.gff} {output.gff}
        mv {input.bed} {output.bed}
        rm -rf {params.merged}.fasta.transdecoder_dir*
        rm -rf pipeliner.*.cmds
        """
