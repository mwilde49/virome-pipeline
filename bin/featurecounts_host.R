#!/usr/bin/env Rscript
library(Rsubread)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5) {
    cat("Usage: Rscript featurecounts_host.R <bamFilesDirectory> <gtfFile> <isPairedEnd> <numThreads> <outputCSV>\n")
    quit(status = 1)
}

filepath <- args[1]
gtfFile <- args[2]
isPairedEnd <- as.logical(args[3])
numThreads <- as.numeric(args[4])
outputCSV <- args[5]

if (!grepl("/$", filepath)) {
    filepath <- paste0(filepath, "/")
}

filenames <- list.files(path = filepath, pattern = "\\.bam$", full.names = TRUE)

if (length(filenames) == 0) {
    cat("No BAM files found in the specified directory.\n")
    quit(status = 1)
}

featurecounts <- featureCounts(files = filenames,
                               annot.ext = gtfFile,
                               isGTFAnnotationFile = TRUE,
                               nthreads = numThreads,
                               isPairedEnd = isPairedEnd,
                               countReadPairs = TRUE)

write.csv(featurecounts$counts, file = outputCSV, row.names = TRUE)
write.csv(featurecounts$stat,   file = sub("\\.csv$", ".summary.csv", outputCSV), row.names = FALSE)

cat("featureCounts analysis completed successfully.\n")
