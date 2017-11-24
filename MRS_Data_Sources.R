################################################################################
# Microsoft R Server: Working with data sources
################################################################################

#There are sample dataset installed with every copy of Microsoft R Server. You can print the filepath to these datasets using rxGetOption():
file.path(rxGetOption("sampleDataDir"))

#And you can list the sample datasets using list.files():
list.files(file.path(rxGetOption("sampleDataDir")))

################################################################################
# 1- RxTextData
################################################################################
#You can create a data source the same way you create any object in R, 
#by giving it a name and using a constructor.
#The first argument of any RevoScaleR data source is the source data. 
txtFile <- file.path(rxGetOption("sampleDataDir"), "claims.txt")
myTextDS <- RxTextData(file = txtFile)

#After the data source object is created, you can return object properties, precomputed metadata, and rows.
#Return properties:
myTextDS
#Return variable metadata:
rxGetVarInfo(myTextDS)
#get info
rxGetInfo(myTextDS)
# return info with first 10 rows
rxGetInfo(myTextDS, numRows=10)


names(myTextDS)
head(myTextDS)

# try with CSV file
csvFile <- file.path(rxGetOption("sampleDataDir"), "mortDefaultSmall2000.csv")
myCsvDS <- RxTextData(file = csvFile)
myCsvDS
myCsvInfo <- rxGetInfo(myCsvDS, numRows = 20)

################################################################################
# 2- RxSasData
################################################################################

inFileSAS <- file.path(rxGetOption("sampleDataDir"), "claims.sas7bdat") 
sourceDataSAS <- RxSasData(inFileSAS, stringsAsFactors=TRUE)
sourceDataSAS
rxGetInfo(sourceDataSAS)
#Retrieve variables in the data by calling R's names function:
names(sourceDataSAS)

#Compute a regression, passing the data source as the data argument to rxLinMod:
rxLinMod(cost ~ age + car_age, data = sourceDataSAS)

################################################################################
# 3- RxSpssData
################################################################################
#in a similar way
inFileSpss <- file.path(rxGetOption("sampleDataDir"), "claims.sav") 
sourceDataSpss <- RxSpssData(inFileSpss, stringsAsFactors=TRUE)
sourceDataSpss
rxGetInfo(sourceDataSpss, getVarInfo = TRUE)

################################################################################
# 4- RxXdfData
################################################################################
claimsPath <-  file.path(rxGetOption("sampleDataDir"), "claims.xdf")
claimsDs <- RxXdfData(claimsPath)
claimsDs

#get info
claimsDsInfo <- rxGetInfo(claimsDs, getVarInfo = TRUE)
claimsDsInfo
claimsDsInfo$numBlocks

#open the data source
rxOpen(claimsDs)

#Read the next block
claimsBlock1 <- rxReadNext(claimsDs)
class(claimsBlock)
dim(claimsBlock)

claimsBlock2 <- rxReadNext(claimsDs)
claimsBlock2

# close the data source
rxClose(claimsDs)

################################################################################
## 5- Using XDF data sources with CRAN Packages 
################################################################################
#Since data sources for xdf files read data in chunks, it is a good match for the CRAN package biglm.
#The biglm package does a linear regression on an initial chunk of data, then updates the results with subsequent chunks.
#Below is a function that loops through an xdf file object and creates and updates the biglm results.

# Using an Xdf Data Source with biglm
install.packages("biglm")
library("biglm")
  biglmxdf <- function(dataSource, formula)
  {   
    moreData <- TRUE
    df <- rxReadNext(dataSource)
    biglmRes <- biglm(formula, df)  
    while (moreData)
    {
      df <- rxReadNext(dataSource)    
      if (length(df) != 0)
      {
        biglmRes <- update(biglmRes, df)
      }
      else
      {
        moreData <- FALSE
      }
    }                           
    return(biglmRes)            
  }
  
  #create a data source
  airData <- file.path(rxGetOption("sampleDataDir"), "AirlineDemoSmall.xdf")
  airDS <- RxXdfData(airData, 
                     varsToKeep = c("DayOfWeek", "DepDelay","ArrDelay"))
  airInfo <- rxGetInfo(airData, getVarInfo = TRUE)
  airInfo
  airInfo$numBlocks
  
  #open the data source
  rxOpen(airDS)
  #call your function
  bigLmRes <- biglmxdf(airDS, ArrDelay~DayOfWeek)
  #close the data source
  rxClose(airDS)
  summary(bigLmRes)

  ###################################################################################
