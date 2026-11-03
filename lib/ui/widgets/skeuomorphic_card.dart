import 'package:flutter/material.dart';

import '../../core/utils/format.dart';
import '../../data/models/account_model.dart';

/// Horizontally scrollable carousel of 3D wallet cards.
/// Cards tilt in 3D and parallax while scrolling (PageController driven).
class WalletCarousel extends StatefulWidget {
  final List<Account> accounts;

  const WalletCarousel({super.key, required this.accounts});

  @override
  State<WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends State<WalletCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.accounts.length,
        itemBuilder: (context, i) => Skeuomorphic3DCard(
          account: widget.accounts[i],
          pageOffset: _page - i,
        ),
      ),
    );
  }
}

/// A single stacked, skeuomorphic wallet card with perspective tilt,
/// rotational skew and a dynamic drop shadow.
class Skeuomorphic3DCard extends StatelessWidget {
  final Account account;
  final double pageOffset;

  const Skeuomorphic3DCard({
    super.key,
    required this.account,
    required this.pageOffset,
  });

  @override
  Widget build(BuildContext context) {
    final t = pageOffset.clamp(-1.0, 1.0);
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, 0.0016) // perspective
      ..rotateY(t * 0.38)
      ..rotateX(t * -0.08)
      ..scale(1.0 - t.abs() * 0.05);

    return Transform.translate(
      offset: Offset(pageOffset * 26, 0), // parallax drift
      child: Transform(
        alignment: Alignment.center,
        transform: tilt,
        child: Stack(
          children: [
            // ghost card behind → stacked spatial depth
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(12, 16),
                child: Transform.scale(scale: 0.93, child: _body(ghost: true)),
              ),
            ),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body({bool ghost = false}) {
    final c1 = ghost ? account.color1.withOpacity(0.30) : account.color1;
    final c2 = ghost ? account.color2.withOpacity(0.30) : account.color2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(ghost ? 0.05 : 0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(ghost ? 0.12 : 0.32),
            offset: const Offset(0, 18),
            blurRadius: 28,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.22),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                account.typeLabel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const Spacer(),
              _chip(),
            ],
          ),
          const Spacer(),
          Text(
            account.name,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            account.maskedNumber,
            style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BALANCE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoneyShort(account.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  account.typeLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip() {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(colors: [Color(0xFFFFE9A8), Color(0xFFD9B64A)]),
        border: Border.all(color: const Color(0xFFB08D2E), width: 1),
      ),
      child: const Icon(Icons.memory_rounded, size: 16, color: Color(0xFF8A6D1F)),
    );
  }
}
