package com.example.niemyetdientu

import android.app.Activity
import android.content.Intent
import android.speech.RecognizerIntent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "voice_input"

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->

            when (call.method) {

                "startVoice" -> {

                    pendingResult = result

                    try {

                        val intent = Intent(
                            RecognizerIntent.ACTION_RECOGNIZE_SPEECH
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                            RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_LANGUAGE,
                            "vi-VN"
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE,
                            "vi-VN"
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_MAX_RESULTS,
                            1
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_PROMPT,
                            "Hãy nói..."
                        )

                        // ========= Giảm thời gian chờ =========

                        intent.putExtra(
                            RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
                            100L
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
                            100L
                        )

                        intent.putExtra(
                            RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS,
                            500L
                        )

                        startActivityForResult(intent, 1001)

                    } catch (e: Exception) {

                        pendingResult?.error(
                            "VOICE_ERROR",
                            e.message,
                            null
                        )

                        pendingResult = null
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {

        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != 1001) return

        if (pendingResult == null) return

        if (resultCode == Activity.RESULT_OK && data != null) {

            val results = data.getStringArrayListExtra(
                RecognizerIntent.EXTRA_RESULTS
            )

            android.util.Log.d(
                "VOICE",
                "RESULT = ${results?.firstOrNull()}"
            )

            pendingResult?.success(
                results?.firstOrNull() ?: ""
            )

        } else {

            pendingResult?.success("")
        }

        pendingResult = null
    }
}