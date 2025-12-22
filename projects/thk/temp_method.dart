  Widget _buildVerificationCard(ThemeData theme, Size size) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final availableHeight = constraints.maxHeight - keyboardHeight;
            
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 40, 24, math.max(24, keyboardHeight + 16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight > 0 ? availableHeight - 80 : 400,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Email Verification',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    const TranslatedText(
                      'We have sent code to your email',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),

                    // Simple instruction text
                    const Text(
                      'Tip: Copy your entire latest email content for best OTP detection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 20),
                    
                    // Email display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2E7DFF)),
                          const SizedBox(width: 8),
                          Text(
                            _maskEmail(widget.email),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      
                    const SizedBox(height: 24),

                    // OTP Input
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => FocusScope.of(context).requestFocus(_otpFocusNode),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(6, (index) => _OtpBox(
                                controller: _otpController,
                                index: index,
                              )),
                            ),
                          ),
                          Opacity(
                            opacity: 0.01,
                            child: SizedBox(
                              height: 1,
                              child: TextFormField(
                                controller: _otpController,
                                focusNode: _otpFocusNode,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                autofocus: false,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  if (value.length == 6) {
                                     FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      
                    const SizedBox(height: 16),

                    // Email actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openEmailApp,
                            icon: const Icon(Icons.email_outlined, size: 18),
                            label: const Text('Check Email'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7DFF),
                              side: const BorderSide(color: Color(0xFF2E7DFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pasteFromClipboard,
                            icon: Icon(
                              _isClipboardMonitoring ? Icons.content_paste_search : Icons.content_paste,
                              size: 18,
                            ),
                            label: Text(_isClipboardMonitoring ? 'Monitoring...' : 'Paste Latest'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isClipboardMonitoring ? Colors.orange : const Color(0xFF2E7DFF),
                              side: BorderSide(
                                color: _isClipboardMonitoring ? Colors.orange : const Color(0xFF2E7DFF),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Resend section
                    Center(
                      child: _isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _canResend
                              ? TextButton(
                                  onPressed: _isSubmitting ? null : _resendOtp,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7DFF),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 18),
                                      SizedBox(width: 8),
                                      TranslatedText(
                                        'Resend OTP',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                      children: [
                                        const TextSpan(text: 'Resend available in '),
                                        TextSpan(
                                          text: _formatTime(_resendTimer),
                                          style: const TextStyle(
                                            color: Color(0xFF2E7DFF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),

                    const SizedBox(height: 20),

                    // Verify button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7DFF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2E7DFF).withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TranslatedText(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.verified_rounded, size: 18),
                              ],
                            ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }