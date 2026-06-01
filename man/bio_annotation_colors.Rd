\name{bio_annotation_colors}
\alias{bio_annotation_colors}
\title{Create annotation colors for pheatmap}
\usage{
bio_annotation_colors(
  annotation,
  manual = NULL,
  palettes = NULL,
  scheme = "balanced",
  n_gradient = 100
)
}
\arguments{
\item{annotation}{A data frame or named list containing annotation variables.}
\item{manual}{Optional named list of named color vectors. Supplied colors override generated colors level by level.}
\item{palettes}{Optional named list of color vectors used for selected annotation variables.}
\item{scheme}{Built-in color scheme name. Use \code{pheatmap_schemes()} to list choices.}
\item{n_gradient}{Number of colors for numeric annotation gradients.}
}
\value{
A named list suitable for \code{pheatmap::pheatmap(annotation_colors = ...)}.
}
\description{
Create annotation colors for pheatmap with a publication-oriented categorical
palette and partial manual overrides. No annotation column names or level names
receive special presets.
}
\examples{
annotation <- data.frame(
  Regulation = c("up-regulated", "down-regulated"),
  Compare = c("WT-vs-Treat", "KO-vs-WT")
)

bio_annotation_colors(
  annotation,
  scheme = "soft",
  manual = list(Regulation = c("up-regulated" = "#AA0000"))
)
}
