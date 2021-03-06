function plotOrientationsPF(input, varargin)
% Function to load and plot grain orientations in pole figures
%
% Points in the pole figure can be colored accoring to the intensity of the pole figure 
% or the ODF at the corresponding orientation
%
% Syntax
%
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h)
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h, 'minpf',0.0, 'maxpf',5.)
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h, 'colormap', 'WhiteJet')
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h, 'halfwidth', 10)
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h, 'odfColor', true)
%   plotOrientationsPF(inputfile,'cs',cs_ppv,'ss',ss, 'hkl', h, 'output', outputfile)
%
%
% Input
%
%  input can either 
%		- the full path to the file with the list of euler angles, or, (see loadOrientations.m for file format)
%		- a list of orientations if they are already known
%
% Required parameters 
%
%    cs: crystal system
%    ss: sample system
%    hkl: list of hkl for pole figures
%
% Optional parameters
%
%    outputfile : full path to name of file in which to save the image
%    odfColor: color points according to ODF intensity. Otherwise, points are colored according to PF intensity
%    halfwidth: halfwidth for ODF calculation, in degrees, default is 15
%    minpf: minimum for intensity plot (max should be set as well)
%    maxpf: minimum for intensity plot (min should be set as well)
%    hem: hemisphere (upper or lower, upper by default)
%    markersize: 7 by default
%    colormap: name of colormap, between single quotes, default is 'plasma', you can use 'WhiteJet', for instance
% 
% See also loadOrientations
%
% This is part of the TIMEleSS tools
% http://timeless.texture.rocks/
%
% Copyright (C) S. Merkel, Universite de Lille, France
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.


	% default parameters and parser
	p = inputParser;
	addParameter(p,'cs',false);
	addParameter(p,'ss',false);
	addParameter(p,'hkl',false);
	addParameter(p,'outputfile',false);
	addParameter(p,'odfColor',false,@islogical);
	addParameter(p,'halfwidth',15., @isfloat);
	addParameter(p,'minpf',false, @isfloat);
	addParameter(p,'maxpf',false, @isfloat);
	addParameter(p,'hem','upper', @isstring);
	addParameter(p,'markersize',7, @isfloat);
	addParameter(p,'colormap', 'plasma', @ischar);
	parse(p,varargin{:});
	odfColor = p.Results.odfColor;
	outputfile = p.Results.outputfile;
	cs = p.Results.cs;
	ss = p.Results.ss;
	h = p.Results.hkl;
	minpf = p.Results.minpf;
	maxpf = p.Results.maxpf;
	halfwidth = p.Results.halfwidth;
	hem = p.Results.hem;
	markersize = p.Results.markersize;
	colormap = p.Results.colormap;
	
	if (islogical(cs))
		fprintf('\nError: no crystal symmetry provided\n')
		return
	end
	if (islogical(ss))
		fprintf('\nError: no crystal sample provided\n')
		return
	end
	if (islogical(h))
		fprintf('\nError: no list of hkl provided\n')
		return
	end
	
	% If input parameter is a char,
	% load file and create the corresponding list of orientations
	if (ischar(input))
		ori0 = loadOrientations(input, cs, ss);
		n = size(ori0);
	% Else, if input is a list of orientations, just copy them
	elseif (isa(input,'orientation'))
		ori0 = input;
		n = size(ori0);
		fprintf('\nStarting from %d orientations\n', n)
	end
		
	% Fit an ODF to the data
	odf = calcODF(ori0,'halfwidth',halfwidth*degree);
	fprintf('\nCalculated an ODF based on grain orientations\n')
	
	if (not(odfColor))
		% Plot orientations, colors according to pole figure
		% Working on each pole figure individually
		nhkl = size(h,2);
		f=newMtexFigure('figSize','large','layout',[1,nhkl]);
		for i =1:nhkl
			thishkl = h(i);
			fprintf('\nWorking on %d%d%d pole figure\nCalculating pf value at each orientation\n', h(i).h, h(i).k, h(i).l);
			clear colors
			v = ori0*thishkl;
			pf = calcPoleFigure(odf,thishkl,v);
			colors = pf.intensities;
			fprintf('\nPlotting the pole figure\n');
			if i == 1
				plotPDF(ori0,colors,thishkl,'antipodal','MarkerSize',markersize,'all',hem);
			else
				mtexFig = gcm;
				plotPDF(ori0,colors,thishkl,'antipodal','MarkerSize',markersize,'all',hem,'parent',mtexFig.nextAxis);
			end
		end
		f.drawNow;
		if (islogical(minpf) || islogical(maxpf)) 
			CLim(gcm,'equal');
		else
			CLim(gcm,[minpf,maxpf]);
		end
		mtexColorMap(char(colormap));
		mtexColorbar;
	else
		% Plot orientations, colored based on ODF
		fprintf('\nPlotting grain orientations, color based on ODF value for each grain\n')
		plotPDF(ori0,eval(odf,ori0),h,'antipodal','MarkerSize',markersize,'all',hem);
		if (islogical(minpf) || islogical(maxpf)) 
			CLim(gcm,'equal');
		else
			CLim(gcm,[minpf,maxpf]);
		end
		mtexColorMap(char(colormap));
		mtexColorbar;
	end
	if (not (outputfile==false))
		% Save plot to the output file
		saveas(gcf,outputfile);
		fprintf('\nSaved plot of grain orientations in \n\t%s\n', outputfile)
	end
end
