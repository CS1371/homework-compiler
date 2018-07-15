import javafx.fxml.FXML;
import javafx.event.ActionEvent;
import javafx.scene.control.Button;

/**
 * Controller class for the main test case compiler gui.
 * Handles basically everything.
 * @author Daniel Profili
 * @version 1.0
 */
public class TestCaseCompilerController {
//    private Button testButton;
//    boolean buttonPressed;

    protected void handleTestButtonPress(ActionEvent e) {
        System.out.println("Button was pressed");
        System.out.println(e.getSource());
//        if (!buttonPressed) {
//            testButton.setText("Fuck off");
//            buttonPressed = true;
//        } else {
//            testButton.setText("You already pressed the button, go to hell and die");
//        }
    }
}
