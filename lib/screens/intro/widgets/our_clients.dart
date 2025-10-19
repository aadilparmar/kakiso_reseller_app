import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import the package

// --- Color Definitions (Assuming these are global or in your theme) ---
const Color accentColor = Color(0xFFE91E63); // Vibrant Pink
const Color purpleHeaderColor = Color(0xFF4A317E); // Deep Purple
const Color lightPurpleBackground = Color(
  0xFFF7F4F9,
); // A light background color

// Dummy data for testimonials
class Testimonial {
  final String name;
  final double rating;
  final String review;

  Testimonial({required this.name, required this.rating, required this.review});
}

class KClientTestimonials extends StatefulWidget {
  final Color accentColor;
  final Color purpleHeaderColor;

  const KClientTestimonials({
    super.key,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  State<KClientTestimonials> createState() => _KClientTestimonialsState();
}

class _KClientTestimonialsState extends State<KClientTestimonials> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  ); // Show part of next card
  final List<Testimonial> testimonials = [
    Testimonial(
      name: 'John Snow',
      rating: 4.5,
      review:
          'Lorem ipsum dolor sit amet consectetur. Amet lectus sit ut suspendisse elementum senectus curabitur at et.',
    ),
    Testimonial(
      name: 'Jane Doe',
      rating: 4.0,
      review:
          'Amet lectus sit ut suspendisse elementum senectus curabitur at et. Lorem ipsum dolor sit amet consectetur.',
    ),
    Testimonial(
      name: 'Peter Parker',
      rating: 5.0,
      review:
          'This is an amazing service! Highly recommended. Lorem ipsum dolor sit amet consectetur.',
    ),
    Testimonial(
      name: 'Bruce Wayne',
      rating: 3.5,
      review:
          'Good experience overall. Amet lectus sit ut suspendisse elementum senectus curabitur at et.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    const TextSpan(text: 'Our Clients '),
                    TextSpan(
                      text: 'Says',
                      style: TextStyle(color: widget.accentColor),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Action for "See all"
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: testimonials.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final testimonial = testimonials[index];
              return _buildTestimonialCard(testimonial);
            },
          ),
        ),
        const SizedBox(height: 20),
        SmoothPageIndicator(
          controller: _pageController,
          count: testimonials.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 5,
            activeDotColor: widget.accentColor,
            dotColor: widget.accentColor.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(Testimonial testimonial) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testimonial.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '(${testimonial.rating})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < testimonial.rating.floor()
                              ? Icons.star
                              : (index < testimonial.rating
                                    ? Icons.star_half
                                    : Icons.star_border),
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.format_quote, // Large quote icon
                size: 60,
                color: Colors.grey.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            // Ensure text takes available space without overflowing
            child: Text(
              testimonial.review,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 4, // Adjust based on desired card height
            ),
          ),
        ],
      ),
    );
  }
}
