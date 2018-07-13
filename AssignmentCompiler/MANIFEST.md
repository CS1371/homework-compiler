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
- Resources
  - Piazza
  - Help Desk
  - Email
- How To Debug
- Banned Functions
- Testing Your Code
- How To Submit
- Problems

Each section is described in detail below. Note that the file always begins with a top header that describes the homework.

### Honor Code

This section makes the student fill out their information, and ensures they've abided by the Honor Code.

### Resources

This section details the resources afforded to students. It includes:

- Piazza
- Help Desk
- Email

Each resource is described, and various tips are listed

### How To Debug

This is a complement to the debugging help post on Piazza. It details how to debug, and what it means to debug.

### Banned Functions

This sections describes what banned functions _are_, and why it's important the students know what they are.

### Testing Your Code

This section gives an example of how to test code, and critically, explains why you should test your code!

### How To Submit

This section details how to submit assignments to Canvas, and details our policy about the deadlines.

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
%% Resources
%
% CS 1371 Homework can be difficult at times. As such, we have made sure to give you ample time and resources to complete it.
% Below, you will find a synopsis of the resources made available to you:
%
%%% Piazza
%
% Piazza is a great resource for getting help on your problems. Simply ask a question, and both students & TAs will
% try their best to answer your question. This can be a first line of defense once you've become truly stumped. Some tips:
%
% * ALWAYS look for your question before you ask it. This saves both you and us time!
% * NEVER include your own code. This is not a code sharing site. Instead, ask more general questions
% * We have an absurdly fast response rate, but don't be impatient when waiting for an answer.
% * If it's a personal question, post it as a "Private" message
%
% A link to Piazza can be found on our course website
%
%%% Help Desk
%
% Help Desk is an opportunity for you to sit face-to-face with another TA and talk out your problems. However, it is
% NOT a place to just "get answers". We will not answer questions that are vague or show a clear lack of effort.
% Some tips for utilizing Help Desk:
%
% * Help Desk is swarming on the day the submission or resubmission is due. Plan accordingly.
% * TAs will be much more able to help you if you've shown a clear effort to solve the problem.
% * Make sure you have debugged before you attempt to ask a question. See below on how to debug.
% * TAs are people too! Respect is a mutual thing - if you treat us with respect, we'll be happy to return the favor.
% * Yelling at TAs will never work out in your favor!
%
%%% Email
%
% You can also email your TA asking for help. You should never email the professor first - your TA is
% your first line of defense. We will escalate it if it becomes clear it needs the professor's attention. Some tips:
%
% * Start your subject with [CS 1371] - that way we know why you're emailing us
% * Do NOT attach code (unless a TA explicitly asks you to do so)
% * TAs, despite popular belief, actually have lives. Don't expect a super fast response
%
%% How to Debug your Code
%
% For a more in-depth guide, look at our Piazza site.
%
% Debugging is a way to inspect exactly what your code does "under the hood". Thankfully,
% it's also super simple in MATLAB.
%
% A breakpoint is a point where code will "break" execution, and let you inspect the
% workspace. You'll know you're in "break" mode (debugging) when the prompt changes from
% ">>" to "K>>". Here, you can inspect variable values, and run functions. However, you
% can't edit the source file (your homework file): Saving your edits will stop the debugger!
%
% Critically, when a breakpoint is encountered, the code on that line is NOT run yet:
% Instead, you'll notice a green arrow has shown up, pointing at your line of code. This green
% arrow represents what is ABOUT TO BE executed.
%
% To execute one line at a time, click the button called "Step". To just continue execution normally,
% click the button that looks like a Play Button, called "Continue".
%
% To set a breakpoint, just click to the left of the line number you want to stop at. A red dot will
% indicate that MATLAB will pause execution before running that line. If it's greyed out, then either you
% haven't saved, or you have a syntax error in your code.
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
%% Writing Your Code
%
% So, now you're ready to write your code. Great! Make sure you follow some general practices:
%
% * MAKE SURE your file is named correctly. Failure to do this will result in a 0 for that problem.
% * There is no partial credit - it is up to you to test your code (see below)
% * Do NOT assume the test cases given in this document represent the test cases we will use to test your code.
% * Seek help early, and start early. More time is always better!
%
%% Testing Your Code
%
% This document includes sections for testing your code. Critically, these tests are NOT comprehensive.
% While you can be generally confident if your code passes these test cases, we do NOT test your code
% with the same test case(s)!
%
% Testing code is a three step process:
%
% 1. Load the inputs
% 2. Run your function with the given inputs, collecting all the outputs
% 3. Run the solution function with the SAME inputs, collecting all the outputs
% 4. Use isequal() to compare each output.
%
% To get the inputs, you'll need to load them from a MAT file, which was included with the homework. To do that,
% just run the following code:
%
%   load <functionName>_inputs.mat
%
% Running your code is easy - just call your function normally, making sure you collect all the outputs:
%
% Running the solution code is also easy - the solution is always called "<functionName>_soln". Just run
% it exactly like you ran your function, but make sure you include the "_soln"!
%
% Comparing outputs is done with isequal. For more information, type help isequal at the command line.
%
% Below is an example of what that might look like. Suppose you wrote a function called "rectangleMath"
% that, given two side lengths called side1 and side2, computed the area and perimeter. Testing your
% code would then look like this:
%
%   % Load the inputs
%   load rectangleMath_inputs.mat
%   % Run your code
%   [out1, out2] = rectangleMath(side1, side2);
%   % Run the solution code (with same inputs)
%   [out1_soln, out2_soln] = rectangleMath_soln(side1, side2);
%   % Use isequal to compare:
%   isSame1 = isequal(out1_soln, out1);
%   isSame2 = isequal(out2_soln, out2);
%
% If both isSame1 and isSame2 are true, then congratulations! Your code passed this given test case.
%
% NOTE: There is no partial credit. Your answer is either right or wrong - no in between.
% **IF ISEQUAL RETURNS FALSE, YOU WILL NOT RECEIVE ANY CREDIT, NO MATTER HOW "CLOSE" YOU ARE**
%
%% Submitting Your Homework
%
% Submissions are always done through our Canvas site: NEVER email TAs your code.
%
% As a rule, submissions are due every Tuesday at 8:00 pm, and resubmissions are due every Friday
% at 8:00 pm. You can, of course, submit earlier, and you are allowed to submit as many times as you
% see fit. Note, however, that the actual time listed on Canvas is 11:59 pm. This 3 hour and 59 minute
% period is a "grace period" - you can continue to submit, but cannot expect help. If your computer breaks
% before 8:00 and you email a TA, we will try our best to help - but after 8:00, we are not responsible.
%
% You MUST submit each file! Submitting only some files results in 0s for files not submitted.
% This applies to the resubmission as well!
%
% If you submit after your first submission, Canvas will rename your file to "fileName-1.m". This is expected
% behavior, and rest assured we will still grade it correctly.
%
% If you need help submitting to Canvas, ask a TA. 
%
%% Problems
%
% For this homework, you will be submitting the following problems:
%
% * problem1Name.m
% * problem2Name.m
% * ...
% * hw10.m
%
% Below, we have provided test cases to help you along.
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
