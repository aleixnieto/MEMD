###############################################
# T�tulo: 9. ANN
# Autor: Alba
# Fecha: 14/12/21

# Descripci�n: En este script empleamos redes 
# neuronales (ANN) para entrenar un 
# modelo que nos permita predecir cancelaciones
###############################################

library(MASS)
library(nnet)
library(caret)
library(pROC)

set.seed(2021)

if(!exists('d.e')){
  path <-'../data'
  d.e <- read.csv2(paste0(path,'/',"hotel_bookings_proc.csv"), sep=",")
  d.e$adr<-as.numeric(d.e$adr)
  v<-list(
    categoric=c('hotel','is_canceled', 'arrival_date_month','arrival_date_year', 'meal','market_segment','distribution_channel',
                'is_repeated_guest','reserved_room_type','assigned_room_type', 'room_coherence', 
                'is_company', 'is_agent', 'customer_type','deposit_type', 'if_prev_cancel','if_wait'),
    integer=c('lead_time', 'stays_in_weekend_nights','stays_in_week_nights','adults','children','babies',
              'booking_changes','required_car_parking_spaces','total_of_special_requests'),
    continua='adr')
  v$numeric <- c(v$integer,v$continua)
  library(ggplot2)
  for(i in v$categoric) d.e[[i]]<-as.factor(d.e[[i]])
  for(i in v$integer) d.e[[i]]<-as.integer(d.e[[i]])
}
dd_ann <- d.e
str(dd_ann)

head(dd_ann)

# Dividimos en train/test
test <- sample(1:nrow(dd_ann),size = nrow(dd_ann)/3)
dataTrain <- dd_ann[-test,]
dataTest <- dd_ann[test,]

# Hyperparameter tuning
sizes = 1:25
acc = list()

for (s in sizes) {
  
  folds <- createFolds(dataTrain$is_canceled, k = 10)
  
  cvNN <- lapply(folds, function(x){
    training_fold <- dataTrain[-x, ]
    test_fold <- dataTrain[x, ]
    clasificador <- nnet(data=training_fold, class.ind(is_canceled) ~ ., entropy=T,
                         size=s,decay=0,maxit=2000,trace=T)
    y_pred <- predict(mynet, test_fold, type='class')
    cm <- table(test_fold$is_canceled, y_pred)
    precision <- (cm[1,1] + cm[2,2]) / (cm[1,1] + cm[2,2] +cm[1,2] + cm[2,1])
    return(precision)
  })
  accuracy <- mean(unlist(cvNN))
  acc[[s]] <- accuracy
}

acc

mynet <- nnet(data=dataTrain,class.ind(is_canceled) ~ ., entropy=T,size=19,decay=0,maxit=20000,trace=T)
mynet.resubst <- predict (mynet, dataTrain, type='class')

tab <- table(dataTrain$is_canceled, mynet.resubst)
mynet.resubst.error <- 1-sum(tab[row(tab)==col(tab)])/sum(tab)
1-mynet.resubst.error

rownames(tab) = c("0","1")
confusionMatrix(tab)

mynet.resubst <- predict (mynet, dataTest, type='class')
tab <- table(dataTest$is_canceled, mynet.resubst)
mynet.resubst.error <- 1-sum(tab[row(tab)==col(tab)])/sum(tab)
1-mynet.resubst.error

colnames(tab) = c("0","1")
confusionMatrix(tab)

# Escalamos
dd_ann[c("lead_time", "stays_in_weekend_nights", "stays_in_week_nights", "adults",
         "children", "babies","booking_changes", "required_car_parking_spaces",
         "total_of_special_requests")] = scale(dd_ann[c("lead_time", "stays_in_weekend_nights", "stays_in_week_nights", "adults",
                                                        "children", "babies","booking_changes", "required_car_parking_spaces",
                                                        "total_of_special_requests")])

# Vamos a intentar aumentar el accuracy intentando predecir s�lo con las variables num�ricas

dd_anncat = dd_ann[c("is_canceled","lead_time", "stays_in_weekend_nights", "stays_in_week_nights", "adults",
         "children", "babies","booking_changes", "required_car_parking_spaces",
         "total_of_special_requests")]

dataTraincat <- dd_anncat[-test,]
dataTestcat <- dd_anncat[test,]

mynet <- nnet(data=dataTraincat, class.ind(is_canceled) ~ ., entropy=T,size=19,decay=0,maxit=2000,trace=T)

mynet.resubst <- predict(mynet, dataTraincat, type='class')
tab <- table(dataTraincat$is_canceled, mynet.resubst)
mynet.resubst.error <- 1-sum(tab[row(tab)==col(tab)])/sum(tab)
1-mynet.resubst.error

rownames(tab) = c("0","1")
confusionMatrix(tab)

mynet.resubst <- predict (mynet, dataTestcat, type='class')
tab <- table(dataTestcat$is_canceled, mynet.resubst)
mynet.resubst.error <- 1-sum(tab[row(tab)==col(tab)])/sum(tab)
1-mynet.resubst.error

colnames(tab) = c("canceled","not_canceled")
confusionMatrix(tab)
