# AI-search-algorithms

Swift implementation of the Null Move Quiescence Search and Alpha-Beta Algorithms.

*The main logic of the app is in the file AI-Assignment-1/ViewController.swift*

This app allows to create sample game trees using the parameters provided in order to compare the performance of two search algorithms: Null Move Quiescence Search and Alpha-Beta. For this purpose 10 trees (with a branching factor of 5, a height of 10, and true value of 100)were created. As expected, both algorithms return a value close to the true value in most of the cases. However, the Null Move Quiescence Search algorithm delivers a better accuracy but requires a greater number of static evaluations. The following table summarises the results:

![GUI sample 1](https://github.com/samuelpf/AI-search-algorithms/blob/master/AI-Assignment-1/gui-example-3.png)

For a detailed analysis of the results view the file AI-Assignment-1/results-analysis.pdf


Output sample of a small tree (branching factor: 2, height: 2):

![GUI sample 1](https://github.com/samuelpf/AI-search-algorithms/blob/master/AI-Assignment-1/gui-example-1.png)

Setup screen:

![GUI sample 2](https://github.com/samuelpf/AI-search-algorithms/blob/master/AI-Assignment-1/gui-example-2.jpg)

To run the project XCode 8 or greater is needed.
