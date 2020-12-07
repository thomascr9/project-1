library(tidyverse)
library(pracma)
library(readr)

set.seed(400)

covid_dat <- read.csv("WHO-COVID-19-global-data.csv") #reading in WHO data

italy_dat <- covid_dat %>% # filtering for Italy data
  filter(Country == "Italy")

italy_dat_early <- italy_dat[44:87,] %>% #filtering 2/15 to 3/29
  mutate(scaled_cases = Cumulative_cases/max(Cumulative_cases)) #scaling data to be used with log regression

italy_dat_early["index"] <- seq(1:nrow(italy_dat_early)) #creating index column


plot(italy_dat_early$Cumulative_cases) #plotting cumulative cases

# Logistic Regression

# NLS METHOD

coef(lm(logit(italy_dat_early$Cumulative_cases/100000)~italy_dat_early$index))

italy_log = nls(italy_dat_early$Cumulative_cases~a/(1+exp(-(b+c*italy_dat_early$index))),
            start=list(a=100000,b=-10.242468,c=0.293917),data=italy_dat_early,trace=TRUE)

summary(italy_log)

flex_point = -coef(italy_log)[2]/coef(italy_log)[3]

projection = (coef(italy_log)[1])/(1 + exp(-(coef(italy_log)[2]+coef(italy_log)[3]*1:100)))

plot(italy_dat_early$index,italy_dat_early$Cumulative_cases,ylim = c(0,130000),xlim = c(0,100))
lines(1:100,projection)

# GLM METHOD

log_fit <- glm(scaled_cases~index, family = "binomial", data = italy_dat_early)
summary(log_fit)

newdat <- data.frame(index = seq(0,100,1)) 
newdat$preds = predict(log_fit, newdata=newdat, type="response") #using logistic model to get predictions to use to plot

ggplot() + #plotting scaled cases and predictions using log model
  geom_point(data = italy_dat_early, aes(x=index, y=scaled_cases)) +
  geom_line(data = newdat, aes(x = index, y = preds))

# need to get flex date


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

# Run logistic regression for 150 simulations and get flex date for each



# Extension: US Data

us_dat <- covid_dat %>%
  filter(Country == "United States of America")


plot(us_dat$Cumulative_cases[30:100])
