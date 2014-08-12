#SPSStoMplus

SPSS Python Extension function to export SPSS data to Mplus

Creates a subdirectory off the current directory called "Mplus data" that contains a tab-delimited textfile with the data and a textfile with the code required to import the data. The data file will have the same filename as the original dataset but will have the extension .dat. The import file will have the same filename as the original data set but will have the extension .inp. Will also create a file just containing the variables in the data set so that programs built off of the original .inp file can be updated easily.

##Usage: *SPSStoMplus(fileloc)*
* fileloc = name of SPSS data file to convert

##Example: *SPSStoMplus("C:/users/jamie/workspace/Project/Data/SPSSfile.sav")*
* Will load the file "C:/users/jamie/workspace/Project/Data/SPSSfile.sav", convert it to be consistent with Mplus guidelines, and save the data in a text file named 
"C:/users/jamie/workspace/Project/Data/Mplus data/SPSSfile.dat". It will also create a skeleton .inp file named C:/users/jamie/workspace/Project/Data/Mplus data/SPSSfile.inp" that will load the data and a variable list called C:/users/jamie/workspace/Project/Data/Mplus data/SPSSfile.var that contains a list of the variables in the data file.

##What does the program do specifically?

1. Saves the SPSS file as a tab-delimited text file
2. Writes the Mplus input file
3. Changes all missing values to -999
4. Truncates all variable names to 8 characters
5. Renames any variables that have conflicting names when truncated
6. Recodes any string variables into numeric variables
7. Replaces all non-alphanumeric characters in variable names with _
8. Changes variables in date format to numeric format. It codes the dates as the number of seconds since October 14, 1582 (which is how they are stored in SPSS).
