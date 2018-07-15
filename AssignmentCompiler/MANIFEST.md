# Manifest File

The "Manifest" file, also known as the `hw##.m` file, is a MATLAB code file that represents all the
problems we have given them, as well as sample function calls to test them. It also provides general
guidance on how to do the homework, and how to test and submit.

This guide is, in essence, a manifest for the manifest. It details what sections there are, and what those sections contain.

## House Rules

Each section is demarcated by a double percent: `%%`.

Each sub-section (if any) is demarcated by a triple percent: `%%%`.

The manifest file is _non-executable: It has no real code!_

The file will always be named `hw##.m`, with the `##` _always_ two digits long (i.e., `9` becomes `09`)

## Layout

The file has the following sections:

- Honor Code
- Banned Functions
- Files to Submit
- Test Cases

Each section is described in detail below. Note that the file always begins with a top header that describes the homework.

### Honor Code

This section makes the student fill out their information, and ensures they've abided by the Honor Code.

### Banned Functions

This sections describes what banned functions _are_, and why it's important the students know what they are. 
Additionally, it lists several functions that are globally banned in every homework assignment.

### Files to Submit

This section lists exactly the files that should be submitted to Canvas.

### Problems

This section has a set of subsections, each of which represents a single problem's test cases. Critically,
NO outputs are shown. This is so that the student will be forced to use `isequal`, which will benefit them
in the long run.

## Template

As an example, the below template is given:

```matlab

%% Homework 10: Structures
%
%% Honor Code Agreement
%
% By entering my name, GT Username, and Section below, I am confirming that I am bound by the Georgia Tech
% Honor Code, which can be found here: http://osi.gatech.edu/content/honor-code. Failing to agree will
% result in a 0 for the entire assignment.
%
% Name: <Your Name Here>
% GT Username (gburdell3): <Your GT Username Here>
% Section: <Your Section Here>
%
%% Banned Functions
%
% In general, you are allowed to use any function you see fit. However, there are a few functions you
% are NOT allowed to ever use. Additionally, specific homework files may specify that you cannot use a certain
% function. Code that uses any of these functions will automatically receive a 0.
%
% NEVER use the following functions in your function code:
%
% * input
% * solve
% * fclose all
% * close
% * load
% * figure
% * imshow
% * imread
%
%% Files to Submit
% 
% For full credit, you should submit the following files to Canvas by the assignment deadline:
%
%   - problem1.m
%   - hw##.m
%   - problem2.m
%   - problem3.m
%
%% Test Cases
%
%%% problem1Name
%
%   load problem1Name_inputs.mat
%   [out1, out2, ...] = problem1Name(in1, in2, ...);
%   [out1_soln, out2_soln, ...] = problem1Name_soln(in1, in2, ...);
%
%   [out3, out4, ...] = problem1Name(in3, in4, ...);
%   [out3_soln, out4_soln, ...] = problem1Name_soln(in3, in4, ...);
%
% And so on...
%
%%% problem2Name
%
% ...
%
```
