# blast-tips-and-tricks
A (mostly) empirically acquired collection of BLAST+ tricks and things you should know

---

## Tip 1

Look at the `blastn -help`. No seriously look at it. Now your defaults and formats.

## Tip 2

If your output is going to be used by other programs, consider the fields that the program requires. I like using the default "-outfmt 6" format. From the `blastn -help`:

```
   When not provided, the default value is:
   'qaccver saccver pident length mismatch gapopen qstart qend sstart send
```

This includes the main relevant fields, if you want to add more fields, you can add them at the end (after `send`). Many programs will easily take the default format and you will avoid having to mess with the output:

- [BASTA](https://github.com/timkahlke/BASTA) for consensus-based Last Common Ancestor sequence taxonomy annotation
- [QIIME2](https://docs.qiime2.org/) you can import the results into a search-results.qza artifact.

##### TODO, LOADING INTO QIIME

---

## Scripts

### [blast_taxid2lineage.sh](blast_taxid2lineage.sh): A script to add the taxonomic lineage string to the results of a BLAST search.

**Use:** Adds the levels (if they exist in the tax2lin file): superkingdom, phylum, class, order, family, genus, species to a BLAST output file.

**Requires:**

1. The (unzipped) output of [ncbitax2lin](https://github.com/zyxue/ncbitax2lin): `ncbi_lineages_[date].csv`.

2. An [`-outfmt 6`](https://www.metagenomics.wiki/tools/blast/blastn-output-format-6) BLAST output result file containing the TaxIDs corresponding to the matched sequence. By default it is assumed to be in the last field.

**Usage:**

`./blast_taxid2lineage.sh <taxid_to_lineage_file> <blast_result_file> <output_file> [taxid_field]`

This is an `awk` based script that loads the `ncbitax2lin` mapping file into an associative array with TaxIDs as keys and the taxonomic string as values. Then, the BLAST results file is read and when the TaxID in the current line exists in the TaxID-Taxonomy array, it adds the corresponding string in the last field of the BLAST result file.

---
