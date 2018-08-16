package controller;

import java.io.File;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/**
 * Class representing a homework problem.
 * @author Daniel Profili
 * @version 1.0
 */
public class Problem implements Serializable {
    private int numTestCases;
    private int numInputs;
    private int numOutputs;
    private File functionSource;
    private File inputFile;
    private boolean isRecursive;
    private List<File> supportingFiles = new LinkedList<>();
    private boolean exportToDrive = true;
    private File localOutputDirectory;
    private boolean exportToDisk = false;
    private List<TestCase> testCases = new LinkedList<>();
    private List<String> inputBaseWords = new LinkedList<>();
    private List<String> outputBaseWords = new LinkedList<>();

    /**
     * The minimum number of test cases a problem may have. The compiler will start out displaying this many test cases.
     * The number of test cases cannot be less than this value.
     */
    public static final int MIN_NUM_TEST_CASES = 3;

    /**
     * Creates a new Problem object
     * @param src the source file (i.e. the solution function .m file)
     * @param numInputs the number of inputs of the solution function
     * @param numOutputs the number of outputs of the solution function
     */
    public Problem(File src, int numInputs, int numOutputs) {
        functionSource = src;
        this.numInputs = numInputs;
        this.numOutputs = numOutputs;
    }

    /**
     * Gets the location of the user's chosen local output directory
     * @return File object containing the location of the chosen output directory
     */
    public File getLocalOutputDirectory() {
        return localOutputDirectory;
    }

    /**
     * Set the local output directory
     * @param localOutputDirectory the new output directory to set
     * @throws IllegalArgumentException if the new directory is null
     */
    public void setLocalOutputDirectory(File localOutputDirectory) {
        if (localOutputDirectory == null) {
            throw new IllegalArgumentException("Local output directory cannot be null.");
        }

        this.localOutputDirectory = localOutputDirectory;
    }

    /**
     * Gets the number of test cases this problem has.
     * @return the number of test cases
     */
    public int getNumTestCases() {
        return numTestCases;
    }

    /**
     * Sets the number of test cases for the problem. Cannot be less than the minimum number.
     * @param numTestCases the new number of test cases
     * @throws IllegalArgumentException if the new number is less than the minimum
     */
    public void setNumTestCases(int numTestCases) {
        if (numTestCases < MIN_NUM_TEST_CASES) {
            throw new IllegalArgumentException("A Problem cannot have less than " + MIN_NUM_TEST_CASES + " test cases.");
        }

        this.numTestCases = numTestCases;
    }

    /**
     * Gets the location of the function solution source file
     * @return File object locating the function solution file
     */
    public File getFunctionSource() {
        return functionSource;
    }

    /**
     * Gets the location of the problem's input .mat file
     * @return the location of the problem's input .mat file
     */
    public File getInputFile() {
        return inputFile;
    }

    /**
     * Sets the location of the problem's input .mat file
     * @param inputFile the new input .mat file
     * @throws IllegalArgumentException if the new input file location is null
     */
    public void setInputFile(File inputFile) {
        if (inputFile == null) {
            throw new IllegalArgumentException("The input file location cannot be null.");
        }

        this.inputFile = inputFile;
    }

    /**
     * Gets whether the problem is recursive or not.
     * @return whether or not the problem is recursive
     */
    public boolean isRecursive() {
        return isRecursive;
    }

    /**
     * Sets whether the problem is recursive or not
     * @param recursive the new status of recursiveness
     */
    public void setRecursive(boolean recursive) {
        isRecursive = recursive;
    }

    /**
     * Gets whether the user has selected the export to drive option
     * @return whether or not the user has selected the export to drive option
     */
    public boolean isExportToDrive() {
        return exportToDrive;
    }

    /**
     * Sets whether the user has selected the export to drive option
     * @param exportToDrive the new value of the export to drive option
     */
    public void setExportToDrive(boolean exportToDrive) {
        /*
            TODO: Decide if this should check and make sure exportToDrive || exportToDisk is true
         */
        this.exportToDrive = exportToDrive;
    }

    /**
     * Gets whether the user has selected the export to disk option
     * @return the export to disk option
     */
    public boolean isExportToDisk() {
        return exportToDisk;
    }

    /**
     * Sets the export to disk option
     * @param exportToDisk the new value of the export to disk option
     */
    public void setExportToDisk(boolean exportToDisk) {
        this.exportToDisk = exportToDisk;
    }



    /**
     * Set the location of the function solution source
     * @param newSrc the new location of the function solution
     * @throws IllegalArgumentException if the new location is null
     */
    public void setFunctionSource(File newSrc) {
        if (newSrc == null) {
            throw new IllegalArgumentException("The function source location cannot be null.");
        }

        functionSource = newSrc;
    }

    /**
     * Gets a list of the supporting files
     * @return List of the problem's supporting files
     */
    public List<File> getSupportingFiles() {
        return supportingFiles;
    }

    /**
     * Gets the list of test cases
     * @return List of TestCase objects
     */
    public List<TestCase> getTestCases() {
        return testCases;
    }

    /**
     * Gets the input base words
     * @return list of input base words
     */
    public List<String> getInputBaseWords() {
        return inputBaseWords;
    }

    /**
     * Gets the output base words
     * @return list of output base words
     */
    public List<String> getOutputBaseWords() {
        return outputBaseWords;
    }

    /**
     * Get the number of outputs for this problem's solution
     * @return the number of outputs
     */
    public int getNumOutputs() {
        return numOutputs;
    }


    /**
     * Get the number of inputs for this problem's solution
     * @return the number of inputs
     */
    public int getNumInputs() {
        return numInputs;
    }
}
