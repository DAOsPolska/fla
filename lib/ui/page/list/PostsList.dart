import 'package:core/api/Api.dart';
import 'package:core/api/data.dart';
import 'package:core/api/decoder/discussions.dart';
import 'package:core/api/decoder/tags.dart';
import 'package:core/api/decoder/users.dart';
import 'package:core/generated/l10n.dart';
import 'package:core/ui/html/html.dart';
import 'package:core/util/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../widgets.dart';

class PostsList extends StatefulWidget {
  final InitData initData;
  final DiscussionInfo discussionInfo;

  PostsList(this.initData, this.discussionInfo);

  @override
  _PostsListState createState() => _PostsListState();
}

class _PostsListState extends State<PostsList> {
  DiscussionInfo discussionInfo;
  int count = 0;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return discussionInfo != null
        ? Center(
            child: Center(
              child: ListView.builder(
                  itemCount: count + 1,
                  itemBuilder: (BuildContext context, int index) {
                    index = index - 1;
                    if (index == -1) {
                      Color backGroundColor;
                      if (widget.discussionInfo.tags == null ||
                          widget.discussionInfo.tags.length == 0) {
                        backGroundColor = Theme.of(context).primaryColor;
                      } else {
                        for (var t in widget.discussionInfo.tags) {
                          if (!t.isChild) {
                            backGroundColor =
                                backGroundColor = HexColor.fromHex(t.color);
                            break;
                          }
                        }
                        if (backGroundColor == null) {
                          backGroundColor = Theme.of(context).primaryColor;
                        }
                      }
                      Color textColor =
                          ColorUtil.getTitleFormBackGround(backGroundColor);
                      return Container(
                        height: 120,
                        color: backGroundColor,
                        child: Center(
                          child: ListTile(
                            title: Text(
                              discussionInfo.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(color: textColor, fontSize: 20),
                            ),
                            subtitle: SizedBox(
                              height: 48,
                              child: Center(
                                child: makeMiniCards(
                                    context,
                                    widget.discussionInfo.tags,
                                    widget.initData),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    var card;
                    var p =
                        discussionInfo.posts[discussionInfo.postsIdList[index]];
                    switch (p.contentType) {
                      case "comment":
                        card = Card(
                            elevation: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: Text(
                                      discussionInfo.users[p.user].displayName),
                                  leading: Avatar(discussionInfo.users[p.user],
                                      Theme.of(context).primaryColor),
                                  subtitle: Text(p.createdAt),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 15, right: 15, bottom: 15),
                                  child: HtmlView(
                                    p.contentHtml,
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 40, bottom: 10, right: 40),
                                        child: IconButton(
                                            icon: FaIcon(
                                              FontAwesomeIcons.thumbsUp,
                                              size: 18,
                                            ),
                                            onPressed: () {}),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 40, bottom: 10, right: 40),
                                        child: IconButton(
                                            icon: FaIcon(
                                                FontAwesomeIcons.commentAlt,
                                                size: 18),
                                            onPressed: () {}),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 40, bottom: 10, right: 40),
                                        child: IconButton(
                                            icon: FaIcon(Icons.more_horiz,
                                                size: 18),
                                            onPressed: () {}),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ));
                        break;
                      case "discussionStickied":
                        var sticky =
                            p.source["attributes"]["content"]["sticky"];
                        UserInfo u = discussionInfo.users[int.parse(
                            p.source["relationships"]["user"]["data"]["id"])];
                        Color textColor = Color.fromARGB(255, 209, 62, 50);
                        card = makeMessageCard(
                            textColor,
                            FontAwesomeIcons.thumbtack,
                            u.displayName,
                            sticky
                                ? S.of(context).c_stickied_the_discussion
                                : S.of(context).c_unstickied_the_discussion);
                        break;
                      case "discussionLocked":
                        var locked =
                            p.source["attributes"]["content"]["locked"];
                        UserInfo u = discussionInfo.users[int.parse(
                            p.source["relationships"]["user"]["data"]["id"])];
                        Color textColor = Color.fromARGB(255, 136, 136, 136);
                        card = makeMessageCard(
                            textColor,
                            FontAwesomeIcons.lock,
                            u.displayName,
                            locked
                                ? S.of(context).c_locked_the_discussion
                                : S.of(context).c_unlocked_the_discussion);
                        break;
                      case "discussionTagged":
                        List before = p.source["attributes"]["content"][0];
                        List after = p.source["attributes"]["content"][1];
                        UserInfo u = discussionInfo.users[int.parse(
                            p.source["relationships"]["user"]["data"]["id"])];
                        List<TagInfo> removed = [];
                        List<TagInfo> added = [];

                        before.forEach((id) {
                          if (!after.contains(id)) {
                            removed.add(Api.getTag(id));
                          }
                        });
                        after.forEach((id) {
                          if (!before.contains(id)) {
                            added.add(Api.getTag(id));
                          }
                        });

                        card = makeTaggedCard(
                            context, u.displayName, added, removed);
                        break;
                      default:
                        print("UnimplementedTypes:" + p.contentType);
                        card = Card(
                          child: Text("UnimplementedTypes:" + p.contentType),
                        );
                    }
                    return Padding(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 6),
                      child: card,
                    );
                  }),
            ),
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget makeMessageCard(
      Color textColor, IconData icon, String userName, String text) {
    return Card(
        child: Padding(
      padding: EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
      child: RichText(
          text: TextSpan(children: [
        WidgetSpan(
            child: FaIcon(
          icon,
          color: textColor,
          size: 18,
        )),
        WidgetSpan(child: Padding(padding: EdgeInsets.only(right: 10))),
        WidgetSpan(
            child: InkWell(
          child: Text(
            userName,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
          ),
          onTap: () {},
        )),
        TextSpan(
          text: " ",
          style: TextStyle(fontSize: 18),
        ),
        TextSpan(
          text: text,
          style: TextStyle(fontSize: 18, color: textColor),
        )
      ])),
    ));
  }

  Widget makeTaggedCard(BuildContext context, String userName,
      List<TagInfo> added, List<TagInfo> removed) {
    Color textColor = Color.fromARGB(255, 102, 125, 153);
    InlineSpan centerWidget = WidgetSpan(child: SizedBox());
    if (added.length != 0 && removed.length != 0) {
      centerWidget = TextSpan(
          text: S.of(context).c_tag_and,
          style: TextStyle(color: textColor, fontSize: 18));
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
        child: RichText(
            text: TextSpan(children: [
          WidgetSpan(
              child: FaIcon(
            FontAwesomeIcons.tag,
            color: textColor,
            size: 18,
          )),
          WidgetSpan(child: Padding(padding: EdgeInsets.only(right: 10))),
          WidgetSpan(
              child: InkWell(
            child: Text(
              userName,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
            ),
            onTap: () {},
          )),
          TextSpan(
            text: " ",
            style: TextStyle(fontSize: 18),
          ),
          added.length != 0
              ? TextSpan(
                  text: S.of(context).c_tag_added,
                  style: TextStyle(color: textColor, fontSize: 18))
              : WidgetSpan(child: SizedBox()),
          WidgetSpan(child: makeMiniTagCards(context, added, widget.initData)),
          centerWidget,
          removed.length != 0
              ? TextSpan(
                  text: S.of(context).c_tag_removed,
                  style: TextStyle(color: textColor, fontSize: 18))
              : WidgetSpan(child: SizedBox()),
          WidgetSpan(
              child: makeMiniTagCards(context, removed, widget.initData)),
        ])),
      ),
    );
  }

  Widget makeMiniTagCards(
      BuildContext context, List<TagInfo> tags, InitData initData) {
    List<Widget> cards = [];
    tags.forEach((t) {
      Color backGroundColor = HexColor.fromHex(t.color);
      Color textColor = ColorUtil.getTitleFormBackGround(backGroundColor);
      cards.add(Padding(
        padding: EdgeInsets.only(left: 5),
        child: Container(
          color: backGroundColor,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 2, right: 2),
              child: Text(
                t.name,
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ),
      ));
    });
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: cards,
      ),
    );
  }

  loadData() async {
    var d = await Api.getDiscussion(widget.discussionInfo.id);
    setState(() {
      if (d.posts.length >= 20) {
        count = 20;
      } else {
        count = d.posts.length;
      }
      discussionInfo = d;
    });
  }
}
