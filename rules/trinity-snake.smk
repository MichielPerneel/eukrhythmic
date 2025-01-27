configfile: "config.yaml"

import io
import os
import pandas as pd
from snakemake.exceptions import print_exception, WorkflowError
import sys
sys.path.insert(1, '../scripts')
from importworkspace import *
    
def get_samples_commas(assemblygroup, dropspike, leftorright, commas = False):
    samplelist = list(SAMPLEINFO.loc[SAMPLEINFO['AssemblyGroup'] == assemblygroup]['SampleID']) 
    foldername = "bbmap"
    extensionname = "clean"
    if dropspike == 0:
        foldername = "firsttrim"
        extensionname = "trimmed"
    if leftorright == "left":
        samplelist = [os.path.join(OUTPUTDIR, foldername, sample + "_1." + extensionname + ".fastq.gz") 
                      for sample in samplelist]
    else:
        samplelist = [os.path.join(OUTPUTDIR, foldername, sample + "_2." + extensionname + ".fastq.gz") 
                      for sample in samplelist]
    if commas:
        return ",".join(samplelist)
    else:
        return samplelist
   
print("CPUs in")
print(MAXCPUSPERTASK * MAXTASKS)
    
# This module needs to grab all of the list of the individual files associated with the specified
# assembly group, after the scripts/make-assembly-file.py script builds said assembly groups 
# according to user specifications.  
rule trinity:
    input:
        left = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "left", commas = False),
        right = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "right", commas = False)
    output:
        os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}", "Trinity.fasta")
    params:
        extra = "",
        outdir = os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}"),
        left = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "left", commas = True),
        right = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "right", commas = True),
        maxmem = MAXMEMORY,
        CPUs = MAXCPUSPERTASK * MAXTASKS #MAXTHREADS * MAXCORES
    log:
        err = os.path.join("logs","trinity","outputlog_{assembly}_err.log"),
        out = os.path.join("logs","trinity","outputlog_{assembly}_out.log")
    conda: '../envs/trinity-env.yaml'
    shell:
        '''
        echo {params.left}
        Trinity --seqType fq --max_memory {params.maxmem}G --CPU {params.CPUs} --max_memory 150G --left {params.left} --right {params.right} --output {params.outdir} --NO_SEQTK 2> {log.err} 1> {log.out}
        '''
        
rule trinity_SE:
    input:
        single = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "left", commas = False)
    output:
        os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}", "Trinity.fasta")
    params:
        extra = "",
        outdir = os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}"),
        single = lambda filename: get_samples_commas(filename.assembly, DROPSPIKE, "left", commas = True),
        maxmem = MAXMEMORY,
        CPUs = MAXCPUSPERTASK * MAXTASKS #MAXTHREADS * MAXCORES
    log:
        err = os.path.join("logs","trinity","outputlog_{assembly}_err.log"),
        out = os.path.join("logs","trinity","outputlog_{assembly}_out.log")
    conda: '../envs/trinity-env.yaml'
    shell:
        '''
        Trinity --seqType fq --max_memory {params.maxmem}G --CPU {params.CPUs} --max_memory 150G --bflyCalculateCPU --single {params.single} --output {params.outdir} --NO_SEQTK 2> {log.err} 1> {log.out}
        '''
   
rule trinity_cleanup:
    input:
        trinityfile = os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}", "Trinity.fasta")
    output:
        assembled = os.path.join(ASSEMBLEDDIR, "{assembly}_trinity.fasta"),
        jellyfish = os.path.join(OUTPUTDIR, "jellyfish", "{assembly}_jellyfish_25.fasta"),
        scratchout = directory(os.path.join(SCRATCHDIR, "trinity_results_assembly_{assembly}")) 
    params:
        extra = "",
        outdir = os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}"),
        scratch = os.path.join(SCRATCHDIR),
        jellyfile = os.path.join(OUTPUTDIR, "trinity_results_assembly_{assembly}", "jellyfish.kmers.25.asm.fa")
    shell:
        '''
        mkdir -p {params.scratch}
        cp {input.trinityfile} {output.assembled}
        mv {params.jellyfile} {output.jellyfish}
        if [ {params.outdir} != {params.scratch} ]
        then
            mv {params.outdir} {params.scratch}
        fi
        '''

