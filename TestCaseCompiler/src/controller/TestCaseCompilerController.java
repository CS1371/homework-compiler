package controller;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Menu;
import javafx.scene.control.MenuItem;
import javafx.scene.control.Tab;
import javafx.scene.layout.AnchorPane;
import javafx.stage.DirectoryChooser;
import javafx.stage.FileChooser;
import javafx.stage.DirectoryChooser;
import javafx.event.ActionEvent;
import javafx.scene.control.ListView;

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
}
