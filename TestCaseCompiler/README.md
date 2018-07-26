# Test Case Compiler

The `Test Case Compiler` is responsible for compiling a set of test cases into a single cohesive _Problem Definition_. This is also responsible for initial verification;
making sure that the solution actually works, and checking for common mistakes.

Additionally, it generates a single `Problem Package`, or `Package`, which contains all _files_, _code_, and _information_ needed to create and grade that problem.

## Package Specification

The `Package` is actually a specification for a set of folders and files. It's organized as follows:

- The name of the root folder is `<problemName>`
- There is a single file in this folder; namely, the solution file.
- There also exists three separate folders:
  - `student`
  - `submission`
  - `resubmission`
- These folders represent the three problem definitions this tool compiles
- Each of these folders contains the following files:
  - `rubric.json`: Rubric specification, which is detailed below
  - `inputs.mat`: A mat file that specifies all the necessary inputs to run all the test cases.
  - `supporting file`: Any necessary supporting files are placed here as well

Below, each part of the above specification is explained in more detail.

### Solution

The solution is a _single file_, called `<problemName.m>`. Note that there is no `_soln` extension! The solution has a number of restrictions that it must pass:

- It must run in no less than 7 seconds, according to MATLAB's `tic`/`toc`
- Any files it creates, it must name them `filename_soln.ext`
- It must not use any banned functions
- It must close any files it opens
- Any "easter eggs" must be _deterministic_: It cannot be randomly triggered
- For any valid input, it _must not error_.

### Problem Definition Types

The three types are:

- `student`: Defines what inputs the student may use to test their code.
- `submission`: Defines what to use to grade the original submission
- `resubmission`: Defines what to use to grade the resubmission

### Inputs

The `inputs.mat` file is a simple MAT file that contains _only the inputs to the function_. These inputs must match the names of the inputs for all the function calls.

### Rubrics

The `rubric.json` stores a variety of information about the problem. It contains the following fields:

- `name`: A string that is equal to `<problemName>`; no `.m` extension
- `isRecursive`: A boolean that is true if the problem must be solved recursively
- `banned`: An array of strings, where each string is the name of a banned function (without the `.m` extension)
- `calls`: An array of strings, where each string is a complete function call that tests the function

### Supporting Files

In general, the user can name a supporting file whatever they wish to name it. However, the filename must follow a few simple rules:

- It must have an extension, though the actual extension is not important
- It cannot be called `rubric.json`, `inputs.mat`, `<problemName>.m`, or `<problemName>_soln.m`
- You cannot include the solution file as a supporting file
- You _can_, and should, include any external _helper functions_. By convention, these files should be obfuscated via `pcode`

