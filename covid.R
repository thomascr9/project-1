library(tidyverse)
library(readr)
library(car)

set.seed(2020)

covid_dat <- read.csv("WHO-COVID-19-global-data.csv") #reading in WHO data

dates <- covid_dat$Date_reported

italy_dat <- covid_dat %>% # filtering for Italy data
  filter(Country == "Italy")

ggplot() +
  geom_line(data = italy_dat, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = italy_dat, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = New_cases), color = "blue") +
  xlab("Date") +
  ylab("Cumulative Cases (red) and New Cases (blue)") +
  ggtitle("Overview of COVID-19 Cases in Italy") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()


italy_dat_early <- italy_dat[44:87,]  #filtering 2/15 to 3/29

italy_dat_early["index"] <- seq(1:nrow(italy_dat_early)) #creating index column



ggplot() +
  geom_line(data = italy_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = italy_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = New_cases), color = "blue") +
  xlab("Date") +
  ylab("Cumulative Cases (red) and New Cases (blue)") +
  ggtitle("COVID-19 Cases in Italy Feb 15th to March 29th") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()


# Logistic Regression

# NLS METHOD

coef(lm(logit(italy_dat_early$Cumulative_cases/100000)~italy_dat_early$index))

italy_log <- nls(italy_dat_early$Cumulative_cases~a/(1+exp(-(b+c*italy_dat_early$index))),
            start=list(a=100000,b=-10.242468,c=0.293917),data=italy_dat_early,trace=TRUE)

summary(italy_log)

flex_point <- -coef(italy_log)[2]/coef(italy_log)[3]

projection <- (coef(italy_log)[1])/(1 + exp(-(coef(italy_log)[2]+coef(italy_log)[3]*1:100)))

proj_dates <- data.frame(projection, "date" = dates[44:143])

ggplot() +
  geom_point(data = italy_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = proj_dates, aes(x = as.Date(date, "%m/%d/%y"), y = projection), color = "blue") +
  ylim(0,130000) +
  xlab("Date") +
  ylab("Cumulative Cases") +
  ggtitle("Cumulative Cases with Fitted Regression Line for Italy") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()


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


mean(na.omit(flex_mc)) #mean flex date -> 38 days from Feb 15th = March 23rd
  #original paper's result was March 25th so we are close!
sd(na.omit(flex_mc)) #sd of flex dates

upper <- mean(flex_mc) + qt(0.975, df = 149)*(sd(flex_mc)/sqrt(150))
lower <- mean(flex_mc) - qt(0.975, df = 149)*(sd(flex_mc)/sqrt(150))

lower
upper
#March 23rd to March 24th

quantile(flex_mc, probs = c(.025, 0.975))
#March 19th to April 3rd?

ggplot() + #plot of simulated flex dates with line for avg
  geom_point(aes(x = seq(1,150,1), y = flex_mc), color = "red") +
  xlab("MC Simulation") +
  ylab("# Days from Feb 15th") +
  ggtitle("Projected Flex Date for 150 MC Simulations (Italy)") +
  geom_hline(aes(yintercept = mean(na.omit(flex_mc)))) +
  theme_bw()



# Extension: US Data

us_dat <- covid_dat %>%
  filter(Country == "United States of America")

ggplot() +
  geom_line(data = us_dat, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = us_dat, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = New_cases), color = "blue") +
  xlab("Date") +
  ylab("Cumulative Cases (red) and New Cases (blue)") +
  ggtitle("Overview of COVID-19 Cases in the United States") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()


us_dat_early <- us_dat[30:100,] #selecting days Feb 1st to April 11th

ggplot() +
  geom_line(data = us_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = us_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = New_cases), color = "blue") +
  xlab("Date") +
  ylab("Cumulative Cases (red) and New Cases (blue)") +
  ggtitle("COVID-19 Cases in US Feb 1st to April 11th") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()


# NLS 

us_dat_early["index"] <- seq(1:nrow(us_dat_early)) #creating index column


coef(lm(logit(us_dat_early$Cumulative_cases/500000)~us_dat_early$index))

us_log <- nls(us_dat_early$Cumulative_cases~a/(1+exp(-(b+c*us_dat_early$index))),
                 start=list(a=500000,b=-13.0652170,c=0.1920636),data=us_dat_early,trace=TRUE)

summary(us_log)

flex_point <- -coef(us_log)[2]/coef(us_log)[3]

projection <- (coef(us_log)[1])/(1 + exp(-(coef(us_log)[2]+coef(us_log)[3]*1:100)))

proj_dates <- data.frame(projection, "date" = dates[30:129])

ggplot() +
  geom_point(data = us_dat_early, aes(x = as.Date(Date_reported, "%m/%d/%y"), y = Cumulative_cases), color = "red") +
  geom_line(data = proj_dates, aes(x = as.Date(date, "%m/%d/%y"), y = projection), color = "blue") +
  ylim(0,650000) +
  xlab("Date") +
  ylab("Cumulative Cases") +
  ggtitle("Cumulative Cases with Fitted Regression Line for US") + 
  theme(axis.text.x = element_text(angle=45, hjust = 1)) +
  theme_bw()

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

upper <- mean(flex_mc_us) + qt(0.975, df = 149)*(sd(flex_mc_us)/sqrt(150))
lower <- mean(flex_mc_us) - qt(0.975, df = 149)*(sd(flex_mc_us)/sqrt(150))

lower
upper
#April 6th to April 7th

quantile(flex_mc_us, probs = c(.025, 0.975))
#April 3rd to April 12th

ggplot() + #plot of simulated flex dates with line for avg
  geom_point(aes(x = seq(1,150,1), y = flex_mc_us), color = "red") +
  xlab("MC Simulation") +
  ylab("# Days from Feb 1st") +
  ggtitle("Projected Flex Date for 150 MC Simulations (US)") +
  geom_hline(aes(yintercept = mean(na.omit(flex_mc_us)))) +
  theme_bw()
