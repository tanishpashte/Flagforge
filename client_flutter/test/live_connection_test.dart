import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:client_flutter/flagforge_sdk.dart';

void main() {
  test('End-to-End Live WebSocket sync with FastAPI backend', () async {
    // Check if backend is running first
    bool serverRunning = false;
    try {
      final socket = await Socket.connect('127.0.0.1', 8000, timeout: const Duration(seconds: 1));
      socket.destroy();
      serverRunning = true;
    } catch (_) {
      print('E2E Test: Local backend server not running on port 8000. Skipping integration test.');
    }

    if (!serverRunning) {
      return; // Skip test
    }

    // 1. Instantiate the real FlagForgeClient pointing to local backend
    final client = FlagForgeClient(host: '127.0.0.1:8000');
    
    print('E2E Test: Initializing client connection...');
    // 2. Initialize (this fetches baseline flags and connects via WS)
    await client.initialize(1);
    
    // Dynamically check the current state and target the opposite value
    final initialDarkMode = client.isEnabled('dark_mode');
    final targetDarkMode = !initialDarkMode;
    print('E2E Test: Initial dark_mode state is $initialDarkMode. Expecting state to transition to $targetDarkMode');
    
    // 3. Set up a listener to capture when client cache updates
    final completer = Completer<void>();
    client.addListener(() {
      print('E2E Test: Listener notified of client update! Current dark_mode: ${client.isEnabled('dark_mode')}');
      if (client.isEnabled('dark_mode') == targetDarkMode) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    
    // 4. Mimic the Python TUI by making a real HTTP PATCH request to backend to toggle the flag
    // In our database seeding, flag 'dark_mode' has ID 2
    print('E2E Test: Triggering HTTP toggle request (simulating TUI)...');
    final response = await http.patch(Uri.parse('http://127.0.0.1:8000/api/flags/2/toggle'));
    expect(response.statusCode, 200);
    final json = jsonDecode(response.body);
    expect(json['is_enabled'], targetDarkMode);
    print('E2E Test: Toggle request successful, is_enabled matches target state');
    
    // 5. Wait for the WebSocket stream to deliver the update and notify our listener
    print('E2E Test: Waiting for WebSocket broadcast...');
    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      fail('WebSocket update timed out. Connection was not synchronized.');
    });
    
    print('E2E Test: WebSocket update successfully received and applied to cache!');
    expect(client.isEnabled('dark_mode'), targetDarkMode);
    
    // Clean up
    client.dispose();
  });
}
