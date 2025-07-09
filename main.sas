/*
	- CSV FILE = "healthcare_dataset"
	- CLEANING & PREPROCESSED FILE = "healthcare_cleaned"
*/

/*testing*/
/*
	- CSV FILE = "healthcare_dataset"
	- CLEANING & PREPROCESSED FILE = "healthcare_cleaned"
*/
DATA lab.healthcare_dataset;
    SET lab.healthcare_dataset;
    IF Age = 150 THEN Age = 95;
RUN;
 
DATA lab.healthcare_dataset;
    SET lab.healthcare_dataset; 
    IF "Billing Amount"n = 1000000 THEN "Billing Amount"n = 53000;
RUN;
 
PROC FREQ DATA=lab.healthcare_dataset;
RUN;
 
PROC FREQ DATA=lab.healthcare_cleaned;
RUN;

/*CLEANING & PREPROCESSING*/
 
/*1. HANDLE MISSING VALUES -------------------------------------------------------------------------------------------------*/

/* 1.1. Identify missing values in the data - Done*/

	/*number of missing values for numeric columns - Done*/

PROC MEANS DATA=lab.healthcare_dataset N NMISS;

RUN;
 
	/*missing counts for all columns*/

PROC FREQ DATA=lab.healthcare_dataset;

RUN;

/*1.2. Handle categorical missing value

	- Gender: impute "unknown"

	- Test Result: impute with "unknown" 

	- Admission type: unknown */

DATA lab.healthcare_cleaned;

   SET lab.healthcare_dataset;

   /* Impute missing categorical values with 'Unknown' */

   IF Gender = " " THEN Gender = "unknown";

   IF "Test Results"n = " " THEN "Test Results"n = "unknown";

   IF "Admission Type"n = " " THEN "Admission Type"n = "unknown";

RUN;
 
 
/*1.3 handles numerical data:

	- Age : mean

	- Billing amount : mean*/

/*standardizes the age to convert negative to positive*/

DATA lab.healthcare_cleaned;

   SET lab.healthcare_cleaned;

   /* Convert negative Age values to positive */

   Age = ABS(Age);

RUN;
 
/*standardize the billing amount*/

DATA lab.healthcare_cleaned;

   SET lab.healthcare_cleaned;

   /* Convert negative Billing Amount values to positive */

   "Billing Amount"n = ABS("Billing Amount"n);

RUN;
 
/*handle age & billing amount*/

/*Displaying mean*/

PROC MEANS DATA=lab.healthcare_cleaned N MEAN;

   VAR Age "Billing Amount"n;

   OUTPUT OUT=stats MEAN=Mean_Age Mean_Billing;

RUN;
 
 
/* Calculate the mean for Age and Billing Amount, excluding missing values */

PROC MEANS DATA=lab.healthcare_cleaned NOPRINT;

   VAR Age "Billing Amount"n;

   OUTPUT OUT=mean_values MEAN(Age)=mean_Age MEAN("Billing Amount"n)=mean_Billing;

RUN;
 
/* Impute missing values with the calculated means */

DATA lab.healthcare_cleaned;

   SET lab.healthcare_cleaned;

   IF Age = . THEN Age = mean_Age;

   IF "Billing Amount"n = . THEN "Billing Amount"n = mean_Billing;

   /* Merge with mean values dataset */

   IF _N_ = 1 THEN SET mean_values;

   DROP mean_Age mean_Billing;

RUN;
 
/*verifying*/

PROC MEANS DATA=lab.healthcare_cleaned N NMISS MEAN;

   VAR Age "Billing Amount"n;

RUN;
 
 
/*2. HANDLING INCONSISTENCIES -------------------------------------------------------------------------------------------------*/

/*2.0 Removing duplicates*/

/*check rows

	- before ; 

	- after ; */

PROC SQL;

    SELECT COUNT(*) AS Total_Rows 

    FROM LAB.HEALTHCARE_CLEANED;

QUIT;
 
/*remove duplicates*/

PROC SORT DATA=lab.healthcare_cleaned OUT=lab.healthcare_cleaned NODUPKEY;

    BY _ALL_;

RUN;
 
/*2.1. (NAME) making all the names in the Name column lowercase*/

DATA lab.healthcare_cleaned;

    SET lab.healthcare_cleaned;

    Name = LOWCASE(Name);

RUN;
 
/*this one checks all names with mr, mrs, ms*/

PROC SQL;

   CREATE TABLE lab.names_with_titles AS 

   SELECT * 

   FROM lab.healthcare_cleaned

   WHERE INDEX(Name, 'mr') > 0 OR INDEX(Name, 'mrs') > 0 OR INDEX(Name, 'ms') > 0;

QUIT;
 
/*removes mr, mrs & ms from the name column*/

DATA lab.healthcare_cleaned;

   SET lab.healthcare_cleaned;

   /* Remove 'mr.' and 'mrs.' from the Name column */

   Name = TRANWRD(Name, 'mr.', '');

   Name = TRANWRD(Name, 'mrs.', '');

   Name = TRANWRD(Name, 'ms.', '');

RUN;
 
/*after names are all lower case make the first letter of the first and last name capital*/

DATA lab.healthcare_cleaned;

    SET lab.healthcare_cleaned;

    /* Capitalize first letter of each word in the Name column */

    Name = PROPCASE(Name);

RUN;
 
 
/*printing all the occurences and the rows*/

/* Step 1: Identify names that appear more than once */

PROC FREQ DATA=lab.healthcare_cleaned NOPRINT;

    TABLES Name / OUT=NameFreq (WHERE=(COUNT > 1));

RUN;

/* Step 2: Filter the original dataset to include only rows with duplicate names */

PROC SQL;

    CREATE TABLE lab.Duplicates AS

    SELECT A.*

    FROM lab.healthcare_cleaned AS A

    INNER JOIN NameFreq AS B

    ON A.Name = B.Name;

QUIT;

/* Step 3: Print the entire rows that meet the condition */

PROC PRINT DATA=lab.Duplicates;

RUN;
 
/*removing duplicates of name records*/

PROC SORT DATA=lab.healthcare_cleaned NODUPKEY;

    BY Name "Date of Admission"n;

RUN;
 
/*checking that duplicates were removed*/

PROC SQL;

    /* Count occurrences of each (Name, Admission_Date) pair */

    CREATE TABLE Duplicate_Check AS

    SELECT Name, "Date of Admission"n, COUNT(*) AS Count

    FROM lab.healthcare_cleaned

    GROUP BY Name, "Date of Admission"n

    HAVING COUNT(*) > 1;

QUIT;

 
/*2.2. (AGE) Making the age column a whole number*/

DATA LAB.HEALTHCARE_CLEANED;

    SET LAB.HEALTHCARE_CLEANED;

    Age = INT(Age);

RUN;
 
/*2.3 (GENDER) standarizing the gender column to only display Male and Female*/
 
DATA lab.healthcare_cleaned;

    SET lab.healthcare_cleaned;

    Gender = UPCASE(Gender);

RUN;
 
 
DATA LAB.HEALTHCARE_CLEANED;

    SET LAB.HEALTHCARE_CLEANED;
 
    /* Standardize gender values */

    IF Gender IN ('M', 'MALE') THEN Gender = 'Male';

    ELSE IF Gender IN ('F', 'FEMALE') THEN Gender = 'Female';

    ELSE IF Gender IN('UNKNOW') THEN Gender = "unknown";

RUN;
 
/*2.4.(BLOOD TYPE) making the blood types all the same format*/

DATA LAB.HEALTHCARE_CLEANED;

    SET LAB.HEALTHCARE_CLEANED;

    /* Convert Blood Type values to uppercase */

    "Blood Type"n = UPCASE("Blood Type"n);
 
RUN;
 
/*2.5. (MEDICAL CONDITION) : fix misspelling*/
 
/*this shows the count of each unique value*/

PROC FREQ DATA = LAB.HEALTHCARE_CLEANED;

	TABLES "Medical Condition"n;

RUN;
 
/*1rst try - works in one go*/

DATA LAB.HEALTHCARE_CLEANED;

    SET LAB.HEALTHCARE_CLEANED;
 
    /* Standardize common misspellings */

    IF "Medical Condition"n IN ('Diabtes', 'Diabete', 'Diabetess', 'Daabetes', 'Ddabetes', 'Dgabetes', 'Diabeces',

                             'Diabeees', 'Diabemes', 'Diabeoes', 'Diaberes', 'Diabeses', 'Diabetcs', 'Diabetee',

                             'Diabetek', 'Diabeteq', 'Diabetms', 'Diabetxs', 'Diabetys', 'Diabezes', 'Diabites',

                             'Diabktes', 'Diabltes', 'Diabutes', 'Diabwtes', 'Diacetes', 'Diagetes', 'Diajetes',

                             'Dianetes', 'Diaqetes', 'Dicbetes', 'Dilbetes', 'Ditbetes', 'Diubetes', 'Diybetes',

                             'Djabetes', 'Doabetes', 'Dpabetes', 'Drabetes', 'Dvabetes', 'aiabetes', 'iiabetes',

                             'kiabetes', 'liabetes', 'niabetes', 'qiabetes', 'xiabetes') 

    THEN "Medical Condition"n = 'Diabetes';
 
    ELSE IF "Medical Condition"n IN ('Hypertensn', 'Hypertensoin', 'HBP', 'Hcpertens', 'Hdpertens', 'Hrpertens',

                                  'Htpertens', 'Hvpertens', 'Hybertens', 'Hygertens', 'Hymertens', 'Hypegtens',

                                  'Hypehtens', 'Hypeitens', 'Hypentens', 'Hyperbens', 'Hyperfens', 'Hyperkens',

                                  'Hypertefs', 'Hypertems', 'Hypertenb', 'Hyperteng', 'Hypertets', 'Hypertfns',

                                  'Hypertins', 'Hypertpns', 'Hyperxens', 'Hypeutens', 'Hypevtens', 'mypertens',

                                  'nypertens', 'qypertens') 

    THEN "Medical Condition"n = 'Hypertension';
 
    ELSE IF "Medical Condition"n IN ('Asthama', 'Asthmaa', 'Abthma', 'Acthma', 'Ahthma', 'Aqthma', 'Asbhma', 'Aschma',

                                  'Asehma', 'Asghma', 'Ashhma', 'Aslhma', 'Asqhma', 'Astema', 'Astfma', 'Asthga',

                                  'Asthha', 'Asthmb', 'Asthmh', 'Asthmi', 'Asthmj', 'Asthml', 'Asthmm', 'Asthmp',

                                  'Asthmu', 'Asthqa', 'Asthta', 'Asthxa', 'Asthza', 'Astlma', 'Astqma', 'Astuma',

                                  'Astxma', 'Asuhma', 'Asyhma', 'Aszhma', 'bsthma', 'dsthma', 'esthma', 'gsthma',

                                  'hsthma', 'lsthma', 'psthma', 'ssthma', 'wsthma') 

    THEN "Medical Condition"n = 'Asthma';
 
    ELSE IF "Medical Condition"n IN ('Pneumona', 'Pneumonnia') 

    THEN "Medical Condition"n = 'Pneumonia';
 
    ELSE IF "Medical Condition"n IN ('Arthrits', 'Arthritiss', 'Afthritis', 'Aothritis', 'Arahritis', 'Ardhritis',

                                  'Arehritis', 'Arghritis', 'Artbritis', 'Artfritis', 'Arthoitis', 'Arthqitis',

                                  'Arthratis', 'Arthretis', 'Arthrftis', 'Arthrgtis', 'Arthribis', 'Arthricis',

                                  'Arthrilis', 'Arthritas', 'Arthritib', 'Arthritic', 'Arthritit', 'Arthritts',

                                  'Arthritvs', 'Arthritxs', 'Arthriuis', 'Arthrntis', 'Arthrttis', 'Arthrwtis',

                                  'Arthtitis', 'Artkritis', 'Artsritis', 'Artwritis', 'Artyritis', 'hrthritis',

                                  'prthritis', 'rrthritis', 'srthritis', 'yrthritis') 

    THEN "Medical Condition"n = 'Arthritis';
 
    ELSE IF "Medical Condition"n IN ('Cadcer', 'Cafcer', 'Cajcer', 'Canaer', 'Cancar', 'Cancbr', 'Canceg', 'Cancek',

                                  'Cancet', 'Cancey', 'Cancfr', 'Cancgr', 'Canckr', 'Canclr', 'Cancor', 'Cancur',

                                  'Canfer', 'Canjer', 'Canner', 'Canoer', 'Canrer', 'Canzer', 'Caucer', 'Cavcer',

                                  'Cfncer', 'Cincer', 'Ckncer', 'Csncer', 'Cvncer', 'aancer', 'gancer', 'pancer',

                                  'zancer') 

    THEN "Medical Condition"n = 'Cancer';
 
    ELSE IF "Medical Condition"n IN ('Obebity', 'Obecity', 'Obegity', 'Obejity', 'Obepity', 'Obesfty', 'Obeshty',

                                  'Obesidy', 'Obesify', 'Obesigy', 'Obesily', 'Obesita', 'Obesitc', 'Obesitd',

                                  'Obesiti', 'Obesitj', 'Obesitq', 'Obesits', 'Obesitu', 'Obesitv', 'Obesitw',

                                  'Obesiyy', 'Obesizy', 'Obeskty', 'Obesmty', 'Obesnty', 'Obesqty', 'Obessty',

                                  'Obesvty', 'Obeswty', 'Obeszty', 'Obetity', 'Obeyity', 'Obezity', 'Obfsity',

                                  'Obhsity', 'Obpsity', 'Obvsity', 'Obwsity', 'Obysity', 'Odesity', 'Ofesity',

                                  'Oiesity', 'Ooesity', 'Oresity', 'cbesity', 'hbesity', 'ibesity', 'lbesity',

                                  'obesity', 'pbesity', 'tbesity', 'zbesity') 

    THEN "Medical Condition"n = 'Obesity';
 
RUN;

 
/*2.6 (Medication) Standardize typos*/

PROC FREQ DATA = LAB.HEALTHCARE_CLEANED;

	TABLES "Medication"n;

RUN;
 
DATA lab.healthcare_cleaned;

    SET lab.healthcare_cleaned;

    Medication = UPCASE(Medication);

RUN;
 
DATA LAB.HEALTHCARE_CLEANED;

    SET LAB.HEALTHCARE_CLEANED;
 
    /* Standardizing medication names */

    IF "Medication"n IN ('AFPIRIN', 'ALPIRIN', 'AOPIRIN', 'AQPIRIN', 'ASBIRIN', 'ASGIRIN', 

                      'ASIIRIN', 'ASKIRIN', 'ASLIRIN', 'ASPARIN', 'ASPGRIN', 'ASPILIN', 

                      'ASPIMIN', 'ASPIOIN', 'ASPIPIN', 'ASPIREN', 'ASPIRIU', 'ASPIRIW', 

                      'ASPIRIZ', 'ASPIRJN', 'ASPIRNN', 'ASPISIN', 'ASPIUIN', 'ASPKRIN', 

                      'ASPPRIN', 'ASPQIRIN', 'ASPSRIN', 'ASPVRIN', 'ASPXRIN', 'ASSIRIN', 

                      'ASWIRIN', 'ASYIRIN', 'GSPIRIN', 'HSPIRIN', 'JSPIRIN', 'NSPIRIN', 

                      'OSPRIN', 'QSPIRIN', 'TSPIRIN', 'YSPIRIN','ASPIRIA', 'ASPIRIN', 'OSPIRIN') 

    THEN "Medication"n = 'Aspirin';
 
    ELSE IF "Medication"n IN ('IAUPROFEN', 'IBDPROFEN', 'IBFPROFEN', 'IBMROFEN', 'IBOPROFEN', 

                           'IBRPROFEN', 'IBUEROFEN', 'IBUPAOFEN', 'IBUPEOFEN', 'IBUPLOFEN', 

                           'IBUPNOFEN', 'IBUPRCFEN', 'IBUPRDFEN', 'IBUPRHFEN', 'IBUPROAEN', 

                           'IBUPROCEN', 'IBUPROFEB', 'IBUPROFED', 'IBUPROFEI', 'IBUPROFEQ', 

                           'IBUPROFER', 'IBUPROFNN', 'IBUPROFSN', 'IBUPROFZN', 'IBUPROGEN', 

                           'IBUPROMEN', 'IBUPROOEN', 'IBUPROSEN', 'IBUPRPFEN', 'IBUPRTFEN', 

                           'IBUPRUFEN', 'IBUPRVFEN', 'IBUPRXFEN', 'IBUPTOFEN', 'IBXPROFEN', 

                           'IBZPROFEN', 'IDUPROFEN', 'IHUPROFEN', 'IJUPROFEN', 'IKUPROFEN', 

                           'IMUPROFEN', 'IOUPROFEN', 'ITUPROFEN', 'IZUPROFEN', 'BBUPROFEN', 

                           'DBUPROFEN', 'FBUPROFEN', 'GBUPROFEN', 'TBUPROFEN','IBMPROFEN', 'IBUPROFEN') 

    THEN "Medication"n = 'Ibuprofen';
 
    ELSE IF "Medication"n IN ('LBPITOR', 'LDPITOR', 'LIDITOR', 'LIFITOR', 'LIHITOR', 'LINITOR', 

                           'LIPBTOR', 'LIPETOR', 'LIPHTOR', 'LIPIDOR', 'LIPIEOR', 'LIPIHOR', 

                           'LIPIIR', 'LIPINOR', 'LIPISOR', 'LIPITHR', 'LIPITIR', 'LIPITJR', 

                           'LIPITOE', 'LIPITOG', 'LIPITOH', 'LIPITOJ', 'LIPITOT', 'LIPITOW', 

                           'LIPITOX', 'LIPITTR', 'LIPITXR', 'LIPIVOR', 'LIPIYOR', 'LIPKTOR', 

                           'LIPOTOR', 'LIPTTOR', 'LIPWTOR', 'LIWITOR', 'LIXITOR', 'LIYITOR', 

                           'LKPITOR', 'LLPITOR', 'LMPITOR', 'LRPITOR', 'LSPITOR', 'LTPITOR', 

                           'LZPITOR', 'BIPITOR', 'GIPITOR', 'JIPITOR', 'NIPITOR', 'OIPITOR', 

                           'QIPITOR', 'TIPITOR', 'WIPITOR', 'XIPITOR', 'ZIPITOR','LIPIIOR', 'LIPITOR', 'LIPITOR') 

    THEN "Medication"n = 'Lipitor';
 
    ELSE IF "Medication"n IN ('PALACETAMOL', 'PANACETAMOL', 'PARACECAMOL', 'PARACEGAMOL', 

                           'PARACEJAMOL', 'PARACETACOL', 'PARACETAIOL', 'PARACETAMBL', 

                           'PARACETAMJL', 'PARACETAMLL', 'PARACETAMNL', 'PARACETAMOD', 

                           'PARACETAMOG', 'PARACETAMOI', 'PARACETAMOJ', 'PARACETAMOM', 

                           'PARACETAMOR', 'PARACETAMOV', 'PARACETAMOW', 'PARACETAXOL', 

                           'PARACETCMOL', 'PARACETFMOL', 'PARACETHMOL', 'PARACETIMOL', 

                           'PARACETJMOL', 'PARACETOMOL', 'PARACETTMOL', 'PARACETZMOL', 

                           'PARACEVAMOL', 'PARACOTAMOL', 'PARACZTAMOL', 'PARALETAMOL', 

                           'PARAQETAMOL', 'PARASETAMOL', 'PARATETAMOL', 'PARAUETAMOL', 

                           'PARAWETAMOL', 'PARBCETAMOL', 'PARCCETAMOL', 'PARGCETAMOL', 

                           'PAROCETAMOL', 'PARSCETAMOL', 'PARWCETAMOL', 'PASACETAMOL', 

                           'PATACETAMOL', 'PAUACETAMOL', 'PIRACETAMOL', 'PLRACETAMOL', 

                           'PXRACETAMOL', 'PYRACETAMOL', 'PZRACETAMOL', 'CARACETAMOL', 

                           'HARACETAMOL', 'OARACETAMOL', 'ZARACETAMOL', 'PARACETAMOL') 

    THEN "Medication"n = 'Paracetamol';
 
    ELSE IF "Medication"n IN ('PEBICILLIN', 'PEEICILLIN', 'PEGICILLIN', 'PEMICILLIN', 'PENICBLLIN', 

                           'PENICICLIN', 'PENICILEIN', 'PENICILIIN', 'PENICILLIB', 'PENICILLWN', 

                           'PENICILZIN', 'PENICIOLIN', 'PENICIPLIN', 'PENICIQLIN', 'PENICLLLIN', 

                           'PENICMLLIN', 'PENICSLLIN', 'PENIIILLIN', 'PENIWILLIN', 'PENWCILLIN', 

                           'PEOICILLIN', 'PEPICILLIN', 'PESICILLIN', 'PEUICILLIN', 'PEWICILLIN', 

                           'PEYICILLIN', 'PEZICILLIN', 'PENICILLIN', 'PENICILLEN', 'IENICILLIN', 

                           'RENICILLIN', 'SENICILLIN', 'VENICILLIN', 'CENICILLIN', 'PMNICILLIN', 'PQNICILLIN', 'PWNICILLIN') 

    THEN "Medication"n = 'Penicillin';

RUN;
 
/*2.7 (Date of Admission & Date of Discharge) data set was checked*/
 
/*2.8 (Billing Amount) round to 2 decimal place*/

DATA lab.healthcare_cleaned;

    SET lab.healthcare_cleaned;

    /* Only round if Billing_Amount is NOT missing */

    IF NOT MISSING("Billing Amount"n) THEN 

        "Billing Amount"n = ROUND("Billing Amount"n, 0.01);

RUN;
 
/*4. Noisy data / Outliers*/

/*_DATA TRANSFORMATION_*/
*1. Normalization (Min-Max Scaling) for Age and Billing Amount*/
/*Calculate the min max values for age and BillingAmount*/

PROC MEANS DATA=lab.healthcare_cleaned N MIN MAX;
	VAR Age "Billing Amount"n;
	OUTPUT OUT=minmax MIN=Min_Age Min_Billing MAX=Max_Age Max_Billing;
RUN;

/*Apply Min-Max Scaling*/
DATA lab.healthcare_cleaned;
	SET lab.healthcare_cleaned;
	IF _N_ = 1 THEN SET Minmax;/*Get Min_Age,Max_Age,Min_Billing,Max_Billing*/
	Age_Normalised = (Age - Min_Age)/(Max_Age-Min_Age);
	BillingAmount_Normalised=("Billing Amount"n-Min_Billing)/(Max_Billing - Min_Billing);
RUN;
 
 
 
/*2. Standardisation(Z-Score transformation)*/
/*Calculate the mean and Standard deviation for Age and BillingAmount*/
PROC MEANS DATA=lab.healthcare_cleaned N MEAN STD;
	VAR Age "Billing AMount"n;
	OUTPUT OUT=meanstd MEAN=Mean_Age Mean_Billing STD=Std_Age Std_Billing;
RUN;

/* Apply Z-score standardization */
DATA lab.healthcare_cleaned;
   SET lab.healthcare_cleaned;
   IF _N_ = 1 THEN SET meanstd; /* Get Mean_Age, Std_Age, Mean_Billing, Std_Billing */
   Age_Standardized = (Age - Mean_Age) / Std_Age;
   BillingAmount_Standardized = ("Billing Amount"n - Mean_Billing) / Std_Billing;
RUN;


/* 3. Creating new variables from existing variables */

/* a. Categorizing age groups */
DATA lab.healthcare_cleaned;
   SET lab.healthcare_cleaned;
   IF Age < 18 THEN Age_Group = "Under 18";
   ELSE IF Age >= 18 AND Age <= 35 THEN Age_Group = "18-35";
   ELSE IF Age >= 36 AND Age <= 55 THEN Age_Group = "36-55";
   ELSE Age_Group = "Over 55";
RUN;

/* b. Binning billing amounts */
DATA lab.healthcare_cleaned;
   SET lab.healthcare_cleaned;
   IF "Billing Amount"n < 1000 THEN Billing_Category = "Low";
   ELSE IF "Billing Amount"n >= 1000 AND "Billing Amount"n <= 3000 THEN Billing_Category = "Medium";
   ELSE Billing_Category = "High";
RUN;

/* c. Interaction and Ration features */
DATA lab.healthcare_cleaned;
   SET lab.healthcare_cleaned;
   
   /* Interaction: Age * Billing Amount */
   Age_Billing_Interaction = Age * "Billing Amount"n;
    /*Create HAS_DIABETES first then run this one. */
   /* Interaction: Age * Has_Diabetes (Indicator) */
   IF "Medical Condition"n = "Diabetes" THEN Has_Diabetes = 1;
   ELSE Has_Diabetes = 0;
   
    /* Ratio: Billing Amount / Age */
   /*Handle Potential division by zero*/
   IF Age > 0 THEN Billing_Per_Age = "Billing Amount"n / Age;
   ELSE Billing_Per_Age = .;/*Assign missing if Age is zero*/
   PUT "Interaction Term Created: Age=" Age "Billing Amount=" "Billing Amount"n " Interaction=" Age_Billing_Interaction; /*DEBUG*/
   PUT "Ratio Feature Created: Age=" Age "Billing Amount=" "Billing Amount"n " Ratio=" Billing_Per_Age; /*DEBUG*/
RUN;


DATA LAB.healthcare_cleaned_final;
    SET lab.healthcare_cleaned;
RUN;

/* --- Descriptive Statistics (Before Cleaning) --- */

TITLE "Descriptive Statistics (Before Cleaning)";

/* Numerical Variables */
PROC MEANS DATA=LAB.HEALTHCARE_DATASET N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3;
    VAR Age "Billing Amount"n; /* Add other numerical variables as needed */
    TITLE "Descriptive Statistics (Before Cleaning): Numerical Variables";
RUN;
TITLE; /* Clear the title after use */

/* Categorical Variables */
PROC FREQ DATA=LAB.HEALTHCARE_DATASET;
    TABLES Gender "Blood Type"n "Medical Condition"n "Admission Type"n "Test Results"n Medication  / NOPRINT OUT=BeforeFreq; /* Add other categorical variables. Store frequency data.*/
    TITLE "Frequencies (Before Cleaning): Categorical Variables";
RUN;
TITLE; /* Clear title */

PROC PRINT DATA=BeforeFreq; /*Print frequency data*/
RUN;

ODS GRAPHICS ON; /* Enable ODS Graphics */

/* Histograms (Before Cleaning) */
PROC SGPLOT DATA=LAB.HEALTHCARE_DATASET;
    HISTOGRAM Age;
    TITLE "Distribution of Age (Before Cleaning)";
    XAXIS LABEL="Age";
    YAXIS LABEL="Frequency";
RUN;

PROC SGPLOT DATA=LAB.HEALTHCARE_DATASET;
    HISTOGRAM "Billing Amount"n;
    TITLE "Distribution of Billing Amount (Before Cleaning)";
    XAXIS LABEL="Billing Amount";
    YAXIS LABEL="Frequency";
RUN;

/* Bar Charts (Before Cleaning) */
PROC SGPLOT DATA=LAB.HEALTHCARE_DATASET;
    VBAR Gender;
    TITLE "Distribution of Gender (Before Cleaning)";
    XAXIS LABEL="Gender";
    YAXIS LABEL="Frequency";
RUN;

PROC SGPLOT DATA=LAB.HEALTHCARE_DATASET;
    VBAR "Medical Condition"n;
    TITLE "Distribution of Medical Conditions (Before Cleaning)";
    XAXIS LABEL="Medical Condition";
    YAXIS LABEL="Frequency";
RUN;

ODS GRAPHICS OFF;

/* Numerical Variables:  Distribution Summary (Before Cleaning) */
PROC UNIVARIATE DATA=LAB.HEALTHCARE_DATASET PLOT NORMAL; /* NORMAL for normality tests. PLOT for histogram and boxplot */
   VAR Age "Billing Amount"n; /* Add other numerical variables as needed */
   TITLE "Univariate Analysis (Before Cleaning): Numerical Variables";
RUN;
TITLE;


/*  AFTER DATA CLEANING                                           */
/* -------------------------------------------------------------- */

/* --- Descriptive Statistics (After Cleaning) --- */

TITLE "Descriptive Statistics (After Cleaning)";

/* Numerical Variables */
PROC MEANS DATA=LAB.HEALTHCARE_CLEANED_FINAL N NMISS MEAN STD MIN MAX Q1 MEDIAN Q3;
    VAR Age "Billing Amount"n; /* Add other numerical variables as needed */
    TITLE "Descriptive Statistics (After Cleaning): Numerical Variables";
RUN;
TITLE; /* Clear the title after use */

/* Categorical Variables */
PROC FREQ DATA=LAB.HEALTHCARE_CLEANED_FINAL;
    TABLES Gender "Blood Type"n "Medical Condition"n "Admission Type"n "Test Results"n Medication Age_Group Billing_Category / NOPRINT OUT=AfterFreq; /* List all relevant categorical variables */
    TITLE "Frequencies (After Cleaning): Categorical Variables";
RUN;
TITLE; /* Clear title */

PROC PRINT DATA=AfterFreq; /Print frequency data/
RUN;

ODS GRAPHICS ON; /* Enable ODS Graphics */

/* Histograms (After Cleaning) */
PROC SGPLOT DATA=LAB.HEALTHCARE_CLEANED_FINAL;
    HISTOGRAM Age;
    TITLE "Distribution of Age (After Cleaning)";
    XAXIS LABEL="Age";
    YAXIS LABEL="Frequency";
RUN;

PROC SGPLOT DATA=LAB.HEALTHCARE_CLEANED_FINAL;
    HISTOGRAM "Billing Amount"n;
    TITLE "Distribution of Billing Amount (After Cleaning)";
    XAXIS LABEL="Billing Amount";
    YAXIS LABEL="Frequency";
RUN;

/* Bar Charts (After Cleaning) */
PROC SGPLOT DATA=LAB.HEALTHCARE_CLEANED_FINAL;
    VBAR Gender;
    TITLE "Distribution of Gender (After Cleaning)";
    XAXIS LABEL="Gender";
    YAXIS LABEL="Frequency";
RUN;

PROC SGPLOT DATA=LAB.HEALTHCARE_CLEANED_FINAL;
    VBAR "Medical Condition"n;
    TITLE "Distribution of Medical Conditions (After Cleaning)";
    XAXIS LABEL="Medical Condition";
    YAXIS LABEL="Frequency";
RUN;

ODS GRAPHICS OFF;

/* Numerical Variables:  Distribution Summary (After Cleaning) */
PROC UNIVARIATE DATA=LAB.HEALTHCARE_CLEANED_FINAL PLOT NORMAL; /* NORMAL for normality tests. PLOT for histogram and boxplot */
   VAR Age "Billing Amount"n; /* Add other numerical variables as needed */
    TITLE "Univariate Analysis (After Cleaning): Numerical Variables";
RUN;
TITLE;
