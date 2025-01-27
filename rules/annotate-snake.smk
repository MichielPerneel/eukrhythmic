configfile: "config.yaml"

import io
import os
import pathlib
import pandas as pd
from snakemake.exceptions import print_exception, WorkflowError
import sys
sys.path.insert(1, '../scripts')
from importworkspace import *

KEGG_PROT_DB = config["kegg_prot_db"]
KEGG_PATH = config["kegg"]
BUSCO_DATABASES = list(config["busco"])
PFAM = config["pfam"]

rule diamond_database:
    input:
        tobuild = KEGG_PROT_DB
    output:
        dmnd = os.path.join(OUTPUTDIR, "diamond", "diamond_ref.dmnd")
    params:
        db = os.path.join(OUTPUTDIR, "diamond", "diamond_ref")
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        # diamond makedb --in {input} --db {params.db}
        cp {input.tobuild} {output.dmnd}
        '''

rule align_assemblies:
  ## runs alignment against reference DB and generates .aln files for each contig in each samples
    input:
        dmnd = os.path.join(OUTPUTDIR, "diamond", "diamond_ref.dmnd"),
        fasta = os.path.join(OUTPUTDIR, "cluster_{folder}", "{assembly}_merged.fasta") 
    output:
        os.path.join(OUTPUTDIR, "diamond", "{folder}", "{assembly}.diamond.out")
    params:
        other = "--outfmt 6 -k 100 -e 1e-5",
        outfmt = 6,
        k = 100,
        e = 1e-5
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        diamond blastx --db {input.dmnd} -q {input.fasta} -o {output} --outfmt {params.outfmt} -k {params.k} -e {params.e}
        '''
        
rule kegg_annotation:
    input:
        dmnd = os.path.join(OUTPUTDIR, "diamond", "{folder}", "{assembly}.diamond.out")
    output:
        fileout = os.path.join(OUTPUTDIR, "kegg", "{folder}", "{assembly}_kegg.csv")
    params:
        kegg_dir = KEGG_PATH
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        python scripts/kegg_annotator.py {params.kegg_dir} -d {input.dmnd} -o {output.fileout}
        '''
        
rule download_busco:
    output:
        directory(os.path.join(OUTPUTDIR, "busco", "{database}_odb10"))
    params:
        busco_loc = os.path.join(OUTPUTDIR, "busco"),
        zipped = os.path.join(OUTPUTDIR, "busco", "{database}.tar.gz"),
        busco_avail = " ".join(BUSCO_DATABASES),
        db = "{database}"
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        for b in {params.busco_avail}
        do
            if grep -q {params.db} <<< "$b"; then
              wget -O {params.zipped} "$b" 
              mkdir -p {output}
              tar -xzf {params.zipped} -C {params.busco_loc}
            fi
        done
        '''
        
rule run_busco:
    input:
        #busco_db = os.path.join(OUTPUTDIR, "busco", "{database}_odb10"),
        fasta_file = os.path.join(OUTPUTDIR, "cluster_{folder}", "{assembly}_merged.fasta")
    output:
        busco_res = directory(os.path.join(OUTPUTDIR, "busco", "{database}", "{folder}", "{assembly}"))
    params:
        db = "{database}",
        assembly = "{assembly}",
        busco_db_name = "{database}_odb10", 
        CPUs = MAXCPUSPERTASK,
        out_path = os.path.join(OUTPUTDIR, "busco", "{database}", "{folder}"),
        ini_path = os.path.join(OUTPUTDIR, "busco", "{database}", "{folder}", "{assembly}", "config.ini"),
        static_ini_path = os.path.join("static","busco_config.ini")
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        mkdir -p {output.busco_res}
        BUSCO_DIR="$(dirname $(which busco))"
        BUSCO_CONFIG_FILE="$BUSCO_DIR"/../config/config.ini
        busco_configurator.py $BUSCO_CONFIG_FILE {params.static_ini_path}
        cp {params.static_ini_path} {params.ini_path}
        sed -i '/out = /c\out = {params.assembly}' {params.ini_path} # the name of the output files
        sed -i '/out_path = /c\out_path = {params.out_path}' {params.ini_path} # what directory the output will be stored in
        busco -i {input.fasta_file} -l {params.busco_db_name} -m transcriptome --cpu {params.CPUs} --config {params.ini_path} -f
        '''
  
rule download_pfam:
    output:
        pfam_file = os.path.join(OUTPUTDIR, "pfam", "pfam_hmmer.hmm")
    params:
        pfam_file = os.path.join(OUTPUTDIR, "pfam", "pfam_hmmer.hmm.gz"),
        pfam_loc = PFAM
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        wget -O {params.pfam_file} {params.pfam_loc}
        gunzip -c {params.pfam_file} > {output.pfam_file}
        '''
        
rule run_hmmer:
    input:
        pfam_file = os.path.join(OUTPUTDIR, "pfam", "pfam_hmmer.hmm"),
        fasta_file = os.path.join(OUTPUTDIR, "cluster_{folder}", "{assembly}_merged.fasta")
    output:
        hmmer_res = os.path.join(OUTPUTDIR, "pfam", "{folder}", "{assembly}.tblout")
    params:
        db = PFAM,
        CPUs = MAXCPUSPERTASK
    conda:
        "../envs/annotate-env.yaml"
    shell:
        '''
        hmmsearch --tblout -cpu {params.CPUs} {output.hmmer_res} {input.pfam_file} {input.fasta_file}
        '''
