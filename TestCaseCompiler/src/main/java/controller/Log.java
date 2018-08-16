package controller;

import javafx.stage.Window;

import java.util.LinkedList;
import java.util.List;

/**
 * Class used to log errors and other messages by the test case compiler.
 * Allows adding messages to the log and printing, but not deleting.
 * @author Daniel Profili
 * @version 1.0
 */
public class Log {
    private final LinkedList<String> log = new LinkedList<>();

    /**
     * Records a message to the log.
     * @param msg The message to record
     */
    public void log(String msg) {
        log.addLast(msg);
    }

    /**
     * Prints the contents of the log to the console.
     */
    public void printLog() {
        for (String c : log) {
            System.out.println(c);
        }
    }

    /**
     * Gets the log as a list of strings
     * @return list of strings representing the log
     */
    public List<String> getLog() {
        return log;
    }

    /**
     * Shows the error log as a basic console window.
     * @param owner the owner JavaFX window
     */
    public void show(Window owner) {
        /*
            TODO
         */
    }
}
