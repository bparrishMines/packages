// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';

import 'video_displayer.dart';

/// Example widget displaying an Ad before a video.
class VideoAdExampleScreen extends StatefulWidget {
  /// Constructs an [VideoAdExampleScreen].
  const VideoAdExampleScreen({
    super.key,
    required this.adType,
    required this.adTagUrl,
    this.enablePreloading = true,
  });

  /// The URL from which ads will be requested.
  final String adTagUrl;

  /// Allows the player to preload the ad at any point before
  /// [AdsManager.start].
  final bool enablePreloading;

  /// The type of ads that will be requested.
  final String adType;

  @override
  State<VideoAdExampleScreen> createState() => _VideoAdExampleScreenState();
}

class _VideoAdExampleScreenState extends State<VideoAdExampleScreen> {
  // Model for showing a video with interleaved ads.
  late final VideoDisplayerModel _videoDisplayerModel = VideoDisplayerModel(
    adTagUrl: widget.adTagUrl,
    enablePreloading: widget.enablePreloading,
  );

  // Key for VideoDisplayer a new unique value to force disposal and recreation.
  var _platformViewKey = const ValueKey<int>(0);

  @override
  void initState() {
    super.initState();
    // Adds model as an observer for `AppLifecycleState` changes.
    WidgetsBinding.instance.addObserver(_videoDisplayerModel);
    _videoDisplayerModel.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _videoDisplayerModel.dispose();
  }

  Future<void> openFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: VideoDisplayer(model: _videoDisplayerModel),
          );
        },
        fullscreenDialog: true,
      ),
    );

    if (mounted) {
      setState(() {
        // Change the key to a new unique value to force disposal and rebuilding.
        _platformViewKey = ValueKey(_platformViewKey.value + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMA Test App'),
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Open Fullscreen',
            onPressed: openFullscreen,
          ),
        ],
      ),
      body: Center(
        child: Column(
          spacing: 80,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.adType,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(
              width: 300,
              child: !_videoDisplayerModel.isInitialized
                  ? Container()
                  : VideoDisplayer(
                      key: _platformViewKey,
                      model: _videoDisplayerModel,
                    ),
            ),
            ColoredBox(
              color: Colors.green,
              child: SizedBox(
                width: 300,
                height: 250,
                child: _videoDisplayerModel.companionAd.buildWidget(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _videoDisplayerModel.isInitialized
          ? FloatingActionButton(
              onPressed: () {
                _videoDisplayerModel.contentVideoIsPlaying ||
                        _videoDisplayerModel.adIsPlaying
                    ? _videoDisplayerModel.pause()
                    : _videoDisplayerModel.play();
              },
              child: Icon(
                _videoDisplayerModel.contentVideoIsPlaying ||
                        _videoDisplayerModel.adIsPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
