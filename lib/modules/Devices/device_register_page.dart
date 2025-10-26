import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart'; // <-- NEW
import 'device_model.dart';
import 'device_service.dart';

class DeviceRegisterPage extends StatefulWidget {
  const DeviceRegisterPage({super.key});

  @override
  State<DeviceRegisterPage> createState() => _DeviceRegisterPageState();
}

class _DeviceRegisterPageState extends State<DeviceRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = DeviceService();

  final _hardwareCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _role = 'master'; // 'master' | 'slave'
  bool _submitting = false;

  List<DeviceModel> _masters = [];
  int? _selectedMasterId;
  bool _loadingMasters = false;
  String _error = '';

  @override
  void dispose() {
    _hardwareCtrl.dispose();
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMasters() async {
    setState(() {
      _loadingMasters = true;
      _error = '';
    });
    try {
      final m = await _svc.fetchMasters();
      setState(() {
        _masters = m;
        if (_masters.isNotEmpty) {
          _selectedMasterId ??= _masters.first.id;
        }
      });
    } catch (e) {
      setState(() => _error = 'Failed to load masters: $e');
    } finally {
      setState(() => _loadingMasters = false);
    }
  }

  // ---- NEW: Use device GPS to auto-fill lat/lng ----
  Future<void> _useCurrentLocation() async {
    setState(() => _error = '');
    try {
      // 1) Services ON?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }
      // 2) Permission flow
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. '
            'Enable them from Settings.');
      }
      // 3) Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location filled from GPS'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      setState(() => _error = 'Latitude/Longitude must be valid numbers');
      return;
    }
    if (_role == 'slave' && _selectedMasterId == null) {
      setState(() => _error = 'Please select a master for the slave device');
      return;
    }

    setState(() {
      _submitting = true;
      _error = '';
    });

    try {
      final result = await _svc.registerDevice(
        hardwareIdentifier: _hardwareCtrl.text.trim(),
        deviceName: _nameCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        deviceRole: _role,
        masterId: _role == 'slave' ? _selectedMasterId : null,
      );

      // On success, just return device to parent; parent page shows snackbar & refreshes
      if (result.isSuccess && result.device != null) {
        Get.back(result: result.device);
        return;
      }

      // Failure: keep on page and show inline error
      setState(() => _error = 'Registration failed (code ${result.statusCode}).');
    } catch (e) {
      setState(() => _error = 'Register failed: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSlave = _role == 'slave';

    return Scaffold(
      appBar: AppBar(title: const Text('Register Device')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _input(label: 'Hardware Identifier', controller: _hardwareCtrl),
                const SizedBox(height: 12),
                _input(label: 'Device Name', controller: _nameCtrl),
                const SizedBox(height: 12),

                // Lat/Lng + Use current location
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        label: 'Latitude',
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _input(
                        label: 'Longitude',
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
                  ),
                ),

                const SizedBox(height: 12),

                // Role selector
                Row(
                  children: [
                    const Text('Role:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Master'),
                      selected: _role == 'master',
                      onSelected: (_) => setState(() => _role = 'master'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Slave'),
                      selected: _role == 'slave',
                      onSelected: (_) async {
                        setState(() => _role = 'slave');
                        await _loadMasters();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Master dropdown when Slave selected
                if (isSlave) ...[
                  if (_loadingMasters) const LinearProgressIndicator(),
                  if (!_loadingMasters && _masters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No masters available. Register a master first.'),
                    ),
                  if (_masters.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _selectedMasterId ?? _masters.first.id,
                      items: _masters
                          .map((m) => DropdownMenuItem<int>(
                                value: m.id,
                                child: Text(
                                  '${m.deviceName.isNotEmpty ? m.deviceName : m.hardwareIdentifier} (ID ${m.id})',
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMasterId = v),
                      decoration: InputDecoration(
                        labelText: 'Select Master',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_submitting ? 'Submitting...' : 'Register'),
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
