import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/services/media_service.dart';
import 'package:lockify/utils/colors.dart';
import 'package:lockify/utils/snackbar.dart';

class AddPollScreen extends StatefulWidget {
  final String? receiverPhone;
  final String? receiverName;
  final String? groupId;
  final String? groupName;
  final String? channelId;
  final String? channelName;

  const AddPollScreen({
    super.key,
    this.receiverPhone,
    this.receiverName,
    this.groupId,
    this.groupName,
    this.channelId,
    this.channelName,
  });

  @override
  State<AddPollScreen> createState() => _AddPollScreenState();
}

class _AddPollScreenState extends State<AddPollScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MediaService _mediaService = MediaService();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isSubmitting = false;

  bool get _isPrivateChat => widget.receiverPhone != null && widget.receiverPhone!.trim().isNotEmpty;
  bool get _isGroupChat => widget.groupId != null && widget.groupId!.trim().isNotEmpty;
  bool get _isChannelChat => widget.channelId != null && widget.channelId!.trim().isNotEmpty;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _destinationLabel {
    if (_isPrivateChat) {
      final name = widget.receiverName?.trim();
      return (name != null && name.isNotEmpty) ? name : 'chat';
    }
    if (_isGroupChat) {
      return widget.groupName?.trim().isNotEmpty == true ? widget.groupName!.trim() : 'group';
    }
    if (_isChannelChat) {
      return widget.channelName?.trim().isNotEmpty == true ? widget.channelName!.trim() : 'channel';
    }
    return 'conversation';
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    final controller = _optionControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  Future<void> _submitPoll() async {
    if (_isSubmitting) return;

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      AppSnackBar.warning(context, 'Enter a poll question.');
      return;
    }

    if (options.length < 2) {
      AppSnackBar.warning(context, 'Add at least two options.');
      return;
    }

    if (options.toSet().length != options.length) {
      AppSnackBar.warning(context, 'Poll options must be unique.');
      return;
    }

    if (!_isPrivateChat && !_isGroupChat && !_isChannelChat) {
      AppSnackBar.error(context, 'Missing conversation target for this poll.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final pollRef = _firestore.collection('polls').doc();
      final votes = <String, int>{for (final option in options) option: 0};

      await pollRef.set({
        'id': pollRef.id,
        'question': question,
        'options': options,
        'votes': votes,
        'votedUserIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (_isPrivateChat) {
        await _mediaService.sendMediaMessage(
          receiverPhone: widget.receiverPhone!,
          receiverName: widget.receiverName,
          file: null,
          type: MediaType.poll,
          pollId: pollRef.id,
          question: question,
        );
      } else if (_isGroupChat) {
        await _mediaService.sendGroupMediaMessage(
          groupId: widget.groupId!,
          file: null,
          type: MediaType.poll,
          pollId: pollRef.id,
          question: question,
        );
      } else if (_isChannelChat) {
        await _mediaService.sendChannelMediaMessage(
          channelId: widget.channelId!,
          file: null,
          type: MediaType.poll,
          pollId: pollRef.id,
          question: question,
        );
      }

      if (!mounted) return;
      AppSnackBar.success(context, 'Poll sent to $_destinationLabel.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed to create poll: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      backgroundColor: AppColors.backgroundGrey,
      title: 'Create Poll',
      body: Column(
        children: [
          if (_isSubmitting) const LinearProgressIndicator(color: AppColors.primaryPurple),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask $_destinationLabel a question',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'People can vote once. Add between 2 and 6 options.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    child: TextField(
                      controller: _questionController,
                      maxLength: 120,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        hintText: 'What should we decide?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_optionControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _optionControllers[index],
                                    maxLength: 60,
                                    decoration: InputDecoration(
                                      labelText: 'Option ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                if (_optionControllers.length > 2) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _isSubmitting ? null : () => _removeOption(index),
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                                    tooltip: 'Remove option',
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting || _optionControllers.length >= 6 ? null : _addOption,
                          icon: const Icon(Icons.add),
                          label: Text(
                            _optionControllers.length >= 6 ? 'Maximum options reached' : 'Add option',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPoll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isSubmitting ? 'Sending...' : 'Send poll'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
