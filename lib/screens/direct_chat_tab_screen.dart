import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/native_ad_widget.dart';

class DirectChatTabScreen extends StatefulWidget {
  final VoidCallback onShareApp;
  final VoidCallback onSendFeedback;
  final bool showBackButton;

  const DirectChatTabScreen({
    super.key,
    required this.onShareApp,
    required this.onSendFeedback,
    this.showBackButton = false,
  });

  @override
  State<DirectChatTabScreen> createState() => _DirectChatTabScreenState();
}

class _DirectChatTabScreenState extends State<DirectChatTabScreen> {
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _countryIndex = 0;
  bool _opening = false;

  static const List<Map<String, String>> _countryCodes = [
    {'name': 'Pakistan', 'code': '92', 'flag': '🇵🇰'},
    {'name': 'India', 'code': '91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '44', 'flag': '🇬🇧'},
    {'name': 'UAE', 'code': '971', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'code': '966', 'flag': '🇸🇦'},
    {'name': 'Bangladesh', 'code': '880', 'flag': '🇧🇩'},
    {'name': 'Indonesia', 'code': '62', 'flag': '🇮🇩'},
    {'name': 'Turkey', 'code': '90', 'flag': '🇹🇷'},
    {'name': 'Egypt', 'code': '20', 'flag': '🇪🇬'},
    {'name': 'Nigeria', 'code': '234', 'flag': '🇳🇬'},
    {'name': 'Brazil', 'code': '55', 'flag': '🇧🇷'},
    {'name': 'Germany', 'code': '49', 'flag': '🇩🇪'},
    {'name': 'Canada', 'code': '1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '61', 'flag': '🇦🇺'},
  ];

  String get _countryCode => _countryCodes[_countryIndex]['code']!;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _digitsOnlyPhone {
    return _phoneController.text.replaceAll(RegExp(r'\D'), '');
  }

  String get _fullNumber {
    var phone = _digitsOnlyPhone;
    // Drop leading 0 (common local format).
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return '$_countryCode$phone';
  }

  Future<void> _openChat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _opening = true);

    final number = _fullNumber;
    final message = _messageController.text.trim();

    // Click-to-chat URL — no contact save required.
    final uri = Uri.parse(
      message.isEmpty
          ? 'https://wa.me/$number'
          : 'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the chat app. Please install it and try again.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the chat app. Please install it and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _pickCountryCode() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select country code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _countryCodes.length,
                    itemBuilder: (context, index) {
                      final item = _countryCodes[index];
                      final isSelected = index == _countryIndex;
                      return ListTile(
                        leading: Text(
                          item['flag']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(item['name']!),
                        trailing: Text(
                          '+${item['code']}',
                          style: TextStyle(
                            color: AppConstants.primaryGreen,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _countryIndex = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _countryCodes[_countryIndex];

    return Scaffold(
      appBar: AppAppBar(
        title: 'Direct Chat',
        showBackButton: widget.showBackButton,
        onShareApp: widget.onShareApp,
        onSendFeedback: widget.onSendFeedback,
      ),
      bottomNavigationBar: const NativeAdWidget(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat, color: AppConstants.primaryGreen, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start a chat without saving the number to your contacts.',
                        style: TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Phone number',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _pickCountryCode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(selectedCountry['flag']!,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '+$_countryCode',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) {
                          return 'Enter a phone number';
                        }
                        if (digits.length < 7) {
                          return 'Number is too short';
                        }
                        if (digits.length > 15) {
                          return 'Number is too long';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Message (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Type a message to send…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _opening ? null : _openChat,
                icon: _opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat),
                label: Text(_opening ? 'Opening…' : 'Open Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Note: This app cannot check if a number is registered. '
                'If the number is not available, the chat app will show its own message.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
