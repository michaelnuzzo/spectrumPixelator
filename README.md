<div  align="center">

<img width="400" src="docs/imgs/logo.jpg">
[![View Spectrum Pixelator on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/72449-spectrum-pixelator)


</div>

## Overview

The Spectrum Pixelator is a real-time VST plugin that deconstructs a real-time audio signal into its most significant spectral components. By using advantages of the Modified Discrete Cosine Transform in eliminating time-domain artifacts, the Spectrum Pixelator alters the signal by isolating the most prominent spectral components of a signal and eliminating the remaining frequency components. For more information, please visit the Mathworks File Exchange submission linked above, or watch the short demonstration video below.
<div  align="center">
<a href="https://youtu.be/tT46hXvSd8Q"><img width="600px" src="docs/imgs/thumb.jpg"></a> 
</div>

This plugin won the Silver Award in the 2019 AES MATLAB Plugin Student Competition at the 247th Audio Engineering Society Convention.

## Install

The VST itself can be downloaded from the [Releases page](https://github.com/michaelnuzzo/spectrumPixelator/releases) in this repository. Once downloaded, the plugin can be installed by simply dragging the VST file into your plugins folder. 

```
macOS:
Macintosh HD/Library/Audio/Plug-Ins/VST
```


## Build

At present, the only binaries available are for VST on macOS. However, if you would like to generate your own binary for Windows or another file format and you own a copy of MATLAB and the Audio System Toolbox, you can compile your own plugin.

First, clone this repository to your local machine.

```
git clone https://github.com/michaelnuzzo/spectrumPixelator.git
```

Open the MATLAB file that contains the DSP loop (plugin/spectrumPixelator.m) in MATLAB, and run the file. In the MATLAB command window, run the VST generator. See the [MATLAB documentation](https://www.mathworks.com/help/audio/ref/generateaudioplugin.html) for different options on export flags and formats.

```
generateAudioPlugin spectrumPixelator
```
The compiled binary should be saved to your working MATLAB directory, and you can install the file using the process detailed in [Install](#install).
