
%%%%%%%%%%%%%
% Class to display information of a search performed by the
%	genetic algorithm class (GA.m) and recorded with an assigned
%	recorder class object (Recorder.m)
%
% last modification: 09.03.2020
%
% © Michael Müller
%	GitHub:	leahcimrelleum
%	ORCID:	0000-0002-6915-4820
%%%%%%%%%%%%%

classdef Statistics < handle
	
	properties(SetAccess = public)
		
		%%% data properties %%%
		recorder;		% recorder object holding the data
		selGen;			% currently displayed generation
		allSolMat;		% all solutions of the current generation in a matrix
		%%% /data properties %%%
		
		%%% GUI elements %%%
		window;
		sldGen;
		subWins;
		txtElem;
		tmpObj;
		
		statsOpt;
		statsFun;
		selTypes;
		
		lbxStatsSel;
		lbxWinCols;
		lbxWinRows;
		%%% /GUI elements %%%
	end

	methods(Access = public)
		
		%% constructor
		function this = Statistics(rec)
			if(isempty(rec) || isempty(rec.individuals))
				warning('Empty recorder!');
				return;
			end
			
			% set recorder and the generation to display initially
			this.recorder = rec;
			this.allSolMat = this.getSolutionMat(this.recorder.individuals);
			
			% set all available statistics to display
			% and the corresponding functions
			this.statsOpt = {'population fitness summary (mean ± sd & max)', ...
							'population fitness complete', ...
							'generation fitness', ...
							'element changes per individual (mean ± sd)', ...
							'element selection (cumulative)', ...
							'unique solutions & elements', ...
							'total unique solutions (cumulative)', ...
							'parent fitness (mean ± sd)', ...
							'crossovers', ...
							'mutations', ...
							'mutation portions', ...
							'fitness changes'};
			this.statsFun = {@this.plotPopFitSum, ...
							@this.plotPopFitCompl, ...
							@this.plotPopulationDist, ...
							@this.plotIndChanges, ...
							@this.plotElementSelection, ...
							@this.plotUniqueIndEl, ...
							@this.plotTotIndPop, ...
							@this.plotParentFitness, ...
							@this.plotCrossover, ...
							@this.plotMutations, ...
							@this.plotMutationRate, ...
							@this.plotFitnessChanges};
						
			% setup the available selection types
			this.selTypes = {'Random', ...
								'Fitness prop.', ...
								'Rank prop.', ...
								'Tournament'};
			
			% setup GUI elements
			this.lbxStatsSel = [];
			this.tmpObj = {};
			
			% setup window
			winSize = [1366 768];
			screenSize = get(0, 'ScreenSize');
			winSize = min([winSize; screenSize(3:4)]);
			this.window = figure('Position',[(screenSize(3)-winSize(1))/2 ...
											(screenSize(4)-winSize(2))/2 ...
											winSize]);
			colormap(this.window, hot);
			this.baseWin(this.window);
			this.plotTxtElem();
			
			for selIdx = 1:numel(this.lbxStatsSel)
				set(this.lbxStatsSel(selIdx), 'String',this.statsOpt);
			end
		end
		
		
		%% get/set methods
		function solutions = getSolutionMat(~, individuals)
			% return solutions of submitted individuals in a matrix
			allSolSizes = cellfun(@(x) numel(x), individuals);
			solutions = cellfun(@(x) [x zeros(1, max(allSolSizes(:)) - numel(x))], individuals, 'uni',false);
			solutions = cell2mat(solutions);
		end
		
		
		%% GUI win functions
		function baseWin(this, fig)
			% setup the last generation to display initially
			this.selGen = size(this.recorder.individuals, 3);
			
			this.sldGen	= uicontrol('Parent',fig, 'Style','slider', ...
							'Units','normalized', 'Position',[0.1 0.96 0.89 0.03], ...
							'Min',1, 'Max', this.selGen, 'Value',this.selGen, ...
							'SliderStep',[1/(this.selGen-1) 10/(this.selGen-1)], ...
							'Callback',@this.changeGen);
			
			% setup default window configuration
			iniWinRow = 2;
			iniWinCol = 1;
			
			this.lbxWinRows	= uicontrol('Parent',fig, 'Style','popupmenu', ...
										'Units','normalized', 'Position',[0.01 0.95 0.04 0.04], ...
										'String',1:3, 'Value',iniWinRow, 'Callback',@this.changeSubWin);
			this.lbxWinCols	= uicontrol('Parent',fig, 'Style','popupmenu', ...
										'Units','normalized', 'Position',[0.055 0.95 0.04 0.04], ...
										'String',1:3, 'Value',iniWinCol, 'Callback',@this.changeSubWin);
			
			% setup fix text fields
			uicontrol('Parent',fig, 'Style','text', 'Units','normalized', 'Position',[0.01 0.90 0.075 0.03], ...
				'String','Nb. of individuals', 'Fontweight','bold');
			uicontrol('Parent',fig, 'Style','text', 'Units','normalized', 'Position',[0.01 0.87 0.075 0.03], ...
				'String',size(this.recorder.individuals, 1));
			
			% setup algorithm dependent parameter txt fields
			upperHeight = 0.84;
			nbAlgoParam = this.plotParameters(fig, upperHeight);
			upperHeight = upperHeight - 0.03*nbAlgoParam;
			
			% setup generation dependent text fields
			uicontrol('Parent',fig, 'Style','text', 'String','Generation', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 upperHeight-0.03 0.075 0.03]);
			this.txtElem(1) = uicontrol('Parent',fig, 'Style','text', 'Units','normalized', ...
										'Position',[0.01 upperHeight-0.06 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Avg. fitness', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 upperHeight-0.10 0.075 0.03]);
			this.txtElem(2) = uicontrol('Parent',fig, 'Style','text', 'Units','normalized', ...
										'Position',[0.01 upperHeight-0.13 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Best fitness', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 upperHeight-0.17 0.075 0.03]);
			this.txtElem(3) = uicontrol('Parent',fig, 'Style','text', 'Units','normalized', ...
										'Position',[0.01 upperHeight-0.20 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Unique solutions', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 upperHeight-0.24 0.075 0.03]);
			this.txtElem(4) = uicontrol('Parent',fig, 'Style','text', 'Units','normalized', ...
										'Position',[0.01 upperHeight-0.27 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Unique elements', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 upperHeight-0.31 0.075 0.03]);
			this.txtElem(5) = uicontrol('Parent',fig, 'Style','text', 'Units','normalized', ...
										'Position',[0.01 upperHeight-0.34 0.075 0.03]);		
			
			% setup field displaying the best resection of the
			% currently selected generation
			selSize = size(this.allSolMat, 2) * 0.04;
			yBottom = max(0.87-selSize, 0);
			uicontrol('Parent',fig, 'Style','text', 'String','Current best solution', ...
						'Fontweight','bold', 'Units','normalized', 'Position',[0.92 0.87 0.07 0.06]);
			this.txtElem(6) = uicontrol('Parent',fig, 'Style','text', 'Fontweight','bold', ...
										'Units','normalized', 'Position',[0.92 yBottom 0.07 0.87-yBottom]);
			
			% setup statistic windows
			this.changeSubWin();
		end
		
		function initSubWin(this, nbRow, nbCol)
			% setup sub-windows for the statistic plots
			for rowIdx = 1:nbRow
				for colIdx = 1:nbCol
					
					winIdx = (rowIdx-1)*nbCol + colIdx;
					
					this.subWins(winIdx) = subplot(nbRow, nbCol, winIdx);
					
					xCoord = 0.125 + (colIdx - 1) * 0.85/nbCol;
					yCoord = 0.025 + (nbRow - rowIdx) * 0.925/nbRow;
					
					lbxSel	= uicontrol('Parent',this.window, 'Style','popupmenu', ...
										'Units','normalized', 'Position',[xCoord yCoord 0.22 0.04], ...
										'String',this.statsOpt, 'Value',winIdx, ...
										'Callback',@this.changeStatsSel);
					
					this.lbxStatsSel(winIdx) = lbxSel;
				end
			end
		end
		
		
		%% callback functions
		function changeSubWin(this, ~, ~)
			% get new number of sub-windows
			nbRow = get(this.lbxWinRows, 'Value');
			nbCol = get(this.lbxWinCols, 'Value');
			
			% store current statistic selections
			storeNb = min(nbRow*nbCol, numel(this.lbxStatsSel));
			storeSel = get(this.lbxStatsSel, 'Value');
			if(numel(storeSel) > 1)
				storeSel = cell2mat(storeSel(1:storeNb));
			end
			
			% clear sub windows
			delete(this.subWins);
			delete(this.lbxStatsSel);
			this.subWins = [];
			this.lbxStatsSel = [];
			this.tmpObj = {};
			
			% initialize new sub windows
			this.initSubWin(nbRow, nbCol);
			
			% restore previous stats selections
			subWinSel = [storeSel; setdiff(1:(nbRow*nbCol), storeSel)'];
			for subWinIdx = 1:(nbRow*nbCol)
				sel = this.lbxStatsSel(subWinIdx);
				statsSel = subWinSel(subWinIdx);
				set(sel, 'Value',statsSel);
				feval(this.statsFun{statsSel}, subWinIdx, 1);
			end
		end
		
		% perform change in selection of statistics to display
		function changeStatsSel(this, source, ~)
			subWinIdx = find(source == this.lbxStatsSel, 1);
			
			% delete current display
			statsSel = get(source, 'Value');
			cla(this.subWins(subWinIdx));
			legend(this.subWins(subWinIdx), 'off');
			reset(this.subWins(subWinIdx));
			this.tmpObj{subWinIdx} = [];
			
			% setup new display
			feval(this.statsFun{statsSel}, subWinIdx, 1);
		end
		
		% perform change in the generation selected to display
		function changeGen(this, source, ~)
			this.selGen = round(get(source, 'Value'));
			
			% delete generation dependent objects
			cellfun(@delete, this.tmpObj);
			
			% get current statistics selections and setup display
			statsSel = get(this.lbxStatsSel, 'Value');
			if(numel(statsSel) > 1)
				statsSel = cell2mat(statsSel);
			end
			for subWinIdx = 1:numel(statsSel)
				feval(this.statsFun{statsSel(subWinIdx)}, subWinIdx, 0);
			end
						
			this.plotTxtElem();
		end
		
		
		%% plot statistics functions
		% display generation dependent parameters
		function plotTxtElem(this)
			set(this.txtElem(1), 'String',num2str(this.selGen));
			
			genFitMean = mean(this.recorder.indFitness(:, :, this.selGen));
			[genFitMax, maxIdx] = max(this.recorder.indFitness(:, :, this.selGen));
			
			set(this.txtElem(2), 'String',num2str(genFitMean));
			set(this.txtElem(3), 'String',num2str(genFitMax));
			
			individuals = this.allSolMat(:, :, this.selGen);
			uniqueInd = size(unique(individuals, 'rows'), 1);
			uniqueGenes = numel(setdiff(unique(individuals), 0));
			
			set(this.txtElem(4), 'String',num2str(uniqueInd));
			set(this.txtElem(5), 'String',num2str(uniqueGenes));
			
			maxIndSel = this.recorder.individuals{maxIdx, :, this.selGen};
			set(this.txtElem(6), 'String',maxIndSel);
		end
		
		% display algorithm dependent parameters
		function nbParam = plotParameters(this, fig, startHeight)
			nbParam = 8;
			startHeight = startHeight - 0.03*(0:nbParam);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Selection Type', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 startHeight(1) 0.075 0.03]);
			uicontrol('Parent',fig, 'Style','text', 'String',this.selTypes{this.recorder.selectionType}, ...
						'Units','normalized', 'Position',[0.01 startHeight(2) 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Crossover prob.', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 startHeight(3) 0.075 0.03]);			
			uicontrol('Parent',fig, 'Style','text', 'String',this.recorder.crossoverProb, ...
						'Units','normalized', 'Position',[0.01 startHeight(4) 0.075 0.03]);

			uicontrol('Parent',fig, 'Style','text', 'String','Mutation prob.', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 startHeight(5) 0.075 0.03]);
			uicontrol('Parent',fig, 'Style','text', 'String',this.recorder.mutationProb, ...
						'Units','normalized', 'Position',[0.01 startHeight(6) 0.075 0.03]);
			
			uicontrol('Parent',fig, 'Style','text', 'String','Elite individuals', 'Fontweight','bold', ...
						'Units','normalized', 'Position',[0.01 startHeight(7) 0.075 0.03]);
			uicontrol('Parent',fig, 'Style','text', 'String',this.recorder.elitismRate, ...
						'Units','normalized', 'Position',[0.01 startHeight(8) 0.075 0.03]);
		end
		
		% plot population fitness summary
		function plotPopFitSum(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 5)
				fullDraw = 1;
			end
			hold on;
			
			% get fitness average and maximum
			popFitMean = squeeze(mean(this.recorder.indFitness, 1));
			popFitMax = squeeze(max(this.recorder.indFitness, [], 1));
						
			% potentially plot static elements
			if(fullDraw)
				popFitStd = squeeze(std(this.recorder.indFitness, 0, 1));
				
				cla;
				legend('off');
				plot([popFitMean-popFitStd popFitMean+popFitStd], 'Color',[255 207 207]/255);
				plot(1:numel(popFitMean), repmat(mean(popFitMean), numel(popFitMean), 1), ':', 'Color',[255 127 127]/255);
				plot(popFitMean, 'r');
				plot(popFitMax, 'Color', [63 207 63]/255);
				xlim([1 numel(popFitMean)]);
			end
			
			% plot generation dependent elements
			h1 = plot(this.selGen, popFitMean(this.selGen), 'or');
			h2 = plot(this.selGen, popFitMax(this.selGen), 'o', 'Color', [63 207 63]/255);
			this.tmpObj{subWinIdx} = [h1 h2];
		end
		
		% plot population fitness of all individuals
		function plotPopFitCompl(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 1)
				fullDraw = 1;
			end
			hold on;
			
			% potentially plot static elements
			if(fullDraw)
				cla;
				legend('off');
				imagesc(squeeze(this.recorder.indFitness), [min(this.recorder.indFitness(:)) max(max(this.recorder.indFitness(:)), 1)]);
				set(gca, 'YDir','reverse');
				axis tight;
			end
			
			% plot generation dependent elements
			nbIndividuals = size(this.recorder.individuals, 1);
			h1 = line([this.selGen this.selGen]-0.5, [0.5 nbIndividuals+0.5], 'Color','c');
			h2 = line([this.selGen this.selGen]+0.5, [0.5 nbIndividuals+0.5], 'Color','c');
			this.tmpObj{subWinIdx} = [h1 h2];
		end
		
		% plot fitness of all individuals of selected generation
		function plotPopulationDist(this, subWinIdx, ~)
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			
			cla;
			bar(this.recorder.indFitness(:, :, this.selGen));
			xlim([0 size(this.recorder.indFitness, 1)+1]);
			
			minFit = min(this.recorder.indFitness(:));
			maxFit = max(this.recorder.indFitness(:));
			ylim([minFit*0.8 maxFit*1.2]);
		end
		
		% plot average changes occuring in individuals between generations	
		function plotIndChanges(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 4)
				fullDraw = 1;
			end
			hold on;
			
			% potentially plot static elements
			if(fullDraw)
				[nbIndividuals, ~, nbGen] = size(this.allSolMat);
				indChanges = zeros(nbGen, nbIndividuals);

				% determine change of every individual
				% between all successive generations
				for genIdx = 2:nbGen
					for indIdx = 1:nbIndividuals

						oldInd = this.recorder.individuals{indIdx, :, genIdx - 1};
						newInd = this.recorder.individuals{indIdx, :, genIdx};

						intersection = bsxfun(@minus, oldInd, newInd');
						indChanges(genIdx, indIdx) = max(numel(oldInd), numel(newInd)) - sum(intersection(:) == 0);
					end
				end

				indChanges(1, :) = [];
				indChangeMean = mean(indChanges, 2);
				indChangeStd = std(indChanges, 0, 2);
				
				cla;
				legend('off');
				plot(1:nbGen-1, [indChangeMean-indChangeStd indChangeMean+indChangeStd], 'Color',[207 207 255]/255);
				plot(1:nbGen-1, repmat(mean(indChangeMean), numel(indChangeMean), 1), ':', 'Color',[127 127 255]/255);
				plot(1:nbGen-1, indChangeMean, 'b');
				xlim([1 nbGen]);
			else
				axChildren = get(gca, 'Children');
				indChangeMean = get(axChildren(1), 'YData');
			end
			
			% plot generation dependent elements
			if(this.selGen <= numel(indChangeMean))
				h1 = plot(this.selGen, indChangeMean(this.selGen), 'bo');
				this.tmpObj{subWinIdx} = h1;
			end
		end
	
		% plot selection frequencies of all elements until selected generation
		function plotElementSelection(this, subWinIdx, ~)
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			
			nbEl = max([this.recorder.individuals{:}]);
			genEl = [this.recorder.individuals{:,:,1:this.selGen}];
			itemSel = histc(genEl, 1:nbEl);
			
			cla;
			bar(itemSel);
			xlim([0 nbEl+1]);
		end
		
		% plot unique individuals and elements of all generations
		function plotUniqueIndEl(this, subWinIdx, fullDraw)			
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 4)
				fullDraw = 1;
			end
			hold on;
			
			% potentially plot static elements
			if(fullDraw)
				nbGen = size(this.allSolMat, 3);
				nbUniqueInd = zeros(nbGen, 1);
				nbUniqueEl = zeros(nbGen, 1);
				for genIdx = 1:nbGen
					nbUniqueInd(genIdx) = size(unique(this.allSolMat(:, :, genIdx), 'rows'), 1);
					nbUniqueEl(genIdx) = numel(setdiff(unique(this.allSolMat(:, :, genIdx)), 0));
				end
				
				cla;
				legend('off');
				plot(1:nbGen, repmat(mean(nbUniqueInd), nbGen, 1), ':', 'Color',[127 127 255]/255);
				h1 = plot(nbUniqueInd, 'b');
				plot(1:nbGen, repmat(mean(nbUniqueEl), nbGen, 1), ':', 'Color',[255 127 255]/255);
				h2 = plot(nbUniqueEl, 'm');
				xlim([1 nbGen]);
				ylim([min(min(nbUniqueInd), min(nbUniqueEl))-1 max(max(nbUniqueInd), max(nbUniqueEl))+1]);
				legend([h1, h2], {'solutions', 'elements'});
			else
				axChildren = get(gca, 'Children');
				h1 = axChildren(3);
				h2 = axChildren(1);
				nbUniqueInd = get(h1, 'YData');
				nbUniqueEl = get(h2, 'YData');
			end
			
			% plot generation dependent elements
			h3 = plot(this.selGen, nbUniqueInd(this.selGen), 'bo');
			h4 = plot(this.selGen, nbUniqueEl(this.selGen), 'mo');
			this.tmpObj{subWinIdx} = [h3 h4];
			legend([h1 h2]);
		end
		
		% plot cumulative number of unique individuals in the population
		function plotTotIndPop(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 1)
				fullDraw = 1;
			end
			hold on;
			
			% potentially plot static elements
			if(fullDraw)
				nbGen = size(this.allSolMat, 3);
				uniqueInd = [];
				nbEvalInd = zeros(nbGen, 1);
				for genIdx = 1:nbGen
					uniqueInd = unique([uniqueInd; this.allSolMat(:, :, genIdx)], 'rows');
					nbEvalInd(genIdx) = size(uniqueInd, 1);
				end
				
				cla;
				legend('off');
				plot(nbEvalInd, 'b');
				xlim([1 nbGen]);
			else
				axChildren = get(gca, 'Children');
				nbEvalInd = get(axChildren(1), 'YData');
			end
			
			% plot generation dependent elements
			h1 = plot(this.selGen, nbEvalInd(this.selGen), 'bo');
			this.tmpObj{subWinIdx} = h1;
		end
		
		% plot fitness of individuals selected as parents
		function plotParentFitness(this, subWinIdx, fullDraw)			
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 4)
				fullDraw = 1;
			end
			hold on;
			
			parSizes = size(this.recorder.parentsFitness);
			
			% potentially plot static elements
			if(fullDraw)
				parents = reshape(this.recorder.parentsFitness, parSizes(1)*parSizes(2), parSizes(3));
				parFitMean = mean(parents, 1)';
				parFitStd = std(parents, 0, 1)';
			
				cla;
				legend('off');
				plot(1:parSizes(3), repmat(mean(parFitMean), parSizes(3), 1), ':', 'Color',[127 127 255]/255);
				plot(1:parSizes(3), [parFitMean-parFitStd parFitMean+parFitStd], 'Color',[223 223 255]/255);
				plot(1:parSizes(3), parFitMean, 'b');
				xlim([1 numel(parFitMean)+1]);
			else
				axChildren = get(gca, 'Children');
				parFitMean = get(axChildren(1), 'Ydata');
			end
			
			% plot generation dependent elements
			if(this.selGen <= parSizes(3))
				h1 = plot(this.selGen, parFitMean(this.selGen), 'bo');
				this.tmpObj{subWinIdx} = h1;
			end	
		end
		
		% plot number of crossovers performed
		function plotCrossover(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 2)
				fullDraw = 1;
			end
			hold on;
			
			coSum = squeeze(sum(this.recorder.crossoverFlags, 1));

			% potentially plot static elements
			if(fullDraw)
				cla;
				legend('off');
				plot(coSum, 'b');
				plot(1:numel(coSum), repmat(mean(coSum), numel(coSum), 1), ':', 'Color',[127 127 255]/255);
				xlim([1 numel(coSum)+1]);
			end
			
			% plot generation dependent elements
			if(this.selGen <= numel(coSum))
				h1 = plot(this.selGen, coSum(this.selGen), 'bo');
				this.tmpObj{subWinIdx} = h1;
			end
		end
		
		% plot number of mutations performed
		function plotMutations(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 4)
				fullDraw = 1;
			end
			hold on;
			
			nbGen = size(this.recorder.mutations, 3);
			
			% potentially plot static elements
			if(fullDraw)
				nbMutInd = zeros(nbGen, 1);
				nbMutEl = zeros(nbGen, 1);
				for genIdx = 1:nbGen
					nbMutInd(genIdx) = nnz(this.recorder.mutations(:, :, genIdx));
					nbMutEl(genIdx) = sum(sum(this.recorder.mutations(:, :, genIdx)));
				end
				
				cla;
				legend('off');
				plot(1:nbGen, repmat(mean(nbMutInd), nbGen, 1), ':', 'Color',[127 127 255]/255);
				h1 = plot(nbMutInd, 'b');
				plot(1:nbGen, repmat(mean(nbMutEl), nbGen, 1), ':', 'Color',[255 127 255]/255);
				h2 = plot(nbMutEl, 'm');
				xlim([1 nbGen+1]);
				legend([h1, h2], {'individuals', 'elements'});
			else
				axChildren = get(gca, 'Children');
				h1 = axChildren(3);
				h2 = axChildren(1);
				nbMutInd = get(h1, 'Ydata');
				nbMutEl = get(h2, 'Ydata');
			end
			
			% plot generation dependent elements
			if(this.selGen <= nbGen)
				h3 = plot(this.selGen, nbMutInd(this.selGen), 'bo');
				h4 = plot(this.selGen, nbMutEl(this.selGen), 'om');
				this.tmpObj{subWinIdx} = [h3 h4];
			end
			
			legend([h1 h2]);
		end
		
		% plot portions of mutations performed
		function plotMutationRate(this, subWinIdx, fullDraw)
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > 4)
				fullDraw = 1;
			end
			hold on;
			
			nbGen = size(this.recorder.mutations, 3);
			
			% potentially plot static elements
			if(fullDraw)
				nbPopInd = zeros(nbGen, 1);
				nbMutInd = zeros(nbGen, 1);
				nbPopEl = zeros(nbGen, 1);
				nbMutEl = zeros(nbGen, 1);
				for genIdx = 1:nbGen
					allParEl = this.allSolMat(this.recorder.parentsIndices(:, :, genIdx), :, genIdx);
					nbPopInd(genIdx) = size(allParEl, 1);
					nbMutInd(genIdx) = nnz(this.recorder.mutations(:, :, genIdx));
					nbPopEl(genIdx) = nnz(allParEl);
					nbMutEl(genIdx) = sum(sum(this.recorder.mutations(:, :, genIdx)));
				end
				mutIndRate = nbMutInd ./ nbPopInd;
				mutElRate = nbMutEl ./ nbPopEl;
				
				cla;
				legend('off');
				plot(1:nbGen, repmat(mean(mutIndRate), nbGen, 1), ':', 'Color',[127 127 255]/255);
				h1 = plot(mutIndRate, 'b');
				plot(1:nbGen, repmat(mean(mutElRate), nbGen, 1), ':', 'Color',[255 127 255]/255);
				h2 = plot(mutElRate, 'm');
				xlim([1 nbGen+1]);
				legend([h1, h2], {'individuals', 'elements'});
			else
				axChildren = get(gca, 'Children');
				h1 = axChildren(3);
				h2 = axChildren(1);
				mutIndRate = get(h1, 'Ydata');
				mutElRate = get(h2, 'Ydata');
			end
			
			% plot generation dependent elements
			if(this.selGen <= nbGen)
				h3 = plot(this.selGen, mutIndRate(this.selGen), 'bo');
				h4 = plot(this.selGen, mutElRate(this.selGen), 'om');
				this.tmpObj{subWinIdx} = [h3 h4];
			end
			
			legend([h1 h2]);
		end
		
		% plot portions of mutations performed
		function plotFitnessChanges(this, subWinIdx, fullDraw)
			% get number of recorded changes during an iteration
			muStats = any(this.recorder.mutations(:));
			elStats = this.recorder.elitismRate > 0;
			nbStats = 2 + muStats + elStats;
			
			% check number of objects in corresponding axis
			set(gcf, 'CurrentAxes',this.subWins(subWinIdx));
			if(numel(get(gca, 'Children')) > (nbStats-1)*2)
				fullDraw = 1;
			end
			hold on;
			
			[nbCh, ~, nbGen] = size(this.recorder.parentsIndices);
			nbCh = nbCh * 2;
			
			% get step-wise changes in fitness'
			fitnessArr = cell(nbStats, 1);
			fitnessArr{1} = this.recorder.indFitness(:, :, 1:end-1);
			fitnessArr{2} = reshape(this.recorder.parentsFitness, nbCh, nbGen);
			labels = cell(nbStats-1, 1);
			labels{1} = 'selection';
			if(muStats)
				fitnessArr{3} = reshape(this.recorder.childrenFitnessAMU, nbCh, nbGen);
				labels{2} = 'mutation';
			end
			if(elStats)
				fitnessArr{3+muStats} = this.recorder.indFitness(:, :, 2:end);
				labels{2+muStats} = 'elitism';
			end
			
			fitnessMean = cellfun(@(x) reshape(mean(x, 1), nbGen, 1), fitnessArr, 'uni',false);
			fitnessMean = [fitnessMean{:}];
			fitnessDiff = diff(fitnessMean, 1, 2);
			nbDiff = size(fitnessDiff, 2);
			
			cmap = [[ones(1, 32) 1:-1/31:0]; zeros(1, 64)+0.5; 0:1/31:1 ones(1, 32)]';
			cmapIdx = 63/(nbDiff - 1);
			cmapIdx = round(0:cmapIdx:63) + 1;
			
			% potentially plot static elements
			if(fullDraw)
				cla;
				legend('off');
				
				lines = zeros(1, nbDiff);
				for curIdx = 1:nbDiff
					lines(curIdx) = plot(fitnessDiff(:, curIdx), 'Color',cmap(cmapIdx(curIdx), :));
					plot(1:nbGen, repmat(mean(fitnessDiff(:, curIdx)), nbGen, 1), ':', 'Color',cmap(cmapIdx(curIdx), :));
				end
				xlim([1 nbGen+1]);
				legend(lines, labels);
			else
				lines = get(gca, 'Children');
				lines = lines(end:-2:1);
			end
			
			% plot generation dependent elements
			currTmpObj = [];
			if(this.selGen <= nbGen)
				h = zeros(1, nbDiff);
				for curIdx = 1:nbDiff
					h(curIdx) = plot(this.selGen, fitnessDiff(this.selGen, curIdx), 'o', 'Color',cmap(cmapIdx(curIdx), :));
				end
				currTmpObj = [currTmpObj h];
			end
			this.tmpObj{subWinIdx} = currTmpObj;
			
			legend(lines);
		end
		
	end % /methods
	
end % /class
