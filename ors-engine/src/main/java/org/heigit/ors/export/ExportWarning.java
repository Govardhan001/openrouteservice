package org.heigit.ors.export;

public class ExportWarning {
    public static final int EMPTY_BBOX = 1;

    private int warningCode = 0;
    private String warningMessage = "";

    /**
     * Generate the warning object and initialize the message based on the warning code passed
     * @param warning   The warning code for the warning that should be generated
     */
    public ExportWarning(int warning) {
        warningCode = warning;
        if (warning == EMPTY_BBOX) {
            warningMessage = "The specified bbox doesn't contain any nodes.";
        } else {
            warningMessage = "Unknown error";
        }
    }

    public int getWarningCode() {
        return warningCode;
    }

    public String getWarningMessage() {
        return warningMessage;
    }
}
