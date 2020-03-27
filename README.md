# Genetic Algorithm for MATLAB

This is a MATLAB based object oriented and parallel capable implementation of a genetic algorithm to search for discrete solutions composed of a fixed number of elements drawn from a finite number of elements without replacement per solution. Information about the search's progress can be recorded and displayed subsequently for detailed analysis.

Information for its use are also described in the corresponding script setupSearch.m. For demonstration, this script can be executed without further changes.

For actual use, the Evaluator class (`Evaluator.m`) must be adapted to assess solutions as required. The data necessary to do so must be provided as arguments in the constructor of the class and stored as class properties. The class' function `calcFitness` must be adapted to calculate (and return) the performance value for an arbitrary solution as needed.

The GA in its current form maximizes the performance values of solutions. If minimization is required adapt the performance assessment in the `calcFitness`-function accordingly. For example, use the negative values or if the values are normalized (1 - performance).

The algorithm allows to set certain parameters for a population:
* pop.setSelectionType(#)  
    Type used to select individuals (parents) as origins for new individuals (children)  
    1 = random selection  
    2 = fitness proportionate selection  
    3 = rank proportionate selection (default)  
    4 = tournament selection  
* pop.setCrossoverProbability(#)  
    Probability \[0 1\] that two 'parent' individuals produce offspring and are replaced by these 'children' individuals. Otherwise the 'parents' are used as 'children' in subsequent processing steps.
* pop.setMutationProbability(#)  
    Base probability \[0 1\] of mutation(s) to occur in each 'child' individual. The actually applied mutation probability is adapted during runtime depending on several properties of the currently processed generation.
* pop.setElitism(#)  
    Number/Portion of the best individuals to transmit unchanged to the next generation  
    if 0 <= # < 1 : best # percentage of population is kept unchanged \[0 1)  
    if # >= 1 : best # individuals are kept \[1 `nbIndividuals`\]  

If a parallel pool is open in MATLAB (https://ch.mathworks.com/help/parallel-computing/parpool.html) the algorithm will automatically use it when calculating the performance values of solutions.

---

#### Description of the script `setupSearch.m`

Currently, the performance of a solution is proportional to the sum of its elements (defined in the function `calcFitness` of the class `Evaluator`, instantiated on line 66). Thus, with a total number of 30 elements to draw solutions from (`totElements`, line 45), the best solution of size 9 (`solSize`, line 47) is \[22:30\].

A population of 40 individuals (`nbIndividuals`, line 41) is set up (line 85), a recorder to track the processings of the search is instantiated (line 76) and assigned to the population (line 91). At the end of a search, the recorder object is stored as a mat-file, the default folder is *./recDat/*. Optionally, elements that must not be part of a solution can be defined (line 51) and provided as arguments when creating the population (line 86).

Next, the search is performed, initially for 77 iterations (`nbEvolvements`, line 104) and subsequently for 33 additional iterations (line 109). To re-use a population without information from a previous search it can be re-initialized (line 99) to set up a random population and clear a potentially assigned recorder (this does not affect the recorder object that was stored as a mat-file, a new mat-file will be created to store the recorder object of a subsequent search).

Finally, the recorder is provided to the `Statistics` class (line 115) which opens a window that allows to display different information about the performed search. The number of subplots displaying information can be set using the drop-down lists in the left upper corner. The information displayed in every subplot can be selected using its assigned drop-down list. The generation to display information from resp. to highlight can be selected using the slider at the top. The best solution of the currently selected (initially last) generation is shown at the right border.

---

last modification: 27.03.2020

© Michael Müller  
    GitHub: leahcimrelleum  
    ORCID: 0000-0002-6915-4820  
