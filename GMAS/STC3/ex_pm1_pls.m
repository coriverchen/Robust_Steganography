%% EXAMPLE OF MULTI-LAYERED EMBEDDING - +-1 PAYLOAD LIMITED SENDER
% implemented using syndrome-trellis codes
clc; clear;

n = 1e+5; % use n pixels
m = n/2;  % embed m bits
h = 10;   % use STCs with constraint_height = 10. Try values between 7 and 12.

cover = int32(256*rand(1,n));  % generate random cover pixels
msg = uint8(rand(1,m));        % generate m random message bits

costs = zeros(3, n, 'single'); % for each pixel, assign cost of being changed
costs(:,1) = [1e+5 0 1];       % cost of changing the first cover pixel by -1, 0, +1
costs([1 3],2:end) = 1;        % cost can be defined arbitrarily

[d stego n_msg_bits l] = stc_pm1_pls_embed(cover, costs, msg, h);
extr_msg = stc_ml_extract(stego, n_msg_bits, h);

if all(extr_msg==msg)
    fprintf('Message was embedded and extracted correctly.\n');
    fprintf('  %d bits embedded => %d bits in 2LSB and %d bits in LSB.\n', ...
        sum(n_msg_bits), n_msg_bits(1), n_msg_bits(2));
    fprintf('  achieved coding_loss = %4.2f%%\n', l*100);
end
