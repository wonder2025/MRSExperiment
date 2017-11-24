################################################################################
# Microsoft R Server: Data Ingestion Examples
# This script is based on https://github.com/mmparker-msft/intro_to_mrs  
################################################################################

# Help and Solutions
# If you get stuck at any point, you can use the help() function to look up
# the official documentation:
help(rxImport)
?rxImport

################################################################################
# Microsoft R Server: Sample datasets
################################################################################

# All of the exercises in this script depend on the sample data directories
# that are installed with every copy of Microsoft R Server.
# You can print the filepath to these datasets using rxGetOption():
rxGetOption("sampleDataDir")


# And you can list the sample datasets using list.files()
list.files(rxGetOption("sampleDataDir"))


#Set the filepath to the sample data directory below to create 
# a filepath to the dataset "mortDefault2000.csv"
csvFile <- file.path(rxGetOption("sampleDataDir"), "mortDefaultSmall2000.csv")



# Check that your filepath works with file.exists()
file.exists(csvFile)


################################################################################
# Settings
################################################################################
# set the folder where you want to store your XDF files
XdfDir <- file.path(getwd(),"XDF_Files")

################################################################################
# Exercise 1: Import a CSV File
################################################################################

# Now that you have a filepath to a CSV file, import it.
# In open-source R, you'd do something like this:
exampleData <- read.csv(csvFile)
# which creates an object called exampleData in your R workspace (that is, in
# your computer's physical memory).
dim(exampleData)

# But to take full advantage of Microsoft R Server's big-data capabilities,
# you'll want to use an XDF file. Unlike exampleData, an XDF file won't exist in
# your computer's physical memory, but on your hard drive.
# First, let's create a filepath for that XDF file.
xdfFile <- file.path(XdfDir, "mortDefault2000.xdf")

# Now we have a filepath - but that file doesn't exist yet:
file.exists(xdfFile)


# To create the XDF file, use rxImport to read data from your CSV into a new
# XDF file. Fill in the blanks here:
rxImport(inData = csvFile,
         outFile = xdfFile,
         overwrite = TRUE)


# Now, check that the XDF was created:
file.exists(xdfFile)


# And check that the results look good. rxGetInfo gives you a quick overview of
# any XDF file. This should tell you that there are 10,000 observations of
# 6 variables:
rxGetInfo(xdfFile)
rxGetInfo(xdfFile, getVarInfo = TRUE, getBlockSizes = TRUE)

# rxImport return a data source
xdfFileDS <- rxImport(inData = csvFile,
                      outFile = xdfFile,
                      overwrite = TRUE)
class(xdfFileDS)
xdfFileDS
dimnames(xdfFileDS)
names(xdfFileDS)

#get info
xdfInfo <- rxGetInfo(xdfFileDS, getVarInfo = TRUE, getBlockSizes = TRUE)
xdfInfo
xdfInfo$fileName
xdfInfo$numRows
xdfInfo$numVars
xdfInfo$numBlocks
xdfInfo$compressionType
xdfInfo$rowsPerBlock
xdfInfo$varInfo

#summary
rxSummary(~ ., data = xdfFileDS)

rxSummary(~ creditScore + year, data = xdfFileDS)


################################################################################
# Exercise 2: Import Selected Variables
################################################################################

# You can specify many options when importing data with rxImport. One 
# commonly-used option is to select only a few variables to keep from the whole
# dataset.

# In MRS, you can do this in two ways:
# - use varsToKeep to name the variables you want to import, or
# - use varsToDrop to name variables that you don't want to import.

# Use either varsToKeep or varsToDrop to create a subset of the CSV data above
# that contains only the variables "creditScore", "houseAge", and "default".

# Hint: When you pass variable names, create a character vector, like this one:
# c("example", "character", "vector")

xdfSubset <- file.path(XdfDir, "xdfSubset.xdf")

rxImport(inData = csvFile, 
         outFile = xdfSubset,
         varsToKeep = c("creditScore", "houseAge", "default"),
         overwrite = TRUE
)


# Now, use rxGetInfo to check the results. By adding the "numRows = 10" argument,
# rxGetInfo will show us the first ten rows of the dataset along with its
# metadata.
rxGetInfo(xdfSubset)
rxGetInfo(xdfSubset, numRows = 10)
rxGetInfo(xdfSubset, numRows = 10,
          getVarInfo = TRUE,
          getBlockSizes = TRUE)



################################################################################
# Exercise 3: Append a New Dataset
################################################################################

# So - we've imported one year's worth of mortgage data:
rxGetInfo(xdfFile, numRows = 10)

# Here's the data from 2001:
csv2001 <- file.path(rxGetOption("sampleDataDir"), "mortDefaultSmall2001.csv")

# Use rxImport to append csv2001 to the existing XDF file (xdfFile):
rxImport(inData = csv2001,
         outFile = xdfFile,
         append = TRUE
)



# Check your results using rxGetInfo. There should now be 20,000 rows,
# and the "year" variable should have a low value of 2000 and a high of 2001:
rxGetInfo(xdfFile, getVarInfo = TRUE)


################################################################################
# Exercise 4: Combine Several CSVs into One XDF
################################################################################

# Now let's combine several CSV files into one XDF at once.
# Here are the filepaths of all of the mortgauge default CSV files:
csvList <- list.files(rxGetOption("sampleDataDir"),
                      pattern = "mortDefaultSmall.*.csv",
                      full.names = TRUE)

# Print to review
csvList


# Use this path for the new XDF file:
xdfAll <- file.path(XdfDir,"mortDefaultAll.xdf")


# Now we want to run rxImport() once for each CSV file in csvList. In R, one
# way to do this is to use lapply(). For example, here's how to use lapply() to
# check if each of those files exists:
lapply(csvList, FUN = file.exists)

# It printed TRUE for each of the ten files. We can use similar logic to append
# new data to an XDF file. 

lapply(csvList, FUN = function(oneCsv) {
    
    rxImport(inData = oneCsv,
             outFile = xdfAll,
             append = file.exists(xdfAll)
             )

})
#lapply(csvList, FUN = function(oneCsv) {
  
#  rxImport(inData = oneCsv,
#           outFile = xdfAll,
#           append = file.exists(xdfAll),
#           overwrite = TRUE)
  
#})

# rxGetInfo should now show 100,000 observations (1e+05 in R's scientific notation),
# and the maximum value of "year" should be 2009:
rxGetInfo(xdfAll, getVarInfo = TRUE)
rxGetInfo(xdfAll, getVarInfo = TRUE,
          getBlockSizes = TRUE)



# Troubleshooting tips:

# - append needs to be set to FALSE for the first CSV file, so rxImport knows to
#   create a new XDF file, but set to TRUE for the 2nd-10th CSV files, so rxImport knows
#   to add to an existing XDF file. See the first lapply() example for a hint.

# - If something goes wrong and you need to delete xdfAll, use file.remove(xdfAll)


################################################################################
# Exercise 5: Import a Subset
################################################################################

# Now imagine that you only wanted to pull in the records where a customer had
# defaulted on their loan (that is, where default == 1). In rxImport, you can use
# the rowSelection argument to set one or more criteria. Any comparison that
# produces TRUE or FALSE, like default == 1, can be used to subset, and several
# criteria can be chained together using R's logical operators 
# (for example, default == 1 & houseAge > 10)

# Create a new subset in this XDF file, including only records where default == 1
xdfDefaults <- file.path(XdfDir,"defaultsOnly.xdf")

# Use rxImport again:
rxImport(inData = csvFile,
         outFile = xdfDefaults,
         rowSelection = (default == 1),
         overwrite = TRUE
)



# Use rxGetInfo to check the results. There should be just 10,000 records again,
# and the high and low values of "default" should be (1, 1)
rxGetInfo(xdfDefaults, getVarInfo = TRUE)
rxGetInfo(xdfDefaults, numRows = 10)



################################################################################
# Exercise 6: Specify Variable Types
################################################################################


# When you import data, rxImport() does its best to guess how each variable should
# be stored - numeric, character, factor, date, etc. If you need to specify a 
# different type for a variable, you can use the colClasses argument.

# colClasses lets you specify a type for each variable with a named vector. The
# name of the variable to change is on the left, and the desired type is on the 
# right. That would look something like this:
# colClasses = c(name = "character", age = "numeric", country = "factor") 

# For this exercise, let's look at a new dataset of flights. It has three variables:
# - ArrDelay, a measure of how late a flight arrived (in minutes)
# - CRSDepTime, the flight's departure time on the 24-hour clock as a numeric variable
#   (0 is midnight, 6.0 is 6 in the morning, 18.5 is 6 in the evening, etc)
# - DayOfWeek, the day on which the plane departed


# Here's the CSV path
airlineCsv <- file.path(rxGetOption("sampleDataDir"), "AirlineDemoSmall.csv")

# Let's make a new XDF
airlineXdf <- file.path(XdfDir,"airline.Xdf")

rxImport(inData = airlineCsv, 
         outFile = airlineXdf,
         overwrite = TRUE)

rxGetInfo(airlineXdf, numRows = 10)

# Now that we've imported the XDF, let's see how the variables were imported:

rxGetVarInfo(airlineXdf)

# CRSDepTime looks like it was correctly imported as a numeric variable.
# ArrDelay has been imported as a character vector, which is definitely wrong.
# DayOfWeek is a character - but to use it in many statistical algorithms, we
# need it to be a factor.

# One more thing: missing values in this dataset are denoted with an "M", so I'm
# setting missingValueString = "M" so they'll be properly converted into NA.

# Use rxImport to import airlineCsv into airlineXdf, and set the colClasses
# argument so that arrDelay is an integer and DayOfWeek is a factor
rxImport(inData = airlineCsv,
         outFile = airlineXdf,
         colClasses = c(arrDelay = "integer", DayOfWeek = "factor"),
         missingValueString = "M",
         overwrite = TRUE
)
#rxImport(inData = airlineCsv,
#         outFile = airlineXdf,
#         colClasses = c(arrDelay = "integer", DayOfWeek = "ordered"),
#         missingValueString = "M",
#         overwrite = TRUE
#)

# Check the results with rxGetVarInfo
rxGetVarInfo(airlineXdf)





################################################################################
# Exercise 7: Advanced Variable Controls
################################################################################


# Sometimes you need even more control over how a variable is imported. The
# colInfo argument lets you specify types, just like colClasses, but it also
# lets you rename variables, set the levels in a factor, and more.

# colInfo is the most complex argument we've seen so far, so read the description
# and review the example below carefully.
# colInfo takes a list. 
# Each item in that list is a variable in the original dataset (CRSDepTime and DayOfWeek)
# Each variable gets *another* list.
# Each item in the *variable's* list is an argument that modifies the imported variable:
# - type lets you specify the variable type, just like colClasses;
# - newName will change the variable's name to whatever text you provide;
# - levels lets you provide a list of levels that a factor should have.

# Reading in the airline data with colClasses helped, but we could do more. This
# time, use colInfo  to:
# 1. Convert ArrDelay into an integer
# 2. Change the name of CRSDepTime to DepartureTime (with the newName argument)
# 3. Re-arrange the levels of DayOfWeek so Sunday is first (with the levels argument)

rxImport(inData = airlineCsv,
         outFile = airlineXdf,
         colInfo = list(
             ArrDelay = list(type = "integer"),
             CRSDepTime = list(newName = "DepartureTime"),
             DayOfWeek = list(type = "factor",
                              levels = c("Sunday", "Monday", "Tuesday",
                                         "Wednesday", "Thursday",
                                         "Friday", "Saturday"
         ))),
         missingValueString = "M",
         overwrite = TRUE)

# Check the results. ArrDelay should be numeric or integer, CRSDepTime renamed to
# DepTime24, and DayOfWeek should be a factor with Sunday as its first level.
rxGetVarInfo(airlineXdf)
rxGetInfo(airlineXdf,numRows = 10000)


################################################################################
# Exercise 8: Create or modify variables
################################################################################
# You can use the transforms argument to rxImport to create new variables or modify existing variables
# when you initially read the data into .xdf format.
# in this excercise, we will work with claims.txt data
inFile <- file.path(rxGetOption("sampleDataDir"), "claims.txt")
outfile <- file.path(XdfDir, "claimsXform.xdf")
#For example, we could create a new variable, logcost, by taking the log of the existing cost variable as follows:
claimsDS <-rxImport(inFile, outFile = outfile, transforms=list(logcost=log(cost)))
rxGetInfo(claimsDS, getVarInfo=TRUE)

################################################################################
# Exercise 9: Change compression level
################################################################################
# An XDF file is much smaller than a CSV file because it is compressed.
# You can set the compression level using xdfCompressionLevel, an integer in the range of -1 to 9.
# The higher the value, the greater the amount of compression - resulting in smaller files but a longer time to create them.
# the default is: rxGetOption("xdfCompressionLevel")
# try rxImport with different values



################################################################################
# Exercise 9: Import SAS data
################################################################################
#The rxImport function can also be used to read data from SAS files having a .sas7bdat or .sd7 extension.
#You do not need to have SAS installed on your computer; simple file access is used to read in the data.
#The sample directory contains a SAS version of the claims data as claims.sas7bdat.
#We can read it into .xdf format most simply as follows:
inFileSAS <- file.path(rxGetOption("sampleDataDir"), "claims.sas7bdat")
xdfFileSAS <- file.path(XdfDir, "claimsSAS.xdf")
claimsSAS <- rxImport(inData = inFileSAS, outFile = xdfFileSAS)
rxGetInfo(claimsSAS, getVarInfo=TRUE)

################################################################################
# Exercise 10: Import SPSS data
################################################################################
#The rxImport function can also be used to read data from SPSS files. 
#The sample directory contains an SPSS version of the claims data as claims.sav.
#We can read it into .xdf format as follows:
inFileSpss <- file.path(rxGetOption("sampleDataDir"), "claims.sav")
xdfFileSpss <- file.path(XdfDir, "claimsSpss.xdf")
claimsSpss <- rxImport(inData = inFileSpss, outFile = xdfFileSpss)
rxGetInfo(claimsSpss, getVarInfo=TRUE)

