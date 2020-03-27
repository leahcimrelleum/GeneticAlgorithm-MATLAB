
%%%%%%%%%%%%%
% Class to store information about the processings of a
%	genetic algorithm search (GA.m) and make it available to the
%	statistics class (Statistics.m)
%
% last modification: 09.03.2020
% 
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%

classdef Recorder < handle

	properties(SetAccess = public)
		
		%%% recorder parameters %%%
		writeDir;				% directory to write recorder file in
		writeFile;				% path to recorder file
		writeFreq;				% number of iterations before saving in file
		%%% /recorder parameters %%%
		
		%%% search parameters %%%
		selectionType;
		crossoverProb;
		mutationProb;
		elitismRate;
		%%% /search parameters %%%
		
		%%% population data %%%
		individuals;			% population
		indFitness;				% fitness of population's individuals		
		parentsIndices;			% indices of individuals selected as parents
		parentsFitness;			% fitness of selected parents
		crossoverFlags;			% where crossover was performed
		mutations;				% where how many mutations were performed
		childrenFitnessAMU;		% fitness of children after mutation
		%%% /population data %%%
	end
	
	methods(Access = public)
		
		function this = Recorder(varargin)
			% set up parameters of the recorder
			switch(nargin)
				case 0
					% default values
					this.writeFreq = 100;
					this.writeDir = '.\recDat\';
				case 1
					this.writeFreq = varargin{1};
					this.writeDir = '.\recDat\';
				case 2
					this.writeFreq = varargin{1};
					this.writeDir = varargin{2};
					if(~exist(this.writeDir, 'dir'))
						mkdir(this.writeDir);
					end
			end
			
			% path to the recorder file after saving it for the first time
			this.writeFile = [];
		end
		
		function reset(this)
			% delete path to file, a new file will be generated afterwards
			[this.writeFile] = deal([]);
			
			% delete the data currently stored in this recorder object
			[this.individuals, this.indFitness, this.parentsIndices, ...
				this.parentsFitness, this.crossoverFlags, ...
				this.mutations, this.childrenFitnessAMU] = deal([]);
		end
		
		
		%% set methods
		function setInitPop(this, ancestors, ancestorFitness)
			% set initial population
			this.reset();
			this.individuals = cell(numel(ancestors), 1, 1);
			this.individuals(:, :, 1) = arrayfun(@(x) x.getSolution(), ancestors, 'uni',false);
			this.indFitness(:, :, 1) = ancestorFitness;
		end
		
		function setSearchParameters(this, st, cor, mr, er)
			% set search parameters
			this.selectionType = st;
			this.crossoverProb = cor;
			this.mutationProb = mr;
			this.elitismRate = er;
		end
		
		function setGeneration(this, parentsIdx, parentsFitness, crossoverFlags, mutations, ...
								chFitAMU, children, childrenFitness)
			
			genNr = size(this.individuals, 3);
			
			% set the processing steps of this iteration
			% performed on the individuals of this generation
			this.parentsIndices(:, :, genNr) = parentsIdx;
			this.parentsFitness(:, :, genNr) = parentsFitness;
			this.crossoverFlags(:, :, genNr) = crossoverFlags;
			this.mutations(:, :, genNr) = mutations;
			this.childrenFitnessAMU(:, :, genNr) = chFitAMU;
			
			% set the resulting individuals that constitute the next generation
			this.individuals(:, :, genNr+1) = arrayfun(@(x) x.getSolution(), children, 'uni',false);
			this.indFitness(:, :, genNr+1) = childrenFitness;
			
			% if indicated save recorder data as file
			if(~mod(genNr, this.writeFreq))
				this.writeData();
			end
		end
		
		function setWriteDir(this, writeDir)
			% set a new directory to write in
			this.writeDir = writeDir;
			
			% delete potential path to a file
			this.writeFile = [];
		end
		
		function writeData(this)
			% if no file exists yet create a new file
			if(isempty(this.writeFile))
				this.writeFile = [this.writeDir 'recorder-' datestr(now, 'yyyy-mm-dd-HH-MM') '.mat'];
			end
			
			% write all object data in the assigned file
			save(this.writeFile, 'this');
		end
		
	end % /methods
	
end % /class
