package googleDriveIntegration.logic;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;


public class GoogleFolder {
    private final String id;
    private final String name;
    private final String token;
    private static final String APPLICATION_KEY = "AIzaSyDrJfq4PT-johRn7Ws2xHdYR22yEcYJHOk";
    private static final String API_ROOT = "https://www.googleapis.com/drive/v3/files/";

    public GoogleFolder(String id, String token) throws Exception {
        this.id = id;
        this.token = token;
        // Make request for other information
        URL url = new URL(API_ROOT + id + "?key=" + APPLICATION_KEY);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("GET");
        con.setRequestProperty("Authorization", "Bearer " + token);
        con.setRequestProperty("Accept", "application/json");

        BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
        String ln;
        String tmp = null;
        while ((ln = reader.readLine()) != null) {
            if (ln.startsWith(" \"name\"")) {
                // We don't have JSON parsing abilities...
                int index = ln.indexOf(":") + 3;
                tmp = ln.substring(index, ln.length() - 2);
                break;
            }
        }
        if (tmp == null) {
            throw new Exception();
        } else {
            this.name = tmp;
        }
        reader.close();
        con.disconnect();
    }

    public String getName() {
        return name;
    }

    @Override
    public String toString() {
        return this.name;
    }

    public String getId() {
        return id;
    }

    public ArrayList<GoogleFolder> getChildren() throws Exception {
        // Make Request for children and populate
        String searchTerm = "'" + this.id + "'%20in%20parents%20and%20trashed%20=%20false%20and%20mimeType=%20'application/vnd.google-apps.folder'";

        URL url = new URL(API_ROOT + "?key=" + APPLICATION_KEY + "&q=" + searchTerm);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("GET");
        con.setRequestProperty("Authorization", "Bearer " + this.token);
        con.setRequestProperty("Accept", "application/json");

        BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
        String ln;
        ArrayList<GoogleFolder> children = new ArrayList<>();
        while ((ln = reader.readLine()) != null) {
            // Just look for id
            if (ln.startsWith("   \"id\"")) {
                int index = ln.indexOf(":") + 3;
                String tmp = ln.substring(index, ln.length() - 2);
                children.add(new GoogleFolder(tmp, this.token));
            }
        }
        return children;
    }

    public void download(String path) {

    }

    public void upload(GoogleFolder parent, String path) {

    }



}
