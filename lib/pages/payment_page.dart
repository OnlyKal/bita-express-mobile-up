import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';

class PaymentPage extends StatefulWidget {
  final RideModel ride;

  const PaymentPage({super.key, required this.ride});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  // Paiement uniquement par Mobile Money
  String _selectedCurrency = 'CDF';
  String? _statusMessage;
  bool _isSuccess = false;

  // Opérateurs Mobile Money supportés
  final List<Map<String, dynamic>> _mobileOperators = [
    {
      'name': 'Orange Money',
      'icon': Icons.phone_android,
      'color': Colors.orange,
      'prefixes': ['081', '082', '083'],
    },
    {
      'name': 'M-Pesa (Vodacom)',
      'icon': Icons.phone_android,
      'color': Colors.red,
      'prefixes': ['084', '085', '089'],
    },
    {
      'name': 'Airtel Money',
      'icon': Icons.phone_android,
      'color': Colors.red[800]!,
      'prefixes': ['097', '098', '099'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    final userData = await SessionManager.getUserData();
    if (userData != null && userData['telephone'] != null) {
      setState(() {
        _phoneController.text = userData['telephone'];
      });
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }

    // Nettoyer le numéro
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Vérifier la longueur
    if (cleaned.length < 9) {
      return 'Numéro de téléphone trop court';
    }

    // Vérifier les préfixes valides pour la RDC
    bool isValidPrefix = false;
    for (var operator in _mobileOperators) {
      for (String prefix in operator['prefixes']) {
        if (cleaned.startsWith(prefix) || cleaned.startsWith('243$prefix')) {
          isValidPrefix = true;
          break;
        }
      }
      if (isValidPrefix) break;
    }

    if (!isValidPrefix) {
      return 'Numéro non supporté. Utilisez Orange, Vodacom ou Airtel';
    }

    return null;
  }

  Map<String, dynamic>? _getOperatorInfo(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    for (var operator in _mobileOperators) {
      for (String prefix in operator['prefixes']) {
        if (cleaned.startsWith(prefix) || cleaned.startsWith('243$prefix')) {
          return operator;
        }
      }
    }
    return null;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
      _isSuccess = false;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Convertir le prix en nombre
      double amount = double.parse(widget.ride.prixEstime);

      // Appeler le processus de paiement complet
      final response = await ApiService.processFlexPayPayment(
        token: token,
        courseId: widget.ride.id,
        phone: _phoneController.text,
        amount: amount,
        currency: _selectedCurrency,
        type: 1, // Mobile Money uniquement
      );

      setState(() {
        _isSuccess = response.success;
        _statusMessage = response.message;
      });

      if (response.success) {
        // Attendre 2 secondes puis retourner à la page précédente
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(
            context,
          ).pop(true); // Retourner true pour indiquer le succès
        }
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildPaymentTypeSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paiement Mobile Money',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Mobile Money',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyOption('CDF', 'Francs Congolais'),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildCurrencyOption('USD', 'Dollars US')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String name) {
    bool isSelected = _selectedCurrency == currency;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              currency,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    final operatorInfo = _getOperatorInfo(_phoneController.text);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              validator: _validatePhoneNumber,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: '243xxxxxxxxx',
                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                suffixIcon: operatorInfo != null
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: operatorInfo['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: operatorInfo['color'],
                            width: 1,
                          ),
                        ),
                        child: Text(
                          operatorInfo['name'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: operatorInfo['color'],
                          ),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            if (operatorInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: operatorInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      operatorInfo['icon'],
                      color: operatorInfo['color'],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Opérateur détecté: ${operatorInfo['name']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: operatorInfo['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 4,
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récapitulatif de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Course #${widget.ride.id}', ''),
            _buildSummaryRow('Passager', widget.ride.passagerName),
            _buildSummaryRow(
              'Distance',
              '${(widget.ride.distance / 1000).toStringAsFixed(1)} km',
            ),
            const Divider(height: 20),
            _buildSummaryRow(
              'Montant à payer',
              '${widget.ride.prixEstime} $_selectedCurrency',
              isTotal: true,
            ),
            _buildSummaryRow('Moyen', 'Mobile Money'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isProcessing ? 0 : 4,
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Traitement en cours...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Payer ${widget.ride.prixEstime} $_selectedCurrency',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: _isSuccess ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isSuccess ? Icons.check_circle : Icons.error,
              color: _isSuccess ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isSuccess ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
                child: const Icon(Icons.payment, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Paiement FlexPay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mobile Money sécurisé',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(),
              const SizedBox(height: 16),
              _buildPaymentTypeSelector(),
              const SizedBox(height: 16),
              _buildCurrencySelector(),
              const SizedBox(height: 16),
              _buildPhoneInput(),
              const SizedBox(height: 16),
              _buildStatusMessage(),
              const SizedBox(height: 24),
              _buildPayButton(),
              const SizedBox(height: 16),

              // Instructions
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Assurez-vous d\'avoir suffisamment de solde\n'
                        '• Gardez votre téléphone à portée de main\n'
                        '• Vous recevrez un code de confirmation\n'
                        '• Le paiement sera vérifié automatiquement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
