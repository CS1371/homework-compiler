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
    private ListView<String> bannedFunctionsListView;

    @FXML
    private TextField bannedFunctionAddField;

    /* UI specific instance fields */

    // User-selected local output directory
    private File localOutputDirectory;

    // Whether or not the user wants to export to local disk
    private boolean isLocalExport;

    // Whether or not the user wants to export to Google Drive
    private boolean isDriveExport = true;

    /**
     * Toggles the destination button when the corresponding checkbox is toggled.
     * @param event
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
    void localButtonPressed(ActionEvent event) {
        // Open a directory chooser dialog to pick the local save folder
        DirectoryChooser fc = new DirectoryChooser();
        fc.setTitle("Pick local output folder");
        File selected = fc.showDialog(localButton.getScene().getWindow());
        if (selected != null) {
            localOutputDirectory = selected;
        }
    }

    @FXML
    void bannedFunctionsListViewEdited(ListView.EditEvent<String> e) {
        System.out.println(e);
    }

    @FXML
    void showHelp(ActionEvent e) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.getDialogPane().setStyle("-fx-font-family: \"Consolas\", \"monospace\"");
        alert.setTitle("CS1371 Test Case Generator");
        alert.setHeaderText("#HOMEWORKTEAMTEAMWORKMAKESTHEHOMEWORKTEAMDREAMWORK");
        alert.setContentText("Suggestions? Complaints? Insults? Funny jokes? Email dprofili3@gatech.edu and/or "
                + "arao8@gatech.edu.");
        alert.show();
    }


    @FXML
    void addBannedFunctionButtonPressed(ActionEvent event) {
        String text = bannedFunctionAddField.getText();
        if (text.length() > 0) {
            ObservableList<String> bannedFcns = bannedFunctionsListView.getItems();
            if (!bannedFcns.contains(text)) {
                bannedFcns.add(text);
            }
            bannedFunctionAddField.setText("");
        }
    }

}
