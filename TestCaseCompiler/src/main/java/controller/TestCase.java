package controller;

import java.io.File;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/**
 * Represents a single test case of a problem.
 */
public class TestCase {

    /**
     * Static enum representing the submission type - student, original submission, or resubmission.
     */
    public enum SubmissionType {
        STUDENT, SUBMISSION, RESUBMISSION;

        /**
         * List of File objects containing the supporting files for this submission type.
         */
        private final List<File> supportingFiles = new LinkedList<>();

        /**
         * List of TestCase objects representing the test cases for this particular submission type.
         */
        private final List<TestCase> testCases = new LinkedList<>();

        /**
         * Gets the list of supporting files for this submission type
         * @return a list of File objects referring to supporting files
         */
        public List<File> getSupportingFiles() {
            return supportingFiles;
        }

        /**
         * Gets the list of test cases for this submission type
         * @return a list of TestCase objects for this submission type
         */
        public List<TestCase> getTestCases() {
            return testCases;
        }

    }

    private SubmissionType type;
    private ArrayList<String> inputs = new ArrayList<>();

    /**
     * Instantiates a new test case
     * @param type the type of test case (SubmissionType.STUDENT, SubmissionType.SUBMISSION, or
     * SubmissionType.RESUBMISSION)
     */
    public TestCase(SubmissionType type) {
        this.type = type;
        this.type.getTestCases().add(this);
    }

    /**
     * Get the inputs for this test case
     * @return list of inputs for this test case
     */
    public List<String> getInputs() {
        return inputs;
    }

    /**
     * Gets the submission type
     * @return the submission type, either SubmissionType.STUDENT, SubmissionType.SUBMISSION,
     * or SubmissionType.RESUBMISSION
     */
    public SubmissionType getType() {
        return type;
    }

}
