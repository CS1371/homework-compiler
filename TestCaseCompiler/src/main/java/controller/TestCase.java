package controller;

/**
 * Represents a single test case of a problem.
 */
public class TestCase {

    public enum SubmissionType {
        STUDENT, SUBMISSION, RESUBMISSION;
    }

    private SubmissionType type;

    /**
     * Gets the submission type
     * @return the submission type, either SubmissionType.STUDENT, SubmissionType.SUBMISSION,
     * or SubmissionType.RESUBMISSION
     */
    public SubmissionType getType() {
        return type;
    }

    public void setType(SubmissionType type) {
        this.type = type;
    }

}
