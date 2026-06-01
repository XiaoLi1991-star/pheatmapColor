bio_annotation_colors <- function(annotation,
                                  manual = NULL,
                                  palettes = NULL,
                                  scheme = "balanced",
                                  n_gradient = 100) {
  if (is.null(annotation)) {
    return(list())
  }
  scheme_def <- get_scheme(scheme)
  if (!is.data.frame(annotation) && !is.list(annotation)) {
    stop("`annotation` must be a data.frame or a named list.", call. = FALSE)
  }
  if (is.null(names(annotation)) || any(names(annotation) == "")) {
    stop("`annotation` columns must be named.", call. = FALSE)
  }
  if (!is.null(manual) && !is.list(manual)) {
    stop("`manual` must be a named list of named color vectors.", call. = FALSE)
  }

  colors <- lapply(names(annotation), function(name) {
    values <- annotation[[name]]
    manual_values <- manual[[name]]

    if (is.numeric(values)) {
      return(apply_manual_colors(continuous_palette(n_gradient, scheme_def), manual_values))
    }

    levels <- annotation_levels(values)
    generated <- discrete_annotation_palette(levels, palettes[[name]], scheme_def, name)
    apply_manual_colors(generated, manual_values)
  })

  stats::setNames(colors, names(annotation))
}

pheatmap_schemes <- function() {
  names(scheme_definitions())
}

pheatmap_bio <- function(mat,
                         annotation_col = NULL,
                         annotation_row = NULL,
                         annotation_colors = NULL,
                         palettes = NULL,
                         scheme = "balanced",
                         ...) {
  annotation <- combine_annotations(annotation_col, annotation_row)
  scheme_def <- get_scheme(scheme)
  colors <- bio_annotation_colors(
    annotation,
    manual = annotation_colors,
    palettes = palettes,
    scheme = scheme
  )

  args <- utils::modifyList(
    list(
      mat = mat,
      color = expression_palette(100, scheme_def),
      border_color = NA,
      annotation_col = annotation_col,
      annotation_row = annotation_row,
      annotation_colors = colors
    ),
    list(...)
  )

  do.call(pheatmap::pheatmap, args)
}

annotation_levels <- function(values) {
  if (is.factor(values)) {
    return(levels(droplevels(values)))
  }

  unique(stats::na.omit(as.character(values)))
}

discrete_annotation_palette <- function(levels, palette = NULL, scheme_def, name = "annotation") {
  if (length(levels) == 0) {
    return(stats::setNames(character(), character()))
  }

  if (!is.null(palette)) {
    return(stats::setNames(recycle_palette(palette, length(levels)), levels))
  }

  stats::setNames(default_discrete_palette(length(levels), scheme_def, name), levels)
}

default_discrete_palette <- function(n, scheme_def, name = "annotation") {
  base <- scheme_def$annotation

  if (n <= length(base)) {
    return(base[seq_len(n)])
  }

  if (n > 24) {
    warning(
      sprintf("Annotation `%s` has more than 24 levels; the legend may be hard to read.", name),
      call. = FALSE
    )
  }

  if (n <= 36) {
    return(unname(grDevices::palette.colors(n, palette = "Polychrome 36")))
  }

  base_many <- unname(grDevices::palette.colors(36, palette = "Polychrome 36"))
  extended <- scheme_hcl_colors(n - length(base_many), scheme_def$extend)
  c(base_many, extended)
}

continuous_palette <- function(n, scheme_def = get_scheme("balanced")) {
  grDevices::colorRampPalette(scheme_def$heatmap)(n)
}

expression_palette <- function(n, scheme_def = get_scheme("balanced")) {
  grDevices::colorRampPalette(scheme_def$heatmap)(n)
}

scheme_hcl_colors <- function(n, extend) {
  if (n <= 0) {
    return(character())
  }

  hue <- seq(extend$h[1], extend$h[2], length.out = n + 1)[seq_len(n)]
  grDevices::hcl(
    h = hue %% 360,
    c = rep(extend$c, length.out = n),
    l = rep(extend$l, length.out = n)
  )
}

get_scheme <- function(scheme) {
  schemes <- scheme_definitions()
  if (!is.character(scheme) || length(scheme) != 1 || !scheme %in% names(schemes)) {
    stop(
      "Unknown scheme. Use one of: ",
      paste(names(schemes), collapse = ", "),
      call. = FALSE
    )
  }

  schemes[[scheme]]
}

scheme_definitions <- function() {
  list(
    balanced = list(
      heatmap = c("#2166AC", "#4393C3", "#D1E5F0", "#F7F7F7", "#FDDBC7", "#D6604D", "#B2182B"),
      annotation = c("#4E79A7", "#F28E2B", "#59A14F", "#B07AA1", "#76B7B2", "#EDC948", "#9C755F", "#BAB0AC", "#A0CBE8", "#FFBE7D", "#8CD17D", "#D4A6C8"),
      extend = list(h = c(15, 375), c = 58, l = 66)
    ),
    soft = list(
      heatmap = c("#5E81AC", "#81A1C1", "#D8DEE9", "#F8F9FA", "#F1D6D2", "#D08770", "#BF616A"),
      annotation = c("#6B8FB3", "#D6A06A", "#83A67B", "#B58AA5", "#8CB8B2", "#D7C77A", "#A98F7D", "#B6B3B0", "#AFC8DC", "#E3B98B", "#A8C49E", "#C9A8BE"),
      extend = list(h = c(25, 385), c = 38, l = 70)
    ),
    contrast = list(
      heatmap = c("#053061", "#2166AC", "#92C5DE", "#F7F7F7", "#F4A582", "#B2182B", "#67001F"),
      annotation = c("#1F77B4", "#FF7F0E", "#2CA02C", "#9467BD", "#17BECF", "#BCBD22", "#8C564B", "#7F7F7F", "#AEC7E8", "#FFBB78", "#98DF8A", "#C5B0D5"),
      extend = list(h = c(0, 360), c = 72, l = 58)
    ),
    coolwarm = list(
      heatmap = c("#3B4CC0", "#6F91F2", "#C6D6F1", "#F2F2F2", "#F2CBB7", "#DD6B58", "#B40426"),
      annotation = c("#5277A3", "#D98E4A", "#5F9E6E", "#A77AAE", "#7DB8C0", "#C9B458", "#9A7563", "#B4B4B4", "#8FAFD3", "#E8B27A", "#98C78F", "#C7A2C9"),
      extend = list(h = c(10, 370), c = 52, l = 64)
    ),
    ember = list(
      heatmap = c("#2C5F8A", "#6EA6C8", "#DCEBF2", "#FAF7F2", "#F4C29D", "#D76A3C", "#8F2D1C"),
      annotation = c("#386FA4", "#E08E45", "#6A994E", "#A2678A", "#6CA6A6", "#D4B75E", "#A66A4C", "#A7A19A", "#88BBD6", "#E9B47B", "#9BBC72", "#BD93AF"),
      extend = list(h = c(20, 380), c = 55, l = 62)
    ),
    marine = list(
      heatmap = c("#154360", "#2874A6", "#AED6F1", "#F8F9F9", "#F5CBA7", "#D35400", "#922B21"),
      annotation = c("#2E86AB", "#F6AE2D", "#5AA469", "#8D6A9F", "#62B6CB", "#D5B942", "#9E6F57", "#A9A9A9", "#80BBD3", "#F3C06B", "#8BC58B", "#B79BC5"),
      extend = list(h = c(190, 550), c = 54, l = 63)
    ),
    forest = list(
      heatmap = c("#2B4C7E", "#567EBB", "#D7E3F4", "#F8F7F2", "#E8C7A2", "#B8794A", "#7A3B2E"),
      annotation = c("#5C7F67", "#C49A5A", "#7E9F35", "#8C6D62", "#6B9AC4", "#B8A15A", "#9B7A54", "#A5A39A", "#8EB59A", "#D2B472", "#A8B86F", "#9FAEBD"),
      extend = list(h = c(70, 430), c = 45, l = 60)
    ),
    mono = list(
      heatmap = c("#2F4858", "#5F7A8A", "#C9D3D8", "#F7F7F7", "#E8D0C8", "#B98072", "#7A3E3A"),
      annotation = c("#4C566A", "#A3A380", "#7D9D9C", "#B5838D", "#8D99AE", "#C7B980", "#7D7461", "#B8B8B8", "#708090", "#BFAE7E", "#90A995", "#AA95A4"),
      extend = list(h = c(200, 560), c = 28, l = 60)
    ),
    muted = list(
      heatmap = c("#315C7C", "#7DA9C4", "#DCEAF0", "#F7F7F4", "#EEDBD2", "#C98575", "#934D45"),
      annotation = c("#6C7A89", "#B8A36F", "#7B9E89", "#AA8CA5", "#8BA6A9", "#C2B77A", "#9A8476", "#B2AEAA", "#95AFC0", "#CCB28A", "#9DB69D", "#BCA8B8"),
      extend = list(h = c(30, 390), c = 32, l = 66)
    ),
    vivid = list(
      heatmap = c("#1D4E89", "#468FAF", "#D9EAF7", "#FFFFFF", "#FBC4AB", "#E76F51", "#9D0208"),
      annotation = c("#277DA1", "#F8961E", "#43AA8B", "#9B5DE5", "#F15BB5", "#F9C74F", "#F3722C", "#6C757D", "#4D96FF", "#90BE6D", "#00B4D8", "#B56576"),
      extend = list(h = c(0, 360), c = 78, l = 62)
    )
  )
}

apply_manual_colors <- function(generated, manual) {
  if (is.null(manual)) {
    return(generated)
  }
  if (is.null(names(manual)) || any(names(manual) == "")) {
    stop("Manual colors must be named, for example c(GroupA = '#4DBBD5').", call. = FALSE)
  }

  generated[names(manual)] <- manual
  generated
}

recycle_palette <- function(palette, n) {
  if (length(palette) == 0) {
    stop("Palette vectors must contain at least one color.", call. = FALSE)
  }
  rep(palette, length.out = n)
}

combine_annotations <- function(annotation_col, annotation_row) {
  annotations <- Filter(Negate(is.null), list(annotation_col, annotation_row))
  if (length(annotations) == 0) {
    return(NULL)
  }

  combined <- as.list(annotations[[1]])
  for (annotation in annotations[-1]) {
    for (name in names(annotation)) {
      if (!name %in% names(combined)) {
        combined[[name]] <- annotation[[name]]
      } else {
        combined[[name]] <- c(as.character(combined[[name]]), as.character(annotation[[name]]))
      }
    }
  }
  combined
}
