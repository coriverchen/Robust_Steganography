# SCRIPT
### Code for publication in TIFS titled “Robust Steganography for Black-box Generated Images”
 See our paper for details. Please ***STAR*** and ***CITE*** if you find it helpful!

#### To use a non-adaptive cover selection, the main file is *testRobustGISSttt.m*.
#### To use an adaptive cover selection, the main file is *testRobustGISS.m*.

#### Explanation of input parameters:
**pcover_dir**: Generated un-JPEG-compressed spatial images, e.g., in the format of '.pgm'.\
**cover_dir**: The above images are compressed and used as covers.\
**stego_dir**: Output directory of stego images.\
**payload**: Embedded payload (bpnzac).\
**cover_QF**: Quality factor of the cover.\
**attack_QF**: Quality factor of the compression.\
**R1**: T_gamma; **R2**: T_lambda; **R3**: T_max.\
**distortion**: Selected initial distortion, =1 for JUNIWARD, =2 for UERD.

#### *If other essential functions are missing, please look for them in my other repositories*.
