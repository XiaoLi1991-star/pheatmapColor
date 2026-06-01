source("R/bio-annotation-colors.R")

out_dir <- file.path("evaluation", "schemes")
stress_dir <- file.path("evaluation", "stress")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(stress_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20260601)

make_matrix <- function(n_genes = 42, n_samples = 14) {
  group <- rep(c("Control", "Treat"), each = n_samples / 2)
  mat <- matrix(rnorm(n_genes * n_samples, sd = 0.65), nrow = n_genes)
  mat[1:14, group == "Treat"] <- mat[1:14, group == "Treat"] + 1.35
  mat[15:28, group == "Treat"] <- mat[15:28, group == "Treat"] - 1.15
  rownames(mat) <- paste0("Gene", seq_len(n_genes))
  colnames(mat) <- paste0(group, "_", seq_len(n_samples))
  mat
}

save_heatmap <- function(path, mat, annotation_col = NULL, annotation_row = NULL,
                         scheme = "balanced", title = scheme, width = 1300,
                         height = 1050, ...) {
  png(path, width = width, height = height, res = 160)
  on.exit(dev.off(), add = TRUE)
  pheatmap_bio(
    mat,
    annotation_col = annotation_col,
    annotation_row = annotation_row,
    scheme = scheme,
    fontsize = 9,
    fontsize_row = 7,
    fontsize_col = 8,
    main = title,
    ...
  )
}

mat <- make_matrix()
annotation_col <- data.frame(
  Group = rep(c("Control", "Treat"), each = 7),
  Batch = rep(paste0("B", 1:4), length.out = ncol(mat)),
  Score = seq(-2, 2, length.out = ncol(mat)),
  row.names = colnames(mat)
)
annotation_row <- data.frame(
  Module = rep(paste0("M", 1:6), length.out = nrow(mat)),
  Direction = rep(c("down", "up"), each = nrow(mat) / 2),
  row.names = rownames(mat)
)

for (scheme in pheatmap_schemes()) {
  save_heatmap(
    file.path(out_dir, paste0("scheme-", scheme, ".png")),
    mat,
    annotation_col = annotation_col,
    annotation_row = annotation_row,
    scheme = scheme,
    title = paste("scheme =", scheme)
  )
}

many_groups <- data.frame(
  Group14 = paste0("G", seq_len(ncol(mat))),
  row.names = colnames(mat)
)
save_heatmap(
  file.path(stress_dir, "many-groups-14-columns.png"),
  mat,
  annotation_col = many_groups,
  scheme = "balanced",
  title = "14 column groups: high-distinction palette"
)

mat_30 <- matrix(rnorm(30 * 30), nrow = 30)
rownames(mat_30) <- paste0("Gene", seq_len(nrow(mat_30)))
colnames(mat_30) <- paste0("S", seq_len(ncol(mat_30)))
annotation_30 <- data.frame(
  Group30 = paste0("G", seq_len(ncol(mat_30))),
  row.names = colnames(mat_30)
)
warnings <- capture.output(
  print(tryCatch(
    withCallingHandlers(
      {
        save_heatmap(
          file.path(stress_dir, "very-many-groups-30-columns.png"),
          mat_30,
          annotation_col = annotation_30,
          scheme = "contrast",
          title = "30 column groups: high-distinction palette, warning expected",
          show_rownames = FALSE,
          show_colnames = FALSE
        )
        "completed"
      },
      warning = function(w) {
        message(conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )),
  type = "message"
)
writeLines(warnings, file.path(stress_dir, "stress-warnings.txt"))

colors <- bio_annotation_colors(annotation_30, scheme = "contrast")
writeLines(
  paste(names(colors$Group30), colors$Group30, sep = "\t"),
  file.path(stress_dir, "group30-colors.tsv")
)
