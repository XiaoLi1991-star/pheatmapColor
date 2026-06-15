\name{pheatmap_bio}
\alias{pheatmap_bio}
\title{Draw a pheatmap with generated biological annotation colors}
\usage{
pheatmap_bio(
  mat,
  annotation_col = NULL,
  annotation_row = NULL,
  annotation_colors = NULL,
  palettes = NULL,
  scheme = "balanced",
  ...,
  verbose = TRUE
)
}
\arguments{
\item{mat}{Numeric matrix passed to \code{pheatmap::pheatmap()}.}
\item{annotation_col}{Column annotation data frame passed to \code{pheatmap::pheatmap()}.}
\item{annotation_row}{Row annotation data frame passed to \code{pheatmap::pheatmap()}.}
\item{annotation_colors}{Optional partial or complete annotation colors.}
\item{palettes}{Optional named list of color vectors for selected annotation variables.}
\item{scheme}{Built-in color scheme name. Use \code{pheatmap_schemes()} to list choices.}
\item{...}{Other arguments passed to \code{pheatmap::pheatmap()}.}
\item{verbose}{Whether to print resolved values with \code{message()}.}
}
\value{
The object returned by \code{pheatmap::pheatmap()}.
}
\description{
A thin wrapper around \code{pheatmap::pheatmap()} that applies publication-style
matrix and annotation colors before plotting. It keeps pheatmap's familiar
arguments and lets user-supplied arguments override the defaults.

When \code{verbose = TRUE}, the function prints the resolved scheme, user
arguments passed through \code{...}, injected pheatmapColor defaults, annotation
variables, levels, and generated colors with \code{message()} so agent-assisted
tuning can use the exact previous values as a reference. It does not introspect
pheatmap's internal layout decisions such as tree height, cell size, or legend
placement.
}
