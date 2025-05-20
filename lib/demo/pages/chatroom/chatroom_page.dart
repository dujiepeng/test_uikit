import 'dart:convert';

import 'package:chatroom_uikit/chatroom_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_uikit/demo/pages/chatroom/chatroom_user_data.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage(this.room, {super.key});
  final ChatRoom room;
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with ChatUIKitThemeMixin {
  ChatRoomInputBarController inputBarController = ChatRoomInputBarController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setup();
    });
  }

  void setup() async {
    try {
      await ChatRoomUIKit.instance.joinChatRoom(roomId: widget.room.roomId);
      debugPrint('join chat room success');
    } catch (e) {
      debugPrint('join chat room error: $e');
    }
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    Widget content = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                clipBehavior: Clip.hardEdge,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                ),
                builder: (ctx) {
                  return ChatRoomUIKitMembersView(
                    roomId: widget.room.roomId,
                    ownerId: widget.room.owner ?? '',
                    controllers: [
                      ChatRoomUIKitMembersController('成员列表'),
                      ChatRoomUIKitMutesController('禁言列表'),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.card_membership),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              inputBarController.hiddenInputBar();
            },
            child: Container(color: Colors.green),
          ),
          Positioned(
            top: MediaQuery.of(context).viewInsets.top + 10,
            left: 0,
            right: 0,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20, child: ChatRoomGlobalMessageView()),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            height: 84,
            bottom: 300,
            child: ChatRoomShowGiftView(roomId: widget.room.roomId),
          ),
          Positioned(
            left: 16,
            right: 78,
            height: 204,
            bottom: 90,
            child: ChatRoomMessagesView(roomId: widget.room.roomId),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: ChatRoomInputBar(
                controller: inputBarController,
                onSend: (msg) {
                  if (msg.trim().isEmpty) {
                    return;
                  }
                  ChatRoomUIKit.instance.sendMessage(
                    message: ChatRoomMessage.roomMessage(
                      widget.room.roomId,
                      msg,
                    ),
                  );
                },
                actions: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        clipBehavior: Clip.hardEdge,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        builder: (ctx) {
                          return FutureBuilder(
                            future: rootBundle.loadString('assets/Gifts.json'),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                Map<String, dynamic> map = json.decode(
                                  snapshot.data!,
                                );
                                List<ChatroomGiftPageController> controllers =
                                    [];
                                for (var element in map.keys.toList()) {
                                  final controller = ChatroomGiftPageController(
                                    title: element,
                                    gifts: () {
                                      List<ChatRoomGift> list = [];
                                      map[element].forEach((element) {
                                        ChatRoomGift gift =
                                            ChatRoomGift.fromJson(element);
                                        list.add(gift);
                                      });
                                      return list;
                                    }(),
                                  );
                                  controllers.add(controller);
                                }
                                return ChatRoomGiftsView(
                                  giftControllers: controllers,
                                  onSendTap: (gift) {
                                    ChatRoomUIKit.instance.sendMessage(
                                      message: ChatRoomMessage.giftMessage(
                                        widget.room.roomId,
                                        gift,
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Container();
                              }
                            },
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Image.asset('assets/room/send_gift.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    content = PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        ChatRoomUIKit.instance
            .leaveChatRoom(widget.room.roomId)
            .then((_) {
              debugPrint('leave chat room');
            })
            .catchError((e) {
              debugPrint('leave chat room error: $e');
            });
      },
      child: content,
    );

    content = ChatRoomUserData(child: content);

    return content;
  }
}
