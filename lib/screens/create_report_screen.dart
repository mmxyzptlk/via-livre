import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:via_livre/l10n/app_localizations.dart';
import '../models/issue_type.dart';
import '../services/firebase_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _firebaseService = FirebaseService();

  IssueType? _selectedIssueType;
  Position? _currentPosition;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  String? _locationName;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isFetchingLocationName = false;
  String? _locationError;
  String? _issueTypeError;
  String? _submitError;
  static const double _maxDistanceKm = 10.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    try {
      final String style = await rootBundle.loadString('lib/config/map_style.json');
      await controller.setMapStyle(style);
    } catch (e) {
      // Silently fail if style loading fails
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Request location permissions
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationError = AppLocalizations.of(context)!.locationError;
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isGettingLocation = false;
        _locationName = null;
      });

      // Move map to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          _selectedLocation!,
          14.0,
        ),
      );

      // Fetch location name (reverse geocoding)
      _fetchLocationName(position);
    } catch (e) {
      setState(() {
        _locationError = AppLocalizations.of(context)!.locationError;
        _isGettingLocation = false;
      });
    }
  }

  void _updateSelectedLocation(LatLng location, {bool fetchName = true}) {
    if (_currentPosition == null) return;

    // Check distance
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      location.latitude,
      location.longitude,
    ) / 1000; // Convert to km

    // Always allow location selection, but show alert if too far
    setState(() {
      _selectedLocation = location;
      _locationError = null;
      if (fetchName) {
        _locationName = null;
      }
    });

    // Fetch location name only when requested (not on every camera move)
    if (fetchName) {
      _fetchLocationName(LatLng(location.latitude, location.longitude));
    }

    // Show alert if distance is too far
    if (distance > _maxDistanceKm) {
      _showDistanceAlert(distance);
    }
  }

  void _onCameraIdle() async {
    if (_mapController == null || _currentPosition == null) return;

    try {
      // Get the center of the visible region
      final visibleRegion = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
        (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
      );
      
      _updateSelectedLocation(center);
    } catch (e) {
      // Silently fail - location will update on next camera movement
    }
  }

  void _showDistanceAlert(double distance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.locationTooFar(_maxDistanceKm.toInt()),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.locationDistanceWarning(
                      distance.toStringAsFixed(2),
                      _maxDistanceKm.toInt(),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _fetchLocationName(dynamic position) async {
    LatLng latLng;
    if (position is Position) {
      latLng = LatLng(position.latitude, position.longitude);
    } else if (position is LatLng) {
      latLng = position;
    } else {
      return;
    }
    setState(() {
      _isFetchingLocationName = true;
    });

    try {
      // Use Google Geocoding API
      const apiKey = 'AIzaSyDTUEb00tfLM8yvu95QTTyGNRNZ1hX7GBk';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey&language=${Localizations.localeOf(context).languageCode}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Get the formatted address from the first result
          final formattedAddress = data['results'][0]['formatted_address'] as String?;
          
          // Or build from address components for a shorter version
          String? address;
          if (formattedAddress != null && formattedAddress.isNotEmpty) {
            // Use formatted address but try to make it shorter
            final parts = formattedAddress.split(',');
            if (parts.length > 2) {
              // Take the first 2-3 parts (street, neighborhood/city)
              address = parts.take(2).join(', ').trim();
            } else {
              address = formattedAddress;
            }
          }

          if (mounted && address != null && address.isNotEmpty) {
            setState(() {
              _locationName = address;
              _isFetchingLocationName = false;
            });
            return;
          }
        }
      }

      // If we get here, geocoding failed
      if (mounted) {
        setState(() {
          _isFetchingLocationName = false;
        });
      }
    } catch (e) {
      // Silently fail - location name is optional
      if (mounted) {
        setState(() {
          _isFetchingLocationName = false;
        });
      }
    }
  }

  Future<void> _submitReport() async {
    // Clear previous errors
    setState(() {
      _issueTypeError = null;
      _submitError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIssueType == null) {
      setState(() {
        _issueTypeError = AppLocalizations.of(context)!.selectIssueType;
      });
      return;
    }

    if (_currentPosition == null) {
      setState(() {
        _locationError = AppLocalizations.of(context)!.locationError;
      });
      return;
    }

    if (_selectedLocation == null) {
      setState(() {
        _locationError = AppLocalizations.of(context)!.pleaseSelectLocation;
      });
      return;
    }

    // Check if selected location is within 10 km of current position
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    ) / 1000; // Convert to km

    if (distance > _maxDistanceKm) {
      setState(() {
        _locationError = AppLocalizations.of(context)!.locationTooFar(_maxDistanceKm.toInt());
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _submitError = null;
      _locationError = null;
    });

    try {
      await _firebaseService.createReport(
        location: _selectedLocation!,
        issueType: _selectedIssueType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportCreated),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate report was created successfully
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = AppLocalizations.of(context)!.reportError;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Widget _buildCoordinateRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo(ThemeData theme, AppLocalizations l10n) {
    if (_selectedLocation == null || _currentPosition == null) {
      return const SizedBox.shrink();
    }

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    ) / 1000; // Convert to km

    final isWithinLimit = distance <= _maxDistanceKm;

    return Row(
      children: [
        Icon(
          isWithinLimit ? Icons.check_circle : Icons.warning,
          size: 16,
          color: isWithinLimit ? Colors.green.shade600 : Colors.orange.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '${l10n.distance}: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            '${distance.toStringAsFixed(2)} km / ${_maxDistanceKm.toInt()} km',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWithinLimit ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    // On web, just clear the reference without disposing
    // The web platform handles cleanup automatically and disposing can cause assertion errors
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportForm),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
          children: [
            // Location status - Enhanced Design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentPosition != null
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _currentPosition != null
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _currentPosition != null
                                ? Icons.location_on
                                : Icons.location_searching,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.location,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_currentPosition != null)
                                Text(
                                  l10n.gettingLocation.split('...').first,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isGettingLocation)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.gettingLocation,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_locationError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationError!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(l10n.retry),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_currentPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Map
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _selectedLocation ?? LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      zoom: 17.0,
                                    ),
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                      _setMapStyle(controller);
                                    },
                                    onCameraIdle: _onCameraIdle,
                                    onCameraMove: (CameraPosition position) {
                                      // Update location in real-time as map moves (without fetching name)
                                      if (_currentPosition != null) {
                                        _updateSelectedLocation(position.target, fetchName: false);
                                      }
                                    },
                                  ),
                                  // Fixed center marker (ignores pointer events so map can be dragged)
                                  IgnorePointer(
                                    child: Center(
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 48,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Location info
                          if (_selectedLocation != null) ...[
                            if (_locationName != null || _isFetchingLocationName) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.place,
                                      color: theme.colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _isFetchingLocationName
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading address...',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              _locationName ?? '',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildCoordinateRow(
                                    Icons.north,
                                    l10n.latitude,
                                    _selectedLocation!.latitude.toStringAsFixed(6),
                                    theme,
                                  ),
                                  const Divider(height: 16),
                                  _buildCoordinateRow(
                                    Icons.east,
                                    l10n.longitude,
                                    _selectedLocation!.longitude.toStringAsFixed(6),
                                    theme,
                                  ),
                                  const Divider(height: 16),
                                  _buildDistanceInfo(theme, l10n),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.pleaseSelectLocation,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Issue type selection
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.issueType,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_issueTypeError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _issueTypeError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...IssueType.values.map((type) {
              final isSelected = _selectedIssueType == type;
              final color = _getIssueTypeColor(type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIssueType = type;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : Colors.white,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getIssueTypeIcon(type),
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getIssueTypeName(type, l10n),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? color
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            // Description field
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.description,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                hintText: l10n.additionalDetailsOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(fontSize: 15),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                        _submitError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Distance warning if too far
            if (_selectedLocation != null && _currentPosition != null) ...[
              Builder(
                builder: (context) {
                  final distance = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                  ) / 1000;
                  
                  if (distance > _maxDistanceKm) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cannot create report',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.locationDistanceWarning(
                                    distance.toStringAsFixed(2),
                                    _maxDistanceKm.toInt(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            // Submit button
            SizedBox(
              height: 56,
              child: Builder(
                builder: (context) {
                  final isTooFar = _selectedLocation != null && 
                      _currentPosition != null &&
                      Geolocator.distanceBetween(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        _selectedLocation!.latitude,
                        _selectedLocation!.longitude,
                      ) / 1000 > _maxDistanceKm;
                  
                  return ElevatedButton(
                    onPressed: (_isLoading || isTooFar) ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTooFar 
                          ? Colors.grey.shade400
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: isTooFar ? 0 : 2,
                      shadowColor: isTooFar 
                          ? Colors.transparent
                          : theme.colorScheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isTooFar ? Icons.block : Icons.send,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.submit,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

