class Validators {
  static String? validateIndianMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    
    String digits = cleaned;
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return 'Mobile number must be exactly 10 digits';
    }
    
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    
    // Reject all identical repeating digits: 0000000000, 9999999999, etc.
    if (RegExp(r'^([0-9])\1{9}$').hasMatch(digits)) {
      return 'Please enter a genuine mobile number';
    }
    
    // Reject 7 or more consecutive identical digits: e.g. 9800000000
    if (RegExp(r'([0-9])\1{6,}').hasMatch(digits)) {
      return 'Please enter a genuine mobile number';
    }
    
    // Reject dummy ascending/descending/pattern sequences
    const dummySequences = [
      '1234567890',
      '0123456789',
      '9876543210',
      '8901234567',
      '0987654321',
      '1122334455',
      '9988776655',
    ];
    if (dummySequences.contains(digits)) {
      return 'Please enter a genuine mobile number';
    }
    
    return null;
  }
}
