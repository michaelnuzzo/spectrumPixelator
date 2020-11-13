% Custom testbench tool for verification.

%%
clc;clearvars;close all;

% Set up the plugin parameters

bufsize = 2048;
fs = 44100;

plugin = spectrumPixelator;
% plugin.timeRes = bufsize*2^(5)/fs;
plugin.timeRes = 1;
plugin.freqRes = 10;
plugin.dryWet = 100;

% plugin = Pixelator;
% plugin.timeRes = 5;
% plugin.freqRes = 50;
% plugin.dryWet = 100;

% Set up the environment
% time = 0:1/fs:5;
% audio = [sin(time*2*pi*440)' sin(time*2*pi*440)']; % sin
% audio = 2*(rand(length(time),2)-0.5); % noise
[audio,fs] = audioread('/Users/michaelnuzzo/Music/iTunes/iTunes Media/Music/Kacey Musgraves/Golden Hour/06 Love Is A Wild Thing.m4a');
audio = audio(1:fs*10,:);

dry = [0,0];
processed = [0,0];

% h = animatedline;
% profile on

% Start the DSP loop
for k = 1:(length(audio)/bufsize)-1

    % Stores each buffer input
    in = audio((k*bufsize)+(1:bufsize),:);
    
    % Saves the input via buffers
    dry = [dry;in];
    
    % Processing
    out = process(plugin, in);
    
    % Saves the output via buffers
    processed = [processed;out];
%     addpoints(h,1:length(processed),processed(:,1));
%     drawnow
    

end