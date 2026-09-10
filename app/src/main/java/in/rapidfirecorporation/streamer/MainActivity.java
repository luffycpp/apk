package in.rapidfirecorporation.streamer;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.Toast;

import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.getcapacitor.BridgeActivity;

import java.io.File;
import java.util.concurrent.Executor;

public class MainActivity extends BridgeActivity {

    private boolean authenticated = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        // ── Anti-debugging: kill if debugger attached ───────────────
        if (android.os.Debug.isDebuggerConnected()) {
            android.os.Process.killProcess(android.os.Process.myPid());
        }

        super.onCreate(savedInstanceState);

        // ── Root detection (after super so dialog can show) ────────
        if (isDeviceRooted()) {
            new AlertDialog.Builder(this)
                .setTitle("Access Denied")
                .setMessage("RapidFire Panel does not support rooted devices.")
                .setPositiveButton("Exit", (d, w) -> finishAffinity())
                .setCancelable(false)
                .show();
            return;
        }

        // ── Screenshot / screen-record prevention ──────────────────
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        );

        // ── Keep screen ON while app is open ───────────────────────
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        // ── Full-screen immersive mode ──────────────────────────────
        enableFullScreen();

        // ── Status bar: dark background + light icons ───────────────
        getWindow().setStatusBarColor(0xFF0a0a0a);
        getWindow().setNavigationBarColor(0xFF0a0a0a);

        // ── Check internet connectivity ─────────────────────────────
        if (!isNetworkAvailable()) {
            Toast.makeText(this, "No internet connection", Toast.LENGTH_LONG).show();
        }

        // ── Setup WebView download listener ─────────────────────────
        setupDownloadListener();

        // ── Biometric authentication on launch ─────────────────────
        showBiometricPrompt();
    }

    // ── Biometric Lock ─────────────────────────────────────────────
    private void showBiometricPrompt() {
        BiometricManager biometricManager = BiometricManager.from(this);
        int canAuth = biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG |
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        );

        if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
            // No biometric set up — allow access directly
            authenticated = true;
            return;
        }

        Executor executor = ContextCompat.getMainExecutor(this);
        BiometricPrompt biometricPrompt = new BiometricPrompt(this, executor,
            new BiometricPrompt.AuthenticationCallback() {
                @Override
                public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                    super.onAuthenticationSucceeded(result);
                    authenticated = true;
                    getBridge().getWebView().setVisibility(View.VISIBLE);
                }

                @Override
                public void onAuthenticationFailed() {
                    super.onAuthenticationFailed();
                    Toast.makeText(MainActivity.this,
                        "Authentication failed", Toast.LENGTH_SHORT).show();
                }

                @Override
                public void onAuthenticationError(int errorCode, CharSequence errString) {
                    super.onAuthenticationError(errorCode, errString);
                    finishAffinity(); // Exit if cancelled
                }
            });

        BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
            .setTitle("RapidFire Panel")
            .setSubtitle("Verify your identity to continue")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG |
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
            .build();

        // Hide WebView until authenticated
        getBridge().getWebView().setVisibility(View.INVISIBLE);
        biometricPrompt.authenticate(promptInfo);
    }

    // ── Full-screen Immersive Mode ──────────────────────────────────
    private void enableFullScreen() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat controller = new WindowInsetsControllerCompat(
            getWindow(), getWindow().getDecorView()
        );
        controller.hide(WindowInsetsCompat.Type.systemBars());
        controller.setSystemBarsBehavior(
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        );
    }

    // ── Root Detection ─────────────────────────────────────────────
    private boolean isDeviceRooted() {
        String[] rootPaths = {
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
            "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su",
            "/su/bin/su"
        };
        for (String path : rootPaths) {
            if (new File(path).exists()) return true;
        }
        String buildTags = Build.TAGS;
        if (buildTags != null && buildTags.contains("test-keys")) return true;
        return false;
    }

    // ── Network Check ──────────────────────────────────────────────
    private boolean isNetworkAvailable() {
        ConnectivityManager cm = (ConnectivityManager)
            getSystemService(Context.CONNECTIVITY_SERVICE);
        if (cm == null) return false;
        android.net.Network network = cm.getActiveNetwork();
        if (network == null) return false;
        NetworkCapabilities caps = cm.getNetworkCapabilities(network);
        return caps != null && (
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        );
    }

    // ── File Download Support ──────────────────────────────────────
    private void setupDownloadListener() {
        getBridge().getWebView().setDownloadListener(
            (url, userAgent, contentDisposition, mimeType, contentLength) -> {
                try {
                    Intent intent = new Intent(Intent.ACTION_VIEW);
                    intent.setData(Uri.parse(url));
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                } catch (Exception e) {
                    Toast.makeText(this, "Cannot open download link",
                        Toast.LENGTH_SHORT).show();
                }
            });
    }

    // ── Hardware Back Button ───────────────────────────────────────
    @Override
    public void onBackPressed() {
        WebView webView = getBridge().getWebView();
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            new AlertDialog.Builder(this)
                .setTitle("Exit RapidFire")
                .setMessage("Are you sure you want to exit?")
                .setPositiveButton("Exit", (d, w) -> finishAffinity())
                .setNegativeButton("Cancel", null)
                .show();
        }
    }

    // ── Resume: re-check debugger + restore fullscreen ─────────────
    @Override
    protected void onResume() {
        super.onResume();
        if (android.os.Debug.isDebuggerConnected()) {
            android.os.Process.killProcess(android.os.Process.myPid());
        }
        enableFullScreen();
    }
}
