package com.statusdownloader.download.videoimagesaver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Reads status media through the Storage Access Framework so the app never
 * needs All files access. The user grants one persistable read permission on
 * the messaging app's .Statuses folder; documents are copied into the app
 * cache so the Flutter side can keep working with plain file paths.
 */
class StatusAccessHandler(private val activity: Activity) {

    companion object {
        const val CHANNEL = "com.statusdownloader.download.videoimagesaver/saf"
        const val REQUEST_CODE = 7341

        private const val STORAGE_AUTHORITY = "com.android.externalstorage.documents"
        private const val WHATSAPP_STATUSES =
            "primary:Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
        private const val BUSINESS_STATUSES =
            "primary:Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"

        private val IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "webp", "gif")
        private val VIDEO_EXTENSIONS = setOf("mp4", "3gp", "mkv", "avi", "mov")
    }

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasAccess" -> result.success(grantedStatusTrees().isNotEmpty())
            "requestAccess" -> requestAccess(call.argument<Boolean>("business") ?: false, result)
            "syncStatuses" -> syncStatuses(result)
            "releaseAccess" -> releaseAccess(result)
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val result = pendingResult ?: return true
        pendingResult = null

        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(mapOf("granted" to false, "reason" to "cancelled"))
            return true
        }

        if (!isStatusTree(treeUri)) {
            result.success(mapOf("granted" to false, "reason" to "wrong_folder"))
            return true
        }

        return try {
            activity.contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            result.success(mapOf("granted" to true))
            true
        } catch (e: Exception) {
            result.success(mapOf("granted" to false, "reason" to "not_persistable"))
            true
        }
    }

    private fun requestAccess(business: Boolean, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("IN_PROGRESS", "A folder request is already running", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val documentId = if (business) BUSINESS_STATUSES else WHATSAPP_STATUSES
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    DocumentsContract.buildDocumentUri(STORAGE_AUTHORITY, documentId),
                )
            }
        }

        pendingResult = result
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (e: Exception) {
            pendingResult = null
            result.error("NO_PICKER", "No folder picker available on this device", null)
        }
    }

    private fun releaseAccess(result: MethodChannel.Result) {
        for (uri in grantedStatusTrees()) {
            try {
                activity.contentResolver.releasePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (_: Exception) {
            }
        }
        result.success(true)
    }

    private fun syncStatuses(result: MethodChannel.Result) {
        val trees = grantedStatusTrees()
        if (trees.isEmpty()) {
            result.error("NO_ACCESS", "No status folder access granted", null)
            return
        }

        io.execute {
            try {
                val items = collect(trees)
                prune(items.mapNotNull { it["name"] as? String }.toSet())
                main.post { result.success(items) }
            } catch (e: Exception) {
                main.post { result.error("SYNC_FAILED", e.message, null) }
            }
        }
    }

    /** Copies every status document into the cache and returns its metadata. */
    private fun collect(trees: List<Uri>): List<Map<String, Any>> {
        val resolver = activity.contentResolver
        val cacheDir = statusCacheDir()
        val items = mutableListOf<Map<String, Any>>()
        val seen = mutableSetOf<String>()

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )

        for (tree in trees) {
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )

            resolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    val documentId = cursor.getString(0) ?: continue
                    val name = cursor.getString(1) ?: continue
                    val size = cursor.getLong(2)
                    val modified = cursor.getLong(3)

                    val extension = name.substringAfterLast('.', "").lowercase()
                    val isVideo = extension in VIDEO_EXTENSIONS
                    if (!isVideo && extension !in IMAGE_EXTENSIONS) continue
                    if (!seen.add(name)) continue

                    val cached = File(cacheDir, name)
                    if (!cached.exists() || (size > 0L && cached.length() != size)) {
                        val documentUri =
                            DocumentsContract.buildDocumentUriUsingTree(tree, documentId)
                        val copied = try {
                            resolver.openInputStream(documentUri)?.use { input ->
                                cached.outputStream().use { output -> input.copyTo(output) }
                            } != null
                        } catch (_: Exception) {
                            false
                        }
                        if (!copied) {
                            cached.delete()
                            continue
                        }
                        if (modified > 0L) cached.setLastModified(modified)
                    }

                    items.add(
                        mapOf(
                            "path" to cached.absolutePath,
                            "name" to name,
                            "isVideo" to isVideo,
                            "lastModified" to if (modified > 0L) modified else cached.lastModified(),
                        ),
                    )
                }
            }
        }

        return items
    }

    /** Drops cached copies of statuses that have expired on the source folder. */
    private fun prune(keep: Set<String>) {
        statusCacheDir().listFiles()?.forEach { file ->
            if (file.name !in keep) file.delete()
        }
    }

    private fun statusCacheDir(): File {
        val dir = File(activity.cacheDir, "statuses")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun grantedStatusTrees(): List<Uri> {
        return activity.contentResolver.persistedUriPermissions
            .filter { it.isReadPermission && isStatusTree(it.uri) }
            .map { it.uri }
    }

    private fun isStatusTree(uri: Uri): Boolean {
        val documentId = try {
            DocumentsContract.getTreeDocumentId(uri)
        } catch (_: Exception) {
            return false
        }
        return documentId.substringAfterLast('/').removePrefix(".").equals("Statuses", true)
    }
}
