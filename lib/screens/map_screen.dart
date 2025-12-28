import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:via_livre/l10n/app_localizations.dart';
import '../models/road_report.dart';
import '../models/issue_type.dart';
import '../models/report_vote.dart';
import '../services/firebase_service.dart';

class MapScreen extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  
  const MapScreen({super.key, this.onLanguageChanged});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<List<RoadReport>>? _reportsSubscription;
  List<RoadReport> _reports = [];
  RoadReport? _selectedReport;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _reportsError;
  final Set<IssueType> _selectedFilters = Set.from(IssueType.values); // All selected by default
  bool _isUpdatingMarkers = false;
  Timer? _mapMoveDebounceTimer;

  static const double _defaultZoom = 17.0;
  static const double _searchRadius = 30000.0; // 30km

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Request location permissions
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.locationError;
            _isLoading = false;
          });
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            _defaultZoom,
          ),
        );

        // Subscribe to reports
        _subscribeToReports();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.locationError;
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToReports() {
    if (_currentPosition == null) {
      return;
    }

    final center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    _reportsSubscription?.cancel();
    _reportsSubscription = _firebaseService
        .subscribeToReports(center, _searchRadius)
        .listen(
          (reports) {
            // Check for very recent reports (created in last 30 seconds)
            // and ensure their issue types are in the selected filters
            final now = DateTime.now();
            final recentReports = reports.where((report) {
              final age = now.difference(report.createdAt);
              return age.inSeconds < 30;
            }).toList();

            // Add issue types of recent reports to filters if not already included
            // This ensures newly created reports are always visible
            for (var report in recentReports) {
              if (!_selectedFilters.contains(report.issueType)) {
                _selectedFilters.add(report.issueType);
              }
            }

            if (mounted) {
              setState(() {
                _reports = reports;
                _reportsError = null;
              });
              
              // Update markers after state is set
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _updateMarkers();
                }
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _reportsError = AppLocalizations.of(context)!.failedToLoadReports;
              });
            }
          },
        );
  }

  Future<void> _refreshReports() async {
    if (_currentPosition == null) {
      return;
    }

    final center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    
    try {
      // Fetch reports within 30km
      final reports = await _firebaseService.getNearbyReports(center, _searchRadius);
      
      if (mounted) {
        // Check for very recent reports and add their issue types to filters
        final now = DateTime.now();
        final recentReports = reports.where((report) {
          final age = now.difference(report.createdAt);
          return age.inSeconds < 30;
        }).toList();

        for (var report in recentReports) {
          if (!_selectedFilters.contains(report.issueType)) {
            _selectedFilters.add(report.issueType);
          }
        }

        setState(() {
          _reports = reports;
          _reportsError = null;
        });
        
        // Update markers after state is set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMarkers();
        });
      }
    } catch (e) {
      // Silently fail - subscription will update eventually
    }
  }

  Future<void> _updateMarkers() async {
    // Prevent concurrent updates
    if (_isUpdatingMarkers) return;
    
    _isUpdatingMarkers = true;
    
    try {
      // Filter reports by selected issue types
      final filteredReports = _reports.where((report) => 
        _selectedFilters.contains(report.issueType)
      ).toList();

      // Create new markers set
      final newMarkers = <Marker>[];
      final seenIds = <String>{};

      // Create markers with default icons colored by issue type
      for (var report in filteredReports) {
        try {
          // Check for duplicate IDs
          if (seenIds.contains(report.id)) {
            continue;
          }
          seenIds.add(report.id);
          
          final markerId = MarkerId(report.id);
          // Get icon for this specific issue type - create fresh to ensure correct color
          final hue = _getIssueTypeHue(report.issueType);
          // Create icon with explicit hue value
          final icon = BitmapDescriptor.defaultMarkerWithHue(hue);
          
          final marker = Marker(
            markerId: markerId,
            position: report.location,
            icon: icon,
            onTap: () => _onMarkerTapped(report),
            // Ensure marker is visible and properly configured
            visible: true,
          );
          newMarkers.add(marker);
        } catch (e) {
          // Skip this marker if there's an error creating it
          continue;
        }
      }

      // Only update markers after all are created to avoid flickering
      if (mounted) {
        setState(() {
          // Clear existing markers and set new ones to ensure proper update
          _markers.clear();
          _markers.addAll(newMarkers);
        });
      }
    } catch (e) {
      // On error, don't clear markers - keep existing ones
      // This prevents markers from disappearing on update errors
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  double _getIssueTypeHue(IssueType type) {
    // Map issue types directly to Google Maps marker hue values (0-360)
    switch (type) {
      case IssueType.accident:
        return 0.0; // Red
      case IssueType.construction:
        return 60.0; // Yellow
      case IssueType.flood:
        return 240.0; // Blue
      case IssueType.treeFallen:
        return 120.0; // Green
      case IssueType.protest:
        return 270.0; // Purple/Violet
      case IssueType.other:
        return 330.0; // Rose
    }
  }


  Color _getIssueTypeColor(IssueType type) {
    switch (type) {
      case IssueType.accident:
        return Colors.red;
      case IssueType.construction:
        return Colors.yellow.shade700;
      case IssueType.flood:
        return Colors.blue;
      case IssueType.treeFallen:
        return Colors.green;
      case IssueType.protest:
        return Colors.purple;
      case IssueType.other:
        return Colors.grey;
    }
  }

  String _getIssueTypeName(IssueType type, AppLocalizations l10n) {
    switch (type) {
      case IssueType.accident:
        return l10n.accident;
      case IssueType.construction:
        return l10n.construction;
      case IssueType.flood:
        return l10n.flood;
      case IssueType.treeFallen:
        return l10n.treeFallen;
      case IssueType.protest:
        return l10n.protest;
      case IssueType.other:
        return l10n.other;
    }
  }

  void _onMarkerTapped(RoadReport report) {
    if (!mounted) return;
    setState(() {
      _selectedReport = report;
    });
    _showReportBottomSheet(report);
  }

  void _showReportBottomSheet(RoadReport report) {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        report: report,
        onVote: _onVote,
        onDismiss: () {
          Navigator.pop(context);
          if (mounted) {
            setState(() {
              _selectedReport = null;
            });
          }
        },
      ),
    );
  }

  Future<void> _onVote(String reportId, VoteType voteType) async {
    try {
      await _firebaseService.voteOnReport(reportId, voteType);
      // Refresh all reports to get updated counts
      final reports = await _firebaseService.getAllReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          if (_selectedReport?.id == reportId) {
            _selectedReport = reports.firstWhere((r) => r.id == reportId);
          }
        });
        _updateMarkers();
      }
    } catch (e) {
      // Error is handled in the bottom sheet
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _defaultZoom,
        ),
      );
    }
  }

  Future<void> _onMapMoved(CameraPosition position) async {
    // Debounce map moves to avoid too many updates and marker flickering
    _mapMoveDebounceTimer?.cancel();
    _mapMoveDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // Update reports when map moves significantly
      // Note: We rely on the subscription for primary updates, this is just a supplement
      if (_currentPosition == null) return;
      
      final center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      try {
        final newReports = await _firebaseService.getNearbyReports(
          center,
          _searchRadius,
        );
        
        if (mounted && newReports.isNotEmpty) {
          // Merge new reports with existing ones, avoiding duplicates
          final existingIds = _reports.map((r) => r.id).toSet();
          final uniqueNewReports = newReports.where((r) => !existingIds.contains(r.id)).toList();
          
          setState(() {
            // Add new reports to existing list instead of replacing
            _reports = [..._reports, ...uniqueNewReports];
          });
          
          // Update markers to reflect current state
          _updateMarkers();
        } else if (mounted) {
          // If fetch returned empty or failed, just update markers with existing reports
          // This prevents markers from disappearing
          _updateMarkers();
        }
      } catch (e) {
        // On error, keep existing reports and just update markers
        // This prevents markers from disappearing on fetch failures
        if (mounted) {
          _updateMarkers();
        }
      }
    });
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    _mapMoveDebounceTimer?.cancel();
    // On web, don't dispose the map controller as it can cause errors
    // The web platform handles cleanup automatically
    // _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.gettingLocation),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _currentPosition == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _initializeLocation,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-23.5505, -46.6333); // São Paulo default

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: _defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Use custom button instead
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              // Debounce map moves to avoid too many API calls
            },
            onCameraIdle: () {
              if (_mapController != null) {
                _mapController!.getVisibleRegion().then((region) {
                  final center = LatLng(
                    (region.northeast.latitude + region.southwest.latitude) / 2,
                    (region.northeast.longitude + region.southwest.longitude) / 2,
                  );
                  _onMapMoved(CameraPosition(target: center, zoom: _defaultZoom));
                });
              }
            },
          ),
          // Top UI overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  
                  return Column(
                    children: [
                      // Error banner for reports
                      if (_reportsError != null)
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4.0 : 8.0,
                            vertical: 4.0,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10.0 : 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _reportsError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _reportsError = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      // Filter chips
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isMobile ? 4.0 : 8.0,
                          vertical: 4.0,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8.0 : 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.filterReports,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: IssueType.values.map((type) {
                                final isSelected = _selectedFilters.contains(type);
                                return FilterChip(
                                  label: Text(
                                    _getIssueTypeName(type, l10n),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedFilters.add(type);
                                      } else {
                                        _selectedFilters.remove(type);
                                        // Ensure at least one filter is selected
                                        if (_selectedFilters.isEmpty) {
                                          _selectedFilters.add(type);
                                        }
                                      }
                                    });
                                    _updateMarkers();
                                  },
                                  selectedColor: _getIssueTypeColor(type).withOpacity(0.2),
                                  checkmarkColor: _getIssueTypeColor(type),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? _getIssueTypeColor(type)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  backgroundColor: Colors.grey.shade50,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Menu button - positioned above current location button
          Positioned(
            bottom: 200,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, 50),
                    itemBuilder: (context) {
                      final currentLocale = Localizations.localeOf(context);
                      return [
                        // About option
                        PopupMenuItem<String>(
                          value: 'about',
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.about,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Language options
                        if (widget.onLanguageChanged != null) ...[
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.language,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'lang_en',
                            child: Row(
                              children: [
                                const SizedBox(width: 32),
                                const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.english,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (currentLocale == const Locale('en'))
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'lang_pt',
                            child: Row(
                              children: [
                                const SizedBox(width: 32),
                                const Text('🇲🇿', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.portuguese,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                if (currentLocale == const Locale('pt'))
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ];
                    },
                    onSelected: (value) {
                      if (value == 'about') {
                        Navigator.pushNamed(context, '/about');
                      } else if (value == 'lang_en') {
                        widget.onLanguageChanged?.call(const Locale('en'));
                      } else if (value == 'lang_pt') {
                        widget.onLanguageChanged?.call(const Locale('pt'));
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          // Current location button - positioned on right side (above create report)
          if (_currentPosition != null)
            Positioned(
              bottom: 140,
              right: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _moveToCurrentLocation,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Create report button - positioned on right side below location button
          Positioned(
            bottom: 80,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/create-report');
                      // Refresh reports when returning from create report screen
                      if (result == true && _currentPosition != null) {
                        await _refreshReports();
                      }
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_location_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.createReport,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final RoadReport report;
  final Function(String, VoteType) onVote;
  final VoidCallback onDismiss;

  const _ReportDialog({
    required this.report,
    required this.onVote,
    required this.onDismiss,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final FirebaseService _firebaseService = FirebaseService();
  VoteType? _userVote;
  bool _isLoadingVote = false;
  String? _voteError;
  
  Color _getIssueTypeColor(IssueType type) {
    switch (type) {
      case IssueType.accident:
        return Colors.red;
      case IssueType.construction:
        return Colors.yellow.shade700;
      case IssueType.flood:
        return Colors.blue;
      case IssueType.treeFallen:
        return Colors.green;
      case IssueType.protest:
        return Colors.purple;
      case IssueType.other:
        return Colors.grey;
    }
  }
  
  IconData _getIssueTypeIcon(IssueType type) {
    switch (type) {
      case IssueType.accident:
        return Icons.car_crash;
      case IssueType.construction:
        return Icons.construction;
      case IssueType.flood:
        return Icons.water_drop;
      case IssueType.treeFallen:
        return Icons.park;
      case IssueType.protest:
        return Icons.groups;
      case IssueType.other:
        return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserVote();
  }

  Future<void> _loadUserVote() async {
    final vote = await _firebaseService.getUserVote(widget.report.id);
    if (mounted) {
      setState(() {
        _userVote = vote;
      });
    }
  }

  Future<void> _handleVote(VoteType voteType) async {
    if (_isLoadingVote || !mounted) return;

    setState(() {
      _isLoadingVote = true;
      _voteError = null;
    });

    try {
      if (_userVote == voteType) {
        // Remove vote if clicking same button
        await _firebaseService.removeVote(widget.report.id);
        if (mounted) {
          setState(() {
            _userVote = null;
            _voteError = null;
          });
        }
      } else {
        // Add or change vote
        await _firebaseService.voteOnReport(widget.report.id, voteType);
        if (mounted) {
          setState(() {
            _userVote = voteType;
            _voteError = null;
          });
        }
      }
      if (mounted) {
        widget.onVote(widget.report.id, voteType);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _voteError = AppLocalizations.of(context)!.failedToVote;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVote = false;
        });
      }
    }
  }

  String _getIssueTypeName(IssueType type, AppLocalizations l10n) {
    switch (type) {
      case IssueType.accident:
        return l10n.accident;
      case IssueType.construction:
        return l10n.construction;
      case IssueType.flood:
        return l10n.flood;
      case IssueType.treeFallen:
        return l10n.treeFallen;
      case IssueType.protest:
        return l10n.protest;
      case IssueType.other:
        return l10n.other;
    }
  }
  
  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.reportedAgo(l10n.minutes(difference.inMinutes));
    } else if (difference.inDays < 1) {
      return l10n.reportedAgo(l10n.hours(difference.inHours));
    } else if (difference.inDays < 7) {
      return l10n.reportedAgo(l10n.days(difference.inDays));
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final report = widget.report;
    final issueTypeColor = _getIssueTypeColor(report.issueType);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    issueTypeColor.withOpacity(0.15),
                    issueTypeColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          issueTypeColor,
                          issueTypeColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: issueTypeColor.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIssueTypeIcon(report.issueType),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getIssueTypeName(report.issueType, l10n),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: issueTypeColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeAgo(report.createdAt, l10n),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onDismiss,
                    color: Colors.grey[600],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (report.description != null && report.description!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                report.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.noDetailsAvailable,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Footer with vote buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Vote counts
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Confirmations
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.thumb_up_rounded,
                                  color: Colors.green[700],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${report.confirmationsCount}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    l10n.confirmations(report.confirmationsCount),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        // Dismissals
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.thumb_down_rounded,
                                  color: Colors.red[700],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${report.dismissalsCount}',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    l10n.dismissals(report.dismissalsCount),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Error message
                  if (_voteError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[700],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _voteError!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Vote buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingVote
                              ? null
                              : () => _handleVote(VoteType.confirm),
                          icon: Icon(
                            _userVote == VoteType.confirm
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                            color: _userVote == VoteType.confirm
                                ? Colors.white
                                : Colors.green[700],
                          ),
                          label: Text(
                            l10n.stillPresent,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _userVote == VoteType.confirm
                                ? Colors.green[600]
                                : Colors.green.shade50,
                            foregroundColor: _userVote == VoteType.confirm
                                ? Colors.white
                                : Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: _userVote == VoteType.confirm ? 3 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _userVote == VoteType.confirm
                                    ? Colors.transparent
                                    : Colors.green.shade200,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingVote
                              ? null
                              : () => _handleVote(VoteType.dismiss),
                          icon: Icon(
                            _userVote == VoteType.dismiss
                                ? Icons.cancel_rounded
                                : Icons.cancel_outlined,
                            size: 20,
                            color: _userVote == VoteType.dismiss
                                ? Colors.white
                                : Colors.red[700],
                          ),
                          label: Text(
                            l10n.noLongerPresent,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _userVote == VoteType.dismiss
                                ? Colors.red[600]
                                : Colors.red.shade50,
                            foregroundColor: _userVote == VoteType.dismiss
                                ? Colors.white
                                : Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: _userVote == VoteType.dismiss ? 3 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _userVote == VoteType.dismiss
                                    ? Colors.transparent
                                    : Colors.red.shade200,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


