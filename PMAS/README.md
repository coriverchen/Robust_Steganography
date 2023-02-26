# PMAS
### Code for publication on IEEE Transactions on Circuits and Systems for Video Technology (TCSVT) titled "Robust Steganography for High Quality Images".

The main function is testRobustUNICORE, where the inputs should be as follows:  
- cover_dir: address of the cover image folder  
- stego_dir: address of the stego image folder  
- payload: payload (bpnzac)  
- cover_QF: QF of cover  
- attack_QF: QF of recompression  
- T: Threshold to control the robust region  
- mode:  
    - mode(1): Use un- or post-compressed as a cover. (1-uncompressed, 2-postcompressed) [Postprocessing Mitigation]  
    - mode(2): Distortion calculation method. [Exploring Distortion Assignment]  
    - mode(3): Number of post-processing   
- distortion: distortion function selection. 
    - 1-JUNIWARD
    - 0-UERD

Please read the paper for more details.

NOTE: The usage of GDM or PDM also can be selected in "preprocessUNICORE". Beside the calculation of PDM, there is the commented out GDM code.
