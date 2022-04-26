Hypothesis testing plasticity (HTP)

This is the Matlab code to reproduce the results in the manuscript:
"Short-term plasticity as cause-effect hypothesis testing in distal reward learning", by Andrea Soltoggio


    Copyright (C) 2013 Andrea Soltoggio

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. 


#####
USAGE
#####

To launch one experiment, types the following lines in matlab

exper = 1;
seed = 1;
phase = 1;
name = ['experimentID_e' num2str(exper) 'p' num2str(phase) 's' num2str(seed)];
env = netEnvRECO(exper,phase,seed,name);

and follow the instructions.

For monitoring the progress with graphics (slower), proceed with:

env.createWindow

and then press button “start/stop”

For faster execution (no graphical monitoring), proceed with

env.mainLoop 
