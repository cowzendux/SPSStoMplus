* Create Mplus code to load data set
* Created by Jamie DeCoster
* Usage: importMplus(name of SPSS data file to convert)
* Creates a subdirectory off the current directory called "Mplus data" that contains a 
* tab-delimited textfile with the data and a textfile with the code required to import the data.
* The data file will have the same filename as the original dataset but will have the extension .dat
* The import file will have the same filename as the original data set but will have the extension .inp

*********
* Version history
*********
* 2011-07-16 Created
* 2011-07-17 Added code to write mplus input file
* 2011-07-18 Added missing values
* 2011-07-25 Added renaming of variables
* 2011-07-26 Corrected the file path in the Mplus input file
* 2011-08-12 Automatically recodes string variables into numeric variables
* 2011-09-26 Automatically replaces . with _
* 2011-12-11 Allows the program to run when there are no string variables
   Added modification indices
* 2012-03-01 Saves a file that just has the variable list
* 2012-03-07 Added a ; at the end of the variable list file
* 2012-07-06 Added stdyx to output
   Changed variables in date format to numeric format
   Renamed file and function to "SPSStoMplus"
* 2012-07-07 Corrected an error that occurred when there were no date variables
* 2012-09-07 Converted adate and time variables to numeric
* 2012-11-18 Removed modindices statement from output
* 2013-01-29 Fixed an error with renaming variables with long names
* 2013-08-07 Changed the filename line split so that it doesn't leave
    a space at the end of a line
* 2013-09-08 Reordered variables in active data set after exporting
* 2013-09-13 Added leading zeroes to renamed variable names
* 2014-03-13 Replaces non-alphanumeric characters in variable names with _

******
* What does the program do?
******
* 1) Saves the SPSS file as a tab-delimited text file
* 2) Writes the Mplus input file
* 3) Changes all missing values to -999
* 4) Truncates all variable names to 8 characters
* 5) Renames any variables that have conflicting names when truncated
* 6) Recodes any string variables into numeric variables
* 7) Replaces all non-alphanumeric characters in variable names with _
* 8) Changes variables in date format to numeric format. It codes the dates as
   the number of seconds since October 14, 1582 (which is how they are stored in SPSS).

set printback=off.
begin program python.
import spss, os

def SPSStoMplus(fileloc):

# Identify the different parts of the filename
	(filepath, filename) = os.path.split(fileloc)
	(fname, fext) = os.path.splitext(filename)

# split path into multiple lines
 splitpoint = int(len(filepath)/2)
 while (filepath[splitpoint-1] == " " or filepath[splitpoint] == " "):
  splitpoint += 1
	filepath1 = filepath[:splitpoint]
	filepath2 = filepath[splitpoint:]

# Open data set
	submitstring = """GET FILE=
	'%s' +
	'%s' +
	'/%s'.
DATASET NAME $DataSet WINDOW=FRONT.""" %(filepath1, filepath2, filename)
	print submitstring
	spss.Submit(submitstring)


#########
# Rename variables with names > 8 characters
#########
	print """\n***********
Renaming names > 8 characters
***********"""
 print spss.GetVariableCount()
	for t in range(spss.GetVariableCount()):
		if (len(spss.GetVariableName(t)) > 8):
			name = spss.GetVariableName(t)[0:8]
			for i in range(spss.GetVariableCount()):
				compname = spss.GetVariableName(i)
				if (name.lower() == compname.lower()):
					name = "var" + "%05d" %(t+1)
			submitstring = "rename variables (%s = %s)." %(spss.GetVariableName(t), name)
			print submitstring
			spss.Submit(submitstring)

##########
# Replace non-alphanumeric characters with _ in the variable names
##########
	print """\n***********
Replacing non-alphanumeric with _
***********"""
 nonalphanumeric = [".", "@", "#", "$"]
	for t in range(spss.GetVariableCount()):
		oldname = spss.GetVariableName(t)
		newname = ""
		for i in range(len(oldname)):
			if(oldname[i] in nonalphanumeric):
				newname = newname +"_"
			else:
				newname = newname+oldname[i]
		for i in range(t):
			compname = spss.GetVariableName(i)
			if (newname.lower() == compname.lower()):
				newname = "var" + str(t+1)
		if (oldname != newname):
			submitstring = "rename variables (%s = %s)." %(oldname, newname)
			print submitstring
			spss.Submit(submitstring)

# Obtain lists of variables in the dataset
	varlist = []
	numericlist = []
	stringlist = []
	for t in range(spss.GetVariableCount()):
		varlist.append(spss.GetVariableName(t))
		if (spss.GetVariableType(t) == 0):
			numericlist.append(spss.GetVariableName(t))
		else:
			stringlist.append(spss.GetVariableName(t))

###########
# Automatically recode string variables into numeric variables
###########
# First renaming string variables so the new numeric vars can take the 
# original variable names
	print """\n***********
Recoding string variables into numeric variables
***********"""
	submitstring = "rename variables"
	for var in stringlist:
		submitstring = submitstring + "\n " + var + "=" + var + "_str"
	submitstring = submitstring + "."
	print submitstring
	spss.Submit(submitstring)

# Recoding variables
 if (len(stringlist) > 0):
 	submitstring = "AUTORECODE VARIABLES="
	 for var in stringlist:
		 submitstring = submitstring + "\n " + var + "_str"
 	submitstring = submitstring + "\n /into"
	 for var in stringlist:
		 submitstring = submitstring + "\n " + var
 	submitstring = submitstring + """
   /BLANK=MISSING
   /PRINT."""
 	print submitstring
	 spss.Submit(submitstring)
	
# Dropping string variables
	submitstring = "delete variables"
	for var in stringlist:
		submitstring = submitstring + "\n " + var + "_str"
	submitstring = submitstring + "."
	print submitstring
	spss.Submit(submitstring)

# Set all missing values to be -999
	print """\n***********
Setting missing values to be -999
***********"""
	submitstring = "RECODE "
	for var in varlist:
		submitstring = submitstring + " " + var + "\n"
	submitstring = submitstring + """ (MISSING=-999).
EXECUTE."""
	print submitstring
	spss.Submit(submitstring)

########
# Convert date and time variables to numeric
########
# SPSS actually stores dates as the number of seconds that have elapsed since October 14, 1582.
# This syntax takes variables with a date type and puts them in their natural numeric form

 submitstring = """numeric ddate7663804 (f11.0).
alter type ddate7663804 (date11).
ALTER TYPE ALL (DATE = F11.0).
alter type ddate7663804 (adate11).
ALTER TYPE ALL (ADATE = F11.0).
alter type ddate7663804 (time11).
ALTER TYPE ALL (TIME = F11.0).

delete variables ddate7663804."""
 print submitstring
 spss.Submit(submitstring)

######
# Reorder variables in active data set
######
 submitstring = """MATCH FILES /FILE=*
  /keep="""
 for var in varlist:
		submitstring = submitstring + "\n " + var
 submitstring = submitstring + """.
EXECUTE."""
 spss.Submit(submitstring)

############
# Create files 
############


# Create Mplus data subdirectory if it does not exist
	if not os.path.exists(filepath + "/Mplus data"):
		os.mkdir(filepath + "/Mplus data")

# Save data as a tab-delimited text file
	submitstring = """SAVE TRANSLATE OUTFILE=
	'%s' +
	'%s' +
	'/Mplus data/' +
	'%s.dat'
  /TYPE=TAB
  /MAP
  /REPLACE
  /CELLS=VALUES
	/keep
""" %(filepath1, filepath2, fname)
	for var in varlist:
		submitstring = submitstring + "\n " + var
	submitstring = submitstring + "."
	print submitstring
	spss.Submit(submitstring)


########
# Create Mplus input file
########
	inptext = """TITLE:


DATA:
File is '%s
%s/Mplus data
/%s.dat';

VARIABLE:
Names are """ %(filepath1, filepath2, fname)

	for var in varlist:
		inptext = inptext + "\n" + var
	inptext = inptext + """;

MISSING ARE ALL (-999);

ANALYSIS:


MODEL:


OUTPUT:
stdyx;
"""

	f = open(filepath + "/Mplus data/" + fname + ".inp", 'w')
	f.write(inptext)
	f.close()

###########
# Create text file with just the variable list
###########

 inptext = """VARIABLE:
Names are """

 for var in varlist:
	 inptext = inptext + "\n" + var
	inptext = inptext + ";"

 f = open(filepath + "/Mplus data/" + fname + " vars.inp", 'w')
 f.write(inptext)
 f.close()

end program python.
set printback=on.
