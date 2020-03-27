
%%%%%%%%%%%%%
% Class to store solutions as individuals and make them processible for a
%	genetic algorithm class object (GA.m)
%
% last modification: 09.03.2020
% 
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%

classdef Individual < handle
	
	properties(SetAccess = protected)

		solution;		% solution of individual as a binary vector
		solSize;		% size of solution
		forbEl;			% forbidden dimensions

	end

	methods(Access = public)

		%% constructor
		function this = Individual(nbEl, solSize, forbEl)
			% specify elements allowed resp. forbidden in solution
			if(nargin < 3)
				this.forbEl = [];
				allowedEl = 1:nbEl;
			else
				this.forbEl = forbEl;
				allowedEl = setdiff(1:nbEl, forbEl);
			end
			
			% set up a random solution
			this.solSize = solSize;
			this.solution = false(1, nbEl);
			
			randSol = randperm(numel(allowedEl), solSize);
			this.solution(allowedEl(randSol)) = 1;
		end
		
		% copy 'constructor'
		function newInd = copy(this)
			% create and return a new 'Individual' object with the same solution
			newInd = feval(class(this), numel(this.solution), this.solSize, this.forbEl);
			newInd.setSolutionBin(this.solution);
		end
		
		
		%% get/set methods
		function setSolution(this, newSolution)
			this.solution = false(1, numel(this.solution));
			this.solution(newSolution) = 1;
		end
		
		function setSolutionBin(this, newSolution)
			this.solution = newSolution;
		end
		
		% returns solution as a vector of whole numbers
		function currSolution = getSolution(this)
			currSolution = find(this.solution);
		end
		
		% returns solution as a binary vector
		function currSolution = getSolutionBin(this)
			currSolution = this.solution;
		end
		
		function elForbidden = getForbiddenElements(this)
			elForbidden = this.forbEl;
		end
		
		
		%% crossover - between this individual and argument individual
		function [child1, child2] = crossover(this, parentB)
			% does imitate the shuffle crossover procedure under the restriction of
			%	non-changing solution sizes and unique elements in the new solutions
			% every number of element exchange (within the restricted possibilities)
			%	is similarly probable	
			
			nbEl = numel(this.solution);
			
			% get parent solutions
			p1sol = find(this.solution);
			p2sol = find(parentB.solution);
			
			% more than one element must be different for crossover to make sense
			solDiff = numel(setdiff(p1sol, p2sol));
			if(solDiff > 1)
				% determine elements that appear in both parents
				%	they must also appear in both children
				combSol = [p1sol p2sol];
				combSolUnique = unique(combSol);
				bincounts = histc(combSol, combSolUnique);
				doubleEl = combSolUnique(bincounts == 2); 
				
				% remove double elements
				p1singleEl = setdiff(p1sol, doubleEl);
				p2singleEl = setdiff(p2sol, doubleEl);

				% randomly reorder solutions of both parents
				p1singleEl = p1singleEl(randperm(numel(p1singleEl)));
				p2singleEl = p2singleEl(randperm(numel(p1singleEl)));

				% perform crossover at a random location
				coPoint = randi(numel(p1singleEl)-1);
				c1sol = [p1singleEl(1:coPoint) p2singleEl(coPoint+1:end)];
				c2sol = [p2singleEl(1:coPoint) p1singleEl(coPoint+1:end)];

				% readd double elements
				c1sol = [c1sol doubleEl];
				c2sol = [c2sol doubleEl];

				% create children individuals
				child1 = Individual(nbEl, this.solSize, this.forbEl);
				child1.setSolution(c1sol);

				child2 = Individual(nbEl, this.solSize, this.forbEl);
				child2.setSolution(c2sol);
			else
				% return parents as children
				child1 = this.copy();
				child2 = parentB.copy();
			end
		end
		
		
		%% mutation - change some element(s) of this individual's solution
		function mutate(this, mutSize)
			% if no number of elements to mutate is provided as argument
			%	mutate one element
			if(nargin < 2)
				mutSize = 1;
			end
			
			currSol = find(this.solution);
			
			% get unused and allowed elements
			possEl = setdiff(1:numel(this.solution), [currSol this.forbEl]);
			
			% determine mutation size
			mutSize = min(mutSize, numel(possEl));
			
			% determine elements to mutate
			mutElPos = randperm(numel(currSol), mutSize);
			
			% replace elements with new elements
			currSol(mutElPos) = possEl(randperm(numel(possEl), mutSize));
			this.solution = false(1, numel(this.solution));
			this.solution(currSol) = 1;
		end
		
	end % /methods

end % /class
