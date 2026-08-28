package com.statusdownloader.download.videoimagesaver

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URLConnection

class MainActivity : FlutterActivity() {
    private val channelName = "com.statusdownloader.download.videoimagesaver/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToGallery" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        val isVideo = call.argument<Boolean>("isVideo") ?: false
                        if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "sourcePath and fileName required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveToGallery(sourcePath, fileName, isVideo)
                            if (savedPath != null) {
                                result.success(savedPath)
                            } else {
                                result.error("SAVE_FAILED", "Could not save media to gallery", null)
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "scanFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "path required", null)
                            return@setMethodCallHandler
                        }
                        scanFile(path, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToGallery(sourcePath: String, fileName: String, isVideo: Boolean): String? {
        val source = File(sourcePath)
        if (!source.exists()) return null

        val mimeType = guessMimeType(fileName, isVideo)
        val relativeFolder = if (isVideo) {
            "${Environment.DIRECTORY_MOVIES}/WAStatusSaver"
        } else {
            "${Environment.DIRECTORY_PICTURES}/WAStatusSaver"
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(source, fileName, mimeType, isVideo, relativeFolder)
        } else {
            saveViaPublicDir(source, fileName, mimeType, isVideo)
        }
    }

    private fun saveViaMediaStore(
        source: File,
        fileName: String,
        mimeType: String,
        isVideo: Boolean,
        relativePath: String,
    ): String? {
        val collection: Uri = if (isVideo) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val resolver = applicationContext.contentResolver
        val uri = resolver.insert(collection, values) ?: return null

        resolver.openOutputStream(uri)?.use { output ->
            source.inputStream().use { input -> input.copyTo(output) }
        } ?: run {
            resolver.delete(uri, null, null)
            return null
        }

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return queryAbsolutePath(uri) ?: resolvePublicPath(fileName, isVideo)
    }

    private fun saveViaPublicDir(
        source: File,
        fileName: String,
        mimeType: String,
        isVideo: Boolean,
    ): String? {
        val base = Environment.getExternalStoragePublicDirectory(
            if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES,
        )
        val dir = File(base, "WAStatusSaver")
        if (!dir.exists() && !dir.mkdirs()) return null

        val dest = File(dir, fileName)
        source.copyTo(dest, overwrite = true)

        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(dest.absolutePath),
            arrayOf(mimeType),
            null,
        )
        return dest.absolutePath
    }

    private fun scanFile(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.error("NOT_FOUND", "File not found: $path", null)
            return
        }
        val mimeType = guessMimeType(file.name, path.matches(Regex(".*\\.(mp4|3gp|mkv|avi|mov)$", RegexOption.IGNORE_CASE)))
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(path),
            arrayOf(mimeType),
        ) { _, uri ->
            runOnUiThread {
                result.success(uri?.toString() ?: path)
            }
        }
    }

    private fun queryAbsolutePath(uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        return try {
            applicationContext.contentResolver.query(uri, projection, null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                        if (index >= 0) cursor.getString(index) else null
                    } else {
                        null
                    }
                }
        } catch (_: Exception) {
            null
        }
    }

    private fun resolvePublicPath(fileName: String, isVideo: Boolean): String {
        val base = Environment.getExternalStoragePublicDirectory(
            if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES,
        )
        return File(File(base, "WAStatusSaver"), fileName).absolutePath
    }

    private fun guessMimeType(fileName: String, isVideo: Boolean): String {
        URLConnection.guessContentTypeFromName(fileName)?.let { return it }
        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".png") -> "image/png"
            lower.endsWith(".webp") -> "image/webp"
            lower.endsWith(".gif") -> "image/gif"
            lower.endsWith(".jpg") || lower.endsWith(".jpeg") -> "image/jpeg"
            lower.endsWith(".mp4") -> "video/mp4"
            lower.endsWith(".3gp") -> "video/3gpp"
            lower.endsWith(".mkv") -> "video/x-matroska"
            lower.endsWith(".avi") -> "video/x-msvideo"
            lower.endsWith(".mov") -> "video/quicktime"
            isVideo -> "video/mp4"
            else -> "image/jpeg"
        }
    }
}
