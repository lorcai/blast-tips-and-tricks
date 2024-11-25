#!/bin/bash

# Description:
# This script annotates a BLAST search result file with taxonomic lineage information.
# It REQUIRES the output file from ncbitax2lin (https://github.com/zyxue/ncbitax2lin) 
# to map TaxIDs to their taxonomic lineage. 
# The output is the original BLAST file with an additional field containing the taxonomic
# lineage (superkingdom, phylum, class, order, family, genus, species) corresponding to
# the TaxID in each line.

# Implementation:
# Briefly, this is an awk script that loads the tax2lin mapping file into an associative array
# with TaxIDs as keys and the taxonomic string as values. Then, the BLAST results file
# is read and when the TaxID in the current line exists in the TaxID-Taxonomy array,
# it adds the corresponding string in the last field of the BLAST results file.

# Note:
# TaxIDs are assumed to be present on the last column unless otherwise specified.
# You can change the format of the taxonomy string by modifying the value of nameArr[taxid].
# You can change the levels included by modifying the indexes of line[index]. 
# The headers identifying the different levels should be in the tax2lin file.
# The NCBI taxonomy is regularly updated. It is not (too) weird if some TaxIDs are not found.

# Usage:
# ./blast_taxid2lineage.sh <taxid_to_lineage_file> <blast_result_file> <output_file> [taxid_field]
#
# Parameters:
# 1. <taxid_to_lineage_file>: Output from `ncbitax2lin` mapping TaxIDs to taxonomic lineage (CSV).
# 2. <blast_result_file>: BLAST search result file in TSV format (use -outfmt 6 in the BLAST+ search) 
# 3. <output_file>: Name of the output file with added lineage information.
# 4. [taxid_field]: (Optional) Field number in the BLAST file containing the TaxID (default: last field).

# Check if the correct number of arguments is provided (at least 3 arguments required).
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <taxid_to_lineage_file> <blast_result_file> <output_file> [taxid_field]"
  exit 1
fi

# Assign input arguments to variables.
TAX2LIN="$1"
BLASTOUT="$2"
OUTPUTFILE="$3"
TAXID_FIELD="${4:-NF}" # Default to the last field if not provided.

# Check if files exist and are not empty.
if [ ! -s "$TAX2LIN" ]; then
  echo "Error: TaxID to lineage file '$TAX2LIN' does not exist or is empty."
  exit 1
fi

if [ ! -s "$BLASTOUT" ]; then
  echo "Error: BLAST result file '$BLASTOUT' does not exist or is empty."
  exit 1
fi

# Validate the TAXID_FIELD if supplied.
if [ "$TAXID_FIELD" != "NF" ] && ! [[ "$TAXID_FIELD" =~ ^[0-9]+$ ]]; then
  echo "Error: TaxID field must be an integer."
  exit 1
fi

# Annotate BLAST file with taxonomic lineage.
awk -F $'\t' -v OFS=$'\t' -v tax2lin="$TAX2LIN" -v taxid_field="$TAXID_FIELD" 'BEGIN {
  # Read the lineage mapping file (TaxID to taxonomic lineage).
  while (getline < tax2lin) {
    # Create an array "line", splitting on every level ","
    split($0, line, ",");
    taxid = line[1];
    superkingdom = line[2];
    phylum = line[3];
    class = line[4];
    order = line[5];
    family = line[6];
    genus = line[7];
    species = line[8];

    # Build the lineage array using TaxID as the key.
    nameArr[taxid] = superkingdom "_" phylum "_" class "_" order "_" family "_" genus "_" species;
  }
  close(tax2lin);

  # TaxID to lineage array loaded.
}

{
  # Resolve the field containing the TaxID.
  taxid_value = (taxid_field == "NF") ? $NF : $taxid_field;

  # Append the lineage to the end of the line.
  $(NF + 1) = nameArr[taxid_value];
  print;
}' "$BLASTOUT" > "$OUTPUTFILE"

# Confirmation message.
echo "Annotated BLAST file saved to: $OUTPUTFILE"
