package googleDriveIntegration.logic;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.web.WebView;
import javafx.stage.Stage;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.FileReader;

public class GoogleBrowser {
    private String fileId = null;

    public GoogleBrowser(String prompt) throws Exception {
        // Create Stage
        Parent root = FXMLLoader.load(getClass().getResource("../resources/view.fxml"));
        Stage stage = new Stage();
        stage.setTitle("Google Drive Browser");
        stage.setScene(new Scene(root));
        WebView viewer = (WebView)root.getChildrenUnmodifiable().get(0);
        viewer.getEngine().setJavaScriptEnabled(true);
        BufferedReader reader = new BufferedReader(
                new FileReader(getClass().getResource("../resources/index.html").getFile())
        );
        StringBuilder builder = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            builder.append(line);
        }
        viewer.getEngine().loadContent(builder.toString());
        viewer.getEngine().setOnAlert(event -> alertHandler(event.getData()));

        stage.showAndWait();
    }

    private void alertHandler(String data) {
        if (data != null && data != "") {
            this.fileId = data;
        }
    }

    public String getFileId() throws Exception {
        if (this.fileId == null) {
            throw new Exception();
        } else {
            return this.fileId;
        }
    }

    public void downloadFolder(String ) {

    }

    public void uploadFolder() {

    }
}
