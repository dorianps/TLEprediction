#######################################################################
# PREDICTION OF TEMPORAL LOBE EPILEPSY LATERALITY BASED ON PET ASYMMETRIES
#
# The script uses the asymmetry dataset obtained by Pustina et al.
# to compute TLE laterality in new patients based on three PET variables.
#
# USAGE:
# (Windows):
# source('https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R', echo=F)
#
# (Linux/Mac)
# Install RCurl the first time: install.packages("RCurl")
# Then run command:
# library(RCurl) ; eval( expr = parse( text = getURL("https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R", ssl.verifypeer=FALSE) ))
#
# Enter requested values and obtain the classification
#
# Author: Dorian Pustina
# Date: February 3, 2015
# 


stop('The training data are not available. 
The algorithm cannot proceed without training. Please contact the author or check https://github.com/dorianps/TLEprediction')


x=  as.numeric(readline("Assymetry for PET-mesial: "))
y=  as.numeric(readline("Assymetry for PET-hippo-var: "))
z=  as.numeric(readline("Assymetry for PET-entire-var: "))
boots = as.numeric(readline("Number of bootstraps (i.e., 10000): "))  # number of bootstraps
exclude = as.numeric(readline("Exclude cases from training (0=none, 1=Engel class III/IV, 2=non-operated, 3=1+2): "))  # exclusions










# check entered data for unusual values
if (any(is.na(c(x,y,z,boots))) == T) {
  stop("Missing values. Please run the script again and enter all values")
}
if (x > 1 | y > 1 | z > 1 | x < -1 | y < -1 | z < -1) {
  stop("entered values are beyond [-1 1] range of asymmetries. \nPlease check the values and run the script again.")
}
temp=imaging$PET_mesial
if (x > max(temp) | x < min(temp) ) {
  warning(paste("Unusual value entered: ", x, " for PET-mesial is out of existing TLE range [", 
                round(min(temp), 3), " ", round(max(temp), 3), ']', sep=''  ))
}
temp=imaging$PET_hippo_var
if (y > max(temp) | y < min(temp) ) {
  warning(paste("Unusual value entered: ", y, " for PET-hippo-var is out of existing TLE range [", 
                round(min(temp), 3), " ", round(max(temp), 3), ']', sep=''  ))
}
temp=imaging$PET_entire_var
if (z > max(temp) | z < min(temp) ) {
  warning(paste("Unusual value entered: ", z, " for PET-entire-var is out of existing TLE range [", 
                round(min(temp), 3), " ", round(max(temp), 3), ']', sep=''  ))
}


patient.data = data.frame(PET_mesial= x,  # new patient data frame
                          PET_hippo_var= y,
                          PET_entire_var= z)

# excluding patients from training
if (exclude == 0) {
  # do nothing
} else if (exclude == 1) {
  temp = which(imaging$SzOutcomeClass==3 | imaging$SzOutcomeClass==4)
  imaging = imaging[-temp, ] ; rm(temp)
} else if (exclude == 2) {
  temp = which(imaging$SzOutcomeClass==0)
  imaging = imaging[-temp, ] ; rm(temp)
} else if (exclude == 3) {
  temp = which(imaging$SzOutcomeClass==3 | imaging$SzOutcomeClass==4 | imaging$SzOutcomeClass==0)
  imaging = imaging[-temp, ] ; rm(temp)
} else {
  stop("Invalid value entered for \"Exclude cases\"")
}


#  
leftrows = which(imaging$LeftRightTLE == "left")
rightrows = which(imaging$LeftRightTLE == "right")


# adapt training sample due to exclusions
if (nrow(imaging) < 40) {
  # max is all but one of the smallest group, min = max
  smallgroup = ifelse(length(leftrows) < length(rightrows), length(leftrows), length(rightrows))
  max.train = round(((smallgroup-1)/smallgroup)*100, 0)
  min.train = max.train  # no variability on training sample, always leave/one out
  rm(smallgroup)
} else {
  min.train = 52  # 52%
  max.train = 97  # 97%
}





# install necessary packages and load them
if (! is.element("brglm", installed.packages()[,1])) {
  print("Installing missing `brglm` package")
  install.packages("brglm")
}

library(brglm)
sample.vec <- function(x, ...) x[sample(length(x), ...)]

correct = posterior = pat.probability = pat.category = rep(0, boots)
myformula = formula(LeftRightTLE ~ PET_mesial + PET_hippo_var + PET_entire_var)

cat(paste("Using ", nrow(imaging), " TLE patients for training (", length(leftrows), " left)...\n", sep=''))
cat("\n")
pb <- txtProgressBar(min = 0, max = boots, style = 3)
for (i in 1:boots) {
  
  trainpercent = sample.vec(seq(min.train, max.train, by=3), 1)  # random training sample
  n.left = round(length(leftrows) * trainpercent / 100)
  n.right = round(length(rightrows) * trainpercent / 100)
  
  left = sample(leftrows, replace=F, size=n.left)
  right = sample(rightrows, replace=F, size=n.right)
  

    traindata = imaging[c(left, right), ]
    testdata = imaging[ -c(left, right), ]
  
  
  temp = suppressWarnings( brglm(myformula, data=traindata, family=binomial ) )
  
  temp2 = predict(temp, newdata=testdata, type="response")
  
  success = (temp2>0.5 & testdata$LeftRightTLE == "right") | (temp2<0.5 & testdata$LeftRightTLE == "left")
  correct[i] = sum(success) / nrow(testdata) * 100
  posterior[i] = mean(c(1-temp2[testdata$LeftRightTLE=="left"], temp2[testdata$LeftRightTLE=="right"]))
  
  temp3 = predict(temp, newdata=patient.data, type="response")
  pat.category[i] = ifelse(temp3>0.5, "right", "left")
  pat.probability[i] = temp3
  setTxtProgressBar(pb, i)
}
close(pb)



pat.category = as.factor(pat.category)
# summary(pat.category) / boots * 100  # uncomment this line for raw categorization values

LTLEcorrect = sum( (pat.category=="left")*round(correct) )
RTLEcorrect = sum( (pat.category=="right")*round(correct) )

cat(paste("Patient Classification (", boots, " bootstraps):\n", sep=''))
print(paste('left TLE: ', round( LTLEcorrect / (LTLEcorrect + RTLEcorrect) * 100, 2), "%", sep='') )
print(paste('right TLE: ', round( RTLEcorrect / (LTLEcorrect + RTLEcorrect) * 100, 2), "%", sep='') )

cat("Average Posterior Probability (0=left, 1=right):\n")
print(round(weighted.mean(pat.probability, posterior),3 ) )

cat("95% CI of posterior probability (0.5=chance):\n")
print(round(quantile(pat.probability, probs=c(0.025, 0.975)), 3))
######################################################################
