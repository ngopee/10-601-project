rm(list = ls())

require(bigmemory)
require(nnet)
require(plyr)

source("./code/utils/showImage.R")
source("./code/utils/printConfusions.R")

X.train.filename <- "../../../Dropbox/CMU/ML 601/project/data/preprocessed_X_train_final.csv"
X.train <- read.big.matrix(filename = X.train.filename, type = "double")
train.data <- as.matrix(X.train)

Y.train.filename <- "~/Dropbox/CMU/ML 601/project/data/Y_train.csv"
Y.train <- read.csv(file = Y.train.filename, header = FALSE)
Y.factor <- as.factor(Y.train$V1)

## Perform K-fold cross validation ##
nFolds <- 5
id <- sample(1:nFolds, nrow(train.data), replace = TRUE)
list <- 1:nFolds
predictions <- data.frame()

# Create a progress bar to show the status of CV
progress.bar <- create_progress_bar("text")
progress.bar$init(nFolds)
ptm <- proc.time()
for(i in 1:nFolds) {
  trainingSet <- subset(train.data, id %in% list[-i])
  trainingLabels <- Y.factor[id %in% list[-i]]
  subset.train <- as.data.frame(trainingSet)
  subset.train <- cbind(subset.train, class = trainingLabels)
  
  model.mlr <- multinom(class ~ ., data = subset.train, MaxNWts=40000, decay=0.5)
  testSet <-  subset(train.data, id %in% c(i))
  prediction <- predict(model.mlr, testSet)
  
  testLabels <- Y.factor[id %in% c(i)]
  prediction.data <- data.frame(Predict = prediction, Actual = testLabels)
  predictions <- rbind(predictions, prediction.data)
  accuracy <- sum(prediction == testLabels) / length(testLabels) * 100
  print(paste("Accuracy = ", round(accuracy, 2), "%", sep = ""))
  
  progress.bar$step()
}
print("Total Time on K-fold CV:")
print((proc.time() - ptm))

tot.accuracy <- sum(predictions$Predict == predictions$Actual) / nrow(predictions) * 100
print(paste("Total Accuracy = ", round(tot.accuracy, 2), "%", sep = ""))

pred.table <- table(predictions)
print(pred.table)
printConfusions(pred.table)
