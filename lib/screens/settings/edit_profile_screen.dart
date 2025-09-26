import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _birthDate;
  bool _isLoading = false;
  File? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _bioController.text = user.bio ?? '';
      _websiteController.text = user.website ?? '';
      _locationController.text = user.location ?? '';
      _birthDate = user.birthDate;
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedAvatar = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update profile data
      final result = await ApiService.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        location: _locationController.text.trim(),
        birthDate: _birthDate,
      );

      if (result['success']) {
        // Update avatar if selected
        if (_selectedAvatar != null) {
          final avatarResult = await ApiService.updateProfileAvatar(
            _selectedAvatar!,
          );
          if (!avatarResult['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile updated but avatar upload failed'),
              ),
            );
          }
        }

        // Refresh user data
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUserData();

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedAvatar != null
                          ? FileImage(_selectedAvatar!)
                          : Provider.of<AuthProvider>(
                                  context,
                                ).user?.profileImage !=
                                null
                          ? NetworkImage(
                              Provider.of<AuthProvider>(
                                context,
                              ).user!.profileImage!,
                            )
                          : null,
                      child:
                          _selectedAvatar == null &&
                              Provider.of<AuthProvider>(
                                    context,
                                  ).user?.profileImage ==
                                  null
                          ? Text(
                              Provider.of<AuthProvider>(
                                    context,
                                  ).user?.displayName[0] ??
                                  'U',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.twitterBlue,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
                maxLength: 160,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 16),

              // Birth Date Picker
              ListTile(
                title: const Text('Birth Date'),
                subtitle: Text(
                  _birthDate != null
                      ? DateFormat('MMMM d, yyyy').format(_birthDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _birthDate ??
                        DateTime.now().subtract(const Duration(days: 365 * 18)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().subtract(
                      const Duration(days: 365 * 13),
                    ),
                  );
                  if (date != null) {
                    setState(() => _birthDate = date);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
