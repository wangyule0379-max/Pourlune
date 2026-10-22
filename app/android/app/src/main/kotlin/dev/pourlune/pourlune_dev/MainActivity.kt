package dev.pourlune.pourlune_dev

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // The matching Flutter shell replaces the static system mark on readiness.
            // No timer, retained splash or artificial initialization wait.
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
