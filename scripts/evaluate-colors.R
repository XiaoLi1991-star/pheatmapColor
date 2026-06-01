source("R/bio-annotation-colors.R")

out_dir <- file.path("evaluation", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20260601)

make_de_matrix <- function(n_genes = 36, n_samples = 12) {
  group <- rep(c("WT", "Treat"), each = n_samples / 2)
  mat <- matrix(rnorm(n_genes * n_samples, sd = 0.7), nrow = n_genes)
  mat[1:12, group == "Treat"] <- mat[1:12, group == "Treat"] + 1.4
  mat[13:24, group == "Treat"] <- mat[13:24, group == "Treat"] - 1.2
  rownames(mat) <- paste0("Gene", seq_len(n_genes))
  colnames(mat) <- paste0(group, "_", seq_len(n_samples))
  mat
}

save_heatmap <- function(filename, mat, annotation_col = NULL, annotation_row = NULL,
                         annotation_colors = NULL, palettes = NULL, ...) {
  png(file.path(out_dir, filename), width = 1400, height = 1100, res = 160)
  on.exit(dev.off(), add = TRUE)
  pheatmap_bio(
    mat,
    annotation_col = annotation_col,
    annotation_row = annotation_row,
    annotation_colors = annotation_colors,
    palettes = palettes,
    border_color = NA,
    fontsize = 9,
    fontsize_row = 7,
    fontsize_col = 8,
    ...
  )
}

mat_de <- make_de_matrix()
regulation <- rep(c("up-regulated", "down-regulated"), each = 18)
annotation_row_de <- data.frame(
  Regulation = regulation,
  Cluster = rep(paste0("C", 1:4), each = 9),
  row.names = rownames(mat_de)
)
annotation_col_de <- data.frame(
  Group = rep(c("WT", "Treat"), each = 6),
  Batch = rep(c("B1", "B2", "B3"), times = 4),
  row.names = colnames(mat_de)
)

save_heatmap(
  "01_de_regulation_auto.png",
  mat_de,
  annotation_col = annotation_col_de,
  annotation_row = annotation_row_de,
  main = "Differential expression: automatic biological annotation colors"
)

save_heatmap(
  "02_de_regulation_manual_override.png",
  mat_de,
  annotation_col = annotation_col_de,
  annotation_row = annotation_row_de,
  annotation_colors = list(
    Group = c(WT = "#3C5488", Treat = "#E64B35"),
    Regulation = c("up-regulated" = "#B2182B")
  ),
  main = "Differential expression: partial manual override"
)

mat_compare <- matrix(rnorm(30 * 15), nrow = 30)
compare <- rep(c("WS-vs-WT", "WSAFB-vs-WS", "WSAFB-vs-WT", "WTAFB-vs-WT", "WTATFB-vs-WT"), each = 3)
mat_compare[1:8, compare == "WSAFB-vs-WT"] <- mat_compare[1:8, compare == "WSAFB-vs-WT"] + 1.5
mat_compare[9:16, compare == "WTAFB-vs-WT"] <- mat_compare[9:16, compare == "WTAFB-vs-WT"] - 1.2
rownames(mat_compare) <- paste0("GO_term_", seq_len(nrow(mat_compare)))
colnames(mat_compare) <- paste0("S", seq_len(ncol(mat_compare)))
annotation_col_compare <- data.frame(
  Compare = compare,
  Regulation = rep(c("up-regulated", "down-regulated"), length.out = length(compare)),
  row.names = colnames(mat_compare)
)

save_heatmap(
  "03_multi_compare_auto.png",
  mat_compare,
  annotation_col = annotation_col_compare,
  cluster_cols = FALSE,
  show_rownames = FALSE,
  main = "Multiple comparisons: automatic compare colors"
)

save_heatmap(
  "04_multi_compare_custom_palette.png",
  mat_compare,
  annotation_col = annotation_col_compare,
  palettes = list(
    Compare = c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9")
  ),
  cluster_cols = FALSE,
  show_rownames = FALSE,
  main = "Multiple comparisons: custom compare palette"
)

annotation_col_numeric <- data.frame(
  Group = rep(c("Control", "DrugA", "DrugB"), each = 4),
  Score = seq(-2, 2, length.out = ncol(mat_de)),
  row.names = colnames(mat_de)
)

save_heatmap(
  "05_sample_group_numeric_annotation.png",
  mat_de,
  annotation_col = annotation_col_numeric,
  annotation_row = annotation_row_de["Regulation"],
  main = "Sample groups plus numeric annotation"
)

colors_preview <- bio_annotation_colors(annotation_col_compare)
capture.output(str(colors_preview), file = file.path("evaluation", "annotation-colors-preview.txt"))
