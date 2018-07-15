package googleDriveIntegration.logic;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.web.WebView;
import javafx.stage.Stage;

import java.beans.EventHandler;
import java.io.File;
import java.util.Scanner;

public class Main extends Application {

    @Override
    public void start(Stage primaryStage) throws Exception{
        GoogleBrowser browser = new GoogleBrowser("Hello", "1/bnTziCiz7ewjWsblc6JuYEn9afkJMTvLyDsImnmRU48");
    }


    public static void main(String[] args) {
        launch(args);
    }
}
