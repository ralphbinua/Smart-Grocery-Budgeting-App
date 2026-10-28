import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProductPhotoCaptureDialog extends StatefulWidget {
  const ProductPhotoCaptureDialog({super.key});

  static Future<Uint8List?> show(BuildContext context) {
    return showDialog<Uint8List>(
      context: context,
      builder: (_) => const ProductPhotoCaptureDialog(),
    );
  }

  @override
  State<ProductPhotoCaptureDialog> createState() =>
      _ProductPhotoCaptureDialogState();
}

class _ProductPhotoCaptureDialogState extends State<ProductPhotoCaptureDialog>
    with WidgetsBindingObserver {
  static const int _maxImageBytes = 12 * 1024 * 1024;

  CameraController? _controller;
  String? _error;
  bool _initializing = false;
  bool _capturing = false;
  bool _isForeground = true;
  int _cameraGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
      _cameraGeneration++;
      final oldController = _controller;
      _controller = null;
      if (mounted) setState(() {});
      if (oldController != null) unawaited(oldController.dispose());
    } else if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      if (_controller == null) unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializing || !mounted) return;
    _initializing = true;
    final generation = ++_cameraGeneration;
    if (mounted) setState(() => _error = null);

    CameraController? newController;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera is available on this device.');
        return;
      }

      final backCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      newController = CameraController(
        backCamera.isNotEmpty ? backCamera.first : cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await newController.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await newController.dispose();
        return;
      }
      setState(() => _controller = newController);
      newController = null;
    } on CameraException catch (error) {
      if (mounted && generation == _cameraGeneration) {
        setState(() => _error = _cameraErrorMessage(error));
      }
    } catch (_) {
      if (mounted && generation == _cameraGeneration) {
        setState(() => _error = 'Could not start the camera.');
      }
    } finally {
      if (newController != null) await newController.dispose();
      _initializing = false;
      if (mounted &&
          _isForeground &&
          _controller == null &&
          generation != _cameraGeneration) {
        unawaited(_initializeCamera());
      }
    }
  }

  String _cameraErrorMessage(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') ||
        code.contains('accessdenied') ||
        code.contains('accessrestricted')) {
      return 'Camera permission is required. Allow camera access and try again.';
    }
    return 'Camera unavailable: ${error.description ?? error.code}';
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || _capturing) return;

    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final photo = await controller.takePicture();
      final imageBytes = await photo.readAsBytes();
      if (imageBytes.length > _maxImageBytes) {
        setState(
          () => _error =
              'The photo is too large to analyze. Retake it closer to the product label.',
        );
        return;
      }
      if (mounted) Navigator.of(context).pop<Uint8List>(imageBytes);
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _cameraErrorMessage(error));
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not capture the photo.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text(
        'Photograph the product',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Center the front label so the product name and size are readable.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: controller != null && controller.value.isInitialized
                    ? CameraPreview(controller)
                    : Center(
                        child: _error == null
                            ? const CircularProgressIndicator()
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                      ),
              ),
            ),
            if (_error != null && controller != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: controller != null && !_capturing ? _capturePhoto : null,
          icon: _capturing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_rounded),
          label: const Text('Capture'),
        ),
      ],
    );
  }
}
