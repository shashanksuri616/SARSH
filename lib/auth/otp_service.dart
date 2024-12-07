import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:email_otp/email_otp.dart';

class OTPService {
  // Securely store your credentials - consider using environment variables or secure storage.
  final String _accountSID = 'AC7b61d612b4f774e030b38f72f460f0ff';
  final String _authToken = 'dace4836ffec209181a88c188911bc1b';
  final String _serviceID = 'VAd567c26ed4a30b7dfcc9bf340bcba5ac';


  // Send OTP via Twilio for phone
  Future<void> sendPhoneOTP(String phoneNumber) async {
    final url = Uri.parse('https://verify.twilio.com/v2/Services/$_serviceID/Verifications');
    final response = await http.post(url, headers: {
      'Authorization': 'Basic ' + base64Encode(utf8.encode('$_accountSID:$_authToken')),
    }, body: {
      'To': '+91${phoneNumber}',
      'Channel': 'sms',
    });

    if (response.statusCode != 201) {
      throw Exception('Failed to send phone OTP');
    }
  }



  // Verify OTP for phone using Twilio
  Future<void> verifyPhoneOTP(String phoneNumber, String otp) async {
    final url = Uri.parse('https://verify.twilio.com/v2/Services/$_serviceID/VerificationCheck');
    final response = await http.post(url, headers: {
      'Authorization': 'Basic ' + base64Encode(utf8.encode('$_accountSID:$_authToken')),
    }, body: {
      'To': '+91${phoneNumber}',
      'Code': otp,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to verify phone OTP');
    }
  }


  Future<void> sendEmailOTP(String email) async {
    EmailOTP.config(
      appName: 'GenAi Remote Sensing',
      otpType: OTPType.numeric,
      expiry : 30000,
      emailTheme: EmailTheme.v5,
      appEmail: 'Remote Sense',
      otpLength: 6,
    );
  await EmailOTP.sendOTP(email: email);
  }

  Future<bool> verifyEmailOTP(String otp) async {
  return EmailOTP.verifyOTP(otp: otp);
  }
  }

