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
    private boolean exportToDisk = false;
    private SubmissionType type;

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
