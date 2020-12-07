library(tidyverse)
library(readr)
library(car)

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

italy_log <- nls(italy_dat_early$Cumulative_cases~a/(1+exp(-(b+c*italy_dat_early$index))),
            start=list(a=100000,b=-10.242468,c=0.293917),data=italy_dat_early,trace=TRUE)

summary(italy_log)

flex_point <- -coef(italy_log)[2]/coef(italy_log)[3]

projection <- (coef(italy_log)[1])/(1 + exp(-(coef(italy_log)[2]+coef(italy_log)[3]*1:100)))

plot(italy_dat_early$index,italy_dat_early$Cumulative_cases,ylim = c(0,130000),xlim = c(0,100))
lines(1:100,projection)

# GLM METHOD-- should we keep this????

log_fit <- glm(scaled_cases~index, family = "binomial", data = italy_dat_early)
summary(log_fit)

newdat <- data.frame(index = seq(0,100,1)) 
newdat$preds = predict(log_fit, newdata=newdat, type="response") #using logistic model to get predictions to use to plot

ggplot() + #plotting scaled cases and predictions using log model
  geom_point(data = italy_dat_early, aes(x=index, y=scaled_cases)) +
  geom_line(data = newdat, aes(x = index, y = preds))


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

mc_mat <- as.data.frame(test)

# Run logistic regression for 150 simulations and get flex date for each

flex_mc <- rep(NA, 150)

for (i in 1:150) {
  row_data <- t(mc_mat[i,])
  index <- seq(1:length(row_data))
  coefs <- coef(lm(logit(row_data/100000)~index))
  italy_log <- nls(row_data~a/(1+exp(-(b+c*index))),
                  start=list(a=100000,b=coefs[1],c=coefs[2]),trace=TRUE)
  
  summary(italy_log)
  
  flex_mc[i] <- -coef(italy_log)[2]/coef(italy_log)[3]
}

##getting error for 6 of the MC simulations (too many iterations?)

mean(na.omit(flex_mc)) #mean flex date
sd(na.omit(flex_mc)) #sd of flex dates

ggplot() + #plot of simulated flex dates with line for avg
  geom_point(aes(x = seq(1,150,1), y = flex_mc), color = "red") +
  xlab("MC Simulation") +
  ylab("# Days from Feb 15th") +
  ggtitle("Projected Flex Date for 150 MC Simulations") +
  geom_hline(aes(yintercept = mean(na.omit(flex_mc))))




# Extension: US Data

us_dat <- covid_dat %>%
  filter(Country == "United States of America")

plot(us_dat$Cumulative_cases) #all US cumulative and new positive cases (day 1 = Jan 3rd)
plot(us_dat$New_cases)

plot(us_dat$Cumulative_cases[30:100]) #Feb 1st through April 11th
plot(us_dat$New_cases[30:100])


# NLS 

us_dat_early <- us_dat[30:100,] #selecting days Feb 1st to April 11th

us_dat_early["index"] <- seq(1:nrow(us_dat_early)) #creating index column


plot(us_dat_early$Cumulative_cases) #plotting cumulative cases

coef(lm(logit(us_dat_early$Cumulative_cases/500000)~us_dat_early$index))

us_log <- nls(us_dat_early$Cumulative_cases~a/(1+exp(-(b+c*us_dat_early$index))),
                 start=list(a=500000,b=-13.0652170,c=0.1920636),data=us_dat_early,trace=TRUE)

summary(us_log)

flex_point <- -coef(us_log)[2]/coef(us_log)[3]

projection <- (coef(us_log)[1])/(1 + exp(-(coef(us_log)[2]+coef(us_log)[3]*1:100)))

plot(us_dat_early$index,us_dat_early$Cumulative_cases,ylim = c(0,500000),xlim = c(0,100))
lines(1:100,projection)

# MC Simulations

cum_days_us <- us_dat_early$Cumulative_cases

simulations_us <- sim(150, 71) #150 simulations for 71 days


test_us <- mult(cum_days_us, simulations_us)

mc_mat_us <- as.data.frame(test_us)

flex_mc_us <- rep(NA, 150)

for (i in 1:150) {
  row_data <- t(mc_mat_us[i,])
  index <- seq(1:length(row_data))
  coefs <- coef(lm(logit(row_data/500000)~index))
  us_log <- nls(row_data~a/(1+exp(-(b+c*index))),
                   start=list(a=500000,b=coefs[1],c=coefs[2]),trace=TRUE)
  
  summary(us_log)
  
  flex_mc_us[i] <- -coef(us_log)[2]/coef(us_log)[3]
}

mean(na.omit(flex_mc_us)) #mean flex date -> 67 days from Feb 1st = April 7th
sd(na.omit(flex_mc_us)) #sd of flex dates

ggplot() + #plot of simulated flex dates with line for avg
  geom_point(aes(x = seq(1,150,1), y = flex_mc_us), color = "red") +
  xlab("MC Simulation") +
  ylab("# Days from Feb 1st") +
  ggtitle("Projected Flex Date for 150 MC Simulations") +
  geom_hline(aes(yintercept = mean(na.omit(flex_mc_us))))
