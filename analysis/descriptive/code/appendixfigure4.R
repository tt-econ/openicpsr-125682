library(ggplot2)

theme_nogrid <- function (axis.text=element_text(color="black"),
                          legend.key=element_rect(colour=NA),
                          legend.text=element_text(size=12),
                          legend.title=element_text(size=14),
                          base_size=16, base_family="")
                          {theme_bw(base_size=base_size,
                                    base_family=base_family) %+replace%
                                    theme(panel.grid = element_blank())}

tip <- read.csv(file="../temp/tip_sample.csv", head=TRUE, sep=",")

focustip <- tip[which(tip$tip<=15 & tip$fare<=60),]

qplot(fare, tip, data=focustip, alpha=I(1/20),
      xlab="Fare ($)", ylab="Tip ($)") +
      theme_nogrid() +
      theme(axis.text=element_text(color="black"))
ggsave("../output/appendixfigure4.png", width=8, height=6, unit="in")

smalltip <- tip[which(tip$tip <= 5 & tip$fare <= 20),]

qplot(fare, tip, data=smalltip, alpha=I(1/100),
      xlab="Fare ($)", ylab="Tip ($)", size=1) +
      theme_nogrid() + guides(size=FALSE) +
      theme(axis.text=element_text(color="black"))
ggsave("../output/appendixfigure4_zoomed.png", width=8, height=6, unit="in")
