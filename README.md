# Neurorobotics-and-Neurorehabilitation #
Final project of Neurorobotics and Neurorehabilitation - Project 3 - Group 4

## Assignment: Project 3 [Report]
* **Text of the assignment**: see `20221215_nn_project3.pdf`
* **Report of the assignment**: see `Final Report - project 3 - group 4.pdf`

## Project Structure [Project_NN_group4]
The whole project is contained in the folder Project_NN_group4 and is organized as follows:
* **Main scripts**: `Project3_part1.m`, `Project3_part2.m`.
* **data**: this folder contains the following subfolders:
  * **dataset** `miscontinuous`: **[TO ADD MANUALLY]** (downloadable from link [6] in PDF report) contains the datasets of the 8 subjects , where each dataset contains all GDF offline and online files.
  * **outputs**: contains the following subfolders:
    * **xproc**: (for Project3_part1.m) contains the files for the analysis of each subject.
    * **offline**: (for Project3_part2.m) contains a folder for each subject, where each folder contains the processed offline files in .mat format.
    * **online**: (for Project3_part2.m) contains a folder for each subject, where each folder contains the processed online files in .mat format.
    * **classifiers**: (for Project3_part2.m) contains a folder for each subject, that contains the classifier created for the specific subject in .mat format.
* **functions**: this folder contains the following subfolders and scripts:
  * **Relevant script functions**: `script1_Processing.m`, `script2_Features_selection.m`, `script3_Classification_training.m`, `script4_Classification_evaluation.m`, `script5_Evidence_accumulation_framework.m`.
  * **helper**: contains the helper functions provided for this project.
  * **util**: contains the util functions that have been implemented for this project.
* **toolbox**: it contains the biosig toolbox (see link [7] in PDF report) that allows to use the sload.m function, which allows to load and to read the .gdf files.

## Important notes (TODO before running the program)
* Manually add the dataset folder "micontinuous" in the folder "<PROJECT_PATH>/data/"
* Before running the program, be sure to modify all (and only) the parts of the code indicated with the comment **[TO MODIFY]** with your settings.
* If the program doesn't work (i.e., if the function sload.m doesn't work properly) run manually the install.m file, this only for the first run of the program.
* There are 2 for-loops which allow to iterate all the subjects in one shot for the calibration and for the evaluation part respectively. We suggest you to comment these two lines as follow:
  `% for i = 1 : num_subjects`
and to uncomment the lines marked with the comment **[SUGGESTED]** as follow:
  `for i = <manually select the index of the subject you want to run>`
in this way you can analyze 1 subject at a time, avoiding to generate too many plots all at once.
* If you want to change some settings you can do it by the pieces of code marked as **[OPTIONALLY MODIFY]**, all the rest of the code is supposed to work without any modification.

## Execution instruction
* To run the first part of the project 3 run: `Project3_part1.m`
* To run the second part of the project 3 run: `Project3_part2.m`
