import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import 'fantasy_card.dart';

enum ChatMessageType { user, apex }

class ChatBubble extends StatelessWidget {
  final String message;
  final ChatMessageType type;
  final String? time;
  final Widget? richContent;

  const ChatBubble({
    super.key,
    required this.message,
    required this.type,
    this.time,
    this.richContent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = type == ChatMessageType.user;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Apex',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.kPrimaryGold,
                      ),
                    ),
                  ),
                _buildMessageContainer(isUser),
                if (richContent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: richContent!,
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppColors.kGradientSunset,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryOrange.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Text('🧙‍♂️', style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.kBgCream,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Text('👤', style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildMessageContainer(bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.kPrimaryOrange : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 20),
        ),
        border: isUser ? null : Border(
          left: BorderSide(color: AppColors.kPrimaryGold, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 4),
            Text(
              time!,
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black38,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
