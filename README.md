# Prediction of seizure laterality


The tools provided here utilize three PET asymmetries to predict the laterality of seizure onset in temporal lobe epilepsy. See [Neuroimage Clin 2015 (9) 20-31](http://dx.doi.org/10.1016/j.nicl.2015.07.010) for details on the computation process.  

Requirements:
* An interictal FDG-PET scan
* A T1-weighted MRI
* The parcellation of T1 with Freesurfer (sorry, can't avoid this)
* SOFTWARE 1: [Matlab](http://www.mathworks.com/products/matlab/) with [SPM8](http://www.fil.ion.ucl.ac.uk/spm/software/download.html) 
* SOFTWARE 2: [R](http://www.r-project.org/) or, even better, [Rstudio](http://www.rstudio.com/products/rstudio/download/) 
  
The prediciton is done in two steps: obtain the asymmetries in Matlab (part 1) and use the values to classify the patient in R (part 2).  

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
The R script is fully automated and requires only the three values obtained in Matlab.  

**QUICK USAGE:**  
(Windows):  
`source('https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R', echo=F)`  

(Linux/Mac)  
Install RCurl the first time: `install.packages("RCurl")`  
Then run command:  
`library(RCurl) ; eval( expr = parse( text = getURL("https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R", ssl.verifypeer=FALSE) ))`  

Enter the values obtained in Matlab and get the classification statistics.  

**OFFLINE USAGE:**  
Run the file [TLEpredict.R](https://raw.githubusercontent.com/dorianps/TLEprediction/master/TLEpredict.R) in R and follow the instructions.  
*****
**NOTES**  
The required `brglm` package will be automatically installed if not present in your R libraries.  
The script will automatically stop if asymmetry values entered are out of [-1 1] range, and will warn if values entered are out of the TLE population range.
*****
**QUESTIONS**  
>**Why is Freesurfer parcellation needed?**  
*To know where to look in the PET image and get the right asymmetries of signal and signal variance.*  
**How can I get the parcellation from Freesurfer?**  
*Check the [Freesurfer Beginner guide](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferBeginnersGuide). Once you install Freesurfer, a command like*  
`recon-all -i T1.nii -s JohnB -sd /home/Freesurfer/ -all`  
*will output the analysis of T1.nii in a folder named JohnB in /home/Freesurfer/. The wmparc file is what you need, convert it to niftii if necessary*  
`mri_convert --in_type mgz --out_type nii --out_orientation RAS /home/Freesurfer/JohnB/mri/wmparc.mgz `  
**I don't have a T1 image, I have only PET. Can I still use this tool?**  
*Formally not. But one idea is to use someone's else T1 as reference (or a template), PET will be registered to that and will use the respective parcellation. The fit will not be as good, but given the smoothed nature of the PET signal, it may still work. This idea has never beed tested.*  
**Why can't you do everything in Matlab or everything in R?**  
*Matlab can do image processing through SPM, but has limited resources for penalized regression.*  
*R can easily run penalized logistic regression, but has limited resources for image processing.*  
*We might be able to unify the pipeline in the future.*  
**When will the training data be available?**  
*The training data is available since July 1, 2015*  

*****
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

