# ROAST
Code for publication on IEEE Transactions on Multimedia (TMM) titled "Upward Robust Steganography Based on Overflow Alleviation".

The main functions corresponding to the two algorithms ROAST-ST and ROAST-OS are TestRobustnessUR_JUNIWARD.m and TestRobustnessURA_JUNIWARD.m respectively, 
where the inputs should be as follows: 

precover_dir: address of the cover image folder  
cover_dir: address of preprocessed cover image folder (for output)
stego_dir: address of the stego image folder (for output)
attack_QF: QF of recompression  
payload: payload (bpnzac)
T: parameters for controlling the intensity of ST 
beta: parameters for controlling asymmetric distortion

Please read the paper for more details.
