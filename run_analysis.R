if (!file.exists('getdata-projectfiles-UCI HAR Dataset.zip')) {
  print('Retrieving raw data...')
  download.file(
    'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip',
    method='curl',
    destfile='getdata-projectfiles-UCI HAR Dataset.zip'
  )
}
if (!file.exists('UCI HAR Dataset')) {
  print('Unpacking raw data...')
  unzip('getdata-projectfiles-UCI HAR Dataset.zip')
}


print('Parsing metadata...')

# Identify the data features
features <- read.table('UCI HAR Dataset/features.txt', header=FALSE)
names(features) <- c('feature_id', 'feature_name')
features <- subset(features, grepl('-(mean|std)\\(\\)-(X|Y|Z)', feature_name))
features$feature_name <- gsub('\\(\\)', '', features$feature_name)
features$feature_name <- gsub('-std', '-stdev', features$feature_name)

# Identify the activity types
activities <- read.table('UCI HAR Dataset/activity_labels.txt')
names(activities) <- c('activity_id', 'activity_name')


print('Importing raw datasets...')

importDataSet <- function (dataSetName) {
  dirPrefix <- paste('UCI HAR Dataset/', dataSetName, sep='')
  
  # Get the main data
  main <- read.table(paste(dirPrefix, '/X_', dataSetName, '.txt', sep=''), header=FALSE)
  main <- main[, features$feature_id]
  names(main) <- features$feature_name
  
  # Get the subjects
  subjects <- read.table(paste(dirPrefix, '/subject_', dataSetName, '.txt', sep=''), header=FALSE)
  names(subjects) <- c('subject_id')
  
  # Get the activities
  activities <- read.table(paste(dirPrefix, '/y_', dataSetName, '.txt', sep=''), header=FALSE)
  names(activities) <- c('activity_id')
  
  # Merge it all together
  cbind(subjects, activities, main)
}

trainingData <- importDataSet('train')
testData <- importDataSet('test')


print('Merging datsets...')
allData <- rbind(trainingData, testData)
allData <- merge(activities, allData, by.x=c('activity_id'), by.y=c('activity_id'))
remove('trainingData', 'testData')


print('Calculating summaries...')
summaryData <- aggregate(
  allData[, 4:ncol(allData)],
  by=list(
    subject=allData$subject_id,
    activity=allData$activity_name
  ),
  mean,
  length.warning=FALSE
)
names(summaryData)[3:ncol(summaryData)] <- paste0(names(summaryData)[3:ncol(summaryData)], '-avg')

# Save the summaries to a file
write.table(summaryData, 'output.txt', row.names=FALSE)
print('Summary dataset written to "output.txt".')


# Clean up
remove('activities', 'features', 'importDataSet')
print('All done!')