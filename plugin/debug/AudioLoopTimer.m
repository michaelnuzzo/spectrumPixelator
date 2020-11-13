function [results,figHandle] = helperAudioLoopTimerExample( ...
    setupObjectsOutsideLoop)
% This function helperAudioBenchmark is only in support of the featured
% example 'Measuring Performance of Streaming Real-Time Audio Algorithms'.
% It may change in a future release.

% Copyright 2015-2018 The MathWorks, Inc.

if nargin < 1
   setupObjectsOutsideLoop = false; 
end

%% Define simulation constants
numFrames = 100;
FrameSize = 2048;
Fs = 44100;

%% Create AudioLoopTimer object
at = audioexample.AudioLoopTimer(numFrames,FrameSize,Fs);

%% BEGIN initialization time measurement
ticInit(at)

%% Define algorithm coefficients and objects
reader = dsp.AudioFileReader( ...
    'Filename','/Users/michaelnuzzo/Music/iTunes/iTunes Media/Music/Kacey Musgraves/Golden Hour/06 Love Is A Wild Thing.m4a', ...
    'SamplesPerFrame',FrameSize);
addpath('/Users/michaelnuzzo/Documents/Code/MATLAB/Personal Projects/VSTs/Spectrum Pixelator');

plugin = spectrumPixelator;
% plugin.timeRes = FrameSize*2^(5)/Fs;
plugin.timeRes = 1;

% plugin = Pixelator;
% plugin.timeRes = 5;
% plugin.freqRes = 50;
% plugin.dryWet = 100;

%% Optionally perform object setup outside of the simulation look
if setupObjectsOutsideLoop
    setup(reader);
%     setup(notch,zeros(FrameSize,1));
end

%% END initialization time measurement
tocInit(at)

%% BEGIN simulation loop
for index = 1:numFrames
    ticLoop(at) % BEGIN loop timing measurement
    audioIn = reader();
    audioOut = process(plugin, audioIn); %#ok
    tocLoop(at) % END loop timing measurement
end
%% END simulation loop


%% Generate report
[results,figHandle] = generateReport(at);