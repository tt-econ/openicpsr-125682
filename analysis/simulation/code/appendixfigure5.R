library(ggplot2)
library(data.table)
theme_nogrid <- function (axis.text=element_text(color="black"), legend.key = element_rect(colour = NA), legend.text=element_text(size=12), legend.title=element_text(size=14), base_size = 16, base_family = "") {theme_bw(base_size = base_size, base_family = base_family) %+replace% theme(panel.grid = element_blank())}

pval <- fread(file = "../temp/appendixfigure5_input.txt", header = FALSE, skip = 1)

pval <- melt(pval, measure.vars = c('V1', 'V2'))

cdf_graph <- ggplot(data = pval) +
  stat_ecdf(geom = "step", aes(x=value), color = "black") +
  theme_nogrid() + scale_x_continuous(breaks=seq(0, 1, 0.1)) +
  labs(x = "p-value", y = "Cumulative distribution") +
  theme(axis.text=element_text(color="black"))

ggsave("appendixfigure5.pdf", plot=cdf_graph, path="../output", width=8, height=6)
