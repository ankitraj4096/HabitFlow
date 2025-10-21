import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class MasteryPathLogos extends StatelessWidget {
  const MasteryPathLogos({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tiers = [
      {"id": 1, "name": "The Initiate", "hours": 1, "icon": LucideIcons.sparkles, "gradient": [Colors.grey, Colors.grey.shade700], "glow": Colors.grey},
      {"id": 2, "name": "The Seeker", "hours": 5, "icon": LucideIcons.target, "gradient": [Colors.blue.shade400, Colors.blue.shade600], "glow": Colors.blue},
      {"id": 3, "name": "The Novice", "hours": 10, "icon": LucideIcons.book, "gradient": [Colors.green.shade400, Colors.green.shade600], "glow": Colors.green},
      {"id": 4, "name": "The Apprentice", "hours": 25, "icon": LucideIcons.hammer, "gradient": [Colors.yellow.shade400, Colors.yellow.shade600], "glow": Colors.yellow},
      {"id": 5, "name": "The Adept", "hours": 50, "icon": LucideIcons.zap, "gradient": [Colors.orange.shade400, Colors.orange.shade600], "glow": Colors.orange},
      {"id": 6, "name": "The Disciplined", "hours": 100, "icon": LucideIcons.shield, "gradient": [Colors.purple.shade400, Colors.purple.shade600], "glow": Colors.purple},
      {"id": 7, "name": "The Specialist", "hours": 250, "icon": LucideIcons.award, "gradient": [Colors.pink.shade400, Colors.pink.shade600], "glow": Colors.pink},
      {"id": 8, "name": "The Expert", "hours": 500, "icon": LucideIcons.crown, "gradient": [Colors.indigo.shade400, Colors.indigo.shade600], "glow": Colors.indigo},
      {"id": 9, "name": "The Vanguard", "hours": 1000, "icon": LucideIcons.flame, "gradient": [Colors.red.shade400, Colors.red.shade600], "glow": Colors.red},
      {"id": 10, "name": "The Sentinel", "hours": 1750, "icon": LucideIcons.eye, "gradient": [Colors.cyan.shade400, Colors.cyan.shade600], "glow": Colors.cyan},
      {"id": 11, "name": "The Virtuoso", "hours": 2500, "icon": LucideIcons.music, "gradient": [Colors.teal.shade400, Colors.teal.shade600], "glow": Colors.teal},
      {"id": 12, "name": "The Master", "hours": 4000, "icon": LucideIcons.trophy, "gradient": [Colors.amber.shade400, Colors.amber.shade600], "glow": Colors.amber},
      {"id": 13, "name": "The Grandmaster", "hours": 6000, "icon": LucideIcons.gem, "gradient": [Colors.green.shade400, Colors.green.shade600], "glow": Colors.green},
      {"id": 14, "name": "The Titan", "hours": 8000, "icon": LucideIcons.mountain, "gradient": [Colors.blueGrey.shade400, Colors.blueGrey.shade700], "glow": Colors.blueGrey},
      {"id": 15, "name": "The Luminary", "hours": 10000, "icon": LucideIcons.sun, "gradient": [Colors.yellow.shade300, Colors.orange.shade400, Colors.red.shade500], "glow": Colors.orange},
      {"id": 16, "name": "The Ascended", "hours": "10001+", "icon": LucideIcons.infinity, "gradient": [Colors.purple.shade400, Colors.pink.shade500, Colors.yellow.shade400], "glow": Colors.purple, "animated": true},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1f),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "The Mastery Path",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "15-Tier Progression System • Tap any logo",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Tier Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: tiers.length,
                itemBuilder: (context, index) {
                  final tier = tiers[index];
                  return _TierCard(tier: tier);
                },
              ),

              const SizedBox(height: 30),
              _buildGuideSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e2f).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Flutter Implementation Guide",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            "1. Use flutter_lucide for icons.\n"
            "2. Create TierBadge widget with gradient backgrounds.\n"
            "3. Add BoxShadow glow using the tier color.\n"
            "4. Apply gradients using LinearGradient in containers.\n"
            "5. Add animation for special tiers like 'The Ascended'.",
            style: TextStyle(color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatefulWidget {
  final Map<String, dynamic> tier;
  const _TierCard({required this.tier});

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    if (widget.tier['animated'] == true) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat(reverse: true);
      _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.tier['animated'] == true) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = (widget.tier['gradient'] as List<Color>);
    final glowColor = widget.tier['glow'] as Color;
    final animated = widget.tier['animated'] == true;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e2f),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradientColors),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(animated ? _glowAnim.value : 0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(widget.tier['icon'], color: Colors.white, size: 36),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0f0f1f),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          "T${widget.tier['id']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            widget.tier['name'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.tier['hours']} ${widget.tier['hours'] is int ? 'hours' : ''}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
