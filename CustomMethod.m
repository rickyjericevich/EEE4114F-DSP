[yc, fc] = audioread("Results1\Ambiance-16-44p1-mono-12secs.wav");
yc=yc(:,1);
nc = length(yc);
nco = nc;
Y1 = fft(yc);
plot(20*log10(abs(Y1)))

[ys, fs] = audioread("Results1\Laughter-16-8-mono-4secs.wav");
ys1 = ys;
ns = length(ys);
Y2 = fft(ys);
plot(20*log10(abs(Y2)))

fmax = 16000
if fc < 2*fmax
    [L, M] = rat(96000/fc); % non-integer scaling factor L/M
    yc = resample(yc, L, M);
    fc = round(fc*L/M);
elseif fc >= 32000 
    [A, B] = butter(10, 2*fmax/fc);
    yc = filtfilt(A, B, yc);
    soundsc(yc, fc);
    if fc < 44100
        [L, M] = rat(96000/fc); % non-integer scaling factor L/M
        yc = resample(yc, L, M);
        fc = round(fc*L/M);
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
nso = length(ys);

k = (fs/ns)/(fc/nc)
if k > 1
    ys = ifft(fft(ys, length(yc)));
else % THIS MAKES YC HAVE EMPTY SOUND AT THE END
    yc = [yc; zeros(round(nc*(1/k-1)), 1)];
    nc = length(yc);
end

filename = customMethod(yc, fc, ys, fs, nco, nso);
c = audioread(filename);
SNRmix = snr(yc, yc-c)
YCM = fft(c);
plot(20*log10(abs(YCM)))

filename = extractCustom(filename);
[s, fsecret] = audioread(filename);
secret = audioplayer(s, fsecret);
play(secret);
YS = fft(ys);
plot(20*log10(abs(YS)))

SNRextract = snr(ys, ys-s(1:end-1))

function filename = customMethod(yc, fc, ys, fs, nco, nso)
    start = round((length(yc)-length(ys))/2);
    finish = start + length(ys);
    YC = fft(yc);
    YS = fft(ys);
    for i = start:finish-1
        YC(i) = YS(i-start+1);
    end
    filename = 'Results/Mix.wav';
    comment = sprintf('%d,', [fs, start, nso]);
    yc = real(ifft(YC));
    audiowrite(filename, yc, fc, 'Comment', comment);
end
function filename = extractCustom(filename)
    yc = audioread(filename);
    ycinf = audioinfo(filename);
    info = sscanf(ycinf.Comment, '%g,');
    YS = zeros(info(3)-info(2), 1);
    for i = info(2):info(3)
        YS(i-info(2)+1) = YC(i);
    end
    filename = 'Results/Extract.wav';
    ys = real(ifft(YS));
    audiowrite(filename, ys, info(1));
end
