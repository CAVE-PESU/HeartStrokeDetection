function denoised_ecg_signal = dwt_denoise_ecg(ecg_signal, wavelet_name, levels)   
    [C, L] = wavedec(ecg_signal, levels, wavelet_name);
    
    for i = 1:levels
        start_index = L(i) + 1;
        end_index = L(i + 1);
        C(start_index:end_index) = 0;
    end
    
    denoised_ecg_signal = waverec(C, L, wavelet_name);
end
