import java.io.*;
import java.net.*;

/**
 * Listens on a fixed port (default 19876), accepts connections forever,
 * and for each connection: reads one byte, writes it back, closes.
 *
 * Run once in the background; the Client is invoked in a loop against it.
 */
public class Server {
    static final int PORT = 19876;

    public static void main(String[] args) throws Exception {
        int port = args.length > 0 ? Integer.parseInt(args[0]) : PORT;
        ServerSocket server = new ServerSocket(port);
        System.out.println("server listening on port " + port);
        System.out.flush();

        while (true) {
            Socket conn = server.accept();
            Thread.ofVirtual().start(() -> handle(conn));
        }
    }

    static void handle(Socket conn) {
        try (conn) {
            InputStream  in  = conn.getInputStream();
            OutputStream out = conn.getOutputStream();
            int b = in.read();
            if (b < 0) return;
            out.write(b);
            out.flush();   // reply sent immediately after reading
        } catch (IOException e) {
            System.err.println("handler error: " + e);
        }
    }
}
