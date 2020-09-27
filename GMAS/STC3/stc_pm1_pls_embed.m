%STC_PM1_PLS_EMBED Embeds message in a cover object with +-1 changes - PLS.
%
%[D Y NUM_MSG_BITS L] = STC_PM1_PLS_EMBED(X, COSTS, MSG)
%   implements Payload Limited Sender. Embeds as many bits of message MSG 
%   as possible into cover object X, such that the cost of stego object Y 
%   is minimal with changes limited to +-1. Uses default constraint height 
%   h=10 and INF for cost of wet elements. Outputs distortion caused by 
%   embedding D, stego object Y, number of message bits in each layer of 
%   LSBs NUM_MSG_BITS and coding loss L. See [1] for more details.
%
%[D Y NUM_MSG_BITS L] = STC_PM1_PLS_EMBED(X, COSTS, MSG, H)
%   the same as above, but uses STCs with constraint height H.
%
%[D Y NUM_MSG_BITS L] = STC_PM1_PLS_EMBED(X, COSTS, MSG, H, W)
%   the same as above, but uses W as the cost of wet elements.
%
%   COSTS array must be 3xN, where N=numel(X).
%     COSTS(1,i) = cost of changing X(i) by -1
%     COSTS(2,i) = cost of changing X(i) by  0
%     COSTS(3,i) = cost of changing X(i) by +1
%
%   NUM_MSG_BITS contains number of bits embedded in different layers
%     NUM_MSG_BITS(end) - # of bits in LSBs
%     NUM_MSG_BITS(end-1) - # of bits in 2LSBs
%   sum(NUM_MSG_BITS) = total number of embedded bits. This can be less
%   than numel(MSG) but usually numel(MSG)=sum(NUM_MSG_BITS).
%
%   Use STC_ML_EXTRACT(Y, NUM_MSG_BITS, H) to extract the message back.
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
%   See also STC_ML_EXTRACT, STC_PM1_DLS_EMBED, STC_PM2_PLS_EMBED
%   STC_PM2_DLS_EMBED, STC_EMBED, STC_EXTRACT.
