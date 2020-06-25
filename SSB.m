[yc, fc] = audioread("Results3\Counting-16-44p1-mono-15secs.wav");
yc=yc(:,1);
nc = length(yc);
Y1 = fft(yc);
plot(20*log10(abs(Y1)))

[ys, fs] = audioread("Results3\TrainWhistle-16-44p1-mono-9secs.wav");
ns = length(ys);
Y2 = fft(ys);
plot(20*log10(abs(Y2)))

fmax = 16000
if fc < 2*fmax
    [L, M] = rat(96000/fc); % non-integer scaling factor L/M
    yc = resample(yc, L, M);
    fc = round(fc*L/M);
    YC = fft(yc);
    plot(20*log10(abs(YC)))
elseif fc >= 32000 
    [A, B] = butter(10, 2*fmax/fc);
    yc = filtfilt(A, B, yc);
    if fc < 44100
        [L, M] = rat(96000/fc); % non-integer scaling factor L/M
        yc = resample(yc, L, M);
        fc = round(fc*L/M);
        YC = fft(yc);
        plot(20*log10(abs(YC)))
    end
end


if fs > fc-2*fmax
    scale = (fc - 2*fmax)/fs
    [L, M] = rat(scale + scale/10) % non-integer scaling factor L/M
    ys = resample(ys, L, M);
    
    fs = round(fs*L/M);
    YS = fft(ys);
    plot(20*log10(abs(YS)))
end

k = (fs/ns)/(fc/nc)
if k > 1
    ys = ifft(fft(ys, length(ys)*k))
else % THIS MAKES YC HAVE EMPTY SOUND AT THE END
     yc = [yc; zeros(round(nc*(1/k-1)), 1)];
     nc = length(yc);
end

y2mod = ssbmod(ys, 22000, fc);
Y2MOD = fft(y2mod);
plot(20*log10(abs(Y2MOD)));

YMIX = Y2MOD+Y1;
plot(20*log10(abs(YMIX)));
ymix = ifft(YMIX);
audiowrite("res\Mix.wav",ymix, fc);
soundsc(ymix, fc)
SNRmix = snr(yc, yc-ymix)
filename = 'Results/Mix.wav';
comment = sprintf('%d', 22000);
yc = real(ifft(YC));
audiowrite(filename, yc, fc, 'Comment', comment);

y2mod = audioread(filename);
ycinf = audioinfo(filename);
fm = sscanf(ycinf.Comment, '%g,');
[A, B] = butter(10, 2*fm/fc);
y2mod = filtfilt(A, B, y2mod);
y2demod = ssbdemod(y2mod, fm, fc);
soundsc(y2demod, fs)
Y2DEMOD = fft(y2demod);
plot(20*log10(abs(Y2DEMOD)));
audiowrite("res\Extract.wav",y2demod, fc)
SNRextract = snr(ys, ys-y2demod(1:length(ys)))
