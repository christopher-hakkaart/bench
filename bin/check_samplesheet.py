#!/usr/bin/env python


import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat nf-core/benchmark samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)


def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:

    sample,variant_type,genome,bench_set,truth_set
    SAMPLE,SHORT,GRCH37,SAMPLE.vcf.gz,TRUTH.vcf.gz
    SAMPLE,STRUCTURAL,GRCH38,SAMPLE.vcf.gz,TRUTH.vcf.gz

    For an example see:
    https://raw.githubusercontent.com/christopher-hakkaart/testdata/test_benchmark.csv
    """

    sample_dict = {}
    with open(file_in, "r") as fin:

        ## Check header
        MIN_COLS = 4
        # TODO nf-core: Update the column names for the input samplesheet
        HEADER = ["sample", "variant_type", "genome", "bench_set", "truth_set"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
            sys.exit(1)

        ## Check sample entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            # Check valid number of columns per row
            if len(lspl) < len(HEADER):
                print_error(
                    "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                    "Line",
                    line,
                )
            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                    "Line",
                    line,
                )

            ## Check sample name entries
            sample, variant_type, genome, bench_set, truth_set  = lspl[: len(HEADER)]
            sample = sample.replace(" ", "_")
            if not sample:
                print_error("Sample entry has not been specified!", "Line", line)

            ## Check variant_type entries
            variant_type = variant_type.replace(" ", "_")
            variant_type = variant_type.upper()
            if variant_type != 'SHORT' and variant_type != 'STRUCTURAL':
                print_error("Variant type entry is not known type 'SHORT' or 'STRUCTURAL'!",'Line', line)

            ## Check genome entries
            if genome:
                if genome.find(' ') != -1:
                    print_error("Genome entry contains spaces!",'Line', line)
                if len(genome.split('.')) > 1:
                    if genome[-6:] != '.fasta' and genome[-3:] != '.fa' and genome[-9:] != '.fasta.gz' and genome[-6:] != '.fa.gz':
                        print_error("Genome entry does not have extension '.fasta', '.fa', '.fasta.gz' or '.fa.gz'!",'Line', line)

            ## Check input vcf file extensions
            for bt in [bench_set, truth_set]:
                if bt:
                    if bt.find(" ") != -1:
                        print_error("Bench of truth file contains spaces!", "Line", line)
                    if not bt.endswith(".vcf.gz") and bt.endswith(".vcf"):
                        print_error(
                            "Bench or truth file does not have extension '.vcf.gz' or '.vcf'!",
                            "Line",
                            line,
                        )

            ## Create sample mapping dictionary = { sample: [ genome, bench_set, truth_set ] }
            sample_info = [variant_type, genome, bench_set, truth_set]

            if sample not in sample_dict:
                sample_dict[sample] = [sample_info]
            else:
                if sample_info in sample_dict[sample]:
                    print_error("Samplesheet contains duplicate rows!", "Line", line)
                else:
                    sample_dict[sample].append(sample_info)

    ## Write validated samplesheet with appropriate columns
    if len(sample_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample", "variant_type", "genome", "bench_set", "truth_set"]) + "\n")
            for sample in sorted(sample_dict.keys()):

                ## Check that multiple runs of the same sample are of the same datatype
                if not all(x[0] == sample_dict[sample][0][0] for x in sample_dict[sample]):
                    print_error("Multiple runs of a sample must be of the same datatype!", "Sample: {}".format(sample))

                for idx, val in enumerate(sample_dict[sample]):
                    fout.write(",".join(["{}_T{}".format(sample, idx + 1)] + val) + "\n")
                    # TODO: check T into truthset name when functionality added.
    else:
        print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
