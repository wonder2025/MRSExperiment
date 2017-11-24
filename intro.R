list.files(rxGetOption("sampleDataDir"))
inDataFile <- file.path(rxGetOption("sampleDataDir"), "mortDefaultSmall2000.csv")
mortData <- rxImport(inData = inDataFile)
class(mortData)
#mortDataXDF<-file.path(rxGetOption("sampleDataDir"),"mortDataXDF.xdf")
mortDataXDF<-file.path("d:","mortDataXDF.xdf")
mortData <- rxImport(inData = inDataFile,outFile = mortDataXDF)
rxGetInfo(mortDataXDF)

rxImport(inData = inDataFile,outFile = mortDataXDF,rowsPerRead = 200,overwrite = TRUE)

rxGetInfo(mortDataXDF,getVarInfo = TRUE,getBlockSizes = 100)