% Custom testbench tool for verification.

%%
clearvars

% Set up the plugin parameters
plugin = spectrumPixelator;
plugin.timeRes = .05;
plugin.freqRes = 50;
plugin.dryWet = 0;
bufsize = 1024;
fs = 44100;

% Set up the environment
time = 0:1/fs:5;
audio = [sin(time*2*pi*440)' sin(time*2*pi*440)'];

dry = [0,0];
processed = [0,0];

% Start the DSP loop
for k = 1:length(audio)/bufsize

    % Stores each buffer input
    in = audio(1+k*bufsize:k*bufsize+bufsize,:);
    
    % Saves the input via buffers
    dry = [dry;in];
    
    % Processing
    out = process(plugin, in);
    
    % Saves the output via buffers
    processed = [processed;out];
end