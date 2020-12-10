# DeepEdge
DeepEdge is a MATLAB-based interactive tool for automatic ultrasound tongue contouring, by combining convolutional neural network and SNAKE edge detection methods. DeepEdge uses the pre-trained neural network (U-Net) model to predict the probability of each pixel being covered by the tongue edge, and then SNAKE edge detection refines the neural network predicted tongue edge. 

------------------------------------------
### Installation: 
####   *  METHOD 1. 
####     Requirements:
         - MATLAB R2018b or newer
         - Deep Learning Toolbox
####     Steps:
######      1. Download all the files from this distribution and put them in a folder. 
######      2. Download the U-Net model and put it in the same folder: 
             - [unet4300](https://yaleedu-my.sharepoint.com/:u:/g/personal/wei-rong_chen_yale_edu/EXsijdmwl8hDuP1vKsbHdoIB3hXRq5fJNBa80H9BsyK_TA?e=ILS8Ko)
######      3. Download 'make_snake' from Cathy Laporte's (Laporte & Ménard, 2018) implementation of the ‘snake’ algorithm in EdgeTrak (Li et al. 2005), and put it in the same folder:
             - For Windows: [make_snake.mexw64](https://github.com/cathylaporte/SLURP/blob/master/make_snake.mexw64) 
             - For MAC: [make_snake.mexmaci64](https://github.com/cathylaporte/SLURP/blob/master/make_snake.mexmaci64)
------------------------------------------
