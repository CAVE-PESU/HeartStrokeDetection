function calculate_parameters(ecg, Fs) 
    ecg = ecg';
    ecg=ecg-mean(ecg);
    ecg=ecg/max(abs(ecg));

    slen=length(ecg);
    t=(1:slen)/Fs;

    %% Low pass filtering %%

    b=[1 0 0 0 0 0 -2 0 0 0 0 0 1];
    a=[1 -2 1] * 32;

    %% filtering ECG signal using LPF %%

    ecg_out1=filter(b,a,ecg);
    ecg_out1=ecg_out1 - mean(ecg_out1);
    ecg_out1=ecg_out1/max(abs(ecg_out1));

    %% High pass filtering %%

    b2=[-1,zeros(1,15),32,-32,zeros(1,14),1];
    a2=[1,-1] * 32;

    %% filtering the ECG signal from HPF

    ecg_out2 =filter(b2,a2,ecg_out1);
    ecg_out2= [ecg_out2(1:40)*0.25;ecg_out2(41:end)];
    ecg_out2 = ecg_out2/max(abs(ecg_out2));

    %% derivative operator %% 

    b3= [2 1 0 -1 -2];
    a3 = [1] *8;

    %% filtering the ECG signal from derivative operator %%

    ecg_out3 = filter(b3,a3,ecg_out2);
    %% Normalization %%
    ecg_out3=ecg_out3 - mean(ecg_out3);
    ecg_out3 = ecg_out3/max(abs(ecg_out3));

    %% squaring operation %%

    ecg_out4 = ecg_out3.^2;
    ecg_out4 = ecg_out4/max(abs(ecg_out4));

    %% moving window integration operation %%

    ecg_out4pad = [zeros(1,29) ecg_out4' zeros(1,29)];

    for i=30:length(ecg_out4pad)-29
        ecg_int(i-29) = sum(ecg_out4pad(i-29:i))/30;
    end

    ecg5 = ecg_int';
    ecg5 =ecg5/max(abs(ecg5));

    %% Thresholding operation %%
    TH = mean(ecg5)*max(ecg5); % Set threshold
    w=(ecg5>(TH));

    x=find(diff([0 w']) == 1); % Finding location of 0 to 1 transition
    y=find(diff([w' 0]) == -1); % Finding location of 1 to 0 transition

    %% cancelling the delay due to LOW PASS FILTER and HIGH PASS FILTER %%
    x=x-(6+16); % 6 DELAY BY LPF & 16 DELAY BY HPF
    y=y-(6+16);

    %% Detect Q,R,S points %%
    for i=1:length(x)
        %% R Locations %%
        [R_val(i),R_loc(i)]=max(ecg(x(i):y(i)));
        R_loc(i) = R_loc(i)-1 + x(i); % adding offset

        %% Q Locations %%
        [Q_val(i),Q_loc(i)]=min(ecg(R_loc(i):-1:R_loc(i)-8));
        Q_loc(i) = R_loc(i)-Q_loc(i)+1; % adding offset

        %% S Locations %%
        [S_val(i),S_loc(i)]=min(ecg(R_loc(i):R_loc(i)+10));
        S_loc(i) = R_loc(i)+S_loc(i)-1; % adding offset
    end
    
    %% Calculation of HEART RATE %%
    HT=ceil((length(R_loc)*60)/t(end)); % calculate Heart rate

    %% Calculation of QRS Duration %%
    z1 = S_loc - Q_loc;
    dur=mean(z1)*(1/Fs); % Calculate QRS duration

    %% Calculation of RR interval %%
    RR=diff(R_val);
    RR_sq=RR.^2;

    HRV = sqrt(mean(RR_sq));
    
    disp("HR = ");
    fprintf('%f\n', HT);
    
    disp("HRV = ");
    fprintf('%f\n', HRV);
    
    disp("QRS_dur = ");
    fprintf('%f\n', dur);
end