import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class SampleDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing nails data from your database
  final Map<String, Map<String, dynamic>> _existingNails = {
    'nail1': {
      'name': 'Milky White Pearl',
      'description': 'This nail design features a sweet and delicate beauty with a dominant pastel color palette, enhanced by hand-painted floral patterns that make hands look soft and naturally outstanding.',
      'img_url': 'assets/images/nail1.png',
      'likes': 1234,
      'price': 180000,
      'store_id': '1',
      'tags': ['New', 'Pearl', 'White', 'Elegant', 'Simple', 'Floral'],
    },
    'nail2': {
      'name': 'Pastel Dream Garden',
      'description': 'Inspired by luxurious European style, this nail design uses brown-white color scheme with subtle marble effect, combined with high-quality metal charms creating a noble feeling at first glance.',
      'img_url': 'assets/images/nail2.png',
      'likes': 2130,
      'price': 230000,
      'store_id': '1',
      'tags': ['New', 'Hot Trend', 'Pastel', 'European', 'Marble'],
    },
    'nail3': {
      'name': 'Galaxy Shimmer Night',
      'description': 'This nail set stands out with a transparent base coated with super fine shimmer powder, reflecting mesmerizing sparkles when hands move under light, suitable for both work and parties.',
      'img_url': 'assets/images/nail3.png',
      'likes': 2361,
      'price': 360000,
      'store_id': '2',
      'tags': ['New', 'Galaxy', 'Shimmer', 'Sparkle', 'Party'],
    },
    'nail4': {
      'name': 'Pink Daisy Cutie',
      'description': 'The design focuses on minimalism yet full of character, using delicate geometric lines to create a modern and elegant feeling for those who love minimal style.',
      'img_url': 'assets/images/nail4.png',
      'likes': 3410,
      'price': 250000,
      'store_id': '2',
      'tags': ['Best Choice', 'Minimal', 'Geometric', 'Modern', 'Elegant'],
    },
    'nail5': {
      'name': 'Chrome Silver Mirror',
      'description': 'This nail design has Korean style influences with soft milky pink tones, combined with super smooth ombre technique and small stone embellishments making hands look both youthful and graceful.',
      'img_url': 'assets/images/nail5.png',
      'likes': 1465,
      'price': 200000,
      'store_id': '3',
      'tags': ['New', 'Best Choice', 'Korean', 'Ombre', 'Milky'],
    },
    'nail6': {
      'name': 'Matcha Green Soft Tone',
      'description': 'If you like to stand out, this nail design with wine red color combined with chrome mirror effect will make hands look attractive and full of personality from every angle.',
      'img_url': 'assets/images/nail6.png',
      'likes': 2785,
      'price': 190000,
      'store_id': '3',
      'tags': ['Hot Trend', 'Matcha', 'Green', 'Chrome', 'Bold'],
    },
    'nail7': {
      'name': 'Royal Gold Marble',
      'description': 'This design is highlighted by real dried flowers pressed into transparent gel base, bringing a natural and artistic feeling as if carrying a small garden on your hands.',
      'img_url': 'assets/images/nail7.png',
      'likes': 2417,
      'price': 280000,
      'store_id': '4',
      'tags': ['New', 'Royal', 'Gold', 'Marble', 'Floral', 'Dried Flowers'],
    },
    'nail8': {
      'name': 'Blue Ocean Breeze',
      'description': 'This nail design features a cute style with pastel colors mixed with mini cartoon patterns, creating a cheerful and youthful feeling, suitable for dates or city walks.',
      'img_url': 'assets/images/nail1.png',
      'likes': 1567,
      'price': 220000,
      'store_id': '4',
      'tags': ['New', 'Cute', 'Pastel', 'Cartoon', 'Youthful'],
    },
    'nail9': {
      'name': 'Coffee Mocha Nude',
      'description': 'This nail set is enhanced with 3D gel overlay technique creating soft nail forms, combined with high-quality Swarovski stones making hands more radiant and luxurious at any party.',
      'img_url': 'assets/images/nail1.png',
      'likes': 1560,
      'price': 170000,
      'store_id': '5',
      'tags': ['New', 'Hot Trend', 'Coffee', 'Mocha', '3D', 'Swarovski'],
    },
    'nail10': {
      'name': 'Ruby Red Crystal',
      'description': 'This nail design uses airbrush technique to create extremely smooth gradient effects, paired with a few ultra-thin metal stickers, creating a harmonious overall between art and modern aesthetics.',
      'img_url': 'assets/images/nail1.png',
      'likes': 1240,
      'price': 240000,
      'store_id': '5',
      'tags': ['New', 'Ruby', 'Red', 'Crystal', 'Airbrush', 'Gradient'],
    },
  };

  // Existing stores data from your database
  final Map<String, Map<String, dynamic>> _existingStores = {
    '1': {
      'name': 'Nail Haven Studio',
      'address': '25 Dang Van Ngu, Trung Tu Ward, Dong Da District, Hanoi',
      'img_url': 'assets/images/store1.png',
    },
    '2': {
      'name': 'LumiNail Boutique',
      'address': '72 Nguyen Trai, Thuong Dinh Ward, Thanh Xuan District, Hanoi',
      'img_url': 'assets/images/store2.png',
    },
    '3': {
      'name': 'Glow & Gloss Nails',
      'address': '12 Tran Dai Nghia, Bach Khoa Ward, Hai Ba Trung District, Hanoi',
      'img_url': 'assets/images/store3.png',
    },
    '4': {
      'name': 'PinkAura Nail House',
      'address': '145 Cau Giay, Quan Hoa Ward, Cau Giay District, Hanoi',
      'img_url': 'assets/images/store4.png',
    },
    '5': {
      'name': 'CrystalLeaf Nail Art',
      'address': '8 Ly Quoc Su, Hang Trong Ward, Hoan Kiem District, Hanoi',
      'img_url': 'assets/images/store5.png',
    },
  };

  // Enhanced stores data with additional fields
  final Map<String, Map<String, dynamic>> _enhancedStores = {
    '1': {
      'name': 'Nail Haven Studio',
      'name_lowercase': 'nail haven studio',
      'address': '25 Dang Van Ngu, Trung Tu Ward, Dong Da District, Hanoi',
      'address_lowercase': '25 dang van ngu, trung tu ward, dong da district, hanoi',
      'img_url': 'assets/images/store1.png',
      'phone': '+84 91 234 5678',
      'email': 'info@nailhaven.com',
      'website': 'https://www.nailhavenstudio.com',
      'description': 'Premium nail salon offering professional services with luxurious ambiance and certified nail technicians.',
      'description_lowercase': 'premium nail salon offering professional services with luxurious ambiance and certified nail technicians.',
      'rating': 4.8,
      'review_count': 156,
      'total_score': 748,
      'location': GeoPoint(21.0135, 105.8269),
      'geohash': 'w3g0q',
      'opening_hours': {
        'monday': {'open': '09:00', 'close': '20:00'},
        'tuesday': {'open': '09:00', 'close': '20:00'},
        'wednesday': {'open': '09:00', 'close': '20:00'},
        'thursday': {'open': '09:00', 'close': '20:00'},
        'friday': {'open': '09:00', 'close': '21:00'},
        'saturday': {'open': '08:00', 'close': '21:00'},
        'sunday': {'open': '08:00', 'close': '20:00'}
      },
      'is_open': true,
      'services': ['Gel Polish', 'Nail Art', 'Nail Extension', 'Manicure', 'Pedicure', 'Nail Repair'],
      'services_lowercase': ['gel polish', 'nail art', 'nail extension', 'manicure', 'pedicure', 'nail repair'],
      'categories': ['nail', 'spa', 'beauty'],
      'tags': ['luxury', 'professional', 'clean', 'hygienic', 'modern'],
      'price_range': {'min': 150000, 'max': 500000, 'average': 300000},
      'total_nails': 85,
      'follower_count': 1245,
      'view_count': 10567,
      'owner_id': 'owner_001',
      'owner_name': 'Nguyen Thi A',
      'is_verified': true,
      'is_featured': true,
      'is_premium': true,
      'search_keywords': ['nail salon', 'nail art', 'gel nails', 'manicure', 'pedicure', 'hanoi'],
      'popularity_score': 8.5,
      'created_at': Timestamp.fromDate(DateTime(2023, 6, 15)),
      'updated_at': Timestamp.now(),
    },
    '2': {
      'name': 'LumiNail Boutique',
      'name_lowercase': 'luminail boutique',
      'address': '72 Nguyen Trai, Thuong Dinh Ward, Thanh Xuan District, Hanoi',
      'address_lowercase': '72 nguyen trai, thuong dinh ward, thanh xuan district, hanoi',
      'img_url': 'assets/images/store2.png',
      'phone': '+84 92 345 6789',
      'email': 'contact@luminail.com',
      'website': 'https://www.luminailboutique.com',
      'description': 'Modern nail boutique specializing in trendy nail designs and organic nail care products.',
      'description_lowercase': 'modern nail boutique specializing in trendy nail designs and organic nail care products.',
      'rating': 4.6,
      'review_count': 89,
      'total_score': 409,
      'location': GeoPoint(21.0035, 105.8169),
      'geohash': 'w3g0p',
      'opening_hours': {
        'monday': {'open': '08:30', 'close': '19:30'},
        'tuesday': {'open': '08:30', 'close': '19:30'},
        'wednesday': {'open': '08:30', 'close': '19:30'},
        'thursday': {'open': '08:30', 'close': '19:30'},
        'friday': {'open': '08:30', 'close': '20:00'},
        'saturday': {'open': '08:00', 'close': '20:00'},
        'sunday': {'open': '08:00', 'close': '18:00'}
      },
      'is_open': true,
      'services': ['Regular Polish', 'Gel Polish', 'Nail Art', 'Nail Care', 'Paraffin Wax Treatment'],
      'services_lowercase': ['regular polish', 'gel polish', 'nail art', 'nail care', 'paraffin wax treatment'],
      'categories': ['nail', 'beauty', 'boutique'],
      'tags': ['trendy', 'organic', 'modern', 'friendly', 'affordable'],
      'price_range': {'min': 100000, 'max': 400000, 'average': 200000},
      'total_nails': 120,
      'follower_count': 856,
      'view_count': 6789,
      'owner_id': 'owner_002',
      'owner_name': 'Tran Van B',
      'is_verified': true,
      'is_featured': false,
      'is_premium': true,
      'search_keywords': ['nail boutique', 'organic nails', 'trendy designs', 'thanh xuan'],
      'popularity_score': 7.2,
      'created_at': Timestamp.fromDate(DateTime(2023, 8, 22)),
      'updated_at': Timestamp.now(),
    },
    '3': {
      'name': 'Glow & Gloss Nails',
      'name_lowercase': 'glow & gloss nails',
      'address': '12 Tran Dai Nghia, Bach Khoa Ward, Hai Ba Trung District, Hanoi',
      'address_lowercase': '12 tran dai nghia, bach khoa ward, hai ba trung district, hanoi',
      'img_url': 'assets/images/store3.png',
      'phone': '+84 93 456 7890',
      'email': 'hello@glowgloss.com',
      'website': 'https://www.glowglossnails.com',
      'description': 'Korean-inspired nail salon offering the latest K-beauty nail trends and techniques.',
      'description_lowercase': 'korean-inspired nail salon offering the latest k-beauty nail trends and techniques.',
      'rating': 4.9,
      'review_count': 203,
      'total_score': 994,
      'location': GeoPoint(21.0075, 105.8469),
      'geohash': 'w3g0r',
      'opening_hours': {
        'monday': {'open': '10:00', 'close': '21:00'},
        'tuesday': {'open': '10:00', 'close': '21:00'},
        'wednesday': {'open': '10:00', 'close': '21:00'},
        'thursday': {'open': '10:00', 'close': '21:00'},
        'friday': {'open': '10:00', 'close': '22:00'},
        'saturday': {'open': '09:00', 'close': '22:00'},
        'sunday': {'open': '09:00', 'close': '21:00'}
      },
      'is_open': true,
      'services': ['Korean Gel', 'Nail Art', '3D Nail Design', 'Stone Embellishment', 'Nail Extension'],
      'services_lowercase': ['korean gel', 'nail art', '3d nail design', 'stone embellishment', 'nail extension'],
      'categories': ['nail', 'k-beauty', 'salon'],
      'tags': ['korean', 'trendy', 'artistic', 'creative', 'detailed'],
      'price_range': {'min': 180000, 'max': 600000, 'average': 350000},
      'total_nails': 95,
      'follower_count': 2345,
      'view_count': 18900,
      'owner_id': 'owner_003',
      'owner_name': 'Le Thi C',
      'is_verified': true,
      'is_featured': true,
      'is_premium': true,
      'search_keywords': ['korean nails', 'k-beauty', 'nail art', 'hai ba trung', 'glossy nails'],
      'popularity_score': 9.1,
      'created_at': Timestamp.fromDate(DateTime(2024, 1, 10)),
      'updated_at': Timestamp.now(),
    },
    '4': {
      'name': 'PinkAura Nail House',
      'name_lowercase': 'pinkaura nail house',
      'address': '145 Cau Giay, Quan Hoa Ward, Cau Giay District, Hanoi',
      'address_lowercase': '145 cau giay, quan hoa ward, cau giay district, hanoi',
      'img_url': 'assets/images/store4.png',
      'phone': '+84 94 567 8901',
      'email': 'service@pinkaura.com',
      'website': 'https://www.pinkaura.com',
      'description': 'Cozy nail studio focusing on elegant and sophisticated nail designs for professional women.',
      'description_lowercase': 'cozy nail studio focusing on elegant and sophisticated nail designs for professional women.',
      'rating': 4.5,
      'review_count': 134,
      'total_score': 603,
      'location': GeoPoint(21.0335, 105.7999),
      'geohash': 'w3g1q',
      'opening_hours': {
        'monday': {'open': '09:30', 'close': '20:30'},
        'tuesday': {'open': '09:30', 'close': '20:30'},
        'wednesday': {'open': '09:30', 'close': '20:30'},
        'thursday': {'open': '09:30', 'close': '20:30'},
        'friday': {'open': '09:30', 'close': '21:00'},
        'saturday': {'open': '09:00', 'close': '21:00'},
        'sunday': {'open': '09:00', 'close': '19:00'}
      },
      'is_open': true,
      'services': ['Gel Polish', 'French Manicure', 'Nail Art', 'Nail Strengthening', 'Hand Massage'],
      'services_lowercase': ['gel polish', 'french manicure', 'nail art', 'nail strengthening', 'hand massage'],
      'categories': ['nail', 'studio', 'beauty'],
      'tags': ['elegant', 'sophisticated', 'professional', 'cozy', 'quality'],
      'price_range': {'min': 120000, 'max': 450000, 'average': 250000},
      'total_nails': 78,
      'follower_count': 987,
      'view_count': 7564,
      'owner_id': 'owner_004',
      'owner_name': 'Pham Thi D',
      'is_verified': true,
      'is_featured': false,
      'is_premium': false,
      'search_keywords': ['elegant nails', 'professional nails', 'cau giay', 'nail studio', 'pink aura'],
      'popularity_score': 6.8,
      'created_at': Timestamp.fromDate(DateTime(2023, 11, 5)),
      'updated_at': Timestamp.now(),
    },
    '5': {
      'name': 'CrystalLeaf Nail Art',
      'name_lowercase': 'crystalleaf nail art',
      'address': '8 Ly Quoc Su, Hang Trong Ward, Hoan Kiem District, Hanoi',
      'address_lowercase': '8 ly quoc su, hang trong ward, hoan kiem district, hanoi',
      'img_url': 'assets/images/store5.png',
      'phone': '+84 95 678 9012',
      'email': 'art@crystalleaf.com',
      'website': 'https://www.crystalleafnailart.com',
      'description': 'Artistic nail studio specializing in creative and unique nail art designs for special occasions.',
      'description_lowercase': 'artistic nail studio specializing in creative and unique nail art designs for special occasions.',
      'rating': 4.7,
      'review_count': 187,
      'total_score': 878,
      'location': GeoPoint(21.0285, 105.8519),
      'geohash': 'w3g1s',
      'opening_hours': {
        'monday': {'open': '10:30', 'close': '21:30'},
        'tuesday': {'open': '10:30', 'close': '21:30'},
        'wednesday': {'open': '10:30', 'close': '21:30'},
        'thursday': {'open': '10:30', 'close': '21:30'},
        'friday': {'open': '10:30', 'close': '22:00'},
        'saturday': {'open': '10:00', 'close': '22:00'},
        'sunday': {'open': '10:00', 'close': '20:00'}
      },
      'is_open': true,
      'services': ['Nail Art', 'Crystal Embellishment', 'Airbrush Design', '3D Sculpture', 'Special Occasion Nails'],
      'services_lowercase': ['nail art', 'crystal embellishment', 'airbrush design', '3d sculpture', 'special occasion nails'],
      'categories': ['nail', 'art', 'studio'],
      'tags': ['artistic', 'creative', 'unique', 'luxury', 'special occasion'],
      'price_range': {'min': 200000, 'max': 800000, 'average': 400000},
      'total_nails': 65,
      'follower_count': 1456,
      'view_count': 12345,
      'owner_id': 'owner_005',
      'owner_name': 'Vo Van E',
      'is_verified': true,
      'is_featured': true,
      'is_premium': true,
      'search_keywords': ['nail art', 'crystal nails', 'special occasion', 'hoan kiem', 'artistic nails'],
      'popularity_score': 8.2,
      'created_at': Timestamp.fromDate(DateTime(2024, 2, 14)),
      'updated_at': Timestamp.now(),
    },
  };

  Future<void> enhanceExistingStores() async {
    try {
      print('🔄 Enhancing existing stores with additional fields...');

      for (var storeId in _enhancedStores.keys) {
        final storeData = _enhancedStores[storeId]!;

        // Check if store exists
        final storeRef = _firestore.collection('stores').doc(storeId);
        final storeDoc = await storeRef.get();

        if (storeDoc.exists) {
          // Update existing store with new fields
          await storeRef.update({
            'name_lowercase': storeData['name_lowercase'],
            'address_lowercase': storeData['address_lowercase'],
            'phone': storeData['phone'],
            'email': storeData['email'],
            'website': storeData['website'],
            'description': storeData['description'],
            'description_lowercase': storeData['description_lowercase'],
            'rating': storeData['rating'],
            'review_count': storeData['review_count'],
            'total_score': storeData['total_score'],
            'location': storeData['location'],
            'geohash': storeData['geohash'],
            'opening_hours': storeData['opening_hours'],
            'is_open': storeData['is_open'],
            'services': storeData['services'],
            'services_lowercase': storeData['services_lowercase'],
            'categories': storeData['categories'],
            'tags': storeData['tags'],
            'price_range': storeData['price_range'],
            'total_nails': storeData['total_nails'],
            'follower_count': storeData['follower_count'],
            'view_count': storeData['view_count'],
            'owner_id': storeData['owner_id'],
            'owner_name': storeData['owner_name'],
            'is_verified': storeData['is_verified'],
            'is_featured': storeData['is_featured'],
            'is_premium': storeData['is_premium'],
            'search_keywords': storeData['search_keywords'],
            'popularity_score': storeData['popularity_score'],
            'updated_at': Timestamp.now(),
          });

          print('✅ Updated store: ${storeData['name']}');
        } else {
          // Create new store with all data
          await storeRef.set({
            'name': storeData['name'],
            'name_lowercase': storeData['name_lowercase'],
            'address': storeData['address'],
            'address_lowercase': storeData['address_lowercase'],
            'img_url': storeData['img_url'],
            ...storeData, // Add all other fields
            'created_at': Timestamp.now(),
          });

          print('✅ Created new store: ${storeData['name']}');
        }
      }

      print('🎉 Successfully enhanced all stores!');
    } catch (e) {
      print('❌ Error enhancing stores: $e');
    }
  }

  Future<void> enhanceExistingNails() async {
    try {
      print('🔄 Enhancing existing nails with additional fields...');

      for (var nailId in _existingNails.keys) {
        final nailData = _existingNails[nailId]!;

        // Check if nail exists
        final nailRef = _firestore.collection('nails').doc(nailId);
        final nailDoc = await nailRef.get();

        // Enhanced nail data
        final enhancedData = {
          'name_lowercase': nailData['name'].toLowerCase(),
          'description_lowercase': nailData['description'].toLowerCase(),
          'is_best_choice': nailData['tags']?.contains('Best Choice') ?? false,
          'created_at': Timestamp.fromDate(DateTime(2024, 2, 1)),
          'updated_at': Timestamp.now(),
          'view_count': nailData['likes']! * 2, // Example calculation
          'save_count': (nailData['likes']! / 5).floor(),
          'share_count': (nailData['likes']! / 10).floor(),
          'is_active': true,
          'category': _determineCategory(nailData['tags'] ?? []),
          'difficulty': _determineDifficulty(nailData['tags'] ?? []),
          'estimated_time': _determineEstimatedTime(nailData['tags'] ?? []),
          'materials': _determineMaterials(nailData['tags'] ?? []),
          'color_palette': _determineColorPalette(nailData['name']),
        };

        if (nailDoc.exists) {
          // Update existing nail with new fields
          await nailRef.update(enhancedData);
          print('✅ Updated nail: ${nailData['name']}');
        } else {
          // Create new nail with all data
          await nailRef.set({
            'name': nailData['name'],
            'description': nailData['description'],
            'img_url': nailData['img_url'],
            'likes': nailData['likes'],
            'price': nailData['price'],
            'store_id': nailData['store_id'],
            'tags': nailData['tags'],
            ...enhancedData,
          });

          print('✅ Created new nail: ${nailData['name']}');
        }
      }

      print('🎉 Successfully enhanced all nails!');
    } catch (e) {
      print('❌ Error enhancing nails: $e');
    }
  }

  String _determineCategory(List<String> tags) {
    if (tags.contains('Elegant') || tags.contains('Royal')) return 'elegant';
    if (tags.contains('Cute') || tags.contains('Pastel')) return 'cute';
    if (tags.contains('Modern') || tags.contains('Minimal')) return 'modern';
    if (tags.contains('Artistic') || tags.contains('Creative')) return 'artistic';
    return 'classic';
  }

  int _determineDifficulty(List<String> tags) {
    if (tags.contains('3D') || tags.contains('Sculpture')) return 5;
    if (tags.contains('Art') || tags.contains('Design')) return 4;
    if (tags.contains('Ombre') || tags.contains('Gradient')) return 3;
    if (tags.contains('Simple') || tags.contains('Basic')) return 2;
    return 3;
  }

  int _determineEstimatedTime(List<String> tags) {
    if (tags.contains('3D') || tags.contains('Sculpture')) return 120;
    if (tags.contains('Art') || tags.contains('Design')) return 90;
    if (tags.contains('Ombre') || tags.contains('Gradient')) return 75;
    return 60;
  }

  List<String> _determineMaterials(List<String> tags) {
    final materials = <String>['Base Coat', 'Top Coat'];

    if (tags.contains('Gel')) materials.add('Gel Polish');
    if (tags.contains('Pearl')) materials.add('Pearl Powder');
    if (tags.contains('Crystal') || tags.contains('Swarovski')) materials.add('Crystal Stones');
    if (tags.contains('Chrome')) materials.add('Chrome Powder');
    if (tags.contains('Marble')) materials.add('Marble Gel');

    return materials;
  }

  List<String> _determineColorPalette(String name) {
    if (name.toLowerCase().contains('white')) return ['#FFFFFF', '#F5F5F5', '#FFF8E1'];
    if (name.toLowerCase().contains('pink')) return ['#FFC0CB', '#FFB6C1', '#FF69B4'];
    if (name.toLowerCase().contains('red')) return ['#DC143C', '#B22222', '#8B0000'];
    if (name.toLowerCase().contains('blue')) return ['#1E90FF', '#87CEEB', '#4682B4'];
    if (name.toLowerCase().contains('green')) return ['#98FB98', '#90EE90', '#32CD32'];
    if (name.toLowerCase().contains('gold')) return ['#FFD700', '#DAA520', '#B8860B'];
    return ['#000000', '#333333', '#666666'];
  }

  Future<void> addSearchIndexes() async {
    print('📋 Recommended Firestore Indexes for Search:');
    print('');
    print('1. For store name search:');
    print('   Collection: stores');
    print('   Fields: name_lowercase (Ascending), __name__ (Ascending)');
    print('');
    print('2. For store address search:');
    print('   Collection: stores');
    print('   Fields: address_lowercase (Ascending), __name__ (Ascending)');
    print('');
    print('3. For store tags search:');
    print('   Collection: stores');
    print('   Fields: tags (Array Contains), __name__ (Ascending)');
    print('');
    print('4. For nail name search:');
    print('   Collection: nails');
    print('   Fields: name_lowercase (Ascending), __name__ (Ascending)');
    print('');
    print('5. For nail tags search:');
    print('   Collection: nails');
    print('   Fields: tags (Array Contains), __name__ (Ascending)');
    print('');
    print('⚠️ Please create these indexes in Firebase Console → Firestore → Indexes');
  }

  Future<void> runAllEnhancements() async {
    try {
      print('🚀 Starting data enhancement process...');
      print('=' * 50);

      await enhanceExistingStores();
      print('');

      await enhanceExistingNails();
      print('');

      await addSearchIndexes();
      print('');

      print('🎉 All enhancements completed successfully!');
      print('=' * 50);
      print('');
      print('Next steps:');
      print('1. Create the recommended Firestore indexes');
      print('2. Test your search functionality');
      print('3. Verify data is correctly displayed in the app');
    } catch (e) {
      print('❌ Error during enhancement process: $e');
    }
  }
}