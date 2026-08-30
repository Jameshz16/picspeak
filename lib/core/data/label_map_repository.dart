import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'english_stemmer.dart';
import 'word_category.dart';

abstract class LabelMapRepository {
  /// Translate an English label to Spanish.
  String? translate(String enLabel);

  /// Get all categories.
  List<WordCategory> getCategories();

  /// Get words in a specific category.
  List<MapEntry<String, String>> getWordsInCategory(String categoryId);

  /// Get category ID for a word, or 'other' if not found.
  String getCategoryForWord(String enLabel);

  /// Get total word count.
  int get wordCount;

  Future<void> loadMap();
}

class LabelMapRepositoryImpl implements LabelMapRepository {
  Map<String, String> _map = {};
  Map<String, dynamic> _categories = {};
  final _stemmer = EnglishStemmer();

  late Map<String, String> _lowerMap;
  late Map<String, String> _wordToCategory;

  @override
  Future<void> loadMap() async {
    final jsonString = await rootBundle.loadString('assets/labels_es.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    // New format: {"categories": {...}, "words": {...}}
    if (decoded.containsKey('words')) {
      final wordsMap = decoded['words'] as Map<String, dynamic>;
      _map = wordsMap.map((key, value) => MapEntry(key, value.toString()));
      _categories = decoded['categories'] as Map<String, dynamic>? ?? {};
    } else {
      // Legacy flat format fallback
      _map = decoded.map((key, value) => MapEntry(key, value.toString()));
      _categories = {};
    }

    _lowerMap = _map.map((key, value) => MapEntry(key.toLowerCase(), value));

    // Build reverse index: word (case-insensitive) → categoryId
    _wordToCategory = {};
    for (final entry in _staticCategoryWords.entries) {
      for (final word in entry.value) {
        _wordToCategory[word.toLowerCase()] = entry.key;
      }
    }
  }

  /// Static mapping of words to categories, used as source of truth
  /// since the JSON words dict doesn't embed category info per word.
  static const _staticCategoryWords = <String, List<String>>{
    'animals': [
      'Ant', 'Bee', 'Bear', 'Bird', 'Butterfly', 'Cat', 'Chicken', 'Cow',
      'Crab', 'Deer', 'Dog', 'Dolphin', 'Duck', 'Eagle', 'Elephant',
      'Fish', 'Frog', 'Giraffe', 'Goat', 'Goose', 'Hedgehog', 'Horse',
      'Jellyfish', 'Kangaroo', 'Ladybug', 'Lion', 'Lobster', 'Monkey',
      'Mouse', 'Octopus', 'Owl', 'Panda', 'Parrot', 'Penguin', 'Pigeon',
      'Rabbit', 'Raccoon', 'Rat', 'Seal', 'Shark', 'Sheep', 'Snail',
      'Snake', 'Squirrel', 'Starfish', 'Tiger', 'Turtle', 'Whale',
      'Bat', 'Beetle', 'Caterpillar', 'Chick', 'Cockroach', 'Crow',
      'Dragonfly', 'Fly', 'Fox', 'Hamster', 'Hummingbird', 'Lizard',
      'Sparrow', 'Swan', 'Worm', 'Cricket', 'Flamingo', 'Otter',
      'Seahorse', 'Stingray', 'Ferret', 'Pig',
    ],
    'food': [
      'Apple', 'Banana', 'Bread', 'Broccoli', 'Burger', 'Cake',
      'Carrot', 'Cheese', 'Cherry', 'Chocolate', 'Coconut', 'Coffee',
      'Cookie', 'Corn', 'Cucumber', 'Donut', 'Egg', 'Garlic',
      'Grape', 'Grapefruit', 'Hot dog', 'Ice cream', 'Juice', 'Kiwi',
      'Lemon', 'Lettuce', 'Lime', 'Mango', 'Milk', 'Mushroom',
      'Onion', 'Orange', 'Pancake', 'Pasta', 'Peach', 'Pear',
      'Pepper', 'Pineapple', 'Pizza', 'Potato', 'Rice', 'Salad',
      'Sandwich', 'Soda', 'Soup', 'Strawberry', 'Sushi', 'Tea',
      'Tomato', 'Waffle', 'Watermelon', 'Wine', 'Beer', 'Butter',
      'Steak', 'Taco', 'Pumpkin', 'Blueberry', 'Plum', 'Yogurt',
      'Honey', 'Shrimp', 'Tuna',
    ],
    'clothing': [
      'Belt', 'Boot', 'Cap', 'Coat', 'Dress', 'Glove', 'Hat',
      'Jacket', 'Pants', 'Scarf', 'Shirt', 'Shoe', 'Skirt', 'Sock',
      'Sweater', 'Swimsuit', 'Tie', 'Uniform', 'T-shirt', 'High heels',
      'Helmet',
    ],
    'home': [
      'Bed', 'Blanket', 'Bookshelf', 'Chair', 'Clock', 'Closet',
      'Couch', 'Curtain', 'Desk', 'Door', 'Drawer', 'Lamp', 'Mirror',
      'Oven', 'Pillow', 'Refrigerator', 'Rug', 'Sink', 'Table',
      'Toaster', 'Window', 'Blender', 'Microwave', 'Toilet', 'Bathtub',
      'Nightstand', 'Candle', 'Vase',
    ],
    'vehicles': [
      'Airplane', 'Ambulance', 'Bicycle', 'Boat', 'Bus', 'Car',
      'Fire truck', 'Helicopter', 'Motorcycle', 'Scooter', 'Skateboard',
      'Submarine', 'Taxi', 'Train', 'Truck', 'Van', 'Canoe',
      'Sailboat', 'Ship', 'Tractor', 'Rocket', 'Surfboard',
    ],
    'nature': [
      'Beach', 'Cloud', 'Desert', 'Flower', 'Forest', 'Grass',
      'Hill', 'Island', 'Lake', 'Leaf', 'Mountain', 'Moon', 'Ocean',
      'Rain', 'River', 'Rock', 'Sky', 'Snow', 'Star', 'Sun', 'Tree',
      'Volcano', 'Valley', 'Rainbow', 'Cactus',
    ],
    'technology': [
      'Battery', 'Calculator', 'Camera', 'Computer', 'Flashlight',
      'Headphones', 'Keyboard', 'Laptop', 'Microphone', 'Monitor',
      'Printer', 'Remote control', 'Router', 'Speaker', 'Tablet',
      'Television', 'Watch', 'Phone', 'Smartphone', 'Cell phone',
      'Joystick',
    ],
    'body': [
      'Arm', 'Ear', 'Eye', 'Eyebrow', 'Eyelash', 'Foot', 'Hair',
      'Hand', 'Head', 'Heart', 'Leg', 'Mouth', 'Nose', 'Tooth',
      'Tongue', 'Face', 'Shoulder', 'Knee', 'Finger',
    ],
    'music': [
      'Drum', 'Drum kit', 'Flute', 'Guitar', 'Piano', 'Saxophone',
      'Trumpet', 'Violin', 'Cello', 'Harmonica', 'Xylophone', 'Cymbal',
      'Bass guitar',
    ],
    'sports': [
      'Ball', 'Baseball bat', 'Basketball', 'Football', 'Golf club',
      'Soccer', 'Tennis racket', 'Ski', 'Bowling', 'Tennis',
    ],
    'buildings': [
      'Building', 'Church', 'Factory', 'Garage', 'Hospital', 'Hotel',
      'House', 'Lighthouse', 'Restaurant', 'School', 'Store', 'Stadium',
      'Tower', 'Barn',
    ],
    'tools': [
      'Axe', 'Drill', 'Hammer', 'Knife', 'Ladder', 'Nail', 'Pliers',
      'Saw', 'Scissors', 'Screwdriver', 'Shovel', 'Wrench', 'Ruler',
      'Pencil', 'Cutting board', 'Fork', 'Spoon', 'Pan', 'Pot',
    ],
    'toys_kids': [
      'Balloon', 'Doll', 'Kite', 'Teddy bear', 'Toy', 'Candy',
      'Crayon', 'Lollipop',
    ],
    'places': [
      'Airport', 'Castle', 'Cave', 'Library', 'Museum', 'Park',
      'Pool', 'Zoo', 'Playground', 'Cinema', 'Bakery', 'Farm',
    ],
    'other': [
      'Backpack', 'Bag', 'Box', 'Calendar', 'Crown', 'Dice',
      'Flag', 'Gift', 'Key', 'Mask', 'Necklace', 'Umbrella',
      'Wallet', 'Envelope', 'Towel',
    ],
  };

  @override
  String? translate(String enLabel) {
    // 1. Exact match
    final direct = _lowerMap[enLabel.toLowerCase()];
    if (direct != null) return direct;

    // 2. Stemming fallback
    final variants = _stemmer.stemVariants(enLabel);
    for (final variant in variants) {
      final match = _lowerMap[variant];
      if (match != null) return match;
    }

    return null;
  }

  @override
  List<WordCategory> getCategories() {
    return _categories.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      return WordCategory(
        id: entry.key,
        nameEs: data['nameEs'] as String,
        nameEn: data['nameEn'] as String,
        icon: data['icon'] as String,
      );
    }).toList();
  }

  @override
  List<MapEntry<String, String>> getWordsInCategory(String categoryId) {
    // Filter using the reverse index built from static category data
    final categoryWordSet = (_staticCategoryWords[categoryId] ?? [])
        .map((w) => w.toLowerCase())
        .toSet();
    return _map.entries
        .where((e) => categoryWordSet.contains(e.key.toLowerCase()))
        .toList();
  }

  @override
  String getCategoryForWord(String enLabel) {
    return _wordToCategory[enLabel.toLowerCase()] ?? 'other';
  }

  @override
  int get wordCount => _map.length;
}

final labelMapProvider = FutureProvider<LabelMapRepository>((ref) async {
  final repository = LabelMapRepositoryImpl();
  await repository.loadMap();
  return repository;
});
