import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_site/components/navbar.dart';
import 'package:flutter_blog_site/utils/post_database_service.dart';
import 'package:flutter_blog_site/utils/storage_service_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CreatePosts extends StatefulWidget {
  const CreatePosts({super.key});

  @override
  State<CreatePosts> createState() => _CreatePostsState();
}

class _CreatePostsState extends State<CreatePosts> {
  final StorageServicePost _storageServicePost = StorageServicePost();
  final PostDatabaseService _postDatabaseService = PostDatabaseService();
  bool _isPosting = false;
  String _postState = 'public';
  List<AssetEntity> _imageFiles = [];
  List<Uint8List> _imageFilesWeb = [];
  bool isLoading = true;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future pickImagesMobile() async {
    final List<AssetEntity>? image = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 20,
        selectedAssets: _imageFiles,
        requestType: RequestType.image,
      ),
    );
    if (image != null) {
      setState(() {
        _imageFiles = image;
      });
    }
  }

  Future pickImagesWeb() async {
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
            _imageFilesWeb.addAll(webImages);
          });
        }
      } else {}
    } catch (e) {
      print(e);
    }
  }

  // dart format off
  Future createPosts() async {
    if (_isPosting) return; 
    setState(() {_isPosting = true;});
    final public = _postState;
    final title = _titleController.text;
    final description = _descriptionController.text;
    try {
      List<String> imageUrls = [];
      if (title.trim().isEmpty || description.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Title and Description is required!!')),
        );
        return;
      }
      if (_imageFiles.isNotEmpty) {
        imageUrls = await _storageServicePost.storageUploadMultipleImages(assets: _imageFiles);
      } else if (_imageFilesWeb.isNotEmpty) {
        imageUrls = await _storageServicePost.storageUploadMultipleImages(bytesList: _imageFilesWeb,);
      } 
        await _postDatabaseService.databaseUploadPosts(public, imageUrls, title, description,);
      
      _titleController.clear();
      _descriptionController.clear();
      _imageFiles = [];
      _imageFilesWeb = [];
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Post Successfull')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RadioListTile<String>(
                            title: Text('public'),
                            value: 'public',
                            groupValue: _postState,
                            onChanged: (value) {
                              setState(() {
                                _postState = 'public';
                              });
                            },
                          ),

                          RadioListTile<String>(
                            title: Text('private'),
                            value: 'private',
                            groupValue: _postState,
                            onChanged: (value) {
                              setState(() {
                                _postState = 'private';
                              });
                            },
                          ),
                          Text(
                            'Image: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          if (_imageFilesWeb.isNotEmpty) ...[
                            showAllSelectedImagesWeb()
                    ] else if (_imageFiles.isNotEmpty) ...[
                            showAllSelectedImagesMobile()
                    ] else const Text('No image uploaded'),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: (){
                              if(kIsWeb){
                                pickImagesWeb();
                              }else{
                                pickImagesMobile();
                              }
                            },
                            child: Text('Choose Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Title: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Description: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: createPosts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showAllSelectedImagesWeb(){
    return GridView.builder( shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _imageFilesWeb.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.memory(
                _imageFilesWeb[index],
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _imageFilesWeb.removeAt(index);
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
                     
  }
  Widget showAllSelectedImagesMobile(){
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _imageFiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Positioned.fill(
                child: AssetEntityImage(
                  _imageFiles[index],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imageFiles.removeAt(index);
                    });
                  },
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      );
    
  }

}
