// CVs shared by the user.
//
// Copyright (C) 2024 Software Innovation Institute, Australian National University
//
// License: GNU General Public License, Version 3 (the "License")
// https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Authors: Anushka Vidanage

import 'dart:io';

import 'package:cvpod/constants/colors.dart';
import 'package:cvpod/screens/nav/nav_screen.dart';
import 'package:cvpod/screens/sharing/sharing_tabs.dart';
import 'package:cvpod/widgets/shared_cvs_table.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' hide buildSharedResourcesTable;

import 'package:cvpod/apis/rest_api.dart';
import 'package:cvpod/utils/cv_manager.dart';
import 'package:cvpod/constants/app.dart';
import 'package:universal_html/html.dart' as html;

class SharedByUser extends StatefulWidget {
  final String webId;
  final CvManager cvManager;
  final Map sharedResMap;

  const SharedByUser({
    super.key,
    required this.webId,
    required this.cvManager,
    required this.sharedResMap,
  });

  @override
  SharedByUserState createState() => SharedByUserState();
}

class SharedByUserState extends State<SharedByUser>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  // Function to download the pdf to the local storage
  Widget _downloadPdfButton(Uint8List pdfData, String fileName) {
    return IconButton(
      icon: const Icon(
        Icons.download,
        size: 24.0,
        color: appDarkBlue1,
      ),
      onPressed: () async {
        if (kIsWeb) {
          String customFileName = '';

          final blob = html.Blob([pdfData]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute(
                'download', customFileName.isEmpty ? fileName : customFileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
          // file_picker writes the bytes itself and returns the URI it
          // wrote them to.

          final Uri? savedUri = await FilePicker.saveFile(
            type: FileType.custom,
            fileName: fileName,
            allowedExtensions: ['pdf'],
            bytes: pdfData,
          );

          if (savedUri != null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File downloaded successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No file selected')),
            );
          }
        } else if (Platform.isAndroid || Platform.isIOS) {
          String customFileName = '';

          String? selectedDirectory = await FilePicker.getDirectoryPath();

          if (selectedDirectory != null) {
            final file = File(
                '$selectedDirectory/${customFileName.isEmpty ? "consent_form.pdf" : customFileName}');
            await file.writeAsBytes(pdfData).then((value) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File downloaded successfully')),
              );
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No directory selected')),
            );
          }
        }
      },
    );
  }

  /// Show a dialog listing the user's shared-cvs PDF files so they can pick
  /// one to grant permissions on.
  Future<void> _showPickCvDialog(BuildContext context) async {
    List<String> files;
    try {
      files = await getSharedCvFiles(widget.webId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load shared CVs: $e')),
      );
      return;
    }

    if (!context.mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No PDFs found in shared-cvs/. Generate and save a CV PDF first.',
          ),
        ),
      );
      return;
    }

    final String? chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select a CV to share'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (_, index) {
                final fileName = files[index];
                return ListTile(
                  leading:
                      const Icon(Icons.picture_as_pdf, color: appDarkBlue1),
                  title: Text(fileName),
                  onTap: () => Navigator.of(dialogContext).pop(fileName),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (chosen == null) return;
    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavScreen(
          webId: widget.webId,
          cvManager: widget.cvManager,
          childPage: GrantPermissionUi(
            backgroundColor: bgCardLight,
            resourceNames: ['shared-cvs/$chosen'],
            showAppBar: false,
            child: SharingTabs(
              webId: widget.webId,
              cvManager: widget.cvManager,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              largeHeightGap,
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CVs Shared by You',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              smallHeightGap,
              buildSharedResourcesTable(
                context,
                widget.sharedResMap,
                _downloadPdfButton,
                widget.webId,
                widget.cvManager,
                widget,
              ),
              largeHeightGap,
              ElevatedButton(
                onPressed: () => _showPickCvDialog(context),
                child: const Text('Create a new share'),
              ),
              smallHeightGap,
            ])));
  }
}
