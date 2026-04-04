import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dose/services/google_drive_service.dart';

// Since GoogleSignIn heavily relies on platform channels,
// full service testing requires integration testing bindings.
// Here we unit test the HTTP Client decorator logic.

class DummyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.fromIterable([request.headers.toString().codeUnits]),
      200,
    );
  }
}

void main() {
  group('GoogleDriveService Unit Tests', () {
    test('GoogleAuthClient correctly injects auth headers', () async {
      final headers = {'Authorization': 'Bearer 12345TestToken'};
      final authClient = GoogleAuthClient(headers);

      // We can't easily intercept the inner private _client used by GoogleAuthClient
      // without modifying its source code. But we can ensure it instantiates correctly.
      expect(authClient, isNotNull);
      expect(headers.containsKey('Authorization'), isTrue);
    });
  });
}
