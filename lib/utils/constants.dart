// Static Data
import 'dart:ui';

import 'package:kakiso_reseller_app/screens/dashboard/widgets/sliding_category_bar.dart';

final List<Map<String, String>> leftCategoriesData = [
  {'image': 'https://i.imgur.com/4Z7b2zI.png', 'label': 'Popular'},
  {'image': 'https://i.imgur.com/5zXg2y2.png', 'label': 'Kurti, Saree & L...'},
  {'image': 'https://i.imgur.com/0Xq7g1V.png', 'label': 'Women Western'},
  {'image': 'https://i.imgur.com/E7u1D7R.png', 'label': 'Lingerie'},
  {'image': 'https://i.imgur.com/5u6jL6B.png', 'label': 'Men'},
  {'image': 'https://i.imgur.com/1iQkW2b.png', 'label': 'Kids & Toys'},
  {'image': 'https://i.imgur.com/9yYp7qR.png', 'label': 'Home & Kitchen'},
];

final List<Map<String, String>> gridCategoriesData = [
  {'image': 'https://i.imgur.com/3aXk3kK.png', 'label': 'Smartphones'},
  {'image': 'https://i.imgur.com/lKJiT77.png', 'label': 'Top Brands'},
  {'image': 'https://i.imgur.com/6JcZQ5f.png', 'label': 'Premium Collection'},
  {
    'image': 'https://i.imgur.com/6s9Vqk1.png',
    'label': 'Kurtis & Dress Materials',
  },
  {'image': 'https://i.imgur.com/9HqQY8s.png', 'label': 'Sarees'},
  {'image': 'https://i.imgur.com/3c1t1wM.png', 'label': 'Westernwear'},
  {'image': 'https://i.imgur.com/2Ztq3Kk.png', 'label': 'Jewellery'},
  {'image': 'https://i.imgur.com/7u3m1fG.png', 'label': 'Men Fashion'},
  {'image': 'https://i.imgur.com/8i7F3eY.png', 'label': 'Kids'},
  {'image': 'https://i.imgur.com/0xQj4aP.png', 'label': 'Footwear'},
  {
    'image': 'https://i.imgur.com/4Yp0x5S.png',
    'label': 'Beauty & Personal Care',
  },
  {'image': 'https://i.imgur.com/TU9jK0D.png', 'label': 'Grocery'},
  {'image': 'https://i.imgur.com/5qF8Z0v.png', 'label': 'Accessories'},
  {'image': 'https://i.imgur.com/1f7k7bL.png', 'label': 'Electronics'},
  {'image': 'https://i.imgur.com/2mCz8D3.png', 'label': 'Home Decor & Imp...'},
];

final List<String> allFiltersData = [
  'Trending',
  'New',
  'Under ₹999',
  'Best Seller',
  'Handmade',
];
const Color accentColor = Color(0xFFE91E63);
const Color drawerHeaderColor = Color(0xFF4A317E);
const Color drawerIconColor = Color(0xFFCC0000);

// --- Static Data ---
final List<ProductCategory> homeCategories = [
  ProductCategory(
    imageAssetPath: 'assets/images/icons/jewelry.png',
    label: 'Jewels',
  ),
  ProductCategory(
    imageAssetPath: 'assets/images/icons/cookware.png',
    label: 'Kitchen',
  ),
  ProductCategory(
    imageAssetPath: 'assets/images/icons/headphones.png',
    label: 'Gadegts',
  ),
  ProductCategory(
    imageAssetPath: 'assets/images/icons/incense.png',
    label: 'Aroma',
  ),
  ProductCategory(
    imageAssetPath: 'assets/images/icons/kids.png',
    label: 'Kids',
  ),
];

final List<Map<String, dynamic>> homeProducts = [
  {
    "image": 'assets/images/products/prod_13.png',
    "title": "Elephant Charm Bracelet ",
    "company": "AGOR",
    "price": "₹1199",
    "discount": 20,
  },
  {
    "image": "assets/images/products/prod_12.jpg",
    "title": "Primo Strainer ",
    "company": "Elephant",
    "price": "₹75",
    "discount": 10,
  },
  {
    "image": "assets/images/products/prod_11.jpg",
    "title": "Divorama Insence Sticks",
    "company": "Divorama",
    "price": "₹89",
    "discount": 3,
  },
  {
    "image": "assets/images/products/prod_4.png",
    "title": "Minimalist Desk Lamp",
    "company": "Nexa Mart",
    "price": "₹899",
    "discount": 5,
  },
];
