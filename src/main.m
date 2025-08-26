function main(ecg_filename)
    ecg_signal = load(ecg_filename);
    ecg_signal = ecg_signal.val;
    
    wavelet_name = 'sym5';
    levels = 8;
    denoised_ecg_signal = dwt_denoise_ecg(ecg_signal, wavelet_name, levels);
    
    % Call the feature calculation and saving function
    fs = 300;
    
    calculate_parameters(ecg_signal,fs);
    segment_size = 9000;
    count_af = 0;
    
    num_segments = floor(length(ecg_signal) / segment_size);
    colors = [];
    d = cell(1, 2);
    
    for segment_idx = 1:num_segments
        start_index = (segment_idx - 1) * segment_size + 1;
        end_index = start_index + segment_size - 1;
        segment = ecg_signal(start_index:end_index);
        features2D = save_features(segment, fs);
    
        load('trained_model.mat');
        prediction = predict(net2, features2D);
    
        % Display the prediction
        disp(prediction);
        
        if(prediction(1) < 0.5)
            colors = [colors, 'b'];  
            disp("NO");
        else
            colors = [colors, 'r'];  
            disp("YES");
            count_af = count_af+1;
        end
    end
    disp("duration = ")
    fprintf('%f\n', num_segments*30);
    
    disp("count_af = ");
    fprintf('%f\n', count_af);

    disp("AF_burden = ");
    fprintf('%f\n', count_af/num_segments*100);

    signal_length = length(ecg_signal);
    time = 1:signal_length;
 
    % Create a figure
    figure;

    % Loop through segments
    for i = 1:num_segments
        % Calculate the indices for the current segment
        start_index = (i - 1) * segment_size + 1;
        end_index = min(i * segment_size, signal_length);

        % Extract the current segment
        current_segment = ecg_signal(start_index:end_index);

        % Generate a color for the current segment (you can customize this)
        color = colors(i);
        % Plot the current segment with the chosen color
        if(color == 'b')
            d{1} = plot(time(start_index:end_index), current_segment, 'Color', color);
        else
            d{2} = plot(time(start_index:end_index), current_segment, 'Color', color);
        end

        % Hold on to overlay the next segment
        hold on;
    end

    % Customize the plot as needed (labels, title, etc.)
    xlabel('');
    ylabel('ECG Amplitude');
    title('ECG Indicating AF');
    
    % Add a legend with labels for abnormal and normal
    if ~isempty(d{1}) && ~isempty(d{2})
        % Both d{1} and d{2} are valid
        legend([d{1}, d{2}], {'Normal', 'AF'});
    
    elseif ~isempty(d{1})
        % Only d{1} is valid
        legend(d{1}, {'Normal'});
    
    elseif ~isempty(d{2})
        % Only d{2} is valid
        legend(d{2}, {'AF'});
    end

    % Hold off to stop overlaying additional plots
    hold off;
    
    path = 'C:\Users\Dell\Desktop\Final\ApplicationUpdated\static\myimage.png';
    print(path, '-dpng', '-r300');
end
