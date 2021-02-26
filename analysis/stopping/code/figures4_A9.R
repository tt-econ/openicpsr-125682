library(ggplot2)
library(plyr)
library(reshape2)
library(gridExtra)
library(gtable)
library(grid)
library(scales)
theme_nogrid <- function (base_size = 14, base_family = "") {theme_bw(base_size = base_size, base_family = base_family) %+replace% theme(panel.grid = element_blank())}

incomebin <- read.csv(file='../temp/incomebin.csv')
incomebin[["sign"]] = ifelse(incomebin[["estimate"]] >= 0, "positive", "negative")
incomebin$absestimate = abs(incomebin$estimate)

p1 <- ggplot(data =  incomebin, aes(x = h, y = bin, color=sign)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  labs(color = "Sign") +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  scale_x_continuous(name="Hour of Shift", labels=seq(6, 11, 1), breaks=seq(5.75, 11.25, 1)) +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(legend.position="bottom", legend.key = element_rect(colour = NA), legend.text=element_text(size=12), legend.title=element_text(size=12), legend.key.height=unit(1, "line"))

leg1 <- gtable_filter(ggplot_gtable(ggplot_build(p1)), "guide-box")

p2 <- ggplot(data =  incomebin, aes(x = h, y = bin, size=absestimate)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  labs(size = "Percent change in stopping probability") +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  scale_x_continuous(name="Hour of Shift", labels=seq(6, 11, 1), breaks=seq(5.75, 11.25, 1)) +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(legend.position="bottom", legend.key = element_rect(colour = NA), legend.text=element_text(size=12), legend.title=element_text(size=12), legend.key.height=unit(1, "line"))

leg2 <- gtable_filter(ggplot_gtable(ggplot_build(p2)), "guide-box")

p3 <- ggplot(data =  incomebin, aes(x = h, y = bin, color=sign, size=absestimate)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  scale_x_continuous(name="Hour of Shift", labels=seq(6, 11, 1), breaks=seq(5.75, 11.25, 1)) +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  labs(color = "Sign", size = "Percent change in stopping probability") +
  theme(legend.position="none")


square_graph <- arrangeGrob(p3, leg1,leg2,
                       heights = unit.c(unit(1, "npc") - (leg1$height + leg2$height),
                                        leg1$height,
                                        leg2$height), nrow = 3)

ggsave("figure4.pdf", plot=square_graph, path="../output", width=8, height=6)

breakbin <- read.csv(file='../temp/breaks.csv')
breakbin[["sign"]] = ifelse(breakbin[["estimate"]] >= 0, "positive", "negative")
breakbin$absestimate = abs(breakbin$estimate)

p1 <- ggplot(data = breakbin, aes(x = h, y = bin, color=sign)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  labs(color = "Sign") +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  theme(legend.position="bottom", legend.key = element_rect(colour = NA), legend.text=element_text(size=12), legend.title=element_text(size=12), legend.key.height=unit(1, "line")) +
  scale_x_discrete(name="Alternative definitions of breaks", limits=c("Baseline", "Breaks: >15 min", "Breaks: >30 min", "Breaks: >45 min"))

leg1 <- gtable_filter(ggplot_gtable(ggplot_build(p1)), "guide-box")

p2 <- ggplot(data = breakbin, aes(x = h, y = bin, size=absestimate)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  labs(size = "Percent change in stopping probability") +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  theme(legend.position="bottom", legend.key = element_rect(colour = NA), legend.text=element_text(size=12), legend.title=element_text(size=12), legend.key.height=unit(1, "line")) +
  scale_x_discrete(name="Alternative definitions of breaks", limits=c("Baseline", "Breaks: >15 min", "Breaks: >30 min", "Breaks: >45 min"))

leg2 <- gtable_filter(ggplot_gtable(ggplot_build(p2)), "guide-box")

p3 <- ggplot(data = breakbin, aes(x = h, y = bin, color=sign, size=absestimate)) +
  geom_point(shape=15) + theme_nogrid() + scale_size_continuous(range = c(0,12)) +
  scale_color_manual(values = c("positive" = "darkgreen", "negative" = "orange")) +
  scale_y_continuous(name="Hour when the money is earned", breaks=seq(0, 10, 2)) +
  theme(axis.text = element_text(size=12), axis.ticks = element_blank()) +
  theme(legend.position="none") +
  scale_x_discrete(name="Alternative definitions of breaks", limits=c("Baseline", "Breaks: >15 min", "Breaks: >30 min", "Breaks: >45 min"))

square_graph <- arrangeGrob(p3, leg1,leg2,
                       heights = unit.c(unit(1, "npc") - (leg1$height + leg2$height),
                                        leg1$height,
                                        leg2$height), nrow = 3)

ggsave("appendixfigure9.pdf", plot=square_graph, path="../output", width=8, height=6)

