import 'dart:convert';

import 'package:chatroom_uikit/chatroom_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage(this.room, {super.key});

  final ChatRoom room;
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  ChatRoomInputBarController inputBarController = ChatRoomInputBarController();
  // 发送礼物列表 使用
  List<ChatroomGiftPageController> controllers = [];
  String get roomId => widget.room.roomId;
  @override
  void initState() {
    super.initState();
    analysisGiftList();
    setup();
  }

  void setup() async {
    // 先获取自己的信息，之后再加入聊天室
    await setupMyInfo();
    joinChatRoom();
  }

  // 加入聊天室
  void joinChatRoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatRoomUIKit.instance
          .joinChatRoom(roomId: roomId)
          .then((_) {
            debugPrint('join chat room');
          })
          .catchError((e) {
            debugPrint('join chat room error: $e');
          });
    });
  }

  // 解析礼物列表
  Future<void> analysisGiftList() async {
    String giftJson = await rootBundle.loadString('data/Gifts.json');
    Map<String, dynamic> map = json.decode(giftJson);
    for (var element in map.keys.toList()) {
      final controller = ChatroomGiftPageController(
        title: element,
        gifts: () {
          List<ChatRoomGift> list = [];
          map[element].forEach((element) {
            ChatRoomGift gift = ChatRoomGift.fromJson(element);
            list.add(gift);
          });
          return list;
        }(),
      );
      controllers.add(controller);
    }
  }

  // 设置自己在聊天室中的信息
  Future<void> setupMyInfo() async {
    ChatUIKitProfile profile = ChatRoomUserInfo.createUserProfile(
      userId: ChatRoomUIKit.instance.currentUserId!,
      nickname: '在 ${widget.room.name ?? roomId} 中的昵称',
    );
    ChatUIKitProvider.instance.addProfiles([profile], roomId);
  }

  // 更新自己在聊天室中的信息
  Future<void> updateMyInfo() async {
    ChatUIKitProfile profile = ChatRoomUserInfo.createUserProfile(
      userId: ChatRoomUIKit.instance.currentUserId!,
      nickname: '更新昵称',
    );
    ChatUIKitProvider.instance.addProfiles([profile], roomId);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(onPressed: updateMyInfo, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () {
              chatroomShowMembersView(
                context,
                roomId: roomId,
                ownerId: widget.room.owner!,
                membersControllers: [
                  ChatRoomUIKitMembersController('成员列表'),
                  ChatRoomUIKitMutesController('禁言列表'),
                ],
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
            child: ChatRoomShowGiftView(roomId: roomId),
          ),
          Positioned(
            left: 16,
            right: 78,
            height: 204,
            bottom: 90,
            child: ChatRoomMessagesView(roomId: roomId),
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
                    message: ChatRoomMessage.roomMessage(roomId, msg),
                  );
                },
                actions: [
                  InkWell(
                    onTap: () async {
                      ChatRoomGift? gift = await chatroomShowGiftsView(
                        context,
                        giftControllers: controllers,
                      );
                      if (gift != null) {
                        ChatRoomUIKit.instance.sendMessage(
                          message: ChatRoomMessage.giftMessage(roomId, gift),
                        );
                      }
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
            .leaveChatRoom(roomId)
            .then((_) {
              debugPrint('leave chat room');
            })
            .catchError((e) {
              debugPrint('leave chat room error: $e');
            });
      },
      child: content,
    );

    return content;
  }
}
