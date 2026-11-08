import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/study_material.dart';
import '../../services/material_download_service.dart';
import '../../services/network_service.dart';

class MaterialDetailScreen extends StatefulWidget {
  final StudyMaterial material;

  const MaterialDetailScreen({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  bool _isDownloaded = false;
  bool _isLoading = true;
  bool _isOnline = true;
  StudyMaterial? _localMaterial;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(MaterialDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.material.id != widget.material.id) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final downloaded = await MaterialDownloadService.isDownloaded(widget.material.id);
    final online = await NetworkService.isOnline();
    StudyMaterial? local;
    if (downloaded) {
      local = await MaterialDownloadService.getDownloadedMaterial(widget.material.id);
    }

    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _isOnline = online;
        _localMaterial = local;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDownload() async {
    if (_isDownloaded) {
      await MaterialDownloadService.removeDownloadedMaterial(widget.material.id);
      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _localMaterial = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from offline downloads'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await MaterialDownloadService.downloadMaterial(widget.material);
      final local = await MaterialDownloadService.getDownloadedMaterial(widget.material.id);
      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _localMaterial = local;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloaded for offline use'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Material to display: prioritize the local copy when downloaded
    final activeMaterial = _localMaterial ?? widget.material;

    // If offline and NOT downloaded, indicate that internet is needed
    final bool cannotDisplayContent = !_isOnline && !_isDownloaded;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context, _isDownloaded),
        ),
        title: const Text(
          'Material Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isDownloaded ? 'Downloaded (Tap to remove)' : 'Download offline',
            icon: Icon(
              _isDownloaded ? Icons.check_circle : Icons.download_outlined,
              color: _isDownloaded ? AppColors.success : AppColors.textDark,
            ),
            onPressed: _toggleDownload,
          ),
        ],
      ),
      body: SafeArea(
        child: cannotDisplayContent
            ? _buildOfflineNoContentState()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with title & metadata
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  activeMaterial.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDownloaded
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.border.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isDownloaded
                                          ? Icons.offline_pin_rounded
                                          : Icons.wifi,
                                      size: 14,
                                      color: _isDownloaded
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isDownloaded ? 'Downloaded' : 'Needs Internet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _isDownloaded
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeMaterial.meta,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Download Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _toggleDownload,
                              icon: Icon(
                                _isDownloaded
                                    ? Icons.check_circle_outline
                                    : Icons.download_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _isDownloaded
                                    ? 'Downloaded • Save offline'
                                    : 'Download for Offline Reading',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isDownloaded
                                    ? AppColors.backgroundDark
                                    : AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Offline status indicator banner
                    if (_isDownloaded)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.offline_pin,
                              color: AppColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Loaded from local copy. Available without wifi.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Content Section
                    const Text(
                      'Study Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        activeMaterial.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: AppColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOfflineNoContentState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Internet Connection Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This material has not been downloaded for offline reading. Please connect to the internet to view or download it.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
