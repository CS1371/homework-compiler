package controller;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import javafx.stage.DirectoryChooser;
import javafx.stage.FileChooser;
import javafx.stage.DirectoryChooser;
import javafx.event.ActionEvent;

import java.io.File;

/**
 * Controller class for the main test case compiler gui.
 * Handles basically everything.
 * @author Daniel Profili
 * @version 1.0
 */
public class TestCaseCompilerController {
    @FXML
    private CheckBox driveCheckbox;

    @FXML
    private CheckBox localCheckbox;

    @FXML
    private Button remoteButton;

    @FXML
    private Button localButton;

    @FXML
    private Tab studentTab;

    @FXML
    private Tab submissionTab;

    @FXML
    private AnchorPane resubmissionTab;

    @FXML
    private Menu HelpMenu;

    @FXML
    private MenuItem HelpMenuItem;

    @FXML
    private MenuItem AboutMenuItem;

    @FXML
    private AnchorPane statusBarAnchorPane;

    @FXML
    private AnchorPane inputFileAnchorPane;

    @FXML
    private ListView<String> bannedFunctionsListView;

    @FXML
    private TextField bannedFunctionAddField;

    @FXML
    private TextField functionSourceTextField;

    @FXML
    private Button functionBrowseButton;

    /* UI specific instance fields */

    // User-selected local output directory
    private File localOutputDirectory;

    // Whether or not the user wants to export to local disk
    private boolean isLocalExport;

    // Whether or not the user wants to export to Google Drive
    private boolean isDriveExport = true;

    // User-selected solution function source
    private File functionSourceFile;

    /**
     * Toggles the destination button when the corresponding checkbox is toggled.
     * @param event the ActionEvent used to determine which checkbox was clicked
     */
    @FXML
    void destinationCheckboxClicked(ActionEvent event) {
        if (event.getSource() == localCheckbox) {
            localButton.setDisable(!localCheckbox.isSelected());
            isLocalExport = localCheckbox.isSelected();
        } else {
            remoteButton.setDisable(!driveCheckbox.isSelected());
            isDriveExport = driveCheckbox.isSelected();
        }

        if (!driveCheckbox.isSelected() && !localCheckbox.isSelected()) {
            Alert alert = new Alert(Alert.AlertType.ERROR);
            alert.setTitle("You can't do that!");
            alert.setHeaderText("You have to specify at least one output location.");
            alert.setContentText("With love <3");
            alert.showAndWait();
            driveCheckbox.setSelected(true);
            remoteButton.setDisable(false);
            isDriveExport = driveCheckbox.isSelected();

        }
    }

    @FXML
    void localButtonPressed() {
        // Open a directory chooser dialog to pick the local save folder
        DirectoryChooser fc = new DirectoryChooser();
        fc.setTitle("Pick local output folder");
        File selected = fc.showDialog(localButton.getScene().getWindow());
        if (selected != null) {
            localOutputDirectory = selected;
        }
    }

    @FXML
    void showHelp() {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.getDialogPane().setStyle("-fx-font-family: \"Consolas\", \"monospace\"");
        alert.setTitle("CS1371 Test Case Generator");
        alert.setHeaderText("#HOMEWORKTEAMTEAMWORKMAKESTHEHOMEWORKTEAMDREAMWORK");
        alert.setContentText("Suggestions? Complaints? Insults? Funny jokes? Email dprofili3@gatech.edu and/or "
                + "arao8@gatech.edu.");
        alert.show();
    }


    @FXML
    void addBannedFunctionButtonPressed() {
        String text = bannedFunctionAddField.getText();
        if (text.length() > 0) {
            ObservableList<String> bannedFcns = bannedFunctionsListView.getItems();
            if (!bannedFcns.contains(text)) {
                bannedFcns.add(text);
            }
            bannedFunctionAddField.setText("");
        }
    }

    @FXML
    /**
     * Handler for when the banned functions remove button is clicked.
     * If an item is selected, that item will be deleted from the banned functions list view.
     * Otherwise, nothing is done.
     */
    void removeBannedFunctionsButtonPressed() {
        int ind = bannedFunctionsListView.getSelectionModel().getSelectedIndex();
        ObservableList<String> bannedFcns = bannedFunctionsListView.getItems();
        if (ind != -1) {
            bannedFcns.remove(ind);
        }
    }

    @FXML
    /**
     * Handler for when the function source browse button is pressed.
     * Loads the selected function file and, if valid, enables the disabled function-specific components.
     */
    void functionBrowseButtonPressed() {
        FileChooser fc = new FileChooser();
        fc.setTitle("Choose function solution file");
        fc.getExtensionFilters().addAll(
                new FileChooser.ExtensionFilter("MATLAB files", "*.m"));
        File selected = fc.showOpenDialog(functionBrowseButton.getScene().getWindow());
        if (selected != null) {
            functionSourceFile = selected;

            /*
                TODO:
                Here is where MATLAB would be invoked to nargin()/nargout() the solution file, make sure it's valid,
                etc.

                If the file isn't valid (i.e. it isn't a function [i.e. nargin/nargout error]), then the function source
                text field should turn red and an error message should be displayed notifying the user. Nothing should
                be enabled.
             */
            // DEBUG:
            boolean isFunctionValid = true;
            if (isFunctionValid) {
                functionSourceTextField.setText(selected.getName());
                inputFileAnchorPane.setDisable(false);
            }
        }
    }


}
