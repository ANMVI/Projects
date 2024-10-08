dm log 'clear' log; dm output 'clear' log; /* clears the log and the output so that the code can keep running */
libname _all_ clear; /*clears libraries at the start of the session */

proc import out = sleep 
datafile = "/home/u49225096/Coding Practice/Sleep_health_and_lifestyle_dataset.csv"
dbms = csv replace;
range = "sleep_health_and_lifestyle_data$";
run;

libname sleeplib "/home/u49225096/Coding Practice";

data sleeplib.sleep_raw;
set sleep;
run;

*proc logistics and mixed methods. macros, array, do loop, conditional formatting.
*checking variables;
*find which variable(s) or combination of variables have strongest association to sleep disorder;

proc contents data = sleeplib.sleep_raw; run;

*data transformation;

%macro try (var, rename);
proc datasets library = work;
modify sleep;
rename "&var"n = &rename
;
quit;
%mend try;
%try (Quality of Sleep, Quality_of_Sleep);
%try (Blood Pressure, Blood_Pressure);
%try (BMI Category, BMI_Category);
%try (Daily Steps, Daily_Steps);
%try (Heart Rate, Heart_Rate);
%try (Person ID, Person_ID);
%try (Physical Activity Level, Physical_Activity_Level);
%try (Quality of Sleep, Quality_of_Sleep);
%try (Sleep Disorder, Sleep_Disorder)
%try (Sleep Duration, Sleep_Duration);
%try (Stress Level, Stress_Level);

data sleep_a;
set sleep;
length Age_Group $20.;

Systolic = substr(Blood_Pressure, 1,3) * 1;
Diastolic = Substr(Blood_Pressure, 5, 2) * 1;

if Age >= 27 and Age <= 29 then Age_Group = "Late Twenties";
if Age >= 30 and Age <= 33 then Age_Group = "Early Thirties";
if Age >= 34 and Age <= 36 then Age_Group = "Mid Thirties";

if (systolic >= 130 and systolic <= 139) and (diastolic >= 80 and diastolic <= 89)
then High_BP = "Yes";
else High_BP = "No";
run;

/*Graphing High BP vs Sleep Disorder*/

proc sgplot data= sleep_a;
    vbar Sleep_Disorder /*stress_level*/ /*BMI_Category*/ / group= High_BP
    groupdisplay= cluster
    /*stat = percent*/
    dataskin = pressed;
run;

/*Graphing Daily Steps vs Heart Rate*/
proc sgplot data= sleep_a;
    scatter x=daily_steps y=heart_rate/
    dataskin = pressed;
run;

/*which numeric variables strongly affect BP?*/
proc glm data=sleep_a;
    model Systolic = Age heart_rate quality_of_sleep daily_steps;
    title 'regression of full model';
run;

/*age, heart_rate, and quality_of_sleep strongly affect BP. P value < .0001*/

/*testting correlation between systolic BP and age*/
proc corr data=sleep_a  fisher(rho0 = .8);
var systolic age;
run;
/* we reject the null hypothesis: r square = .61, p value = <.0001*/
