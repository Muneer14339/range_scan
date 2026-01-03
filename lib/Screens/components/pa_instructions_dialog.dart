import 'package:flutter/material.dart';
import '/Screens/components/nra_instruction_dialog.dart';

class LightingRequiredDialog extends StatelessWidget {
  final Function() onTap;
  const LightingRequiredDialog({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔽 scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DialogHeaderWidget(title: 'Lighting Required'),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white, thickness: 1),
                    const SizedBox(height: 10),

                    // Main description
                    const Text(
                      'Black & White targets need BRIGHT background for the center dot to detect properly.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // You MUST section
                    const Text(
                      '✓ You MUST:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildBulletPoint('Remove target from range hanger'),
                    buildBulletPoint('Hold against bright sky or light'),
                    buildBulletPoint('Photograph with brightness behind'),
                    const SizedBox(height: 20),

                    // Will NOT work section
                    const Text(
                      '✗ Will NOT work:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildBulletPoint('While hanging at shooting lane'),
                    buildBulletPoint('Against dark walls'),
                    buildBulletPoint('In dim/indoor lighting'),
                    const SizedBox(height: 16),

                    // Tip section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: Color(0xFFFFC107),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Tip: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Red & White targets work in ANY lighting condition!',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white, thickness: 1),
            const SizedBox(height: 12),
            ActionButton(title: 'Black & White', onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class NoBulletsForBlackWhiteDialog extends StatelessWidget {
  final VoidCallback? onRetake;
  final VoidCallback? onRetry;
  const NoBulletsForBlackWhiteDialog({super.key, this.onRetake, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogHeaderWidget(),
            const SizedBox(height: 16),

            const Divider(color: Colors.white30, thickness: 1),
            const SizedBox(height: 16),

            // Main message
            const Text(
              'Black center needs BRIGHT background to detect properly.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Try section
            const Text(
              'Try:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            buildBulletPoint('Remove from hanger'),
            buildBulletPoint('Use outdoor/bright lighting'),
            buildBulletPoint('Hold against bright surface'),
            const SizedBox(height: 20),

            // Retake Photo button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.image, size: 18),
                label: const Text(
                  'Retake Photo',
                  style: TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Divider(color: Colors.white30, thickness: 1),
            const SizedBox(height: 16),

            // Tip section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Tip: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                'Red & White targets work in any lighting condition',
                          ),
                        ],
                      ),
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
}

class NoBulletsForRedDialog extends StatefulWidget {
  final VoidCallback? onTap;
  final String? selectMode;
  const NoBulletsForRedDialog({super.key, this.onTap, this.selectMode});

  @override
  State<NoBulletsForRedDialog> createState() => _NoBulletsForRedDialogState();
}

class _NoBulletsForRedDialogState extends State<NoBulletsForRedDialog> {
  late String? _selectedMode = widget.selectMode;
  // bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogHeaderWidget(),
            const SizedBox(height: 16),

            const Divider(color: Colors.white30, thickness: 1),
            const SizedBox(height: 16),

            // Main message
            const Text(
              "Let's try a different detection mode based on your background:",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Bright Background Option
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = 'light';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _selectedMode == 'light'
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        _selectedMode == 'light'
                            ? Colors.white
                            : Colors.white54,
                    width: _selectedMode == 'light' ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          color: Color(0xFFFFC107),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bright Background',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(outdoor/well-lit)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    buildBulletPoint('Removed from hanger'),
                    buildBulletPoint('Sky behind target'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dark Background Option
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = 'dark';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _selectedMode == 'dark'
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        _selectedMode == 'dark' ? Colors.white : Colors.white54,
                    width: _selectedMode == 'dark' ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.nightlight_round,
                          color: Color(0xFF9E9E9E),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dark Background',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '(at shooting lane)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    buildBulletPoint('Hanging on range'),
                    buildBulletPoint('Wall behind target'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Divider(color: Colors.white30, thickness: 1),
            // const SizedBox(height: 16),

            // // Retake Photo button
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton.icon(
            //     onPressed: () => Navigator.of(context).pop(null),
            //     icon: const Icon(Icons.camera_alt, size: 18),
            //     label: const Text(
            //       'Retake Photo',
            //       style: TextStyle(fontSize: 14),
            //     ),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: Colors.white,
            //       side: const BorderSide(color: Colors.white54),
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 24,
            //         vertical: 12,
            //       ),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(4),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),

            // // Remember my choice checkbox
            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       _rememberChoice = !_rememberChoice;
            //     });
            //   },
            //   child: Row(
            //     children: [
            //       SizedBox(
            //         width: 20,
            //         height: 20,
            //         child: Checkbox(
            //           value: _rememberChoice,
            //           onChanged: (value) {
            //             setState(() {
            //               _rememberChoice = value ?? false;
            //             });
            //           },
            //           side: const BorderSide(color: Colors.white54),
            //           fillColor: MaterialStateProperty.resolveWith((states) {
            //             if (states.contains(MaterialState.selected)) {
            //               return Colors.white;
            //             }
            //             return Colors.transparent;
            //           }),
            //           checkColor: Colors.black,
            //         ),
            //       ),
            //       const SizedBox(width: 10),
            //       const Text(
            //         'Remember my choice',
            //         style: TextStyle(color: Colors.white, fontSize: 14),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 16),
            ActionButton(
              onTap:
                  _selectedMode != null
                      ? () {
                        Navigator.of(context).pop({'mode': _selectedMode});
                      }
                      : null,
              title: 'Continue',
            ),

            // Continue button
          ],
        ),
      ),
    );
  }
}
