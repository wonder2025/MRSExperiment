################################################################################
# Microsoft R Server: Data Manipulation Examples
# This script is based on https://github.com/mmparker-msft/intro_to_mrs  
################################################################################




################################################################################
#  Dataset: Flights Data of New York City in 2013
################################################################################

# In this module, we'll use a dataset of all the flights originating in the
# three major airports of New York City in 2013 (from the R package 
# 'nycflights13' - thanks to its authors for making it available).

install.packages("nycflights13")
library(nycflights13)


#################################
# Exercise 1
#################################


#take flights data
flights <- nycflights13::flights
dim(flights)
# Put it in an XDF file called:
flightsXdf <- file.path(XdfDir, "flights.xdf")
rxImport(inData = flights,
         outFile = flightsXdf,
         overwrite = TRUE)


# Check the results
rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5)


# Set XDF info
rxSetInfo(data = flightsXdf,
          description = "flights originating in the three major airports of New York City in 2013")
rxGetInfo(flightsXdf, getVarInfo = TRUE)

#Set variable info
rxSetVarInfo(varInfo = list(dest = list(newName = "DestCode", description = "Destination Airport Code"),
                            origin = list(newName = "OriginCode", description = "Origin Airport Code")),
             data = flightsXdf)
rxGetVarInfo( flightsXdf )

# Get Variable Info
flightsVarInfo <- rxGetVarInfo(data = flights)
flightsVarInfo$month

# histogram of the month variable
rxHistogram(formula = ~ month, 
            data = flightsXdf)

rxHistogram(formula = ~ arr_delay|month, 
            data = flightsXdf)


################################################################################
# Sorting
################################################################################

# rxSort has three essential arguments, as well as a few others that give it some
# flexiblity. The essential three are inData and outFile (hopefully familiar by
# now), and the argument sortByVars, which takes a vector of the variables to
# use to sort the datasets. That looks something like this:
# sortByVars = c("default", "creditScore")



#################################
# Exercise 2
#################################


# To start with, use rxSort to sort flightsXdf by arrival delay (arr_delay)

# Here's a path to a new XDF file to write to:
flightsSorted <- file.path(XdfDir,"flights_sorted.xdf")


# Write your rxSort here:
rxSort(inData = flightsXdf,
       outFile = flightsSorted,
       sortByVars = "arr_delay",
       overwrite = TRUE,
       decreasing = TRUE)


# Check the results: what values of arr_delay are at the top now?
rxGetInfo(flightsSorted, getVarInfo = TRUE, numRows = 10)
# or using rxDataStep
df<-rxDataStep(flightsSorted, numRows = 10)



class(df)
#################################
# Exercise 3
#################################


# Maybe it would be more useful to sort by *decreasing* arr_delay.
# In rxSort, you can do that by setting decreasing = TRUE
# Try that here:
rxSort(inData = flightsXdf,
       outFile = flightsSorted,
       sortByVars = "arr_delay",
       decreasing = TRUE,
       overwrite = TRUE)


# Check the results - should be a little more interesting!
rxDataStep(flightsSorted, numRows = 10)




#################################
# Exercise 4
#################################

# rxSort is also the function for removing duplicate records from a dataset.
# When you set removeDupKeys = TRUE, rxSort will sort the dataset, but keep only
# the first record for each unique combination of the sortByVars you specify.

# Use rxSort to create a dataset with one record for each unique carrier in
# flightsXdf.
# (There are better ways to do this in practice, but try it to be sure you
# understand how to apply the function)
uniqueCarriers <- file.path(XdfDir, "uniqueCarriers.xdf")

rxSort(inData = flightsXdf,
       outFile = uniqueCarriers,
       sortByVars = "carrier",
       removeDupKeys = TRUE,
       overwrite = TRUE)



# Check the results - there should be 16 rows, each with a different carrier:
rxDataStep(uniqueCarriers)







################################################################################
# Merging
################################################################################


# Now have a set of all of the unique carriers in the data - but the variable is
# just two-letter codes. Which codes correspond to which airlines?



#################################
# Exercise 5
#################################

# Use rxMerge to merge the airlines data ("airlines.xdf") onto the 
# de-duplicated dataset you created in the previous exercise (uniqueCarriers).

# rxMerge has a few key arguments:
# - inData1 and inData2: the two datasets to merge
# - outFile: an XDF file to write to
# - type: the type of join you want (try these: "left", "inner", "outer")
# - matchVars: the name of the variable(s) that links the two tables

#take airlines data
airlines <- nycflights13::airlines
dim(airlines)
# airlines XDF:
airlinesXdf <- file.path(XdfDir, "airlines.xdf")

# import airlines to XDF
rxImport(inData = airlines,
         outFile = airlinesXdf)



# Check the results
rxGetInfo(airlinesXdf, getVarInfo = TRUE,numRows = 10)

# prepare a file for the results:
carrier_decoded <- file.path(XdfDir, "carrier_decoded.xdf")


# Write your rxMerge here:
rxMerge(inData1 = uniqueCarriers,
        inData2 = airlinesXdf,
        outFile = carrier_decoded,
        overwrite = TRUE,
        
        # Type of join
        type = "left",
        
        # Name the key variable(s)
        matchVars = "carrier"
)



# Check the results
rxDataStep(carrier_decoded)


# Looking just at the carrier variables:
rxDataStep(carrier_decoded, varsToKeep = c("carrier", "name"))










################################################################################
# Creating and Modifying Variables
################################################################################

# The main function for creating and modifying variables in MRS is rxDataStep().
# The transforms argument takes a list() of *named elements*, which would look
# something like this:
# transforms = list( newVar = x / y, anotherVar = x^3)
# Each element in the list() is a new variable we want to create, or an
# existing variable we want to modify. The *name* of the element (newVar and
# anotherVar) goes on the left-hand side of the = sign. The code to compute the
# variable is an R expression that goes on the right-hand side. Just about any
# R expression will work, but see below for some exceptions.

rxGetInfo(flightsXdf, numRows = 10)
# For example, imagine I want to create a variable that tells me the day of week
# for all of the departures (Monday, Tuesday, etc).
# First, I need to create a proper Date variable from the year, month, and day
# variables. And then I need to print the day of the week for each of those.
# That would look like this:
rxDataStep(inData = flightsXdf,
           outFile = flightsXdf,
           overwrite = TRUE,
           
           # My list of transforms
           transforms = list( 

               # First, create the date by combining year, month, and day
               flightDate = as.Date(paste(year, month, day, sep = "-")),
               
               # Then format to day of week
               dayOfWeek = format(flightDate, "%A")

           )
)


# Check the results
rxDataStep(flightsXdf, numRows = 5)




#################################
# Exercise 6
#################################


# Use rxDataStep to calculate the airspeed (in miles per hour) of each flight,
# using the distance and air_time variables from flightsXdf. 
# Take note: air_time is in minutes!

rxDataStep(inData = flightsXdf,
           outFile = flightsXdf,
           overwrite = TRUE,
           transforms = list( speed = distance / (air_time / 60) )
)


# Check the results. Your minimum speed should be 76.8, and max 703.4
rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5)



##########################################################################################
# embedded vs. external transformation 
##########################################################################################
#Embedded transformations provide instructions within a formula, through arguments on a function.
# as in the previous examples.

#Externally defined functions provide data manipulation instructions in an outer function,
# which is then referenced by rxDataStep.

# for example, let's work with the CensusWorkers.xdf
censusWorkers <- file.path(rxGetOption("sampleDataDir"), "CensusWorkers.xdf")
rxGetInfo(censusWorkers,numRows = 2)
# Option 1: Construct a new variable using an embedded transformation argument
NewDS <- rxDataStep (inData = censusWorkers, outFile = file.path(getwd(), "newCensusWorkers.xdf"),
                       transforms = list(ageFactor = cut(age, breaks=seq(from = 20, to = 70, by = 5), 
                                                         right = FALSE)), overwrite=TRUE)
# Return variable metadata; ageFactor is a new variable
rxGetInfo(NewDS, numRows = 5)
rxGetVarInfo(NewDS)

# Option 2: Construct a new variable using an external function and rxDataStep
ageTransform <- function(dataList)
{
  dataList$ageFactor <- cut(dataList$age, breaks=seq(from = 20, to = 70, 
                                                     by = 5), right = FALSE)
  return(dataList)
}

NewDS1 <- rxDataStep(inData = censusWorkers, outFile = file.path(getwd(), "newCensusWorkers1.xdf"),
                      transformFunc = ageTransform, transformVars=c("age"), overwrite=TRUE)

# Return variable metadata; it is identical to that of option 1
rxGetInfo(NewDS1, numRows = 5)
rxGetVarInfo(NewDS1)



##########################################################################################
# Using rxDataStep to Re-Blocking an .xdf File (re-divide the file with a new block size)
##########################################################################################

fileName <- file.path(rxGetOption("sampleDataDir"), "CensusWorkers.xdf")
rxGetInfo(fileName, getBlockSizes = TRUE)

# in this xdf file, the number of rows per block varies from a low of 1799 to a high of 131,234.
#To create a new file with more even-sized blocks, use the rowsPerRead argument in rxDataStep:
newFile <- "censusWorkersEvenBlocks.xdf"
rxDataStep(inData = fileName, outFile = newFile, rowsPerRead = 50000,overwrite = TRUE)
rxGetInfo(newFile, getBlockSizes = TRUE)  
#The new file has blocks sizes of 60,000 for all but the last slightly smaller block

################################################################################
# Factors
################################################################################

# In a way, factors are also "complex" - if we just use R's factor() function
# to create them inside rxDataStep(), they could have different (and 
# incompatible) levels on different chunks. So to create factors in Microsoft R,
# we'll usually use the function rxFactors().

# The key argument in rxFactors() is factorInfo, which is a bit like rxDataStep's
# transforms argument. Just like transforms, factorInfo takes a list of named
# elements, and each of those elements corresponds to a new variable you'd like
# to create.

# But instead of taking R expressions, each element in factorInfo takes 
# *another* list. Each element in *that* list gives rxFactor some information
# about how to create/modify the factor in question. At the simplest, you can
# just specify a variable to convert to a factor with the argument varName.
# Here, I'll convert the 'name' variable in airlinesXdf to a factor:
rxGetInfo(airlinesXdf, getVarInfo = TRUE, numRows = 10)
rxFactors(inData = airlinesXdf,
          outFile = airlinesXdf,
          overwrite = TRUE,
          factorInfo = list( 
              name_Factor = list(varName = "name") 
          )

)

# Check the results
rxGetVarInfo(airlinesXdf)




# You can also specify the exact levels you want for the factor with the
# levels argument, which is used in conjunction with varName like this:
rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5, varsToKeep = "origin")
?rxFactors
rxFactors(inData = flightsXdf,
          outFile = flightsXdf,
          overwrite = TRUE,
          
          factorInfo = list( 
              origin_Factor = list(varName = "origin",
                                   levels = c("EWR", "LGA", "JFK")
              )
          )
          
)


# Check the results
rxGetVarInfo(flightsXdf, varsToKeep = c("origin", "origin_Factor"))



#################################
# Exercise 7
#################################



# Use rxFactors to convert the dayOfWeek variable into a factor.
# Use the newLevels argument to specify the order of the days in an order you
# prefer (Sunday first, Monday first, etc.)


rxFactors(inData = flightsXdf,
          outFile = flightsXdf,
          overwrite = TRUE,
          factorInfo = list( dayOfWeek_Factor = list(
                                 varName = "dayOfWeek",
                                 levels = c("Sunday", "Monday", "Tuesday",
                                            "Wednesday", "Thursday", "Friday",
                                            "Saturday")
                             )
          )
)



# Check the results
rxGetVarInfo(flightsXdf)

