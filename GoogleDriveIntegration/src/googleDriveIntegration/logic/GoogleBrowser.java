package googleDriveIntegration.logic;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.TreeView;
import javafx.stage.Stage;

import java.awt.*;
import java.io.*;
import java.net.*;
import java.nio.CharBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class GoogleBrowser {
    private GoogleFolder root = null;
    private String token;
    private static final String CLIENT_ID = "52505024621-k0m7bhjhamnfpj04j2ec5uon8m94cvqh.apps.googleusercontent.com";
    private static final String CLIENT_SECRET = "qhcHF-mQ3asZBnWed3nLfAUf";

    /**
     * GoogleBrowser shows a prompt to the user, in order to retrieve a folder
     * @param prompt The prompt to show the user (i.e., what should they select?)
     * @throws Exception
     */
    public GoogleBrowser(String prompt, String refresh) throws Exception {
        // Create Stage
        Parent root = FXMLLoader.load(getClass().getResource("../resources/view.fxml"));
        Stage stage = new Stage();
        stage.setTitle("Google Drive Browser");
        stage.setScene(new Scene(root));
        // get list of google folders under root

        this.token = this.refresh2access(null);
        GoogleFolder folder = new GoogleFolder("root", this.token);
        folder.getChildren();
        // TreeView<GoogleFolder> tree;
        stage.showAndWait();
        // if null, then we didn't get anything; die
        if (this.root == null) {
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

    private String refresh2access(String refresh) throws Exception {
        if (refresh == null) {
            refresh = authorize();
        }
        String GRANT_TYPE = "refresh_token";
        String API = "https://www.googleapis.com/oauth2/v4/token";


        URL url = new URL(API);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("POST");
        con.setDoOutput(true);

        Map<String, String> params = new HashMap<>();
        params.put("client_id", CLIENT_ID);
        params.put("client_secret", CLIENT_SECRET);
        params.put("refresh_token", refresh);
        params.put("grant_type", GRANT_TYPE);
        DataOutputStream out = new DataOutputStream(con.getOutputStream());
        out.writeBytes(GoogleBrowser.buildParameters(params));
        out.flush();
        out.close();

        BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
        String ln;
        StringBuilder builder = new StringBuilder();
        while ((ln = reader.readLine()) != null) {
            builder.append(ln);
        }

        reader.close();
        con.disconnect();
        int index = builder.indexOf("access_token") + " access_token \" ".length();
        return builder.substring(index, builder.indexOf("\"", index));

    }

    private String authorize() throws Exception {
        String SCOPE = "https://www.googleapis.com/auth/drive";
        String RESP_TYPE = "code";
        String REDIRECT = "http://127.0.0.1:9004";
        String GRANT_TYPE = "authorization_code";
        String EXCHANGER = "https://www.googleapis.com/oauth2/v4/token";
        String URL = "https://accounts.google.com/o/oauth2/v2/auth?scope=" + SCOPE
                + "&response_type=" + RESP_TYPE + "&redirect_uri=" + REDIRECT
                + "&client_id=" + CLIENT_ID;

        Desktop d = java.awt.Desktop.getDesktop();
        // start a server socket
        ServerSocket server = new ServerSocket(9004);
        URI uri = new URI(URL);
        d.browse(uri);
        Socket client = server.accept();
        BufferedReader reader = new BufferedReader(
                new InputStreamReader(client.getInputStream())
        );
        String code = reader.readLine();
        BufferedReader htmlReader = new BufferedReader(
                new FileReader(getClass().getResource("../resources/success.html").getFile())
        );
        PrintWriter htmlWriter = new PrintWriter(client.getOutputStream());
        htmlWriter.println("HTTP/1.1 200 OK");
        htmlWriter.println("Content-Type: text/html");
        htmlWriter.println("\r\n");
        htmlWriter.println(htmlReader.readLine());
        htmlWriter.close();

        client.close();
        server.close();

        Pattern pattern = Pattern.compile("(?<=^GET [/][?]code[=])([^\\s]*)");
        Matcher matcher = pattern.matcher(code);
        if (matcher.find()) {
            code = matcher.group();
        } else {
            throw new Exception();
        }
        Map<String, String> params = new HashMap<>();
        params.put("code", code);
        params.put("client_id", CLIENT_ID);
        params.put("client_secret", CLIENT_SECRET);
        params.put("redirect_uri", REDIRECT);
        params.put("grant_type", GRANT_TYPE);

        URL url = new URL(EXCHANGER);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("POST");
        con.setDoOutput(true);

        DataOutputStream out = new DataOutputStream(con.getOutputStream());
        out.writeBytes(GoogleBrowser.buildParameters(params));
        out.flush();
        out.close();

        BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
        StringBuilder builder = new StringBuilder();
        String ln;
        while ((ln = in.readLine()) != null) {
            builder.append(ln);
        }

        reader.close();
        con.disconnect();
        int index = builder.indexOf("refresh_token") + " refresh_token \" ".length();
        return builder.substring(index, builder.indexOf("\"", index));
    }

    public static String buildParameters(Map<String, String> params)
            throws UnsupportedEncodingException {

        StringBuilder result = new StringBuilder();

        for (Map.Entry<String, String> entry : params.entrySet()) {
            result.append(URLEncoder.encode(entry.getKey(), "UTF-8"));
            result.append("=");
            result.append(URLEncoder.encode(entry.getValue(), "UTF-8"));
            result.append("&");
        }

        String resultString = result.toString();
        return resultString.length() > 0
                ? resultString.substring(0, resultString.length() - 1)
                : resultString;

    }
}
