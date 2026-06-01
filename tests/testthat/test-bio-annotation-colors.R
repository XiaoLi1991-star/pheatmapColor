test_that("bio_annotation_colors returns named colors for every annotation level", {
  annotation <- data.frame(
    Compare = c("WT-vs-Treat", "KO-vs-WT", "WT-vs-Treat"),
    Cluster = factor(c("C1", "C2", "C3")),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(annotation)

  expect_named(colors, c("Compare", "Cluster"))
  expect_setequal(names(colors$Compare), c("KO-vs-WT", "WT-vs-Treat"))
  expect_setequal(names(colors$Cluster), c("C1", "C2", "C3"))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", unlist(colors))))
})

test_that("all built-in schemes generate valid annotation colors", {
  annotation <- data.frame(
    Group = rep(c("A", "B", "C"), length.out = 9),
    stringsAsFactors = FALSE
  )

  for (scheme in pheatmap_schemes()) {
    colors <- bio_annotation_colors(annotation, scheme = scheme)
    expect_named(colors, "Group")
    expect_setequal(names(colors$Group), c("A", "B", "C"))
    expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colors$Group)))
  }
})

test_that("unknown schemes fail with a helpful error", {
  annotation <- data.frame(Group = c("A", "B"))

  expect_error(
    bio_annotation_colors(annotation, scheme = "unknown"),
    "Unknown scheme"
  )
})

test_that("annotation levels do not receive hard-coded biological presets", {
  annotation <- data.frame(
    Regulation = c("up-regulated", "down-regulated", "up-regulated"),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(annotation)

  expect_setequal(names(colors$Regulation), c("down-regulated", "up-regulated"))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colors$Regulation)))
})

test_that("character annotation levels keep their first-seen order", {
  annotation <- data.frame(
    Group = c("G1", "G2", "G10", "G1"),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(annotation)

  expect_identical(names(colors$Group), c("G1", "G2", "G10"))
})

test_that("manual colors can override only selected levels", {
  annotation <- data.frame(
    Regulation = c("up-regulated", "down-regulated"),
    Compare = c("WT-vs-Treat", "KO-vs-WT"),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(
    annotation,
    manual = list(
      Regulation = c("up-regulated" = "#AA0000"),
      Compare = c("KO-vs-WT" = "#111111")
    )
  )

  expect_equal(unname(colors$Regulation["up-regulated"]), "#AA0000")
  expect_true(grepl("^#[0-9A-Fa-f]{6}$", colors$Regulation["down-regulated"]))
  expect_equal(unname(colors$Compare["KO-vs-WT"]), "#111111")
  expect_true("WT-vs-Treat" %in% names(colors$Compare))
  expect_true(grepl("^#[0-9A-Fa-f]{6}$", colors$Compare["WT-vs-Treat"]))
})

test_that("many annotation levels are extended without duplicate colors", {
  annotation <- data.frame(
    Group = paste0("G", seq_len(18)),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(annotation, scheme = "soft")

  expect_length(unique(unname(colors$Group)), 18)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colors$Group)))
})

test_that("very many annotation levels warn about readability", {
  annotation <- data.frame(
    Group = paste0("G", seq_len(30)),
    stringsAsFactors = FALSE
  )

  expect_warning(
    bio_annotation_colors(annotation, scheme = "contrast"),
    "more than 24 levels"
  )
})

test_that("numeric annotations are represented as gradients", {
  annotation <- data.frame(
    Score = c(-2, 0, 2),
    stringsAsFactors = FALSE
  )

  colors <- bio_annotation_colors(annotation)

  expect_named(colors, "Score")
  expect_length(colors$Score, 100)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colors$Score)))
})

test_that("annotation lists support row and column annotations with different lengths", {
  annotation <- list(
    SampleGroup = c("Control", "Treat", "Treat"),
    GeneCluster = c("C1", "C2", "C3", "C4", "C5")
  )

  colors <- bio_annotation_colors(annotation)

  expect_setequal(names(colors$SampleGroup), c("Control", "Treat"))
  expect_setequal(names(colors$GeneCluster), paste0("C", 1:5))
})

test_that("pheatmap_bio can draw with generated colors and publication defaults", {
  mat <- matrix(rnorm(20), nrow = 5)
  rownames(mat) <- paste0("Gene", seq_len(nrow(mat)))
  colnames(mat) <- paste0("S", seq_len(ncol(mat)))
  annotation <- data.frame(
    Group = rep(c("Control", "Treat"), each = 2),
    row.names = colnames(mat)
  )

  plot <- pheatmap_bio(mat, annotation_col = annotation, scheme = "muted", silent = TRUE)

  expect_s3_class(plot, "pheatmap")
})
