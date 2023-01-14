%STC_ML_EXTRACT Extracts message embedded by ML-STCs.
%   MSG = STC_ML_EXTRACT(Y, NUM_MSG_BITS) extracts the embedded message
%   from stego sequence Y. Array NUM_MSG_BITS describes how many bits to
%   extract from each layer of LSB. Uses default constraint height h=10.
%
%   MSG = STC_ML_EXTRACT(Y, NUM_MSG_BITS, H) does the same as above, but
%   constraint height of the STC is H.
%
% Author: Tomas Filler  email: tomas.filler@gmail.com
%                         www: http://dde.binghamton.edu/filler
%
% STC Toolbox website: http://dde.binghamton.edu/filler/stc
%
% References:
% [1] T. Filler, J. Judas, J. Fridrich, "Minimizing Additive Distortion in 
%     Steganography using Syndrome-Trellis Codes", submitted to IEEE
%     Transactions on Information Forensics and Security, 2010.
%     http://dde.binghamton.edu/filler/pdf/Fill10tifs-stc.pdf
% 
% [2] T. Filler, J. Judas, J. Fridrich, "Minimizing Embedding Impact in 
%     Steganography using Trellis-Coded Quantization", Proc. SPIE,
%     Electronic Imaging, Media Forensics and Security XII, San Jose, CA, 
%     January 18-20, 2010.
%     http://dde.binghamton.edu/filler/pdf/Fill10spie-syndrome-trellis-codes.pdf
%
% [3] T. Filler, J. Fridrich, "Minimizing Additive Distortion Functions
%     With Non-Binary Embedding Operation in Steganography", 2nd IEEE 
%     Workshop on Information Forensics and Security, December 2010.
%     http://dde.binghamton.edu/filler/pdf/Fill10wifs-multi-layer-stc.pdf
%
%   See also STC_PM1_PLS_EMBED, STC_PM1_DLS_EMBED, STC_PM2_PLS_EMBED
%   STC_PM2_DLS_EMBED, STC_EMBED, STC_EXTRACT.
