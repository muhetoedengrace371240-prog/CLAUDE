import '../../core/localization/app_localizations.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Durée maximale d'enregistrement par défaut en V1 (60s en standard).
/// Les membres MUHETO Gold reçoivent 10 minutes — voir [CameraCaptureScreen.maxDurationSeconds],
/// dont la valeur est décidée par l'appelant (`CreateScreen`) selon le
/// statut Gold réel de l'utilisateur au moment de l'ouverture de l'écran.
const kDefaultMaxRecordingSeconds = 60;
const kGoldMaxRecordingSeconds = 600;

/// Écran plein écran de capture vidéo via la caméra du téléphone.
/// Retourne un [File] (chemin de la vidéo enregistrée) via `Navigator.pop`
/// quand l'enregistrement est terminé, ou `null` si l'utilisateur annule.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, this.maxDurationSeconds = kDefaultMaxRecordingSeconds});

  /// Durée maximale d'enregistrement en secondes — 60s en standard, 600s
  /// (10 min) pour les membres MUHETO Gold actifs. Décidée par l'appelant.
  final int maxDurationSeconds;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  bool _isInitializing = true;
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune caméra détectée sur cet appareil.';
          _isInitializing = false;
        });
        return;
      }
      await _startController(_selectedCameraIndex);
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible d'accéder à la caméra. "
            'Vérifie les autorisations dans les réglages du téléphone.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startController(int cameraIndex) async {
    final previousController = _controller;

    final controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    setState(() => _isInitializing = true);

    await previousController?.dispose();
    await controller.initialize();
    await controller.setFlashMode(_flashMode);

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isInitializing = false;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startController(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await controller.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isRecording) return;

    await controller.startVideoRecording();
    setState(() {
      _isRecording = true;
      _recordedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordedSeconds++);
      if (_recordedSeconds >= widget.maxDurationSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;

    _timer?.cancel();
    final file = await controller.stopVideoRecording();

    if (!mounted) return;
    setState(() => _isRecording = false);
    Navigator.of(context).pop(File(file.path));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _ErrorScaffold(message: _errorMessage!);
    }

    if (_isInitializing || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(_controller!)),

          // Barre de progression du temps d'enregistrement (max 60s en V1).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _recordedSeconds / widget.maxDurationSeconds,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
            ),
          ),

          // Fermer + flash en haut.
          Positioned(
            top: 46,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_recordedSeconds}s / ${widget.maxDurationSeconds}s',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                _RoundIconButton(
                  icon: _flashMode == FlashMode.off
                      ? Icons.flash_off_rounded
                      : Icons.flash_on_rounded,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),

          // Bouton d'enregistrement + retournement caméra en bas.
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 64),
                _RecordButton(isRecording: _isRecording, onTap: () {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                }),
                SizedBox(
                  width: 64,
                  child: _isRecording
                      ? null
                      : Center(
                          child: _RoundIconButton(
                            icon: Icons.cameraswitch_rounded,
                            onTap: _switchCamera,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.isRecording, required this.onTap});

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3.5)),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRecording ? BorderRadius.circular(8) : null,
          ),
          margin: EdgeInsets.all(isRecording ? 20 : 0),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_rounded, color: AppColors.gold, size: 44),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).t('common.back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
