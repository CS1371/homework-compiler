package controller;

import java.io.IOException;
import javafx.application.Application;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.BorderPane;
import javafx.stage.Stage;
import java.util.concurrent.ThreadLocalRandom;
public class TestCaseCompiler extends Application {
    private Stage primaryStage;
    private BorderPane rootLayout;
    private final String[] messages = {"Monotonic nondecreasing fun!",
                                        "Is a zebra white with white stripes or black with black stripes?",
                                        "Shoot for the stars and you'll miss",
                                        "Jason Mraz is a talentless hack",
                                        "Full communism 2020",
                                        "Now with more ducks!",
                                        "I went to film school for this",
                                        "AVL Lavigne is dead #woke",
                                        "Poptarts are sandwiches @zacc",
                                        "Above average abs",
                                        "#summersCount",
                                        "#summersDontCount",
                                        "This guy's living in R3018b unlike the rest of us"};

    @Override
    public void start(Stage primaryStage) {
        this.primaryStage = primaryStage;
//        Generate a random message
        int n = ThreadLocalRandom.current().nextInt(0, messages.length + 1);
        this.primaryStage.setTitle("CS1371 Test Case Compiler (" + messages[n] + ")");
        showRoot();
    }

    private void showRoot() {
        try {
            FXMLLoader loader = new FXMLLoader();
            loader.setLocation(TestCaseCompiler.class.getResource("/resources/TestCaseCompiler.fxml"));
            BorderPane root = loader.load();
            primaryStage.setScene(new Scene(root));
            primaryStage.show();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Returns the main stage.
     * @return
     */
    public Stage getPrimaryStage() {
        return primaryStage;
    }

    public static void main(String[] args) {
        launch(args);
    }

}