package com.bottlenote.official.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URISyntaxException
import android.util.Log
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bottlenote.official.app/intents"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "handleIntent") {
                val url = call.argument<String>("url")

                if (url != null) {
                    handleIntent(url)
                    result.success("Intent handled successfully.")
                } else {
                    result.error("INVALID_URL", "URL is null or invalid", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

   private fun handleIntent(url: String) {
    if (url == null) return
    
    try {
        val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
        if (intent.resolveActivity(packageManager) != null) {
            // 카카오 앱이 설치된 경우 실행
            startActivity(intent)
        } else {
            // fallback URL 처리
            val fallbackUrl = intent.getStringExtra("browser_fallback_url")
            if (fallbackUrl != null) {
                val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl))
                startActivity(fallbackIntent)
            } else {
                Toast.makeText(this, "카카오 앱이 설치되어 있지 않습니다.", Toast.LENGTH_LONG).show()
            }
        }
    } catch (e: Exception) {
        e.printStackTrace()
        Toast.makeText(this, "Intent 실행 중 오류 발생: ${e.message}", Toast.LENGTH_LONG).show()
    }
}

}
