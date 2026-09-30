import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Thin wrapper around `nfc_manager` for detecting a contactless bank card
/// tapped on the phone's NFC antenna.
///
/// A generic mobile NFC reader can only see the low-level card
/// (ISO14443 UID, ATQA/SAK, and any NDEF payload). Reading the PAN, expiry
/// or cardholder name off a real EMV chip requires exchanging authenticated
/// APDU commands with the card, which is only possible with a certified
/// payment SDK and secure element (e.g. a Soft-POS SDK from an acquirer).
/// This service therefore reports *presence + basic tag identity*, which is
/// enough to drive the "kart okutuldu" UX; the actual charge is still
/// completed through the manual entry / card-network flow.
class NfcDetectionResult {
  final String tagId;
  final String techList;

  const NfcDetectionResult({required this.tagId, required this.techList});
}

class NfcService {
  static Future<bool> isAvailable() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  /// Starts an NFC session and resolves as soon as a tag/card is detected,
  /// or with `null` if [timeout] elapses first.
  static Future<NfcDetectionResult?> detectCard({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<NfcDetectionResult?>();
    Timer? timeoutTimer;

    timeoutTimer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        completer.complete(null);
        await stop();
      }
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        alertMessageIos: 'Kredi kartınızı telefonun arka tarafına okutunuz.',
        onDiscovered: (NfcTag tag) async {
          timeoutTimer?.cancel();
          final result = _describe(tag);
          if (!completer.isCompleted) {
            completer.complete(result);
          }
          await NfcManager.instance.stopSession();
        },
      );
    } catch (_) {
      timeoutTimer.cancel();
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future;
  }

  static NfcDetectionResult _describe(NfcTag tag) {
    if (Platform.isAndroid) {
      final androidTag = NfcTagAndroid.from(tag);
      if (androidTag != null) {
        return NfcDetectionResult(
          tagId: _hex(androidTag.id),
          techList: androidTag.techList.join(', '),
        );
      }
    } else if (Platform.isIOS) {
      final iso7816 = Iso7816Ios.from(tag);
      if (iso7816 != null) {
        return NfcDetectionResult(
          tagId: _hex(iso7816.identifier),
          techList: 'ISO7816',
        );
      }
      final iso15693 = Iso15693Ios.from(tag);
      if (iso15693 != null) {
        return NfcDetectionResult(
          tagId: _hex(iso15693.identifier),
          techList: 'ISO15693',
        );
      }
      final mifare = MiFareIos.from(tag);
      if (mifare != null) {
        return NfcDetectionResult(
          tagId: _hex(mifare.identifier),
          techList: 'MiFare',
        );
      }
    }
    return const NfcDetectionResult(tagId: '-', techList: 'Bilinmeyen etiket');
  }

  static String _hex(Uint8List bytes) {
    if (bytes.isEmpty) return '-';
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  static Future<void> stop() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // no active session
    }
  }
}
