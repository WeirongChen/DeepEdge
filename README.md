# DeepEdge
v2.1
- DeepEdge is a MATLAB-based interactive tool for automatic ultrasound tongue contouring, by combining convolutional neural network and SNAKE edge detection methods. DeepEdge uses the pre-trained neural network (U-Net) model to predict the probability of each pixel being covered by the tongue edge, and then SNAKE edge detection refines the neural network predicted tongue edge. 

- The SNAKE algorithm in this program was adopted from [Cathy Laporte's]((https://www.etsmtl.ca/Professeurs/calaporte/Accueil?lang=en-CA)) (Laporte & Ménard, 2018) implementation of the ‘snake’ algorithm in EdgeTrak (Li et al. 2005).

#### For now, to cite DeepEdge:
- Chen, W.-R., Tiede, M., & Whalen, D. H. (2020). DeepEdge: automatic ultrasound tongue contouring combining a deep neural network and an edge detection algorithm. Paper presented at the 12th International Seminar on Speech Production (ISSP 2020). 

------------------------------------------
### INSTALLATION


##### Requirements:
         - MATLAB R2021a or newer
         - Deep Learning Toolbox
         - Image Processing toolbox 
         - Computer Vision toolbox 
##### Steps:
- 1. Download all the files from this distribution and put them in a folder. 
  
- 2. Download one of the U-Net models and put it in the same folder: 
    Choose the model that best matches (machine/probe combination) your setting. 
    If there is no match of your machine in the list, try the general purpose model (DpEdge_General...) first.
      - [DpEdg_General_04APR2022](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EeDIJCPppZRHqMZnHYtn574B-uLfHler97yzCtzXDq5a_A?e=KcZB64)
      - [DpEdg_Ultrasonix-SonixTouch_C9-5-10_7NOV2019](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EXsijdmwl8hDuP1vKsbHdoIB3hXRq5fJNBa80H9BsyK_TA)
      - [DpEdg_PhilipsEpiq7_X6-1_31MAR2022](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EfwIjdGuBNpHoo8gKF8KawQBbbiihSoNZ1mA090bPMQCHw?e=32RXCH)
      - [DpEdg_PhilipsEpiq7_C8-5_03APR2022](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EdJcEUJQ7ZhAuDo4EPiPiEgBNGvALYBuYy3lVZp7Lp3vFQ?e=BVpzB8)

- 3. Download 'make_snake' from Cathy Laporte's [SLURP](https://github.com/cathylaporte/SLURP) repository and put it in the same folder:

     For Windows: [make_snake.mexw64](https://github.com/cathylaporte/SLURP/blob/master/make_snake.mexw64) 

     For MAC: [make_snake.mexmaci64](https://github.com/cathylaporte/SLURP/blob/master/make_snake.mexmaci64)

##### Run:
For example, if the above-mentioned files are put in a folder: ''./DeepEdge'', then:
- In MATLAB command window, type:
     >> cd ./DeepEdge  
     >> DeepEdge  

##### Usage: 
- 0. DeepEdge will automatically load the first readable (in alphabetical order) model file in the current folder. 
     Click "Info" -> "Model information" to check if the model is properly loaded.
     You can also manually load the model by clicking "File" -> "Load model"
- 1. Load video:  Click "File" -> "Load video"  
- (Optional) Load TextGrid file: Click "File" -> "Load TextGrid"
- 2. Crop video: Click "CROP" button in "IMAGE" tab, then click & drag to select the fan-shape area that contains tongue contour. 
- 3. In the "DeepEdge" tab, select "NeuralNet" or "NN+SNAKE" for whether you want to track using just the neural network model  or the hybrid method of combining neural network and SNAKE.  
- 4. Click "Apply to current frame" to apply the algorithm on this frame.
- 5. Click "Track" to apply tracking continously; you can stop anytime by clicking "Stop tracking"
------------------------------------------
------------------------------------------
###
<!--  If you don't have access to MATLAB R2021a, you can download a compiled standalone installer (Windows only):
(You still need to download one of the U-Net models but not 'make_snake')
[DeepEdge standalone Web installer v1.6](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EeEVC_R1IKBLmpHzNYtMDC4Bm7v0lqx0HW10wKNQVDKmHA?e=vV5q02)
-->


### COPYRIGHT, LICENSE & DISCLAIMER
Copyright (C) 2020 Wei-Rong Chen <chenw@haskins.yale.edu>  
This program is free software under GNU General Public License, version 3.  
This program is distributed WITHOUT ANY FORM of EXPRESS or IMPLIED WARRANTY and ANY SUPPORT.    
See the GNU General Public License for more details.  


Latest update: 22SEP2022

-------------------------------------------
## REFERENCES
- Laporte, C., & Ménard, L. (2018). Multi-hypothesis tracking of the tongue surface in ultrasound video recordings of normal and impaired speech. Medical Image Analysis, 44, 98-114. doi: https://doi.org/10.1016/j.media.2017.12.003
 - Li, M., Kambhamettu, C., & Stone, M. (2005). Automatic contour tracking in ultrasound images. Clinical linguistics & phonetics, 19(6-7), 545-554. doi: 10.1080/02699200500113616
- Chen, W.-R., Tiede, M., Kang, J., Kim, B., & Whalen, D. (2019). An electromagnetic articulography-facilitated deep neural network model of tongue contour detection from ultrasound images. Paper presented at the 178th Meeting of the Acoustical Society of America, San Diego, California. 
- Chen, W.-R., Tiede, M., & Whalen, D. H. (2020). DeepEdge: automatic ultrasound tongue contouring combining a deep neural network and an edge detection algorithm. Paper presented at the 12th International Seminar on Speech Production (ISSP 2020). 
