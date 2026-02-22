import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_blog_site/pages/posts/view_single_post.dart';
import 'package:flutter_blog_site/utils/comment_database_service.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ViewAllComments extends StatefulWidget {
  final String postId;
  final List<Map<String, dynamic>> allComments;
  final VoidCallback onChange;
  const ViewAllComments({
    super.key,
    required this.postId,
    required this.allComments,
    required this.onChange,
  });

  @override
  State<ViewAllComments> createState() => _ViewAllCommentsState();
}

class _ViewAllCommentsState extends State<ViewAllComments> {
  final SupabaseClient supabase = Supabase.instance.client;
  late final currentUser = supabase.auth.currentUser;
  final StorageServicePost _storageServicePost = StorageServicePost();
  final CommentDatabaseService _commentDatabaseService =
      CommentDatabaseService();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  List<String> images = [];
  String? _comment;
  bool _isEditing = false;
  String? _setEditingId;
  List<String> _imageDatabaseUrl = [];
  List<AssetEntity> _imageFileUpdate = [];
  List<Uint8List> _imageWebUpdate = [];
  final TextEditingController _updateCommentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future pickUpdateImagesMobile() async {
    final List<AssetEntity>? image = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 20,
        selectedAssets: _imageFileUpdate,
        requestType: RequestType.image,
      ),
    );
    if (image != null) {
      setState(() {
        _imageFileUpdate = image;
      });
    }
  }

  Future pickUpdateImagesWeb() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        if (kIsWeb) {
          List<Uint8List> webImages = [];
          for (var image in images) {
            final bytes = await image.readAsBytes();
            webImages.add(bytes);
          }
          setState(() {
            _imageWebUpdate.addAll(webImages);
          });
        }
      } else {}
    } catch (e) {
      print(e);
    }
  }

  Future setEditingIdFn(
    final String commentId,
    final String commentText,
    final List<String> commentImage,
  ) async {
    try {
      setState(() {
        _isEditing = true;
        _setEditingId = commentId;
        _updateCommentController.text = commentText;
        _imageDatabaseUrl = commentImage;
      });
    } catch (e) {
      print(e);
    }
  }

  Future deleteComment(final comment) async {
    if (comment == null) return;

    final String commentId = comment['id'];
    List<String> imageUrl = [];
    setState(() {
      if (comment['image'] != null && comment['image'].toString().isNotEmpty) {
        imageUrl = List<String>.from(jsonDecode(comment['image']));
      }
    });

    try {
      print(imageUrl);
      if (imageUrl.isNotEmpty) {
        await _storageServicePost.deleteListOfImageInComment(imageUrl);
      }
      await _commentDatabaseService.databaseDeleteSingleComment(commentId);
      widget.onChange();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successfully deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future deleteSingleImageInList(String url) async {
    try {
      await _storageServicePost.storageDeleteSingleImageInTheList(url);
      await _commentDatabaseService.deleteDatabaseSinleImageToList(
        url,
        _setEditingId!,
      );
      widget.onChange();
      setState(() {
        _imageDatabaseUrl.remove(url);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Image deleted')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future updateComment() async {
    final comment = _updateCommentController.text;
    try {
      if (comment.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('title and description are required!!')),
        );
        return;
      }
      if (_imageWebUpdate.isNotEmpty || _imageFileUpdate.isNotEmpty) {
        List<String> finalImageList = [];
        finalImageList.addAll(_imageDatabaseUrl);
        List<String> imagesUpdatePost = [];
        if (_imageFileUpdate.isNotEmpty) {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(assets: _imageFileUpdate);
        }
        if (_imageWebUpdate.isNotEmpty) {
          imagesUpdatePost = await _storageServicePost
              .storageUploadMultipleImages(bytesList: _imageWebUpdate);
        }
        finalImageList.addAll(imagesUpdatePost);
        await _commentDatabaseService.dataseUpdateCommentWithImage(
          finalImageList,
          comment,
          _setEditingId!,
        );
        setState(() {
          _imageDatabaseUrl = finalImageList;
          _imageFileUpdate = [];
          _imageWebUpdate = [];
        });
      } else {
        await _commentDatabaseService.databaseUpdateComments(
          comment,
          _setEditingId!,
        );
      }
      widget.onChange();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Updated Successfully')));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(children: [showAllComments()]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showAllComments() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.allComments.length,
      itemBuilder: (context, index) {
        final comment = widget.allComments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${comment['author'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    if (currentUser != null &&
                        comment['author'] ==
                            currentUser!.userMetadata?['name']) ...[
                      PopupMenuButton<int>(
                        offset: const Offset(0, 50),
                        icon: const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.more_vert),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 0, child: const Text('Edit')),
                          PopupMenuItem(value: 1, child: const Text('Delete')),
                        ],
                        onSelected: (value) async {
                          if (value == 0) {
                            if (comment['image'] != null &&
                                comment['image'].toString().isNotEmpty) {
                              images = List<String>.from(
                                jsonDecode(comment['image']),
                              );
                            }
                            setEditingIdFn(
                              comment['id'],
                              comment['comment'],
                              images,
                            );
                          }

                          if (value == 1) {
                            await deleteComment(comment);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                if (_setEditingId == comment['id']) ...[
                  showEditingForm(),
                ] else ...[
                  if (comment['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: displayImage(
                        List<String>.from(jsonDecode(comment['image'])),
                      ),
                    ),
                  SizedBox(height: 10),
                  Text(
                    '${comment['comment'] ?? ''} ',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget displayImage(final List<String> imageUrl) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imageUrl.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned(
              child: Image.network(imageUrl[index], fit: BoxFit.cover),
            ),
          ],
        );
      },
    );
  }

  Widget showEditingForm() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            showAllImages(),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _updateCommentController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'wow impressive',
                    ),
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        kIsWeb
                            ? pickUpdateImagesWeb()
                            : pickUpdateImagesMobile();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Icon(Icons.file_present_sharp, size: 40),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _setEditingId = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => updateComment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget showAllImages() {
    final totalCount =
        _imageDatabaseUrl.length +
        (kIsWeb ? _imageWebUpdate.length : _imageFileUpdate.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        /// 🔹 DATABASE IMAGES FIRST
        if (index < _imageDatabaseUrl.length) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  _imageDatabaseUrl[index],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () =>
                      deleteSingleImageInList(_imageDatabaseUrl[index]),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        /// 🔹 NEW FILE IMAGES
        final fileIndex = index - _imageDatabaseUrl.length;

        return Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? Image.memory(_imageWebUpdate[fileIndex], fit: BoxFit.cover)
                  : AssetEntityImage(
                      _imageFileUpdate[fileIndex],
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    kIsWeb
                        ? _imageWebUpdate.removeAt(fileIndex)
                        : _imageFileUpdate.removeAt(fileIndex);
                  });
                },
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
