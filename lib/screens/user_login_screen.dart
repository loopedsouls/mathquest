import 'package:flutter/material.dart';
import '../../../services/user_auth_service.dart';
import '../../../app_theme.dart';
import '../../../widgets/core_mixins_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with FormMixin, LoadingStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _errorMessage = null;
    });

    await executeWithLoadingAndError(() async {
      if (_isLogin) {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Login bem-sucedido
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _errorMessage = 'As senhas não coincidem.');
          return;
        }

        await _authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Registro bem-sucedido
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    }, 'Erro na autenticação');
  }

  bool _validateForm() {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Digite seu email.');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Digite sua senha.');
      return false;
    }
    if (!_isLogin && _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Confirme sua senha.');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Ícone
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calculate,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  const Text(
                    'MathQuest',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Entre na sua conta' : 'Crie sua conta',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Formulário
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Campo Email
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.black87),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.black87),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black87),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Campo Senha
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            labelStyle: const TextStyle(color: Colors.black87),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.black87),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black87),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54),
                            ),
                          ),
                          obscureText: true,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onSubmitted: (_) => _isLogin ? _submitForm() : null,
                        ),
                        const SizedBox(height: 16),

                        // Campo Confirmar Senha (apenas para registro)
                        if (!_isLogin) ...[
                          TextField(
                            controller: _confirmPasswordController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Confirmar Senha',
                              labelStyle:
                                  const TextStyle(color: Colors.black87),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.black87),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black87),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black54),
                              ),
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitForm(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mensagem de erro
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botão de submit
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isLogin ? 'Entrar' : 'Criar Conta'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Link para alternar entre login/registro
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Não tem conta? Criar conta'
                                : 'Já tem conta? Fazer login',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Link para resetar senha (apenas no login)
                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Digite seu email para receber instruções de reset de senha.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.black87),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black87),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite um email válido.')),
                );
                return;
              }

              try {
                await _authService
                    .sendPasswordResetEmail(emailController.text.trim());
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Email de reset enviado!')),
                      );
                    }
                  });
                }
              } catch (e) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: ${e.toString()}')),
                      );
                    }
                  });
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
