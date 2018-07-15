# Assignment Compiler

The Assignment Compiler will take in a folder of `Problem Packages`, and parse, test, create, and distribute a formal homework definition.

## Actions

The compiler does a variety of different actions, using the `Problem Packages` on Google Drive to accomplish this.

- Download all the `Problem Packages`
- Parse each `Problem` and re-verify it
- Compile all the different distributions
- Insert version-checking code into each problem's code
- Verify the assignment as a whole
- Upload the assignment to various places for distribution (i.e., Google Drive, the Server, etc.)

Below is detailed what each action represents

### Terms

For each of the following sections, the following terms might be useful:

- `<problemName>`: The original problem name (without any extension)
- `##`: The homework number, as a padded two digit number
- Assignment Folder: The root folder of the _assignment_, which is always called `Homework ##`

### Downloading from Google Drive

The compiler will ask the user to choose a Google Drive folder, which represents the Homework to compile. It should be the parent folder in Google Drive.

### Parsing and Verification

Each problem is parsed separately, using all the information of the package as defined by the `Test Case Compiler`.

Although each package was independently verified at compilation (see the `Test Case Compiler` for more information), for the utmost in reliability, each problem will
be _independently verified again_.

### Compilation of Different Distributions

There are three possible distributions:

- `student`: What the student "sees" when s/he gets the homework
- `submission`: What is used to grade the original submission
- `resubmission`: What is used to grade the resubmission

#### (Re)submission

Both the submission and the resubmission are identical in structure; for a more detailed view of this structure, see the rubric specification for the Autograder.

#### Student

The `student` distribution is quite a bit different from the submission and resubmission.

- Each solution file is renamed from `<problemName>` to `<problemName>_soln`
- Each solution file is then obfuscated via `pcode`
- The `inputs.mat` file is renamed to `<problemName>_inputs.mat`
- The Google Doc used to create the problem statements is downloaded and converted to PDF format, and included as `Homework ##.pdf`
- A `hw##.m` file is created, which details the homework and allows students to easily test their code. See the [Manifest Documentation](https://github.gatech.edu/CS1371/homework-compiler/blob/Development/AssignmentCompiler/MANIFEST.md) for more information.

### Version Check

Each solution will have a bit of code spliced in at the beginning, which checks to ensure the student has the latest version of the homework. If the student does not,
then the student is prompted via a warning to run `getMostRecentFiles`

### Overall Verification

After each distribution is created, it is tested using the same verification methods used to test each problem individually.

### Upload & Completion

After verification, the separate distributions are uploaded. The `student` distribution is zipped and uploaded to the server for `getMostRecentFiles`,
while the `submission` and `resubmission` distributions are uploaded to Google Drive, as a new folder called `grader`
