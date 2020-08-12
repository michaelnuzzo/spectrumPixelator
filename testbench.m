% Custom testbench tool for verification.

%%
clc;clearvars;close all

% Set up the plugin parameters
plugin = spectrumPixelator;
plugin.timeRes = .01;
plugin.freqRes = 5;
plugin.dryWet = 100;
bufsize = 2048;
fs = 44100;

% Set up the environment
% time = 0:1/fs:5;
% audio = [sin(time*2*pi*440)' sin(time*2*pi*440)']; % sin
% audio = 2*(rand(length(time),2)-0.5); % noise
[audio,fs] = audioread('/Users/michaelnuzzo/Music/iTunes/iTunes Media/Music/E For Explosion/Reinventing the Heartbeat/13 I Ain''t Lost If I''m With You.m4a');


dry = [0,0];
processed = [0,0];

h = animatedline;

% Start the DSP loop
for k = 1:length(audio)/bufsize
    
    % Stores each buffer input
    in = audio(1+k*bufsize:(k+1)*bufsize,:);
    
    % Saves the input via buffers
    dry = [dry;in];
    
    % Processing
    out = process(plugin, in);
    
    % Saves the output via buffers
    processed = [processed;out];
    addpoints(h,1:length(processed),processed(:,1));
    drawnow
end