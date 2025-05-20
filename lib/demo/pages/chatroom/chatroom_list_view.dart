import 'package:chatroom_uikit/chatroom_uikit.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:test_uikit/demo/pages/chatroom/chatroom_page.dart';

class ChatRoomListView extends StatefulWidget {
  const ChatRoomListView({super.key});

  @override
  State<ChatRoomListView> createState() => _ChatRoomListViewState();
}

class _ChatRoomListViewState extends State<ChatRoomListView>
    with ChatUIKitThemeMixin {
  List<ChatRoom> list = [];
  ValueNotifier<bool> loading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch chat rooms from the server or local database
      fetchChatRooms();
    });
  }

  void fetchChatRooms() async {
    try {
      loading.value = true;
      PageResult<ChatRoom> result =
          await ChatRoomUIKit.instance.fetchPublicChatRoomsFromServer();
      List<String> roomIds = result.data.map((e) => e.roomId).toList();
      list.removeWhere((room) => roomIds.contains(room.roomId));
      list.addAll(result.data);
      loading.value = false;
    } catch (e) {
      loading.value = false;
    }
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return Scaffold(
      appBar: ChatUIKitAppBar(
        title: 'Room',
        titleTextStyle: TextStyle(
          color:
              theme.color.isDark
                  ? theme.color.primaryColor6
                  : theme.color.primaryColor5,
          fontSize: theme.font.titleLarge.fontSize,
          fontWeight: FontWeight.w900,
        ),
        showBackButton: false,
        centerTitle: true,
        trailingActions: [
          ChatUIKitAppBarAction(
            child: TextButton(
              onPressed: fetchChatRooms,
              child: Icon(Icons.more_sharp),
            ),
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: loading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return CircularProgressIndicator();
            }
            return ListView.separated(
              separatorBuilder: (context, index) => Divider(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final chatRoom = list[index];
                return ListTile(
                  title: Text(chatRoom.name ?? chatRoom.roomId),
                  onTap: () {
                    // Navigate to chat room details
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(chatRoom),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

//
