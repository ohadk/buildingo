import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

Future<Map<String, String>> _authHeaders() async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  return {
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// Network ticket photo with auth headers (API proxy) and soft failure UI.
class TicketPhoto extends StatefulWidget {
  final String url;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const TicketPhoto({
    super.key,
    required this.url,
    this.height = 140,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  State<TicketPhoto> createState() => _TicketPhotoState();
}

class _TicketPhotoState extends State<TicketPhoto> {
  late Future<Map<String, String>> _headers = _authHeaders();

  @override
  void didUpdateWidget(covariant TicketPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _headers = _authHeaders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Map<String, String>>(
          future: _headers,
          builder: (context, snap) {
            if (!snap.hasData) {
              return _ImageSkeleton(height: widget.height);
            }
            return Image.network(
              widget.url,
              height: widget.height,
              width: double.infinity,
              fit: widget.fit,
              headers: snap.data,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return _ImageSkeleton(height: widget.height);
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _ImageSkeleton(height: widget.height);
              },
              errorBuilder: (_, error, stack) => _Placeholder(
                height: widget.height,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: DiraColors.inkSoft,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal pager for ticket photos; tap opens a full-screen viewer.
class TicketPhotoCarousel extends StatefulWidget {
  final List<String> urls;
  final double height;

  const TicketPhotoCarousel({
    super.key,
    required this.urls,
    this.height = 168,
  });

  @override
  State<TicketPhotoCarousel> createState() => _TicketPhotoCarouselState();
}

class _TicketPhotoCarouselState extends State<TicketPhotoCarousel> {
  late final PageController _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _openViewer(int start) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _TicketPhotoLightbox(urls: widget.urls, startIndex: start),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) {
      return TicketPhoto(
        url: urls.first,
        height: widget.height,
        onTap: () => _openViewer(0),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _page,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TicketPhoto(
                url: urls[i],
                height: widget.height,
                onTap: () => _openViewer(i),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              Container(
                width: i == _index ? 8 : 6,
                height: i == _index ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? DiraColors.brick
                      : DiraColors.inkSoft.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TicketPhotoLightbox extends StatefulWidget {
  final List<String> urls;
  final int startIndex;

  const _TicketPhotoLightbox({required this.urls, required this.startIndex});

  @override
  State<_TicketPhotoLightbox> createState() => _TicketPhotoLightboxState();
}

class _TicketPhotoLightboxState extends State<_TicketPhotoLightbox> {
  late final PageController _page = PageController(
    initialPage: widget.startIndex,
  );
  late int _index = widget.startIndex;
  late final Future<Map<String, String>> _headers = _authHeaders();

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          SizedBox(
            height: size.height * 0.78,
            width: size.width,
            child: FutureBuilder<Map<String, String>>(
              future: _headers,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return PageView.builder(
                  controller: _page,
                  itemCount: widget.urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        widget.urls[i],
                        fit: BoxFit.contain,
                        width: size.width,
                        height: size.height * 0.78,
                        headers: snap.data,
                        errorBuilder: (_, error, stack) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                '${_index + 1} / ${widget.urls.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageSkeleton extends StatefulWidget {
  final double height;
  const _ImageSkeleton({required this.height});

  @override
  State<_ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<_ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          height: widget.height,
          width: double.infinity,
          alignment: Alignment.center,
          color: Color.lerp(
            DiraColors.creamDeep,
            const Color(0xFFE8DFD0),
            t,
          ),
          child: Icon(
            Icons.image_outlined,
            size: widget.height < 80 ? 20 : 28,
            color: DiraColors.inkSoft.withValues(alpha: 0.35 + (0.25 * t)),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  final Widget child;
  const _Placeholder({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      color: DiraColors.creamDeep,
      child: child,
    );
  }
}
