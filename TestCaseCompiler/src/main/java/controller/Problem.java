package controller;

import java.io.File;
import java.util.ArrayList;

/**
 * Class representing a homework problem.
 * @author Daniel Profili
 * @version 1.0
 */
public class Problem {
    private int numTestCases;
    private File functionSource;
    private File inputFile;
    private boolean isRecursive;
    private ArrayList<File> supportingFiles;
    private boolean exportToDrive = true;
    private File localOutputDirectory;
    private boolean exportToDisk = false;
    private SubmissionType type;

    public static final int MIN_NUM_TEST_CASES = 3;

    public File getLocalOutputDirectory() {
        return localOutputDirectory;
    }

    public void setLocalOutputDirectory(File localOutputDirectory) {
        this.localOutputDirectory = localOutputDirectory;
    }

    public int getNumTestCases() {
        return numTestCases;
    }

    public void setNumTestCases(int numTestCases) {
        this.numTestCases = numTestCases;
    }

    public File getFunctionSource() {
        return functionSource;
    }

    public File getInputFile() {
        return inputFile;
    }

    public void setInputFile(File inputFile) {
        this.inputFile = inputFile;
    }

    public boolean isRecursive() {
        return isRecursive;
    }

    public void setRecursive(boolean recursive) {
        isRecursive = recursive;
    }

    public boolean isExportToDrive() {
        return exportToDrive;
    }

    public void setExportToDrive(boolean exportToDrive) {
        this.exportToDrive = exportToDrive;
    }

    public boolean isExportToDisk() {
        return exportToDisk;
    }

    public void setExportToDisk(boolean exportToDisk) {
        this.exportToDisk = exportToDisk;
    }

    public SubmissionType getType() {
        return type;
    }

    public void setType(SubmissionType type) {
        this.type = type;
    }

    enum SubmissionType {
        STUDENT, SUBMISSION, RESUBMISSION;
    }

    /**
     * Creates a new Problem object
     * @param src the source file (i.e. the solution function .m file)
     */
    public Problem(File src) {
        functionSource = src;
    }

    public void setFunctionSource(File newSrc) {
        functionSource = newSrc;
    }

}
