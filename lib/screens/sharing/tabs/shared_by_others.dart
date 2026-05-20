// CVs shared with the user by others.
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

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart' hide normalLoadingScreenHeight;

import 'package:cvpod/screens/sharing/sharing_tabs.dart';
import 'package:cvpod/utils/cv_manager.dart';
import 'package:cvpod/constants/app.dart';

class SharedByOthers extends StatelessWidget {
  final String webId;
  final CvManager cvManager;

  const SharedByOthers({
    super.key,
    required this.webId,
    required this.cvManager,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sharedResources(null, null),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingScreen(normalLoadingScreenHeight);
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading shared CVs: ${snapshot.error}'),
          );
        }

        final sharedResMap = (snapshot.data as Map?) ?? {};

        if (sharedResMap.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No CVs have been shared with you yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                largeHeightGap,
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CVs Shared with You by Others',
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
                  sharedResMap,
                  SharingTabs(webId: webId, cvManager: cvManager),
                ),
                largeHeightGap,
              ],
            ),
          ),
        );
      },
    );
  }
}
