package controller;
import javafx.beans.value.ObservableValue;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.geometry.HPos;
import javafx.geometry.Pos;
import javafx.geometry.Side;
import javafx.scene.Group;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.*;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.*;
import javafx.stage.DirectoryChooser;
import javafx.stage.FileChooser;
import javafx.stage.DirectoryChooser;
import javafx.event.ActionEvent;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import com.mathworks.engine.MatlabEngine;

/**
 * Controller class for the main test case compiler gui.
 * Handles basically everything.
 * @author Daniel Profili
 * @version 1.0
 */
public class TestCaseCompilerController {

    @FXML
    private BorderPane rootBorderPane;

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
    private GridPane inputBaseGridPane;

    @FXML
    private GridPane outputBaseGridPane;

    @FXML
    private HashSet<Node> inputFileSet;

    @FXML
    private ListView<String> bannedFunctionsListView;

    @FXML
    private TextField bannedFunctionAddField;

    @FXML
    private TextField functionSourceTextField;

    @FXML
    private Button functionBrowseButton;

    @FXML
    private AnchorPane problemSettingsAnchorPane;

    @FXML
    private ListView supportingFilesListView;

    @FXML
    private TabPane studentTestCasesTabPane;

    @FXML
    private TabPane submissionTestCasesTabPane;

    @FXML
    private TabPane resubmissionTestCasesTabPane;

    @FXML
    private GridPane sourceFileGridPane;

    @FXML
    private Label inputFileLabel;

    @FXML
    private TextField inputFileTextField;

    @FXML
    private Button inputFileBrowseButton;

    @FXML
    private CheckBox automaticInputBaseCheckBox;

    @FXML
    private CheckBox automaticOutputBaseCheckBox;

    @FXML
    private GridPane outputLocationGridPane;

    /* UI specific instance fields */

    // This is the problem object that holds all the problem-specific information, such as the solution function source,
    // the number of inputs/outputs, the number of test cases, etc.
    //
    // This will only be instantiated when a function is loaded (via the function browse button).
    private Problem problem;

    // User-selected local output directory
    private File localOutputDirectory;

    // Whether or not the user wants to export to local disk
    private boolean isLocalExport = false;

    // Whether or not the user wants to export to Google Drive
    private boolean isDriveExport = true;

    // Default directory to open filechoosers to
    private File defaultDirectory;

    // Array of input and output base word TextFields
    private ArrayList<TextField> inputBaseTextFields;
    private ArrayList<TextField> outputBaseTextFields;

    // Array of input value textfields
    private ArrayList<TextField> inputValueTextFields = new ArrayList<>();

    // Matlab Engine for communication with main MATLAB runner
    private MatlabEngine engine;

    private String googleFolderId;

    private Log console = new Log();

    /**
     * Constructor. Creates a new TestCaseCompilerController.
     * Initializes problem-specific instance variables and starts MATLAB
     */
    public TestCaseCompilerController() {
        // Initialize instance variables
        /*
            TODO: Implement multithreading when starting MATLAB cause it's slow as fuck
         */
        try {
            console.log("Starting MATLAB...");
            engine = MatlabEngine.connectMatlab();
        } catch (Exception e) {
            e.printStackTrace();
        }
        console.log("MATLAB instance connected");
        console.log("Main GUI object constructed");
    }

    @FXML
    public void initialize() {
        // DEBUG:
        problemSettingsAnchorPane.setDisable(true);

//        defaultDirectory = new File(System.getProperty("user.home") + "/Documents/MATLAB");
        try {
            defaultDirectory = new File((String)engine.feval("userpath"));
        } catch (Exception e) {
            // Couldn't find default MATLAB directory
            defaultDirectory = new File(System.getProperty("user.home"));
        }
        // Adds the input file stuff to the set for use later
        // TODO: use a better method
        // Right now, it's convenient just to add all the input-related stuff to a set so it's iterable and saves two
        // lines of code whenever I want to disable/enable that stuff (which honestly isn't that often, but if the user
        // loads another function after the first and it's not valid I want to disable the input file components so....?
        inputFileSet = new HashSet<>();
        inputFileSet.add(inputFileLabel);
        inputFileSet.add(inputFileBrowseButton);
        inputFileSet.add(inputFileTextField);
        inputFileSet.add(outputLocationGridPane);


//        initializeTestCaseTabPane(studentTestCasesTabPane);
        System.out.println("Initializing...");
        console.log("Initialized");

    }

    /**
     * Loads a problem with jsons already generated.
     * Populates all fields with the relevant data, and makes the UI look exactly as if the user had just entered in
     * everything for the loaded problem.
     * @param path a file path
     */
    private void load(String path) {
        /*
            TODO
         */
    }

    /**
     * Initializes a TabPane with three non-closeable tabs (representing the three required test cases).
     * @param tp the TabPane to initialize
     */
    private void initializeTestCaseTabPane(TabPane tp) {
//        TabPane pane = new TabPane();
//        pane.setRotateGraphic(true);
//        pane.setSide(Side.LEFT);
//        pane.setTabClosingPolicy(TabPane.TabClosingPolicy.UNAVAILABLE);
        tp.setRotateGraphic(true);

        for (int i = 0; i < Problem.MIN_NUM_TEST_CASES; i++) {
            Tab t = new Tab();
            Group tmp = new Group();
            Label num = new Label("Test Case #" + (i + 1));
            num.setRotate(90);
            tmp.getChildren().add(num);
            t.setGraphic(tmp);
            t.setClosable(false);
            t.getStyleClass().add("test-case-tab");
            // TODO: add default starting content
            populateTestCaseTab(t, i);

            tp.getTabs().add(t);

        }
    }

    /**
     * Populates a test case tab with blank text fields and variable labels.
     * @param t the Tab to populate
     * @param testCaseNum the number of the test case being populated
     */
    private void populateTestCaseTab(Tab t, int testCaseNum) {
        if (problem == null) {
            throw new IllegalArgumentException("A problem must be loaded before the test case tabs can be populated.");
        }

        if (t == null) {
            throw new IllegalArgumentException("The tab must be non-null.");
        }
        GridPane g = new GridPane();
        t.setContent(g);
        /*
            TODO: set a minimum size for the gridpane rows and cols
         */
//        g.setMinSize(?, ?);
        for (int i = 0; i < problem.getNumInputs(); i++) {
            Label inputLabel = new Label(problem.getInputNames().get((testCaseNum * problem.getNumInputs())  + i));
            TextField inputField = new TextField();
            // Add to the arraylist so it can be accessed later
            inputValueTextFields.add(inputField);
            g.add(inputLabel, 0, i);
            g.add(inputField, 1, i);
        }

    }
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
        File selected = fc.showDialog(rootBorderPane.getScene().getWindow());
        if (selected != null) {
            localOutputDirectory = selected;
        }
    }

    @FXML
    void showHelp() {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.getDialogPane().getStyleClass().add("-code");
//        alert.getDialogPane().setStyle("-fx-font-family: \"Consolas\", \"monospace\"");
        alert.setTitle("CS1371 Test Case Generator");
        alert.setHeaderText("#HOMEWORKTEAMTEAMWORKMAKESTHEHOMEWORKTEAMDREAMWORK");
        alert.setContentText("Suggestions? Complaints? Insults? Funny jokes? Email dprofili3@gatech.edu and/or "
                + "arao81@gatech.edu.");
        alert.show();
    }


    @FXML
    /**
     * Handler for when the user presses the button to add a banned function.
     * If there is text in the edit field, and that text refers to the name of a valid MATLAB function on the path,
     * that function will be added to the banned functions ListView. If the edit field is empty, nothing is done.
     */
    void addBannedFunctionButtonPressed() {
        String text = bannedFunctionAddField.getText();
        if (text.length() > 0) {
            ObservableList<String> bannedFcns = bannedFunctionsListView.getItems();
            if (!bannedFcns.contains(text)) {
                /*
                    TODO: Verify the banned function exists and/or is on the MATLAB path
                 */
                // Add the banned function to the list
                bannedFcns.add(text);
                // Scroll to the most recently added banned function in the list
                bannedFunctionsListView.scrollTo(bannedFcns.get(bannedFcns.size() - 1));
            } else {
                // If the function is already there, scroll to it
                bannedFunctionsListView.scrollTo(text);
            }
            // Clear the text from the edit field, no matter what happens
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
        fc.setInitialDirectory(defaultDirectory);
        fc.getExtensionFilters().addAll(
                new FileChooser.ExtensionFilter("MATLAB files", "*.m"));
        File selected = fc.showOpenDialog(rootBorderPane.getScene().getWindow());
        loadSolutionFunction(selected);
    }

    /**
     * Loads a solution function from a file in the local disk, enables all problem-related disabled components, and
     * generally sets everything up so that the user can start entering test cases, supporting files, etc.
     * @param selected File representing the solution function file
     * @throws IllegalArgumentException if the file object is null, if it refers to a nonexistent file, or does not
     * refer to a file.
     */
    private void loadSolutionFunction(File selected) {
        if (selected == null) {
            throw new IllegalArgumentException("A null solution file object cannot be loaded.");
        }

        if (!selected.exists() || !selected.isFile()) {
            throw new IllegalArgumentException("File object must refer to an existent file.");
        }
        /*
            TODO:
            Here is where MATLAB would be invoked to nargin()/nargout() the solution file, make sure it's valid,
            etc.

            If the file isn't valid (i.e. it isn't a function [i.e. nargin/nargout error]), then the function source
            text field should turn red and an error message should be displayed notifying the user. Nothing should
            be enabled.
         */
        double numInputs, numOutputs;
        try {
            // MATLAB is garbage, so have to cd() to the solution function directory and nargin there
            String initialDir = engine.feval("cd", selected.getParentFile().getAbsolutePath());
            numInputs = engine.feval(1, "nargin", selected.getName());
            numOutputs = engine.feval(1, "nargout", selected.getName());
            engine.feval("cd", initialDir);
        } catch (Exception e) {

            // Show an alert message
            Alert alert = new Alert(Alert.AlertType.ERROR);
            alert.setTitle("Error loading solution function");
            alert.setHeaderText("Error loading " + selected.getPath() + ".");
            alert.setContentText(e.getCause().toString());
            alert.show();

            // Make the source text field red
            functionSourceTextField.getStyleClass().add("error");

            // Disable problem-related components
            for (Node n : inputFileSet) {
                n.setDisable(true);
            }
            return;
        }

        // Un-errorify, if necessary
        if (functionSourceTextField.getStyleClass().contains("error")) {
            functionSourceTextField.getStyleClass().remove("error");
        }

        // Instantiate the problem
        problem = new Problem(selected, (int) numInputs, (int) numOutputs);
        functionSourceTextField.setText(selected.getName());
        for (Node n : inputFileSet) {
            n.setDisable(false);
        }

        problemSettingsAnchorPane.setDisable(false);
        initializeTestCaseTabPane(studentTestCasesTabPane);
    }

    @FXML
    /**
     * Handler for when the user presses a key (i.e. enter) in the banned functions edit field.
     * Used so that ENTER can be used in place of the add button, with the same functionality.
     * @param e the key event that triggered this handler
     */
    void bannedFunctionsTextFieldKeyPressed(KeyEvent e) {
        if (e.getCode().equals(KeyCode.ENTER)) {
            addBannedFunctionButtonPressed();
        }
    }

    @FXML
    /**
     * Handler for when the user wants to browse for a Google Drive Folder
     */
    void remoteBrowserButtonPressed() {
        try {
            googleFolderId = engine.feval(1, "getGoogleFolder");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @FXML
    /**
     * Handler for when the user clicks the add supporting files button.
     * Opens a FileChooser dialog and adds the selected file if there is one. It will not allow duplicates. If the
     * user's selection is empty, nothing will happen.
     *
     */
    void supportingFilesAddButtonPressed() {
        if (problem == null) {
            throw new IllegalArgumentException("Supporting files cannot be added if the problem is null.");
        }
        FileChooser fc = new FileChooser();
        fc.setTitle("Select supporting files");
        fc.setInitialDirectory(defaultDirectory);
        List<File> selected = fc.showOpenMultipleDialog(rootBorderPane.getScene().getWindow());
        if (selected != null) {
            ObservableList<String> supFiles = supportingFilesListView.getItems();
            for (File f : selected) {
                if (f.equals(problem.getFunctionSource())) {
                    Alert alert = new Alert(Alert.AlertType.ERROR);
                    alert.setTitle("You can't do that!");
                    alert.setHeaderText("You can't add the solution function as a supporting file.");
                    alert.setContentText("With love <3");
                    alert.showAndWait();
                } else if (!supFiles.contains(f.getName())) {
                    supFiles.add(f.getName());
                    problem.getSupportingFiles().add(f);
                    // Scroll to most recently added file
                    supportingFilesListView.scrollTo(supFiles.size() - 1);
                }
            }
        }

    }

    @FXML
    void supportingFilesRemoveButtonPressed() {
        // TODO
        // DEBUG:
        populateBaseWordsSelector(inputBaseGridPane, 6);
    }

    /**
     * Populates the base word selector area with edit fields for each input/output.
     * @param g the GridPane to populate
     * @param num the number of inputs/outputs
     */
    void populateBaseWordsSelector(GridPane g, int num) {
        TextField[] tempBaseWordFields = new TextField[num];
        for (int i = 0; i < num; i++) {
            tempBaseWordFields[i] = new TextField();
//            if (i > 2) {
//                g.addRow(i, null);
//            }
            g.add(tempBaseWordFields[i], 1, i);
//            System.out.println(g.getColumnConstraints().toString());
            Label l = new Label("Base " + (i + 1));
            RowConstraints rc = new RowConstraints();
            rc.setMinHeight(30);
            rc.setMaxHeight(30);
            g.add(l, 0, i);
        }
    }

}
