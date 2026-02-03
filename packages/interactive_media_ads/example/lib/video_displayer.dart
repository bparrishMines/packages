// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:video_player/video_player.dart';

/// Model used by the [VideoDisplayer] widget.
class VideoDisplayerModel extends ChangeNotifier with WidgetsBindingObserver {
  /// Constructs a [VideoDisplayerModel].
  VideoDisplayerModel({required this.adTagUrl, this.enablePreloading = true}) {
    _contentVideoController
      ..addListener(() {
        if (_contentVideoController.value.isCompleted) {
          _adsLoader.contentComplete();
          notifyListeners();
        }
      })
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        notifyListeners();
      });
  }

  // The AdsLoader instance exposes the request ads method.
  late final AdsLoader _adsLoader;

  // AdsManager exposes methods to control ad playback and listen to ad events.
  AdsManager? _adsManager;

  // Last state received in `didChangeAppLifecycleState`.
  AppLifecycleState _lastLifecycleState = AppLifecycleState.resumed;

  // Periodically updates the SDK of the current playback progress of the
  // content video.
  Timer? _contentProgressTimer;

  bool _adIsPlaying = false;

  // Provides the SDK with the current playback progress of the content video.
  // This is required to support mid-roll ads.
  final ContentProgressProvider _contentProgressProvider =
      ContentProgressProvider();

  final CompanionAdSlot companionAd = CompanionAdSlot(
    size: CompanionAdSlotSize.fixed(width: 300, height: 250),
    onClicked: () => debugPrint('Companion Ad Clicked'),
  );

  final _contentVideoController = VideoPlayerController.networkUrl(
    Uri.parse('https://storage.googleapis.com/gvabox/media/samples/stock.mp4'),
  );

  late final _adDisplayContainer = AdDisplayContainer(
    companionSlots: <CompanionAdSlot>[companionAd],
    onContainerAdded: (AdDisplayContainer container) {
      _adsLoader = AdsLoader(
        container: container,
        onAdsLoaded: (OnAdsLoadedData data) {
          debugPrint('OnAdsLoaded: (cuePoints: ${data.manager.adCuePoints})');
          final AdsManager manager = data.manager;
          _adsManager = data.manager;

          manager.setAdsManagerDelegate(
            AdsManagerDelegate(
              onAdEvent: (AdEvent event) {
                debugPrint('OnAdEvent: ${event.type} => ${event.adData}');
                switch (event.type) {
                  case AdEventType.loaded:
                    manager.start();
                  case AdEventType.contentPauseRequested:
                    _pauseContent();
                  case AdEventType.contentResumeRequested:
                    _resumeContent();
                  case AdEventType.allAdsCompleted:
                    manager.destroy();
                    _adsManager = null;
                  case AdEventType.started:
                    _adIsPlaying = true;
                    notifyListeners();
                  case AdEventType.paused:
                    _adIsPlaying = false;
                    notifyListeners();
                  case AdEventType.resumed:
                    _adIsPlaying = true;
                    notifyListeners();
                  case AdEventType.clicked:
                  case AdEventType.complete:
                  case _:
                }
              },
              onAdErrorEvent: (AdErrorEvent event) {
                debugPrint('AdErrorEvent: ${event.error.message}');
                _resumeContent();
              },
            ),
          );

          manager.init(
            settings: AdsRenderingSettings(enablePreloading: enablePreloading),
          );
        },
        onAdsLoadError: (AdsLoadErrorData data) {
          debugPrint('OnAdsLoadError: ${data.error.message}');
          _resumeContent();
        },
      );

      // Ads can't be requested until the `AdDisplayContainer` has been added to
      // the native View hierarchy.
      _requestAds(container);
    },
  );

  bool _shouldShowContentVideo = false;

  final String adTagUrl;

  final bool enablePreloading;

  /// Whether the content video should be displayed.
  bool get shouldShowContentVideo {
    return _shouldShowContentVideo;
  }

  bool get isInitialized {
    return _contentVideoController.value.isInitialized;
  }

  bool get contentVideoIsPlaying => _contentVideoController.value.isPlaying;

  bool get adIsPlaying => _adIsPlaying;

  Future<void> play() async {
    assert(isInitialized);

    if (shouldShowContentVideo && !contentVideoIsPlaying) {
      await _contentVideoController.play();
      notifyListeners();
    } else {
      await _adsManager?.resume();
      notifyListeners();
    }
  }

  Future<void> pause() async {
    assert(isInitialized);

    if (shouldShowContentVideo && contentVideoIsPlaying) {
      await _contentVideoController.pause();
      notifyListeners();
    } else {
      await _adsManager?.pause();
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!shouldShowContentVideo) {
          _adsManager?.resume();
        }
      case AppLifecycleState.inactive:
        // Pausing the Ad video player on Android can only be done in this state
        // because it corresponds to `Activity.onPause`. This state is also
        // triggered before resume, so this will only pause the Ad if the app is
        // in the process of being sent to the background.
        if (!shouldShowContentVideo &&
            _lastLifecycleState == AppLifecycleState.resumed) {
          _adsManager?.pause();
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
    }
    _lastLifecycleState = state;
  }

  Future<void> _requestAds(AdDisplayContainer container) {
    return _adsLoader.requestAds(
      AdsRequest(
        adTagUrl: adTagUrl,
        contentProgressProvider: _contentProgressProvider,
      ),
    );
  }

  Future<void> _resumeContent() async {
    _shouldShowContentVideo = true;
    _adIsPlaying = false;
    notifyListeners();

    if (_adsManager != null) {
      _contentProgressTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (Timer timer) async {
          if (_contentVideoController.value.isInitialized) {
            final Duration? progress = await _contentVideoController.position;
            if (progress != null) {
              await _contentProgressProvider.setProgress(
                progress: progress,
                duration: _contentVideoController.value.duration,
              );
            }
          }
        },
      );
    }

    await _contentVideoController.play();
  }

  Future<void> _pauseContent() {
    _shouldShowContentVideo = false;
    notifyListeners();

    _contentProgressTimer?.cancel();
    _contentProgressTimer = null;
    return _contentVideoController.pause();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _contentProgressTimer?.cancel();
    _contentVideoController.dispose();
    _adsManager?.destroy();
  }
}

/// Widget for showing a video with interleaved ads.
class VideoDisplayer extends StatefulWidget {
  /// Constructs a [VideoDisplayer].
  const VideoDisplayer({super.key, required this.model});

  /// The data model for displaying the video and ads.
  final VideoDisplayerModel model;

  @override
  State<VideoDisplayer> createState() => _VideoDisplayerState();
}

class _VideoDisplayerState extends State<VideoDisplayer> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.model.removeListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: widget.model._contentVideoController.value.aspectRatio,
        child: Stack(
          children: <Widget>[
            widget.model._adDisplayContainer,
            if (widget.model.shouldShowContentVideo)
              VideoPlayer(widget.model._contentVideoController),
          ],
        ),
      ),
    );
  }
}
