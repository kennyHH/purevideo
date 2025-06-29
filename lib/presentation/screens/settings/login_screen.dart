import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_event.dart';
import 'package:purevideo/presentation/widgets/re_captcha.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final SupportedService service;

  const LoginScreen({super.key, required this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fieldValues = {};
  bool _hasRecaptcha = false;

  @override
  void initState() {
    super.initState();
    for (final fieldMap in widget.service.loginRequiredFields) {
      fieldMap.forEach((fieldName, inputType) {
        if (inputType != InputType.recaptcha) {
          _controllers[fieldName] = TextEditingController();
        } else {
          _hasRecaptcha = true;
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logowanie do ${widget.service.displayName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._buildFormFields(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _handleSubmit,
                child: const Text('Zaloguj'),
              ),
              if (widget.service.canBeAnonymous) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    context.read<AccountsBloc>().add(
                          SignInRequested(
                            service: widget.service,
                            fields: {'anonymous': 'true'},
                          ),
                        );
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                  child: const Text('Zaloguj jako gość'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    List<Widget> formFields = [];
    for (var fieldMap in widget.service.loginRequiredFields) {
      fieldMap.forEach((fieldName, inputType) {
        if (inputType == InputType.recaptcha) {
          formFields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GoogleReCaptcha(
                // TODO: Make siteKey and url dynamic if necessary per service
                siteKey:
                    '6LcQs24iAAAAALFibpEQwpQZiyhOCn-zdc-eFout', // Example for Filman
                url: 'https://filman.cc', // Example for Filman
                onToken: (token) {
                  setState(() {
                    _fieldValues[fieldName] = token;
                  });
                },
              ),
            ),
          );
        } else {
          formFields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _controllers[fieldName],
                decoration: InputDecoration(
                  labelText: fieldName
                      .replaceAllMapped(
                          RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
                      .replaceFirst(
                          fieldName[0],
                          fieldName[0]
                              .toUpperCase()), // Simple label generation
                  border: const OutlineInputBorder(),
                ),
                obscureText: inputType == InputType.password,
                keyboardType: inputType == InputType.text &&
                        (fieldName.toLowerCase().contains('email') ||
                            fieldName.toLowerCase().contains('login'))
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać $fieldName';
                  }
                  return null;
                },
                onSaved: (value) {
                  _fieldValues[fieldName] = value ?? '';
                },
              ),
            ),
          );
        }
      });
    }
    return formFields;
  }

  void _handleSubmit() {
    if (_hasRecaptcha &&
        (_fieldValues['g-recaptcha-response'] == null ||
            _fieldValues['g-recaptcha-response']!.isEmpty)) {
      getIt<ReCaptchaBloc>().add(const ReCaptchaShown());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę rozwiązać reCAPTCHA')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _controllers.forEach((key, controller) {
        _fieldValues[key] = controller.text;
      });

      context.read<AccountsBloc>().add(
            SignInRequested(
              service: widget.service,
              fields: Map.from(_fieldValues),
            ),
          );
      if (context.canPop()) {
        context.pop();
      }
    }
  }
}
