##
## Clear the directory
##
rm(list=ls())

##
## Load the TMLE functions
##
source("TMLEfunctions.R")

##
## Load the boot library
library(boot)

##
## Read in example1.csv datafile
##
example1 = read.table("example1.csv",sep=",",header=T)

##
## Call the TMLE function
## sample code 1.1
##
example1.1 = TMLE(data=example1,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",dropoutModel="male age",outcomeModel="male age",
     lag=1,nreps=10000,seed=123)
example1.1$out.table
save(example1.1,file="example1.1.rda")

##
## Call the TMLE function
## sample code 1.2
##
example1.2 = TMLE(data=example1,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",dropoutModel="male age",outcomeModel="male age",
     lagdropout=2,nreps=10000,seed=456)
example1.2$out.table
save(example1.2,file="example1.2.rda")

##
## Call the TMLE function
## sample code 1.3
##
example1.3 = TMLE(data=example1,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",dropoutModel="male age",outcomeModel="male age y1",
     lag=1,nreps=10000,seed=789)
example1.3$out.table
save(example1.3,file="example1.3.rda")

##
## Call the TMLE function
## sample code 1.4
##
example1.scale = example1
for(i in c("y1","y2","y3","y4","y5")) example1.scale[,i] = example1.scale[,i] / 100

example1.4 = TMLE(data=example1.scale,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",dropoutModel="male age",outcomeModel="male age",
     lag=1,nreps=10000,seed=1234,outcomeModelType="lg")
example1.4$out.table
save(example1.4,file="example1.4.rda")


## Call the TMLE function
## sample code 1.5
##
example2 = read.table("example2.csv",sep=",",header=T)
example1.5 = TMLE(data=example2,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",dropoutModel="male age",outcomeModel="male age",
     lag=1,nreps=10000,seed=1773,
     dropoutModel2="male age aux1 y2",dropoutModel4="male age aux2 y4",
     outcomeModel3="male age aux1 y2",outcomeModel5="male age aux2 y4")
example1.5$out.table
save(example1.5,file="example1.5.rda")

##
## Call the TMLE function
## sample code 1.6
##
ModelData = read.table("ModelData.csv",sep=",",header=T)
example1.6 = TMLE(data=example2,A="trt",outcomeVars=c("y1","y2","y3","y4","y5"),
     ,treatmentModel="male age y1",ModelData=ModelData,lag=1,nreps=10000,seed=1773)
example1.6$out.table
save(example1.6,file="example1.6.rda")

## Quit
q(save="no")

