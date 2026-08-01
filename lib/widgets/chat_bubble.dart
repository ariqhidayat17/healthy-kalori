import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildApexAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(isUser, isDark),
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

  Widget _buildApexAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.kPrimaryGold.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryGold.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/apex_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.kDarkSurface,
              child: const Center(
                child: Text('🧙‍♂️', style: TextStyle(fontSize: 18)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.kPrimaryOrange.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.kPrimaryOrange.withOpacity(0.5), width: 2),
      ),
      child: const Center(
        child: Text('⚔️', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildBubble(bool isUser, bool isDark) {
    final bgColor = isUser
        ? AppColors.kPrimaryOrange.withOpacity(0.12)
        : (isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest);
    final borderColor = isUser
        ? AppColors.kPrimaryOrange.withOpacity(0.4)
        : AppColors.kPrimaryGold.withOpacity(0.3);
    final senderLabel = isUser ? 'Adventurer' : 'Apex, Wise Trainer';
    final senderIcon = isUser ? '⚔️' : '🧙‍♂️';
    final labelColor = isUser
        ? AppColors.kPrimaryOrange
        : (isDark ? AppColors.kPrimaryGold : AppColors.stPrimary);

    final textColor = isDark ? Colors.white.withOpacity(0.92) : AppColors.stOnSurface;
    final subTextColor = isDark ? Colors.white70 : AppColors.stOnSurfaceVariant;
    final boldColor = isDark ? AppColors.kPrimaryGold : AppColors.stPrimary;
    final headerColor = isDark ? Colors.white : AppColors.stOnSurface;
    final bulletColor = isDark ? AppColors.kPrimaryGold : AppColors.stPrimary;
    final timeColor = isDark ? Colors.white38 : AppColors.stOnSurfaceVariant.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: (isUser ? AppColors.kPrimaryOrange : AppColors.kPrimaryGold)
                .withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // RPG-style sender header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$senderIcon $senderLabel',
                  style: GoogleFonts.plusJakartaSans(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (time != null)
                  Text(
                    time!,
                    style: GoogleFonts.plusJakartaSans(
                      color: timeColor,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          // Message content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: isUser
                ? Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  )
                : MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.plusJakartaSans(
                        color: textColor,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      strong: GoogleFonts.plusJakartaSans(
                        color: boldColor,
                        fontWeight: FontWeight.bold,
                      ),
                      em: GoogleFonts.plusJakartaSans(
                        fontStyle: FontStyle.italic,
                        color: subTextColor,
                      ),
                      listBullet: GoogleFonts.plusJakartaSans(
                        color: bulletColor,
                      ),
                      h1: GoogleFonts.plusJakartaSans(
                          color: headerColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      h2: GoogleFonts.plusJakartaSans(
                          color: headerColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                      h3: GoogleFonts.plusJakartaSans(
                          color: headerColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}