import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with ChatUIKitThemeMixin, MessageObserver {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return ConversationsView();
  }
}
