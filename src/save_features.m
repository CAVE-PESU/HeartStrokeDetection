function features = save_features(ecg_signal, fs)
    freq = instfreq(ecg_signal, fs);
    entropy = pentropy(ecg_signal, fs);
    
    mean_freq = 5.5703;
    mean_entropy = 0.6202;
    std_freq = 3.5797;
    std_entropy = 0.0789;
    
    % Perform z-scoring standardization
    standardized_freq = (freq - mean_freq) / std_freq;
    standardized_entropy = (entropy - mean_entropy) / std_entropy;
    
    % Combine the standardized features into a single vector.
    features = [standardized_freq, standardized_entropy];
    features = features';

end
