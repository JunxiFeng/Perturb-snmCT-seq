# SNMCT-seq Pipeline (Junxi Version)

This repository contains a fully modular, Slurm-compatible SNMCT-seq processing pipeline customized for the Jin Lab / Luo Lab environment at UCSD–Scripps.  
All steps are configured using a single `your_path_setups.config` file and run through a master launcher `run_pipeline.sh`.

---

# 📁 Directory Structure

Your pipeline directory should look like:

```
LuoLab_Pipeline_Custom_junxi/
│
├── run_pipeline.sh
├── your_path_setups.config
├── your_Scripts/
│   ├── step1_prepare_genome_for_bismark.sub
│   ├── step1_prepare_genome_for_star.sub
│   ├── step2_demultiplex.sub
│   ├── step3_trimming.sub
│   ├── step4_dna_alignment.sub
│   ├── step4_rna_alignment.sub
│   ├── step5_combine_summary.sub
│   ├── step6_gRNA_assignment.sub
│   └── step7_pseudobulk_merge.sub
│
└── metadata/
       ├── plate_S01.xlsx
       └── plate_S02.xlsx
```

---

# ⚙️ Configuration File (`your_path_setups.config`)

This file defines all input/output directories, references, modules, and metadata:

Example:

```
# project folders
DIR_PROJ=/mnt/jin/group/junxi/snmctseq_cassie/snmct_seq_mbd2output

# raw FASTQs
FASTQ_ROOT=/mnt/jin/group/cassie/Cassie/251205_Novaseq/CP_fastq_files

# reference files
REF_DIR=/mnt/jin/group/reference/mouse_gencode_vM38
REF_FASTA=${REF_DIR}/GRCm39.primary_assembly.genome.fa
REF_GTF=${REF_DIR}/gencode.vM38.primary_assembly.annotation.gtf

RUN_GENOME_PREP=false

# STAR index
STAR_INDEX=${REF_DIR}/STAR149

# pipeline scripts
PIPELINE_DIR=/gpfs/home/junxif/xin_lab/LuoLab_Pipeline_Custom_junxi

# metadata folder
METADATA_DIR=${PIPELINE_DIR}/metadata
RATIO_CUTOFF=2.0
```

---

# 🧬 Metadata Format (gRNA Assignment)

Each plate must have **one Excel file** in `metadata/` with the name:

```
plate_S01.xlsx
plate_S02.xlsx
```

Format:

| WELL | Dnmt1_g1 | Dnmt1_g2 | Mbd2_g1 | Safe_g1 | Safe_g2 |
|------|----------|----------|---------|---------|---------|
| A1   | 0        | 513      | 6       | 0       | 0       |
| A10  | 0        | 7        | 4       | 0       | 0       |

The pipeline will automatically:

- detect plate names  
- load all metadata files  
- merge them  
- label wells as **D1**, **ST**, or **Ambiguous**

---

# 🚀 Running the Pipeline

Use:

```
sbatch run_pipeline.sh
```

The pipeline:

1. Optionally prepares genome indices (if `RUN_GENOME_PREP=true`)
2. Demultiplexes FASTQs  
3. Trims reads  
4. Aligns DNA (Bismark)  
5. Aligns RNA (STAR)  
6. Generates combined QC summary  
7. Assigns gRNAs  
8. Produces pseudobulk BAMs per condition (D1 vs ST)

You will see outputs in:

```
${DIR_PROJ}/demultiplexed_fastq
${DIR_PROJ}/trimmed_fastq
${DIR_PROJ}/bismark_alignment
${DIR_PROJ}/star_alignment
${DIR_PROJ}/combined_summary
${DIR_PROJ}/gRNA_assignments
${DIR_PROJ}/pseudobulk_bams
```

---

# 📊 Logging

All logs are written to:

```
your_job_logs/
```

- One log per Slurm step  
- One master log from the `run_pipeline.sh` job  

---

# ❗ Important Notes

### 1. **Do NOT hardcode paths inside scripts.**  
Everything must come from the config file.

### 2. **Do NOT use `#SBATCH --chdir=`**  
All scripts rely on absolute paths and explicitly `cd` into the correct working directory.

### 3. The pipeline supports:
- Single plate  
- Two plates  
- Any number of plates matching `plate_S*.xlsx`

### 4. Dependencies ensure:
- If any step fails → all downstream steps **auto-cancel**

---

# ✅ Summary

This pipeline is:

- Fully modular  
- Automatically plate-aware  
- Supports dynamic metadata  
- Safe on Slurm clusters  
- End-to-end for SNMCT-seq (DNA + RNA)  

If you'd like, I can generate a **versioned release**, **PDF manual**, or **flowchart diagram**.

---

# 🧪 Contact

Pipeline author: **Junxi Feng**  
For issues: Ask ChatGPT 😉
