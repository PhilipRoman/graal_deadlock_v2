import java.io.*;
import java.net.*;
import java.util.concurrent.*;

public class Client {
    static final int PORT    = 19876;
    static final int TIMEOUT = 5;   // seconds before declaring deadlock

    public static void main(String[] args) {
        int port = args.length > 0 ? Integer.parseInt(args[0]) : PORT;

        try (Socket sock = new Socket("localhost", port)) {
            sock.setTcpNoDelay(true);

            OutputStream rawOut = sock.getOutputStream();
            InputStream rawIn = sock.getInputStream();

            CompletableFuture<Integer> result = new CompletableFuture<>();

            Thread.ofVirtual().start(() -> {
                try {
                    rawOut.write(42);
                    rawOut.flush();
                    int reply = rawIn.read();   // hangs forever on native-image
                    result.complete(reply);
                } catch (IOException e) {
                    result.completeExceptionally(e);
                }
            });

            int reply = result.get(TIMEOUT, TimeUnit.SECONDS);
            if (reply != 42) {
                System.err.println("wrong reply: " + reply);
                System.exit(2);
            }
            System.out.println("ok reply=" + reply);

        } catch (TimeoutException e) {
            System.err.println("DEADLOCK: virtual thread never woken up");
            System.exit(1);
        } catch (Exception e) {
            System.err.println("error: " + e);
            System.exit(2);
        }
    }
}
