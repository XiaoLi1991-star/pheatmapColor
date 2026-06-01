# 我写了一个 pheatmap 小工具：让热图分组配色少折腾一点

做差异表达分析的时候，热图几乎绕不开。

我自己最常用的还是 `pheatmap`。原因很简单：函数好记，参数直观，默认图也不难看。表达矩阵丢进去，再加上样本分组，基本很快就能得到一张能用的热图。

但用久了以后，会遇到一个很具体的问题：**分组注释的颜色不够顺手**。

比如样本有 `Control` 和 `Treat`，批次有 `B1`、`B2`、`B3`，基因还想标一下模块。`pheatmap` 当然支持 `annotation_colors`，但每次都要自己写一个嵌套 list：

```r
annotation_colors <- list(
  Group = c(Control = "#4E79A7", Treat = "#F28E2B"),
  Batch = c(B1 = "#59A14F", B2 = "#B07AA1", B3 = "#76B7B2")
)
```

这个功能是有的，但体验并不轻松。

所以我做了一个很小的 R 包：`pheatmapColor`。

它不是重新造一个热图系统，也不替代 `pheatmap`。它只做一件事：**在保留 pheatmap 使用习惯的基础上，让表达矩阵和分组注释的默认配色更适合科研作图**。

项目地址：

```text
https://github.com/XiaoLi1991-star/pheatmapColor
```

## 最简单的用法

安装：

```r
# install.packages("remotes")
remotes::install_github("XiaoLi1991-star/pheatmapColor")
```

使用：

```r
library(pheatmapColor)

pheatmap_bio(
  mat,
  annotation_col = annotation_col,
  scheme = "balanced",
  scale = "row",
  show_rownames = FALSE
)
```

这里的 `mat` 还是普通表达矩阵：

- 行是基因
- 列是样本

`annotation_col` 是样本分组信息，它的行名要对应表达矩阵的列名：

```r
annotation_col <- data.frame(
  Group = c("Control", "Control", "Treat", "Treat"),
  Batch = c("B1", "B2", "B1", "B2"),
  row.names = c("Control_1", "Control_2", "Treat_1", "Treat_2")
)
```

如果想给基因加注释，比如模块、cluster、上下调方向，就用 `annotation_row`：

```r
annotation_row <- data.frame(
  Module = c("M1", "M1", "M2", "M2"),
  row.names = rownames(mat)
)
```

完整调用就是：

```r
pheatmap_bio(
  mat,
  annotation_col = annotation_col,
  annotation_row = annotation_row,
  scheme = "soft",
  scale = "row"
)
```

一句话记：

```r
annotation_col = 描述样本，因为样本在矩阵的列
annotation_row = 描述基因，因为基因在矩阵的行
```

## 不是替代 pheatmap，而是给 pheatmap 加一个配色层

`pheatmap_bio()` 内部还是调用：

```r
pheatmap::pheatmap()
```

所以常见的 `pheatmap` 参数仍然可以继续写：

```r
pheatmap_bio(
  mat,
  annotation_col = annotation_col,
  scheme = "balanced",
  scale = "row",
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  show_rownames = FALSE,
  cutree_rows = 4,
  fontsize = 10
)
```

这个包主要接管两件事：

1. 表达矩阵的默认发散色带
2. annotation 分组颜色

其它绘图参数尽量交还给 `pheatmap`。

## 10 套 scheme

目前内置了 10 套配色方案：

```r
pheatmap_schemes()
```

包括：

```r
c(
  "balanced", "soft", "contrast", "coolwarm", "ember",
  "marine", "forest", "mono", "muted", "vivid"
)
```

我给它们的定位是：

- `balanced`：默认方案，适合大多数热图
- `soft`：颜色更柔和，适合图很密的时候
- `coolwarm`：经典蓝白红风格，适合 Z-score 表达热图
- `contrast`：对比更强，适合展示模式分离
- `muted`：annotation 不抢戏，适合补充图
- `vivid`：更醒目，适合汇报展示
- `ember`、`marine`、`forest`、`mono`：提供不同视觉气质的备用选择

它们不是按字段名预设的。

也就是说，包不会看到 `Regulation` 就自动给红蓝，也不会看到 `up-regulated`、`down-regulated` 就替你判断生物学含义。

我最后选择的是一个更克制的设计：**包只负责提供好看的默认颜色，不替用户解释数据含义**。

如果你想让某些组固定颜色，可以手动覆盖。

## 手动覆盖某些颜色

比如你希望 `Treat` 一定是深红色：

```r
pheatmap_bio(
  mat,
  annotation_col = annotation_col,
  scheme = "balanced",
  annotation_colors = list(
    Group = c(Treat = "#B2182B")
  )
)
```

只需要写你关心的 level。

其它没有写的 level，会由当前 `scheme` 自动补齐。

这对实际作图很有用：既保留自动配色的便利，又能控制关键分组。

## 分组很多怎么办？

这个问题我专门做了压力测试。

结论很现实：**分组太多时，不可能靠颜色优雅地解决所有问题**。

现在的策略是：

- 12 组以内：使用每个 scheme 手工挑选的颜色
- 13 到 36 组：切换到高区分度颜色，优先保证能分辨
- 超过 24 组：给 warning，提醒图例可读性可能变差

也就是说，包会尽量兜底，但不会假装 30 个组还能画得很优雅。

如果一个 annotation 变量有几十个 level，更推荐：

- 合并低频类别
- 拆成多个热图
- 只展示最关键的分组
- 或者换一种展示方式

## 为什么做这个包？

这不是一个宏大的包。

它解决的是一个很小、但很常见的问题：

> 我已经会用 pheatmap 了，只是不想每次为了分组颜色写一堆 list。

所以 `pheatmapColor` 的目标不是“功能很多”，而是：

- 默认图更接近发表图
- 参数尽量少
- 不改变 pheatmap 用户习惯
- 自动配色和手动覆盖都方便
- 不把生物学含义写死在包里

目前还是早期版本。

如果你也经常用 `pheatmap` 画差异表达热图、聚类热图、样本分组热图，可以试一下：

```r
remotes::install_github("XiaoLi1991-star/pheatmapColor")
```

项目地址：

```text
https://github.com/XiaoLi1991-star/pheatmapColor
```

欢迎提 issue，也欢迎给我一些你觉得更适合科研发表的配色方案。
