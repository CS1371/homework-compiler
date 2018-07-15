package googleDriveIntegration.logic;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.web.WebView;
import javafx.stage.Stage;

import java.io.BufferedReader;
import java.io.FileReader;

public class GoogleBrowser {
    private String folderId = null;

    /**
     * GoogleBrowser shows a prompt to the user, in order to retrieve a folder
     * @param prompt The prompt to show the user (i.e., what should they select?)
     * @throws Exception
     */
    public GoogleBrowser(String prompt) throws Exception {
        // Create Stage
        Parent root = FXMLLoader.load(getClass().getResource("../resources/view.fxml"));
        Stage stage = new Stage();
        stage.setTitle("Google Drive Browser");
        stage.setScene(new Scene(root));
        stage.showAndWait();
        // if null, then we didn't get anything; die
        if (this.folderId == null) {
            throw new Exception();
        }
    }

    /**
     * downloadFolder will download the selected folder to the given destination
     *
     * If the folder name already exists in the destination, then it is first deleted.
     * Google Doc formatted files will be converted to PDFs on download; no other conversion is done.
     * @param path The path to the local folder destination
     */
    public void downloadFolderContents(String path) {

    }

    /**
     * uploadFolder will upload the given path to Google Drive.
     *
     * If path points to a single file, that file is uploaded to the
     * folder previously selected; if it points to a directory, then
     * all the contents of that folder are uploaded, _including_ the
     * folder itself. So, if the folder is named myFolder, then under
     * the selected folder a new folder called myFolder will exist.
     * If myFolder doesn't exist, it is created; if it does, then myFolder
     * is first deleted.
     * @param path The path to the resource
     */
    public void uploadFolder(String path) {

    }
}
