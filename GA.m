
%%%%%%%%%%%%%
% Class to perform a genetic algorithm search using
%	'Individual' class objects (Individual.m) to store solutions and a
%	'Evaluator' class object (Evaluator.m) to determine their performances
%
% last modification: 09.03.2020
% 
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%

classdef GA < handle
	
	properties(SetAccess = private)
		
		%%% properties %%%
		individuals;	% list of all individuals of the population
		indFitness;		% fitness (performance) of all individuals
		
		indEl;			% total number of elements theoretically available
		forbEl;			% elements forbidden to occur in solutions
		indSize;		% number of elements that constitute a solution
		
		evaluator;		% evaluates fitness of individuals / solutions
		 evalHandle;	% handle to calcFitness function (needed for parfor loop)
		
		recorder;		% reference to a recorder object that captures runtime data
		%%% /properties %%%
		
		%%% parameters %%%
		selectionType;	% 1 = RS, random selection
						% 2 = FPS, fitness proportionate selection
						% 3 = RPS, rank proportionate selection
						% 4 = TS, tournament selection
						
		crossoverProb;	% probability of parents to get replaced by their children [0 1]
		
		mutationProb;	% base probability of mutation(s) in each child individual [0 1]
		
		elitism;		% transmit best individuals unchanged to the next generation
							% if 0 <= # < 1	: best # percentage of population is kept
							% if # >= 1		: best # individuals are kept
		%%% /parameters %%%
	end
	
	methods(Access = public)
		
		%% constructor & initialization %%%
		function this = GA(eval, popSize, indEl, indSize, forbEl)
			if(nargin < 5)
				this.forbEl = [];		% no forbidden elements
			else
				this.forbEl = forbEl;
			end
			
			% check if specified parameters are valid
			if(indSize >= indEl - numel(this.forbEl))
				error('Solution size not smaller than allowed elements!');
			end
			if(any(this.forbEl > indEl))
				warning(['Forbidden element [' num2str(this.forbEl(this.forbEl > indEl)) '] ignored! Outside range!']);
			end
			
			% set properties
			this.indEl = indEl;
			this.indSize = indSize;
			
			% set evaluator and function handle to its assessment function
			this.evaluator = eval;
			this.evalHandle = @eval.calcFitness;
			
			% set default parameter values
			this.selectionType = 3;
			this.crossoverProb = 1;
			this.mutationProb = 1 - (1 - 1/popSize)^this.indSize;
			this.elitism = round(popSize / 10);
			
			% initialize population / create individuals
			this.init(popSize);
		end
		
		function init(this, popSize)
			if(nargin < 2)
				popSize = numel(this.individuals);
			end
			rng('shuffle');
			
			% initialize individuals (with random solutions)
			this.individuals = repmat(feval(@Individual, this.indEl, this.indSize, this.forbEl), popSize, 1);
			for indIdx = 2:popSize
				this.individuals(indIdx) = feval(@Individual, this.indEl, this.indSize, this.forbEl);
			end
			this.indFitness = [];
			
			% reset recorder if one is set
			if(~isempty(this.recorder))
				this.recorder.reset();
				this.setRecorderParameters();
			end
		end
		%%% /constructor & initialization %%%
		
		
		%% set methods %%%
		function setSelectionType(this, selType)
			this.selectionType = min(max(selType, 1), 4);
			this.setRecorderParameters();
		end
		function setCrossoverProbability(this, coProb)
			this.crossoverProb = min(max(coProb, 0), 1);
			this.setRecorderParameters();
		end
		function setMutationProbability(this, muProb)
			this.mutationProb = min(max(muProb, 0), 1);
			this.setRecorderParameters();
		end
		function setElitism(this, elitism)
			if(elitism < 1)
				% elitism specified as percentage, calculate natural number
				this.elitism = round(max(elitism, 0) * numel(this.individuals));
			else
				% elitisim specificed as number of individuals
				this.elitism = round(min(elitism, numel(this.individuals)));
			end
			this.setRecorderParameters();
		end
		function setEvaluator(this, eval)
			this.evaluator = eval;
			this.evalHandle = @eval.calcFitness;
		end
		function setRecorder(this, rec)
			this.recorder = rec;
			this.setRecorderParameters();
		end
		function setRecorderParameters(this)
			if(~isempty(this.recorder))
				if(~isempty(this.recorder.individuals))
					warning('Change of parameters in a non-empty recorder!');
				end
				
				this.recorder.setSearchParameters(this.selectionType, this.crossoverProb, ...
														this.mutationProb, this.elitism);
			end
		end
		%%% /set methods %%%
		
		
		%% get methods %%%
		function popSize = getPopulationSize(this)
			popSize = numel(this.individuals);
		end
		function fitness = getIndFitness(this, inds)
			% if no specific individuals to assess are provided as argument
			%	evaluate all individuals of this population
			if(nargin < 2)
				inds = this.individuals;
			end
			fitness = zeros(size(inds, 1), 1);
			
			if(isempty(gcp('nocreate')))
				% serial processing, no open parallel pool
				for indIdx = 1:size(inds, 1)
					fitness(indIdx) = this.evaluator.calcFitness(inds(indIdx));
				end
			else
				% parallel processing, open parallel pool
				% does only work with the object property evaluator function handle
				% copied to a local handle here (otherwise object copied)
				
				calcFitnessHandle = this.evalHandle;
				parfor indIdx = 1:numel(inds)
					fitness(indIdx) = feval(calcFitnessHandle, inds(indIdx));
				end
			end
		end
		function [uniqueInd, uniqueSolutions, nbUniqueInd, uniqueIdx] = getUniqueInd(~, inds)
			% get solutions of the individuals provided as argument in a matrix
			indSolutions = arrayfun(@(x) x.getSolution(), inds(:), 'uni',false);
			indSolutions = cell2mat(indSolutions);
			
			% get unique individuals and solutions in these individuals
			[uniqueSolutions, uniqueIdx] = unique(indSolutions, 'rows', 'stable');
			uniqueInd = inds(uniqueIdx);
			nbUniqueInd = size(uniqueInd, 1);
		end
		%%% /get methods %%%
		
		
		%% selection methods %%%
		function [parents, parentsIdx] = randomSelection(~, individuals)
			% randomly select two individuals
			parentsIdx = randperm(numel(individuals), 2);
			parents = individuals(parentsIdx)';
		end
		
		function [parents, parentsIdx] = fitnessSelection(~, individuals, indFitness)
			% select two individuals with probabilities proportional
			% to the values in argument indFitness
			parentsIdx = zeros(1,2);
			parents = repmat(individuals(1,1), 1, 2);
			for parIdx = 1:2
				normFit = indFitness ./ sum(indFitness);
				addFit = cumsum(normFit);
				selIdx = addFit > rand();
				selIdx = find(selIdx, 1);
								
				parents(parIdx) = individuals(selIdx);
				individuals(selIdx) = [];
				indFitness(selIdx) = [];
				
				parentsIdx(parIdx) = selIdx + (parIdx == 2 && selIdx >= parentsIdx(1));
			end
		end
		
		function [parents, parentsIdx] = rankSelection(this, individuals)
			% select two individuals with probabilities proportional
			% to their ranks as given by their fitness'
			indRank = 1:numel(individuals);
			[parents, parentsIdx] = this.fitnessSelection(individuals, indRank);
		end
		
		function [parents, parentsIdx] = tournamentSelection(~, individuals, indFitness)
			% select two pairs of individuals and select in both
			% the one with the higher fitness
			parentsIdx = randperm(numel(individuals), 4);
			
			parentFitness = indFitness(parentsIdx([1 2; 3 4]));
			
			parentSelection = parentFitness(:,1) < parentFitness(:,2);
			
			parentsIdx = [parentsIdx(1 + parentSelection(1)) parentsIdx(3 + parentSelection(2))];
			parents = individuals(parentsIdx);
		end
		%%% /selection methods %%%
		
		
		%% run algorithm %%%
		function evolve(this, nbIteration)
			% if no number of iterations is provided as argument
			%	perform just one iteration
			if(nargin < 2)
				nbIteration = 1;
			end
			rng shuffle;
			
			nbIndividuals = numel(this.individuals);
			
			% determine if a recorder object is assigned to capture runtime data
			doStats = ~isempty(this.recorder);
			
			% get the individuals initial fitness'
			if(isempty(this.indFitness))
				this.indFitness = this.getIndFitness();

				if(doStats)
					this.recorder.setInitPop(this.individuals, this.indFitness);
				end
			end
			
			%%% evolve the next generation(s)
			for evIdx = 1:nbIteration
				
				% use only unique individuals for further steps
				[uniqueInd, ~, ~, uniqueIndIdx] = this.getUniqueInd(this.individuals);

				% sort individuals by their fitness
				[indFitnessSorted, sortIdx] = sort(this.indFitness(uniqueIndIdx));
				individualsSorted = uniqueInd(sortIdx);

				% elitism - determine best individuals
				bestIndividuals = [];
				if(this.elitism)
					bestIndividuals = individualsSorted(end - this.elitism + 1:end);
					bestIndividualsFitness = indFitnessSorted(end - numel(bestIndividuals) + 1:end);
				end

				% selection - select pairs of parent individuals
				nbParentPairs = ceil(nbIndividuals / 2);								% build full population and discard worst this.elitism children
% 				nbParentPairs = ceil((nbIndividuals - numel(bestIndividuals)) / 2);		% build only as many children as needed
				
				parentsIdx = zeros(nbParentPairs, 2);
				parents = repmat(this.individuals(1,1), nbParentPairs, 2); % allocate memory
				for parIdx = 1:nbParentPairs
					switch(this.selectionType)
						case 1; [newParents, newParentsIdx] = this.randomSelection(individualsSorted);	
						case 2; [newParents, newParentsIdx] = this.fitnessSelection(individualsSorted, indFitnessSorted);
						case 3; [newParents, newParentsIdx] = this.rankSelection(individualsSorted);
						case 4; [newParents, newParentsIdx] = this.tournamentSelection(individualsSorted, indFitnessSorted);
					end

					parentsIdx(parIdx, :) = newParentsIdx;
					parents(parIdx, :) = newParents;
				end
				parentsFitness = indFitnessSorted(parentsIdx);

				% setup a new generation (memory allocation)
				children = parents;
				childrenFitness = zeros(size(children));

				% crossover - create new individuals by pair-wise
				% intermingling the parent individuals if destined
				crossoverFlags = rand(nbParentPairs, 1) < this.crossoverProb;
				for parIdx = 1:nbParentPairs
					if(crossoverFlags(parIdx))
						% do crossover
						[child1, child2] = parents(parIdx, 1).crossover(parents(parIdx, 2));
						children(parIdx, :) = [child1, child2];
					else
						% parents survive without mating
						child1 = parents(parIdx, 1).copy();
						child2 = parents(parIdx, 2).copy();
						children(parIdx, :) = [child1, child2];
						childrenFitness(parIdx, :) = parentsFitness(parIdx, :);
					end
				end

				% mutation - mutate children
				% get unique solutions of children individuals
				[~, uniqueChildrenSol, nbUniqueChildren] = this.getUniqueInd(children);
								
				% determine individual driven mutation
				mutRateInd = 1 - nbUniqueChildren / numel(children);
				
				% determine gene driven mutation
				allowEl = this.indEl - numel(this.forbEl);
				if(this.indSize < allowEl)
					expUniqueGenes = (1 - (1 - this.indSize/allowEl)^nbIndividuals) * allowEl;
					nbUniqueGenes = numel(setdiff(unique(uniqueChildrenSol), 0));
					mutRateGene = (1 - this.indSize/allowEl) * ...
									(1 -  log(max(nbUniqueGenes - this.indSize + 1, 1)) / ...
									log(expUniqueGenes - this.indSize + 1));
				else
					mutRateGene = 0;
				end

				% combine base mutation probability and runtime dependent
				% mutation probabilities to final mutation rate
				mutationRate = min(this.mutationProb + (mutRateInd + mutRateGene)/2, 1);
				
				% carry out mutations
				mutationSizes = zeros(size(children));
				for chIdx = 1:numel(children)
					if(rand < mutationRate)
						% randomly determine number of elements to be mutated
						% according to an exponential decay function
						mutSizeBorders = cumsum(exp(linspace(log(0.001), log(1), this.indSize)));
						mutSizeBorders = fliplr(mutSizeBorders / mutSizeBorders(end));
						
						mutationSize = sum(rand < mutSizeBorders);
						mutationSizes(chIdx) = mutationSize;
						
						children(chIdx).mutate(mutationSize);
					end
				end
				
				% get the childrens' fitness
				modFlag = crossoverFlags(:, ones(2,1)) | (mutationSizes > 0);
				childrenFitness(modFlag) = this.getIndFitness(children(modFlag));
				childrenFitnessAMU = childrenFitness;
				
				% elitism - replace children with the lowest fitness
				%	with the parents with the highest fitness
				if(this.elitism)
					[~, sortIdx] = sort(childrenFitness(:), 'descend');
					useChildren = nbIndividuals - numel(bestIndividuals);

					children = [bestIndividuals; children(sortIdx(1:useChildren))];
					childrenFitness = [bestIndividualsFitness; childrenFitness(sortIdx(1:useChildren))];
				end

				% set the new generation of the population
				this.individuals = children(:);
				this.indFitness = childrenFitness(:);

				% submit necessary data to recorder
				% parentsIdx			= indices of individuals selected as parents
				% parentsFitness		= fitness of parents
				% crossoverFlags		= parent pairs where crossover was performed
				% mutationSizes			= locations where mutations were performed
				% childrenFitnessAMU	= fitness of children after mutation
				% individuals			= new generation (children)
				% indFitness			= fitness of children
				if(doStats)
					this.recorder.setGeneration(parentsIdx, parentsFitness, ...
						crossoverFlags, mutationSizes, childrenFitnessAMU, ...
						this.individuals, this.indFitness);
				end
				
			end % /evolve loop
			
			% save recorded data
			if(doStats)
				this.recorder.writeData();
			end
			
		end
		%%% /run algorithm %%%
		
	end % /methods
	
end % /class
