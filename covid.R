library(tidyverse)
library(pracma)
library(readr)

set.seed(400)

covid_dat <- read.csv("WHO-COVID-19-global-data.csv")

italy_dat <- covid_dat %>%
  filter(Country == "Italy")


plot(italy_dat$Cumulative_cases[44:87]) #italy cum cases 2/15 to 3/29

#erf_fit <- erf(italy_dat$Cumulative_cases) #not sure how to fit this function


# MC simulations

sim <- function(m, n) {
  mat <- matrix(data = NA, nrow = m, ncol = n) 
  
  for (i in 1:m){
    mat[i,] <- rnorm(n, sd = 0.1, mean = 1)
  }
  
  return(mat)
}

cum_days <- italy_dat[44:84,6] #only use cum cases from Feb 15th to March 26th

simulations <- sim(150, 41) #150 simulations for 41 days

mult <- function(x, y){
  new_mat <- matrix(data = NA, nrow = 150, ncol = length(x))
  for (i in 1:length(x)) {
    new_mat[,i] <- x[i]*y[,i]
  }
  return(new_mat)
}

test <- mult(cum_days, simulations)
