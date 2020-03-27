
%%%%%%%%%%%%%
% Example script to run a genetic algorithm (GA) search for superior
%	discrete solutions of a fixed size drawn from a finite number of
%	elements without replacement per solution.
%
%	For demonstration, this script can be executed without further changes.
%	See also the corresponding README.txt for further explanations.
%	The algorithm will automatically use an open parallel pool (parpool)
%	to calculate the performances of solutions.
%
%	mandatory used classes:
%	-----------------------
%	- Individual.m	solutions are stored as individuals for use in the GA
%	- GA.m			iteratively processes a defined number of individuals
%					according to the specified parameters to approach
%					better performing solutions
%					in its current form, it maximizes the performance
%					for minimization e.g. use the negative performances
%	- Evaluator.m	holds the data necessary to assess solutions and
%					provides a function to do so for arbitrary solutions
%					accordingly, this class must be adapted first to the
%					specific needs
%
%	optionally used classes:
%	------------------------
%	- Recorder.m	records the step-wise progress made by the GA
%	- Statistics.m	offers possibilities to display information regarding a
%					completed search when provided a recorder object
%
% last modification: 09.03.2020
% 
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%


%% set parameters

nbIndividuals	= 40;		% number of individuals / size of population

nbEvolvements	= 77;		% number of iterations to perform

totElements		= 30;		% total number of elements (1:totElements)

solSize			= 9;		% number of elements in a solution


% optionally specify 'forbidden' elements that must not occur in a solution
forbiddenEl		= [7 14 21];



%% set up evaluator

% set up an evaluator object
%	the class must be adapted first to assess arbitrary solutions as intended
%	all data necessary to do so must be provided here as additional arguments
%	and stored within the evaluator class as properties for subsquent use
% currently this is a dummy evaluator simply summing the elements of a
%	solution and dividing it by the sum of total elements
%	e.g. with 30 possible elements in total the fitness of solution [1:9] is
%			sum(1:9)/sum(1:30) = 0.0968

evaluator = Evaluator(totElements);



%% set up population and assign recorder

% optionally set up a new recorder object
%	optional argument 1: number of iterations before the data is stored in a mat-file, default value = 100
%	optional argument 2: path of the directory to store the file, default = ./recDat/

rec = Recorder();
% rec = Recorder(50);
% rec = Recorder(50, '.\newRecDat\');


% set up a population with
%	the initialized evaluator object to assess solutions (1st argument)
%	the specificed parameters (arguments 2-4, and optionally argument 5)

pop = GA(evaluator, nbIndividuals, totElements, solSize);
% pop = GA(evaluator, nbIndividuals, totElements, solSize, forbiddenEl);


% assign the recorder object to the population to record the subsequent evolution
% optional, otherwise no data is recorded and no statistics can be viewed afterwards
pop.setRecorder(rec);



%% reset population and run algorithm

% initialize population, resets a random population
%	(not actually necessary if no iterations have been performed yet)
pop.init();


% perform a specified number of iterations
%	if no argument is provided, one iteration is carried out
pop.evolve(nbEvolvements);


% an arbitrary number of additional iterations can be appended
%	e.g. in case no solution with satisfactory performance has been found yet
pop.evolve(33);



%% view statistics

Statistics(rec);


