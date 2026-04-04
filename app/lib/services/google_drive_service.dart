import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:dose/services/backup_service.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._init();
  GoogleDriveService._init();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    return await _googleSignIn.signInSilently();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Uploads the local backup to the visible Drive root.
  Future<void> uploadBackup() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) throw Exception("User not signed in to Google.");

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    // Generate local backup
    final localBackupPath = await BackupService.instance.exportData();
    final fileToUpload = File(localBackupPath);
    if (!await fileToUpload.exists()) {
      throw Exception("Local backup file could not be generated.");
    }

    final query = "name = 'dose_backup.json' and trashed = false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');
    final existingFiles = fileList.files;

    final media = drive.Media(
      fileToUpload.openRead(),
      fileToUpload.lengthSync(),
    );

    if (existingFiles != null && existingFiles.isNotEmpty) {
      // Overwrite existing backup
      final existingFileId = existingFiles.first.id!;
      final driveFile = drive.File();
      await driveApi.files.update(
        driveFile,
        existingFileId,
        uploadMedia: media,
      );
    } else {
      // Create new backup
      final driveFile = drive.File()
        ..name = 'dose_backup.json'
        ..mimeType = 'application/json';
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Downloads the backup from drive and imports it locally
  Future<void> downloadBackup() async {
    final account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) throw Exception("User not signed in to Google.");

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    final query = "name = 'dose_backup.json' and trashed = false";
    final fileList = await driveApi.files.list(
      q: query,
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
    );
    final existingFiles = fileList.files;

    if (existingFiles == null || existingFiles.isEmpty) {
      throw Exception("No backup found on Google Drive.");
    }

    final fileId = existingFiles.first.id!;
    final response =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    // Save to temp file
    final tempDir = await Directory.systemTemp.createTemp('dose_drive_restore');
    final tempFile = File('${tempDir.path}/dose_backup.json');

    final sink = tempFile.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    // Import the downloaded backup locally
    await BackupService.instance.importData(tempFile.path);

    // Cleanup temp
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}
  }
}
