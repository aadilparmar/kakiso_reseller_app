import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

const Color accentColor = Color(0xFFE91E63); // Vibrant Pink
const Color purpleHeaderColor = Color(0xFF4A317E); // Deep Purple
const Color lightPurpleBackground = Color(
  0xFFF7F4F9,
); // A light background color

class FinancialInsights extends StatefulWidget {
  const FinancialInsights({super.key});

  @override
  State<FinancialInsights> createState() => _FinancialInsightsState();
}

class _FinancialInsightsState extends State<FinancialInsights> {
  final PageController _pageController = PageController();

  final List<InsightItem> _insights = [
    InsightItem(
      image: 'assets/images/posters/poster3.png',
      date: 'May 9, 2014',
      company: 'Biffco Enterprises Ltd.',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
    InsightItem(
      image: 'assets/images/posters/poster3.png',
      date: 'May 9, 2014',
      company: 'Biffco Enterprises Ltd.',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
    InsightItem(
      image: 'assets/images/posters/poster3.png',
      date: 'May 9, 2014',
      company: 'Biffco Enterprises Ltd.',
      description:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Column(
        children: [
          const Text(
            'Financial insights',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.48,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _insights.length,
              onPageChanged: (int page) {
                setState(() {});
              },
              itemBuilder: (context, index) {
                return InsightCard(insight: _insights[index]);
              },
            ),
          ),
          const SizedBox(height: 16),
          SmoothPageIndicator(
            controller: _pageController,
            count: _insights.length,
            effect: const ExpandingDotsEffect(
              activeDotColor: accentColor,
              dotColor: Color.fromARGB(152, 233, 30, 98),
              dotHeight: 8,
              dotWidth: 8,
              spacing: 8,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class InsightItem {
  final String image;
  final String date;
  final String company;
  final String description;

  InsightItem({
    required this.image,
    required this.date,
    required this.company,
    required this.description,
  });
}

class InsightCard extends StatelessWidget {
  final InsightItem insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                insight.image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.company,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
