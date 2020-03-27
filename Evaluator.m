
%%%%%%%%%%%%%
% Class to evaluate solutions in a
%	genetic algorithm search (GA.m) stored as
%	individual class objects (Individual.m) using the data
%	submitted in the constructor and stored as class properties
%
% last modification: 09.03.2020
% 
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%

classdef Evaluator < handle
	
	properties(SetAccess = private, GetAccess = public)
		
		totElements;
		
	end
	
	methods(Access = public)
		
		%% constructor
		% sets up the object that evaluates the performance of solutions
		%	submit as arguments all the data needed to do so
		%	and store it in additional class properties
		%	for the calcFitness function to use it
		function this = Evaluator(totElements)
			
			this.totElements = totElements;
			
		end
		
		
		%% fitness function
		% function that calculates a performance / fitness value
		%	for an arbitrary solution provided as argument in a
		%	'Individual' class object (Individual.m), using the data
		%	stored as class properties during object construction
		function perf = calcFitness(this, individual)
			
			% get the solution in number or binary representation
			solution = individual.getSolution();		% e.g.: [1 3 5 8]
% 			solution = individual.getSolutionBin();		% e.g.: [1 0 1 0 1 0 0 1]
			
			% calculate the performance value of this solution
			% here a dummy performance evaluation is used for demonstration
			perf = sum(solution) / sum(1:this.totElements);
			
		end

	end % /methods
	
end % /class
