import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'United States';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
    {'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano'},
    {'code': 'pt', 'name': 'Portuguese', 'nativeName': 'Português'},
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語'},
    {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
  ];

  final List<String> _regions = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'India',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Japan',
    'South Korea',
    'Brazil',
    'Mexico',
    'Argentina',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Display Language'),
        _buildLanguageSection(),
        const SizedBox(height: 32),
        _buildSectionHeader('Region'),
        _buildRegionSection(),
        const SizedBox(height: 32),
        _buildAdditionalSettings(),
        const SizedBox(height: 32),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      children: _languages.map((language) {
        final isSelected = language['name'] == _selectedLanguage;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.twitterBlue : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            title: Text(
              language['name']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              language['nativeName']!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            value: language['name']!,
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
            activeColor: AppTheme.twitterBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Region',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your region to see relevant trends and content.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _regions.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRegion = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Additional Settings'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto-translate tweets'),
                subtitle: const Text('Automatically translate tweets in other languages'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement auto-translate setting
                },
                activeColor: AppTheme.twitterBlue,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Show translation option'),
                subtitle: const Text('Show translate button for tweets in other languages'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement translation option setting
                },
                activeColor: AppTheme.twitterBlue,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveLanguageSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.twitterBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Save Language Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveLanguageSettings() async {
    try {
      // TODO: Implement API call to save language settings
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}