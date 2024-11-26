# blast-tips-and-tricks
A (mostly) empirically acquired collection of BLAST+ tricks and things you should know

STATUS: In never-ending process 💤

Most of these pertain to `blastn`.

---

# Tips 

## Know the defaults

Look at the `-help`. No seriously look at it. Know your defaults and formats.

## Use default or extended formats

If your output is going to be used by other programs, consider the fields that the program requires. I like using the default `-outfmt 6` format. From the `blastn -help`:

```
   When not provided, the default value is:
   'qaccver saccver pident length mismatch gapopen qstart qend sstart send
```

This includes the main relevant fields, if you want to add more fields, you can add them at the end (after `send`). Many programs will easily take the default format and you will avoid having to mess with the output:

- [BASTA](https://github.com/timkahlke/BASTA) for consensus-based Last Common Ancestor sequence taxonomy annotation
- [QIIME2](https://docs.qiime2.org/) you can import the results into a `search-results.qza` artifact.
- [blast2taxonomy](https://github.com/tmaruy/blast2taxonomy)

## Pre-made DBs

- [NCBI BLAST web service DBs](https://ftp.ncbi.nlm.nih.gov/blast/db/)
- [NCBI refseq/TargetedLoci for specific genes](https://ftp.ncbi.nlm.nih.gov/refseq/TargetedLoci/)

If you were wondering how to get the `fasta` files for those DBs, a note from NCBI:

> In April 2024, the BLAST FASTA files in this directory will no longer be
> available. You can easily generate FASTA files yourself from the formatted
>BLAST databases by using the BLAST utility blastdbcmd that comes with the
> standalone BLAST programs. See NCBI Insights for more details
> https://ncbiinsights.ncbi.nlm.nih.gov/2024/01/25/blast-fasta-unavailable-on-ftp/

Some tips on how to dump the DBs [below](#dump-the-db)


## Avoid certain taxids

TODO


# Tricks 

Mostly stuff I haven't seen elsewhere.

## Dump the DB

Dump all the sequences:
`blastdbcmd -db storage/dbs/nt/nt -entry all > nt.fna`

Dump the accesion to taxid mapping:
`blastdbcmd -db storage/dbs/nt/nt -entry all -outfmt "%a %T" > nt.fna.taxidmapping`

Got these 2 from: [https://github.com/martin-steinegger/conterminator](https://github.com/steineggerlab/conterminator?tab=readme-ov-file#mapping-file)

Get the taxid in the database for an accesion id (there is a tab in the outfmt string)
`blastdbcmd -db /usr/local/BBDD/nt/nt -entry_batch accid_list.txt -outfmt "%a   %T" > acc2taxid.tsv`

*Be careful, this seems to retrieve other accids in the taxids corresponding to your queried accds*

## Loading a BLAST file into QIIME2

You can export a `search-results.qza` file from the `feature-classifier` QIIME2 plugin functions `blast` or `classify-consensus-blast` (both have a `--o-search-results` option) with:

`qiime tools export --input-path search_results.qza --output-path search_results.qza_exported`

Should return:

`Exported search_results.qza as BLAST6DirectoryFormat to directory search_results.qza_exported`

Within  `search_results.qza_exported` there will be a `blast6.tsv` file in the default `-outfmt 6` format. You can filter and modify it, for example, keep all the hits with the maximum bitscore:

`awk '{if($1 != asv) {asv=$1; maxbitscore=$12; print $0} else if($1==asv && $12==maxbitscore) { print $0 }}' search_results.qza_exported/blast6.tsv > filtered_blast6.tsv`

and load into QIIME2 again (without adding or deleting columns) using:

`qiime tools import --type FeatureData[BLAST6] --input-path filtered_blast6.tsv --output-path filtered_search_results.qza`

Inside QIIME2 again you can use `qiime feature-classifier find-consensus-annotation` to take the Lowest Common Ancestor (LCA) among the hits in the BLAST file for each feature:

`qiime feature-classifier find-consensus-annotation --i-search-results filtered_search_results.qza --i-reference-taxonomy tax_ref.qza --o-consensus-taxonomy topbitscore_taxonomy.qza`

The taxonomic assignment `topbitscore_taxonomy.qza` can be used with other QIIME2 functions such as `qiime taxa barplot`. This give you more freedom to filter the BLAST results.

Note that if you attempt to load a BLAST search from the commandline BLASTn, the output does not include sequences that have no hits, as opposed to the exported `search_results.qza`, where the features without a hit passing the thresholds will be in the `blast6.tsv` file in the format of `feature3` and `feature4` :

```
feature1	MATCHEDSEQ1	100.0	200.0	0.0	0.0	1.0	200.0	329.0	528.0	7.4e-104	370.0
feature2	MATCHEDSEQ2	100.0	200.0	0.0	0.0	1.0	200.0	329.0	528.0	7.4e-104	370.0
feature3	*	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
feature4	*	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
```

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
