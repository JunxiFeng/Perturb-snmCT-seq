#!/bin/bash
#SBATCH --job-name=run_pipeline
#SBATCH --output=/gpfs/home/junxif/xin_lab/LuoLab_Pipeline_Custom_junxi/your_job_logs/run_pipeline.out
#SBATCH --error=/gpfs/home/junxif/xin_lab/LuoLab_Pipeline_Custom_junxi/your_job_logs/run_pipeline.err
#SBATCH --time=00:72:00
#SBATCH --mem=2G
#SBATCH --partition=highmem

CONFIG="/gpfs/home/junxif/xin_lab/LuoLab_Pipeline_Custom_junxi/your_path_setups.config"

if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Missing config file: $CONFIG"
    exit 1
fi
source "$CONFIG"

echo "============================================================"
echo "   SNMCT-seq PIPELINE RUNNER"
echo "   Project directory: $DIR_PROJ"
echo "   Script directory:  $PIPELINE_DIR"
echo "   Config file:       $CONFIG"
echo "   Genome prep:       $RUN_GENOME_PREP"
echo "============================================================"
echo

############################################################
# Convenience: job wrapper
############################################################
submit_job () {
    local dependency=$1
    local script=$2

    if [[ -z "$dependency" ]]; then
        sbatch --kill-on-invalid-dep=yes \
               --export=CONFIG="${CONFIG}" \
               "${PIPELINE_DIR}/your_Scripts/${script}" | awk '{print $4}'
    else
        sbatch --kill-on-invalid-dep=yes \
               --dependency=afterok:${dependency} \
               --export=CONFIG="${CONFIG}" \
               "${PIPELINE_DIR}/your_Scripts/${script}" | awk '{print $4}'
    fi
}

############################################################
# Step 1 — Genome Preparation (optional)
############################################################
if [[ "$RUN_GENOME_PREP" == "true" ]]; then
    echo "[STEP 1a] Preparing Bismark genome index..."
    jid1=$(submit_job "" "step1_prepare_genome_for_bismark.sub")
    echo " Submitted → Job $jid1"

    echo "[STEP 1b] Preparing STAR genome index (depends on 1a)"
    jid2=$(submit_job "$jid1" "step1_prepare_genome_for_star.sub")
    echo " Submitted → Job $jid2"

    PREV_JID=$jid2
else
    echo "[INFO] RUN_GENOME_PREP=false → Skipping Step 1"
    PREV_JID=""
fi

############################################################
# Step 2 — Demultiplex
############################################################
echo "[STEP 2] Demultiplex FASTQs"
jid3=$(submit_job "$PREV_JID" "step2_demultiplex.sub")
echo " Submitted → Job $jid3"
PREV_JID=$jid3

############################################################
# Step 3 — Trimming
############################################################
echo "[STEP 3] Trimming"
jid4=$(submit_job "$PREV_JID" "step3_trimming.sub")
echo " Submitted → Job $jid4"
PREV_JID=$jid4

############################################################
# Step 4a — DNA alignment
############################################################
echo "[STEP 4a] DNA alignment"
jid5=$(submit_job "$PREV_JID" "step4_dna_alignment.sub")
echo " Submitted → Job $jid5"
PREV_JID=$jid5

############################################################
# Step 4b — RNA alignment
############################################################
echo "[STEP 4b] RNA alignment"
jid6=$(submit_job "$PREV_JID" "step4_rna_alignment.sub")
echo " Submitted → Job $jid6"
PREV_JID=$jid6

############################################################
# Step 5 — Combined summary
############################################################
echo "[STEP 5] Combined Summary"
jid7=$(submit_job "$PREV_JID" "step5_combine_summary.sub")
echo " Submitted → Job $jid7"
PREV_JID=$jid7

############################################################
# Step 6 — gRNA metadata classification
############################################################
echo "[STEP 6] gRNA assignment"
jid8=$(submit_job "$PREV_JID" "step6_gRNA_assignment.sub")
echo " Submitted → Job $jid8"
PREV_JID=$jid8

############################################################
# Step 7 — Pseudobulk merging
############################################################
echo "[STEP 7] Pseudobulk merging"
jid9=$(submit_job "$PREV_JID" "step7_pseudobulk_merge.sub")
echo " Submitted → Job $jid9"
PREV_JID=$jid9

############################################################
# Final Summary
############################################################
echo "============================================================"
echo "  ALL PIPELINE STEPS SUBMITTED"
echo "============================================================"
echo "  Step 2 (Demultiplex):       $jid3"
echo "  Step 3 (Trim):              $jid4"
echo "  Step 4a (DNA align):        $jid5"
echo "  Step 4b (RNA align):        $jid6"
echo "  Step 5 (Summary):           $jid7"
echo "  Step 6 (gRNA assign):       $jid8"
echo "  Step 7 (Pseudobulk merge):  $jid9"
echo
echo "Monitor progress with:"
echo "      squeue -u $USER"
echo "============================================================"
