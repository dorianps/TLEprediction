   
## Note! The training data are currently not available. They will become available once the public release is approved. Please contact the author for any questions.
   
   
   
   
   
# Prediction of seizure laterality

This project provides the tools and necessary data to classify new temporal lobe epilepsy patients based on 3 PET asymmetries. Two steps are required for the prediction: obtain the asymmetries in Matlab (part 1) and use the values to classify the patient in R (part 2).  

Requirements:
* [Matlab](http://www.mathworks.com/products/matlab/) with [SPM8](http://www.fil.ion.ucl.ac.uk/spm/software/download.html) installed  
* [R](http://www.r-project.org/) or [Rstudio](http://www.rstudio.com/products/rstudio/download/) (recommended)
* Platform independent (Windows,Linux,Mac)  

## PART 1: obtain 3 PET asymmetries  
Download [all files](https://github.com/dorianps/TLEprediction/archive/master.zip) and add the folder into the Matlab path. Write the command `CalculatePETasymmetries` (case sensitive). The script will ask you for three files:    
1. PET volume (i.e., PET.nii)  
2. MRI volume (i.e. 001.nii)  
3. Parcellation from Freesurfer (i.e., wmparc.nii)  
*Note: the process relies on SPM8 functions, other SPM versions not tested.*  

The script will coregister PET on MRI and reslice the parcellation. It is assumed that the MRI and parcellation volumes are already registered, and that PET and MRI have the same initial orientation.  
The smoothed masks will be computed and saved in the PET folder. Finally, the three asymmetries are computed and displayed.  
PLEASE DOUBLE CHECK THAT PET HAS BEEN WELL COREGISTERED ONTO MRI !



## PART 2: classify the patient  
The R script is fully automated and requires only the three asymmetry values obtained in Matlab.  

**QUICK USAGE:**  
(Windows):  
`source('https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R', echo=F)`  

(Linux/Mac)  
Install RCurl the first time: `install.packages("RCurl")`  
Then run command:  
`library(RCurl) ; eval( expr = parse( text = getURL("https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R", ssl.verifypeer=FALSE) ))`  

Enter the values obtained in Matlab and get the classification statistics.  

**OFFLINE USAGE:**  
Open the file [TLEpredict.R](https://github.com/dorianps/TLEprediction/blob/master/TLEpredict.R) in R and follow the instructions.  


**PREDICTION EXAMPLE:**  
`source('https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R', echo=F)`  
  Assymetry for PET-mesial: -0.037443  
  Assymetry for PET-hippo-var: 0.050887  
  Assymetry for PET-entire-var: 0.12806  
Number of bootstraps (i.e., 10000): 10000  
Exclude cases from training (0=none, 1=Engel class III/IV, 2=non-operated, 3=1+2): 0  
_Using 58 TLE patients for training (28 left)..._  
>  |=============================================================| 100%  
 Patient Classification (10000 bootstraps):  
  [1] "left TLE: 1.48%"  
  [1] "right TLE: 98.52%"  
Average Posterior Probability (0=left, 1=right):  
  [1] 0.941  
95% CI of posterior probability (0.5=chance):  
   2.5% 97.5%   
  0.631 1.000   

  
    
    
**NOTES**  
The required `brglm` package will be automatically installed if not present in your R libraries.  
The script will automatically stop if asymmetry values entered are out of [-1 1] range, and will warn if values entered are out of the TLE population range.
